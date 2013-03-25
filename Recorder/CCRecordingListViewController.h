//
//  CCViewController.h
//  Recorder
//
//  Created by Conrad Calmez on 3/23/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCRecordingListViewController : UITableViewController <UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
