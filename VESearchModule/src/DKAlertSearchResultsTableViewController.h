//
//  DKAlertSearchResultsTableViewController.h
//  DaoKong
//
//  Created by cyyun on 15-2-6.
//  Copyright (c) 2015年 cyyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKAlertSearchResultsTableViewController : UITableViewController

@property (nonatomic, copy) NSString *searchKeyWord;
@property (nonatomic, assign) AlertSearchScope selectedScopeIndex;

@end
