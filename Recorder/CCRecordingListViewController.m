//
//  CCViewController.m
//  Recorder
//
//  Created by Conrad Calmez on 3/23/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import "utilities.h"
#import "CCRecording.h"
#import "CCRecordingListViewController.h"

@interface CCRecordingListViewController ()
{
    NSArray *recordings;
}

@end

@implementation CCRecordingListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	recordings = [[[self class] loadRecodings] copy];
}

- (void)viewWillAppear:(BOOL)animated
{
    recordings = [[[self class] loadRecodings] copy];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Loading Files

// TODO duplicate method, already in recording model
+ (NSString *)recodingsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *recodingsDirectory = [paths objectAtIndex:0];
    recodingsDirectory = [recodingsDirectory stringByAppendingPathComponent:RECODINGS_PATH];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:recodingsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    return recodingsDirectory;
}

+ (NSMutableArray *)loadRecodings {
    NSString *recordingsDirectory = [self recodingsDirectory];
    DebugLog(@"Loading recordings from %@", recordingsDirectory);
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:recordingsDirectory error:&error];
    if (files == nil) {
        NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
        return nil;
    }
    DebugLog(@"found %d files", files.count);
    NSMutableArray *recordings = [NSMutableArray arrayWithCapacity:files.count];
    for (NSString *file in files) {
        if ([file.pathExtension compare:FILE_NAME_EXTENSION options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            CCRecording *rec = [[CCRecording alloc] initWithName:[file stringByDeletingPathExtension]];
            [recordings addObject:rec];
        }
    }
    return recordings;
}

#pragma mark Table View Controller Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [recordings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"recCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[recordings objectAtIndex:indexPath.row] name];
    cell.detailTextLabel.text = @"Additional information to come";
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"All your recodings";
}

@end
