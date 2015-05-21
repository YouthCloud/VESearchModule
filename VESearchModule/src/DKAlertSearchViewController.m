//
//  DKAlertSearchViewController.m
//  DaoKong
//
//  Created by cyyun on 15-2-6.
//  Copyright (c) 2015年 cyyun. All rights reserved.
//

#import "DKAlertSearchViewController.h"
#import "DKAlertSearchResultsTableViewController.h"

@interface DKAlertSearchViewController ()<UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *alertSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchHistoryTableView;

@property (nonatomic, strong) NSMutableArray *searchHistoryMutableArray;

@end

@implementation DKAlertSearchViewController

- (NSMutableArray *)searchHistoryMutableArray
{
    if (!_searchHistoryMutableArray) {
        _searchHistoryMutableArray = [[NSMutableArray alloc] init];
    }
    return _searchHistoryMutableArray;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
   
    [self.navigationController.navigationBar setTranslucent:NO];
    [DKUtils setExtraTableCellLine:self.searchHistoryTableView];
    
    
    //取历史聊天记录
    __weak typeof(self) weakSelf = self;
    [[DKUserInfoManager shareManager] getSearchHistroyByUserName:USER_INFO.userName completionBlock:^(NSArray *resultArray){
        [weakSelf.searchHistoryMutableArray addObjectsFromArray:resultArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.searchHistoryTableView reloadData];
        });
    }];
    
//    UIImage *backgroudImage = [DKUtils imageWithColor:RGBCOLOR(247, 247, 247) andSize:CGSizeMake(320, 40)];
//    [_alertSearchBar setBackgroundImage:backgroudImage];
//    [_alertSearchBar setScopeBarBackgroundImage:backgroudImage];
    
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [MobClick beginLogPageView:SearchView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [MobClick endLogPageView:SearchView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"搜索历史";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowNumber = self.searchHistoryMutableArray.count;
    rowNumber = rowNumber > 0 ? rowNumber + 1 : 0;
    return  rowNumber;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row == self.searchHistoryMutableArray.count) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"clearHistoryCell"];
        cell.textLabel.text = @"清除搜索记录";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        return cell;
    }
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchHistroyCell"];
    cell.textLabel.text = self.searchHistoryMutableArray[indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == self.searchHistoryMutableArray.count) {
        [self.searchHistoryMutableArray removeAllObjects];
        [[DKUserInfoManager shareManager] clearSearchHistoryByUserName:USER_INFO.userName];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.searchHistoryTableView reloadData];
        });

    }else{
        _alertSearchBar.text = self.searchHistoryMutableArray[indexPath.row];
        
        [self performSegueWithIdentifier:@"searchSegue" sender:self];
    }
}


#pragma mark - UISearhBar - delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    _alertSearchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [_alertSearchBar resignFirstResponder];
    _alertSearchBar.text = nil;
    _alertSearchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSLog(@"searchScope:%d",selectedScope);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBar clicked");
    if (![self.searchHistoryMutableArray containsObject:_alertSearchBar.text]) {
        [self.searchHistoryMutableArray insertObject:_alertSearchBar.text atIndex:0];
    }
    [self.searchHistoryTableView reloadData];
    
    [[DKUserInfoManager shareManager] saveSearchHistory:self.searchHistoryMutableArray userName:USER_INFO.userName];
    
    [self performSegueWithIdentifier:@"searchSegue" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    DKAlertSearchResultsTableViewController *alertSearchResultsViewController = (DKAlertSearchResultsTableViewController *)[segue destinationViewController];
    
    alertSearchResultsViewController.searchKeyWord = _alertSearchBar.text;
    alertSearchResultsViewController.selectedScopeIndex = _alertSearchBar.selectedScopeButtonIndex;
}


@end
