//
//  DKDetailViewController.h
//  DaoKong
//
//  Created by cyyun on 15-2-6.
//  Copyright (c) 2015年 cyyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKDetailViewController : UIViewController

@property (nonatomic, strong) NSArray *listDatas;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) ParentViewController whichParent;

@property(strong, nonatomic) NSMutableSet *mayDeleteFavoriteItems;  // FromFavoriteRecommend、FromFavoriteAlerts

@end
