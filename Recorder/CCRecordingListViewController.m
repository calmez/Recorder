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
    NSInteger rowToDelete;
    BOOL isTableInEditMode;
}

@end

@implementation CCRecordingListViewController

@synthesize editModeToggle = _editModeToggle;

- (void)viewDidLoad
{
    [super viewDidLoad];
	recordings = [[[self class] loadRecodings] copy];
    self.editModeToggle.target = self;
    self.editModeToggle.action = @selector(toggleEditMode);
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)  {
        rowToDelete = indexPath.row;
        UIAlertView* deleteConfimation = [[UIAlertView alloc] initWithTitle:@"Confimation"
                                                                    message:@"Do you really want to delete the file?"
                                                                   delegate:self cancelButtonTitle:@"No"
                                                          otherButtonTitles:@"Yes", nil];
        [deleteConfimation show];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate protocol implemetation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    CCRecording* recording = recordings[rowToDelete];
    if (buttonIndex == 1) {
        [recording deleteFile];
    }
    [self updateRecordings];
}

#pragma mark Edit mode for table view

- (void)toggleEditMode
{
    isTableInEditMode = !isTableInEditMode;
    [self.tableView setEditing:isTableInEditMode animated:YES];
}

- (IBAction)nextEntry:(UIBarButtonItem *)sender {
}

@end
