//
//  DKDetailViewController.m
//  DaoKong
//
//  Created by cyyun on 15-2-6.
//  Copyright (c) 2015年 cyyun. All rights reserved.
//

#import "DKDetailViewController.h"
#import "DKAlert.h"
#import "DKRecommendRead.h"
#import "DKCommonInfo.h"
#import "GRMustache.h"
#import "DKOriginalViewController.h"
#import "MWPhoto.h"
#import "MWPhotoBrowser.h"
#import "DKRecommendReadManager.h"
#import "DKAlertManager.h"
#import "UIActionSheet+UFBlock.h"
#import "JSONKit.h"
#import "DKSendTaskTableViewController.h"
#import "DoActionSheet.h"

@interface DKDetailViewController ()<UIWebViewDelegate,MWPhotoBrowserDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>


@property (weak, nonatomic) IBOutlet UIWebView *detailWebView;
@property (weak, nonatomic) IBOutlet UIToolbar *detailToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextPageBtnItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *prePageBtnItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnItemFavorite;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *orginialUrlLinkBtnItem;

@property (nonatomic, strong) FYNHttpRequestLoader *httpRequestLoader;
@property (nonatomic, strong) FYNHttpRequestLoader *httpRequestArticleLoader;
@property (nonatomic, strong) FYNHttpRequestLoader *httpRequestFavoriteLoader;

@property (nonatomic, strong) GRMustacheTemplate *template;

@property (nonatomic, strong) NSArray *picUrlArray;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, assign) NSInteger fontSize;

@end

@implementation DKDetailViewController


#pragma mark - getter

- (FYNHttpRequestLoader *)httpRequestLoader
{
    if (_httpRequestLoader == nil)
    {
        _httpRequestLoader = [[FYNHttpRequestLoader alloc] init];
    }
    return _httpRequestLoader;
}

- (FYNHttpRequestLoader *)httpRequestArticleLoader
{
    if (_httpRequestArticleLoader == nil)
    {
        _httpRequestArticleLoader = [[FYNHttpRequestLoader alloc] init];
    }
    return _httpRequestArticleLoader;
}

- (FYNHttpRequestLoader *)httpRequestFavoriteLoader
{
    if (_httpRequestFavoriteLoader == nil)
    {
        _httpRequestFavoriteLoader = [[FYNHttpRequestLoader alloc] init];
    }
    return _httpRequestFavoriteLoader;
}

- (NSMutableArray *)photos
{
    if (!_photos) {
        _photos = [[NSMutableArray alloc] init];
    }
    return _photos;
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
    // Do any additional setup after loading the view.
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"DetailTemplate" ofType:@"html"];
    self.template = [GRMustacheTemplate templateFromContentsOfFile:templatePath error:NULL];
    
    UIImage *toolbarImage = [DKUtils imageWithColor:RGBCOLOR(60, 140, 156) andSize:CGSizeMake(320.0f, 44.0f)];
    [_detailToolbar setBackgroundImage:toolbarImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(adjustFont:)];
    [self.detailWebView addGestureRecognizer:pinchGestureRecognizer];
    self.detailWebView.userInteractionEnabled = YES;

    //获取信息并刷新界面内容
    [self refreshContent];

    _fontSize = 100;
    
    self.detailWebView.delegate = self;
    
    
}

- (void)adjustFont:(UIPinchGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateEnded) {
        if (gr.scale > 1.0f) {
            if (_fontSize < 140) {
                _fontSize += 20;
            }else{
                [self showHint:@"已是最大字体"];
            }

        }else{
            if (_fontSize > 60) {
                _fontSize -= 20;
            }else{
                [self showHint:@"已是最小字体"];
            }
        }
        NSString *str = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'",_fontSize];
        [self.detailWebView stringByEvaluatingJavaScriptFromString:str];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Target - Action

//前一页
- (IBAction)prePageButtonTapped:(id)sender {
    if (_currentPage == 0) {
        [self showHint:@"已经是第一页了"];
    }else{
        _currentPage --;
        [self refreshContent];
    }
}

//后一页
- (IBAction)nextPageButtonTapped:(id)sender {
    if (_currentPage == (self.listDatas.count - 1)) {
        [self showHint:@"已经是最后一页了"];
    }else{
        _currentPage ++;
        [self refreshContent];
    }
}

//添加收藏或取消收藏
- (IBAction)favouriteButtonTapped:(id)sender {
    // 10 : 已被收藏,  11: 未被收藏
    
    NSInteger tag = self.btnItemFavorite.tag;  // 10 : 已被收藏,  11: 未被收藏
    NSString *action = tag == 10 ? @"WarnFavoritesRemove.htm" : @"WarnFavoritesAdd.htm";
    DKAlert *currentAlert = self.listDatas[_currentPage];
    
    NSString *stringUrl = [NSString stringWithFormat:@"%@/%@", COMMONURL, action];
    NSString *paramsStr = [NSString stringWithFormat:@"aid=%@&warnType=%d",currentAlert.aid, currentAlert.warnType];
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    [self.httpRequestFavoriteLoader cancelAsynRequest];
    [self.httpRequestFavoriteLoader startAsynRequestWithURL:url withParams:paramsStr];
    
    __weak typeof(self) weakSelf = self;
    [self.httpRequestFavoriteLoader setCompletionHandler:^(NSDictionary *resultData, NSString *error){
        if (resultData != nil)
        {
            NSString *message = [resultData objectForKey:@"message"];
            NSString *type = [resultData objectForKey:@"type"];
            if ([type isEqualToString:@"success"])
            {
                if (tag == 10)
                {
                    [weakSelf showHint:@"取消收藏"];
                    weakSelf.btnItemFavorite.image = [UIImage imageNamed:@"nofavourite.png"];
                    weakSelf.btnItemFavorite.tag = 11;
                    [MobClick event:RemoveFavoriteEvent];
                }
                else
                {
                    [weakSelf showHint:@"成功收藏"];
                    weakSelf.btnItemFavorite.image = [UIImage imageNamed:@"favourite.png"];
                    weakSelf.btnItemFavorite.tag = 10;
                    [MobClick event:AddFavoriteEvent];
                }
                
                if (weakSelf.whichParent == dkParentViewController_FavoriteAlerts||
                    weakSelf.whichParent == dkParentViewController_FavoriteRecommend)
                {
                    if (weakSelf.btnItemFavorite.tag == 11)  // 取消了收藏
                    {
                        BOOL bIsAlreadyThere = NO;
                        for (NSNumber *deleteItem in weakSelf.mayDeleteFavoriteItems)
                        {
                            if ([deleteItem integerValue] == weakSelf.currentPage)
                            {
                                bIsAlreadyThere = YES;
                                break;
                            }
                        }
                        if (bIsAlreadyThere == NO)
                        {
                            [weakSelf.mayDeleteFavoriteItems addObject:[NSNumber numberWithInteger:weakSelf.currentPage]];
                        }
                    }
                    else  // 先取消了收藏，后又添加了收藏
                    {
                        NSNumber *shouldRemoveObject = nil;
                        for (NSNumber *deleteItem in weakSelf.mayDeleteFavoriteItems)
                        {
                            if ([deleteItem integerValue] == weakSelf.currentPage)
                            {
                                shouldRemoveObject = deleteItem;
                                break;
                            }
                        }
                        if (shouldRemoveObject != nil)
                        {
                            [weakSelf.mayDeleteFavoriteItems removeObject:shouldRemoveObject];
                        }
                    }
                }
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
//通过邮箱,短信，拷贝来分享内容
- (IBAction)shareInfo:(id)sender {
    DoActionSheet *actionSheet = [[DoActionSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    if (_whichParent == dkParentViewController_AlertSearch || _whichParent == dkParentViewController_FavoriteAlerts || USER_INFO.turnTask == NO) {
        NSArray * operationArray = @[@"邮件",@"短信",@"拷贝"];
        [actionSheet showC:nil cancel:@"取消" buttons:operationArray result:^(int nResult) {
            switch (nResult) {
                case 0:
                    [weakSelf doShareViaMail];
                    break;
                case 1:
                    [weakSelf doShareViaMessage];
                    break;
                case 2:
                    [weakSelf doShareViaCopy];
                    break;
                default:
                    break;
            }
        }];
    }else{
        NSArray *operationArray = @[@"转任务",@"邮件",@"短信",@"拷贝"];
        
        [actionSheet showC:nil cancel:@"取消" buttons:operationArray result:^(int nResult) {
            switch (nResult) {
                case 0:
                    [weakSelf transferTaskAction];
                    break;
                case 1:
                    [weakSelf doShareViaMail];
                    break;
                case 2:
                    [weakSelf doShareViaMessage];
                    break;
                case 3:
                    [weakSelf doShareViaCopy];
                default:
                    break;
            }
        }];
    }
}

#pragma mark - helper method

//转任务

- (void)transferTaskAction
{
    [self performSegueWithIdentifier:@"TransferTask" sender:self];
}

- (void)refreshArticleDetailWithCommonInfo:(DKCommonInfo *)commonInfo
{
    NSString *stringUrl = nil;
    if (_whichParent == dkParentViewController_AlertSearch) {
        stringUrl = [NSString stringWithFormat:@"%@/articleDetail.htm", COMMONURL];
    }else{
        stringUrl = [NSString stringWithFormat:@"%@/warningDetail.htm", COMMONURL];
    }
    NSString *paramsStr = [NSString stringWithFormat:@"aid=%@", commonInfo.aid];
    
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    
    [self.httpRequestArticleLoader cancelAsynRequest];
    [self.httpRequestArticleLoader startAsynRequestWithURL:url withParams:paramsStr];
    
    __weak typeof(self) weakSelf = self;
    [self.httpRequestArticleLoader setCompletionHandler:^(NSDictionary *resultData, NSString *error){
        if (resultData != nil)
        {
            NSString *resultType = [resultData objectForKey:@"type"];
            NSString *message = [resultData objectForKey:@"message"];
            if ([resultType isEqualToString:@"success"])
            {

                
                NSDictionary *articleDetailDic = [resultData objectForKey:@"data"];
                
                //设置摘要字段
                if (weakSelf.whichParent != dkParentViewController_AlertSearch) {
                    NSString *abstract = nil;
                    if ([articleDetailDic objectForKey:@"abContent"] != [NSNull null]) {
                        abstract = [articleDetailDic objectForKey:@"abContent"];
                    }
                    if (abstract.length > 0) {
                        commonInfo.abstract = abstract;
                    }
                }
                
                NSString * content = [articleDetailDic objectForKey:@"content"];
                if (content.length > 0)
                {
                    commonInfo.content = content;
                }
                
                //保存摘要和内容  舆情搜索不需要存储 Sava abstact and content to DB
                if (weakSelf.whichParent != dkParentViewController_AlertSearch) {
                    [[DKAlertManager shareManager] saveAlertAbstrat:commonInfo.abstract andContent:commonInfo.content WithArticleId:commonInfo.aid callBack:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf constructHTMLWithInfo:commonInfo];
                        });
                    }];
                }else{
                    [weakSelf constructHTMLWithInfo:commonInfo];
                }
                
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


- (void)constructHTMLWithInfo:(DKCommonInfo *)commonInfo
{
    [self hideHud];
    
    NSString *imageFileName = nil;
    switch (commonInfo.level) {
        case dkAlertLevel_Urgent:
            imageFileName = @"ico_lvjj@2x";
            break;
        case dkAlertLevel_Serious:
            imageFileName = @"ico_lvzy@2x";
            break;
        case dkAlertLevel_General:
            imageFileName = @"ico_lvyb@2x";
            break;
        default:
            imageFileName = @"ico_lvyb@2x";
            break;
    }
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imageFileName ofType:@"png"];
    NSString *imageFilePath = [[NSURL fileURLWithPath:filePath] absoluteString];

    
    NSString *abstractPath = [[NSBundle mainBundle] pathForResource:@"ico_info@2x" ofType:@"png"];
    NSString *abstractAbsoluteString = [[NSURL fileURLWithPath:abstractPath] absoluteString];
    
    //组建HTML
    NSDictionary *renderObject = nil;
    NSString *replaceContent = [commonInfo.content stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp"];
    replaceContent = [replaceContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    if([commonInfo isKindOfClass:[DKAlert class]])
    {
        DKAlert *alert = (DKAlert *)commonInfo;
        renderObject = @{@"title":alert.title,@"date":alert.tmPost,@"author":(alert.author == nil ? [NSNull null]:alert.author),@"levelImage":imageFilePath,@"site":(alert.site == nil ? [NSNull null]:alert.site),@"abstract":(alert.abstract == nil ? [NSNull null]:alert.abstract),@"content":(replaceContent == nil ? [NSNull null]:replaceContent),@"hasAbstract":@(alert.abstract == nil ? NO :YES),@"abstractImage":abstractAbsoluteString};
        
    }else{
        
        DKRecommendRead * recommendRead = (DKRecommendRead *)commonInfo;
        BOOL hasPic = NO;
        NSInteger numofPic = 0;
        NSString *firstPicUrl = @"";
        if (recommendRead.imageUrls.count > 0) {
            hasPic = YES;
            self.picUrlArray = recommendRead.imageUrls;
            firstPicUrl = [recommendRead.imageUrls firstObject];
            numofPic = recommendRead.imageUrls.count;
        }
        renderObject = @{@"title":commonInfo.title,@"date":commonInfo.tmPost,@"levelImage":imageFilePath,@"abstract":(recommendRead.abstract == nil ? [NSNull null]:recommendRead.abstract),@"content":replaceContent,@"has_pic":[NSNumber numberWithBool:hasPic],@"num_pic":[NSNumber numberWithInteger:numofPic],@"first_picurl":firstPicUrl,@"abstractImage":abstractAbsoluteString};
    }
    
    NSString *htmlContent = [self.template renderObject:renderObject error:NULL];
    
    [self.detailWebView loadHTMLString:htmlContent baseURL:nil];
}


- (NSString *)retrieveShareContent
{
    // 分享的内容: 标题、正文、原文url
    DKCommonInfo *currentCommonInfo = self.listDatas[_currentPage];
    
    NSString *shareContent = @"";
    NSString *title = currentCommonInfo.title;
    if (title.length > 0)
    {
        shareContent = [shareContent stringByAppendingFormat:@"标题：%@\n\n",title];
    }
    if ([currentCommonInfo isKindOfClass:[DKAlert class]]) {
        DKAlert *alert = (DKAlert *)currentCommonInfo;
        NSString *author = alert.author;
        if (author.length > 0) {
            shareContent = [shareContent stringByAppendingFormat:@"作者：%@\n\n",author];
        }
        
        NSString *timePost = alert.tmPost;
        if(timePost.length > 0)
        {
            shareContent = [shareContent stringByAppendingFormat:@"发文时间：%@\n\n",timePost];
        }
    }

    NSString *articleContent = currentCommonInfo.content;
    if (articleContent.length > 0)
    {
        shareContent = [shareContent stringByAppendingFormat:@"内容：\n%@\n\n",articleContent];
    }
    NSString *stringUrl = currentCommonInfo.url;
    if (stringUrl.length > 0)
    {
        shareContent = [shareContent stringByAppendingFormat:@"原文链接：%@",stringUrl];
    }
    
    return shareContent;
}

- (void)doShareViaMail
{
    if ([MFMailComposeViewController canSendMail])
    {
        [MobClick event:ShareMailEvent];
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        mailViewController.navigationBar.tintColor = [UIColor blackColor];
        
        [mailViewController setSubject:nil];
        [mailViewController setToRecipients:nil];
        [mailViewController setMessageBody:[self retrieveShareContent] isHTML:NO];
        
      
        [self presentViewController:mailViewController animated:YES completion:NULL];
       
    }
    else
    {
        [self showHint:@"当前设备不支持发送邮件"];
    }
}

- (void)doShareViaMessage
{
    if ([MFMessageComposeViewController canSendText])
    {
        [MobClick event:ShareSMSEvent];
        
        MFMessageComposeViewController *messageVC = [[MFMessageComposeViewController alloc] init];
        messageVC.messageComposeDelegate = self;
        [messageVC setBody:[self retrieveShareContent]];
        
        [self presentViewController:messageVC animated:YES completion:NULL];
       
    }
    else
    {
        [self showHint:@"当前设备不支持发送短信"];
    }
}

- (void)doShareViaCopy
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self retrieveShareContent];
    
    [self showHint:@"内容拷贝成功\n您可在短信或邮件中粘贴发送"];
    [MobClick event:ShareCopyEvent];
}

#pragma mark - UIWebView delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *scheme = request.URL.scheme;
    NSString *host = request.URL.host;
    
    if ([scheme isEqualToString:@"gap"]) {
        if ([host isEqualToString:@"daoKongDetailClass.showMorePic"]) {
            
            
            [self showAllPic];
            return NO;
        }
        
    }

    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideHud];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideHud];
    [self showHint:@"加载失败"];
}

#pragma mark - helper method

- (void)showAllPic
{
    for (NSString *picUrl in self.picUrlArray) {
        
        NSURL *url = [NSURL URLWithString:picUrl];
        MWPhoto *photo = [MWPhoto photoWithURL:url];
        [self.photos addObject:photo];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    browser.displayActionButton = YES;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:nc animated:YES completion:nil];
}

// 初始化预警信息的收藏状态
- (void)loadFavoriteStateWithArticleID:(NSString *)articleID andWarnType:(NSInteger)warnType
{
    if (self.whichParent == dkParentViewController_FavoriteRecommend ||      // 来自“收藏夹”
        self.whichParent == dkParentViewController_FavoriteAlerts)
    {
        BOOL bIsAlreadyThere = NO;
        for (NSNumber *mayDeleteFavorite in self.mayDeleteFavoriteItems)
        {
            if ([mayDeleteFavorite integerValue] == self.currentPage)
            {
                bIsAlreadyThere = YES;
                break;
            }
        }
        if (bIsAlreadyThere)
        {
            self.btnItemFavorite.image = [UIImage imageNamed:@"nofavourite.png"];
            self.btnItemFavorite.tag = 11;
        }
        else
        {
            self.btnItemFavorite.image = [UIImage imageNamed:@"favourite.png"];
            self.btnItemFavorite.tag = 10;
        }
    }
    else  // 来自“最新预警”、“舆情搜索”、“推荐阅读”
    {
        // 检测当前信息是否被添加收藏
        if (self.btnItemFavorite.isEnabled) {
            NSString *stringUrl = [NSString stringWithFormat:@"%@/WarnFavoritesState.htm", COMMONURL];
            NSString *paramsStr = [NSString stringWithFormat:@"aid=%@&warnType=%d", articleID, warnType];
            NSURL *url = [NSURL URLWithString:stringUrl];
            
            [self.httpRequestFavoriteLoader cancelAsynRequest];
            [self.httpRequestFavoriteLoader startAsynRequestWithURL:url withParams:paramsStr];
            
            __weak typeof(self) weakSelf = self;
            [self.httpRequestFavoriteLoader setCompletionHandler:^(NSDictionary *resultData, NSString *error){
                if (resultData != nil)
                {

                    NSString *message = [resultData objectForKey:@"message"];
                    NSString *type = [resultData objectForKey:@"type"];
                    if ([type isEqualToString:@"success"])
                    {
                        NSDictionary *dataDic = [resultData objectForKey:@"data"];
                        int favoriteStateValue = [[dataDic objectForKey:@"warnFavorites"] intValue];
                        if (favoriteStateValue == 1)
                        {
                            weakSelf.btnItemFavorite.image = [UIImage imageNamed:@"favourite.png"];
                            weakSelf.btnItemFavorite.tag = 10;
                        }else{
                            weakSelf.btnItemFavorite.image = [UIImage imageNamed:@"nofavourite.png"];
                            weakSelf.btnItemFavorite.tag = 11;
                        }
                    }else{
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

    }
}

//刷新页面所有内容
- (void)refreshContent
{
    DKCommonInfo *currentCommonInfo = self.listDatas[_currentPage];
    
    if (_currentPage == 0) {
        _prePageBtnItem.enabled = NO;
    }else{
        _prePageBtnItem.enabled = YES;
    }
    if (_currentPage == self.listDatas.count - 1) {
        _nextPageBtnItem.enabled = NO;
    }else{
        _nextPageBtnItem.enabled = YES;
    }
    if (currentCommonInfo.url.length > 0) {
        self.orginialUrlLinkBtnItem.enabled = YES;
    }else{
        self.orginialUrlLinkBtnItem.enabled = NO;
    }
    
    if (currentCommonInfo.warnType == dkAlertWarnType_CustomAlert) {
        self.btnItemFavorite.enabled = NO;
    }else{
        self.btnItemFavorite.enabled = YES;
    }
    // 设置预警信息的“已读”或“未读”标志，来自“收藏夹”的信息不设置（都是已读过的）
    [self setAlertRead:currentCommonInfo];
    
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:@"正在加载数据中..."];
    if (_whichParent == dkParentViewController_AlertSearch) {
        //搜索的摘要和内容不缓存
        [self refreshArticleDetailWithCommonInfo:currentCommonInfo];
    }else{
        [[DKAlertManager shareManager] fetchAbstractAndContentWithArticleId:currentCommonInfo.aid callBack:^(NSString *abstract, NSString *content) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (content.length > 0) {
                    currentCommonInfo.abstract = abstract;
                    currentCommonInfo.content = content;
                    [weakSelf constructHTMLWithInfo:currentCommonInfo];
                }else{
                    //从后台获取文章内容
                    [self refreshArticleDetailWithCommonInfo:currentCommonInfo];
                }
            });

        }];
    }
    
    //加载是否收藏的状态
    [self loadFavoriteStateWithArticleID:currentCommonInfo.aid andWarnType:currentCommonInfo.warnType];
}

- (void)setAlertRead:(DKCommonInfo *)commonInfo
{
    if (!commonInfo.isRead) {
        commonInfo.isRead = YES;
        
        if (_whichParent == dkParentViewController_LatestAlert) {
            
            // 如果信息来自最新预警，则保存已读标志;并保存第一次点击阅读文章的时间
            NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970] * 1000;
            // 保存预警列表中文章的已读标志到本地数据库
            [[DKAlertManager shareManager] setTheArticleReadWithAid:commonInfo.aid withFirstReadTime:nowTimeInterval warnType:commonInfo.warnType];
        }
        
        if (_whichParent == dkParentViewController_RecommendRead) {
            
            // 保存推荐阅读中文章的已读标志到本地数据库
            [[DKRecommendReadManager shareManager] setTheArticleReadWithAid:commonInfo.aid];
        }
    }

}


#pragma mark - MWPhotoBrowser delegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [self.photos count];
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < [self.photos count])
    {
        return [self.photos objectAtIndex:index];
    }
    return nil;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        [self showHint:@"邮件已发送"];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
   
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:NULL];
  
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TransferTask"]) {
        DKSendTaskTableViewController *sendTaskViewController = [segue destinationViewController];
        sendTaskViewController.parentController = dkParentViewController_AlertDetail;
        DKCommonInfo *commonInfo = _listDatas[_currentPage];
        sendTaskViewController.commonInfo = commonInfo;
    }else{
        DKOriginalViewController *originalViewController = (DKOriginalViewController *)[segue destinationViewController];
        DKAlert *alert = self.listDatas[_currentPage];
        originalViewController.orignialUrl =alert.url;
    }
}


@end
