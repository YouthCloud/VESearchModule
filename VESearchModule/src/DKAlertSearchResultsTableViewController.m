//
//  DKAlertSearchResultsTableViewController.m
//  DaoKong
//
//  Created by cyyun on 15-2-6.
//  Copyright (c) 2015年 cyyun. All rights reserved.
//

#import "DKAlertSearchResultsTableViewController.h"
#import "SVPullToRefresh.h"
#import "DKAlert.h"
#import "DKDetailViewController.h"
#import "JSONKit.h"

@interface DKAlertSearchResultsTableViewController ()

@property (nonatomic, strong) NSMutableArray *searchAlertData;
@property (nonatomic, strong) FYNHttpRequestLoader *httpRequestLoader;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL noMoreResults;


@end

@implementation DKAlertSearchResultsTableViewController

#pragma mark - getter

- (FYNHttpRequestLoader *)httpRequestLoader
{
    if (_httpRequestLoader == nil)
    {
        _httpRequestLoader = [[FYNHttpRequestLoader alloc] init];
    }
    return _httpRequestLoader;
}

- (NSMutableArray *)searchAlertData
{
    if (_searchAlertData == nil)
    {
        _searchAlertData = [[NSMutableArray alloc] init];
    }
    return _searchAlertData;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentPage = 0;
    _noMoreResults = NO;
    self.clearsSelectionOnViewWillAppear = YES;
    
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf loadMoreDataToTable];
    }];
    
    [self.tableView triggerInfiniteScrolling];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
    [MobClick beginLogPageView:SearchResultView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_httpRequestLoader)
    {
        [self.httpRequestLoader cancelAsynRequest];
        self.httpRequestLoader = nil;
    }
    [MobClick endLogPageView:SearchResultView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadMoreDataToTable
{
    if (!self.noMoreResults) {
        [self grabNewSearchResults];
    }else{
        [self showHint:@"暂无更多数据"];
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.searchAlertData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alertSearchResultCell" forIndexPath:indexPath];
    
    DKAlert *alert = [self.searchAlertData objectAtIndex:indexPath.section];
    
    NSInteger level = alert.level;
    NSString *imageName = levelImage_blue;             // 预警等级 1:红色; 2:黄色; 3:蓝色; 其它为绿色.
    if (level == 3)
    {
        imageName = levelImage_blue;
    }
    else if (level == 2)
    {
        imageName = levelImage_yellow;
    }
    else if (level == 1)
    {
        imageName = levelImage_red;
    }

    UIImageView *levelImageView = (UIImageView *)[cell viewWithTag:100];
    levelImageView.image = [UIImage imageNamed:imageName];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:101];
    titleLabel.text = alert.title;
    
    UILabel *siteLabel = (UILabel *)[cell viewWithTag:102];
    siteLabel.text = alert.site;
    
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:103];
    timeLabel.text = alert.tmPost;
    
    UIImageView *backgroupImageView = (UIImageView *)[cell viewWithTag:104];
    
    NSString *backgroundImageName = backgroundImage_white;
    if (alert.isRead)
    {
        titleLabel.textColor = read_titleColor;
        backgroundImageName = backgroundImage_gray;
    }
    else
    {
        titleLabel.textColor = unread_titleColor;
    }
    backgroupImageView.image = [UIImage imageNamed:backgroundImageName];
    
//    UIView *backgroup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
//    backgroup.backgroundColor = [UIColor clearColor];
//    cell.backgroundView = backgroup;
    
    // Configure the cell...
    
    return cell;
}


#pragma mark - helper method

- (void)grabNewSearchResults
{
    _currentPage ++;
    
    NSString *stringUrl = [NSString stringWithFormat:@"%@/search.htm", COMMONURL];
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    // utf8编码
    NSString *encodeSearchWord = [DKUtils encodeToPercentEscapeString:self.searchKeyWord];
    NSString *paramStr = [NSString stringWithFormat:@"word=%@&size=%d", encodeSearchWord, MAXSIZES];
    
//    if (self.selectedScopeIndex == 0)
//    {
//        paramStr = [paramStr stringByAppendingString:@"&scope=title"];
//    }
//    else if (self.selectedScopeIndex == 1)
//    {
//        paramStr = [paramStr stringByAppendingString:@"&scope=content"];
//    }
//    else
//    {
//        paramStr = [paramStr stringByAppendingString:@"&scope=all"];
//    }
    paramStr = [paramStr stringByAppendingFormat:@"&page=%ld", (long)_currentPage];
    
    [self.httpRequestLoader cancelAsynRequest];
    [self.httpRequestLoader startAsynRequestWithURL:url withParams:paramStr];
    

    __weak typeof(self) weakSelf = self;
    [self.httpRequestLoader setCompletionHandler:^(NSDictionary *resultData, NSString *error) {
        
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
        
        if (error != nil)
        {
            [DKUtils showServerErrorMeassage:error];
        }
        if (resultData != nil)
        {
            
            NSLog(@"result data:%@",resultData);
            NSString *message = [resultData objectForKey:@"message"];
            NSString *type = [resultData objectForKey:@"type"];
           
            if ([type isEqualToString:@"success"])
            {
                
                NSArray *listArray = [resultData objectForKey:@"data"];
                int size = [listArray count];
    
                if (size != MAXSIZES || weakSelf.currentPage == MAXPAGES)
                {
                    //无更多数据,无需再次上拉加载
                    weakSelf.noMoreResults = YES;
                    weakSelf.tableView.showsInfiniteScrolling = NO;
                }
                else
                {
                    weakSelf.noMoreResults = NO;
                }
                [weakSelf updateSearchlertData:listArray];

            }
            else
            {
                int resultCode = [[resultData objectForKey:@"code"] intValue];
                if (resultCode == 5) {
                    [DKUtils showSessionTokenAlertView];
                }
                [weakSelf showHint:message];
            }
        }else{
            [weakSelf showHint:@"网络连接异常"];
        }
    }];
}

// 刷新数据
- (void)updateSearchlertData:(NSArray *)listDatas
{
    if (listDatas != nil)
    {
        for (NSDictionary *singleData in listDatas)
        {
            DKAlert *alert = [[DKAlert alloc] init];
            alert.aid = [singleData objectForKey:@"guid"];
            alert.abstract = [singleData objectForKey:@"abContent"];
            alert.author = [singleData objectForKey:VEauthor];
            if ([singleData objectForKey:@"websiteName"] == [NSNull null]) {
                alert.site = @"";
            }else{
                alert.site = [singleData objectForKey:@"websiteName"];
            }
            alert.title = [singleData objectForKey:VEtitle];
            long long postTime = [[singleData objectForKey:@"postTime"] longLongValue];
            NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:(postTime / 1000.0f)];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            alert.tmPost = [dateFormatter stringFromDate:postDate];
            alert.url = [singleData objectForKey:VEurl];
            alert.level = dkAlertLevel_General;
            alert.isRead = NO;
            [self.searchAlertData addObject:alert];
        }
    }
    [self.tableView reloadData];
    self.navigationItem.title = [NSString stringWithFormat:@"搜索结果 (%lu)", (unsigned long)self.searchAlertData.count];
}

 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     DKDetailViewController *detailViewController = (DKDetailViewController *)[segue destinationViewController];
     detailViewController.listDatas = self.searchAlertData;
     detailViewController.currentPage = self.tableView.indexPathForSelectedRow.section;
     detailViewController.whichParent = dkParentViewController_AlertSearch;
 }
 

@end
