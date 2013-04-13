//
//  CCViewController.m
//  Recorder
//
//  Created by Conrad Calmez on 3/23/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import "CCRecording.h"
#import "CCRecordingListViewController.h"

@interface CCRecordingListViewController ()
{
    NSArray* recordings;
    NSInteger rowToDelete;
    BOOL isTableInEditMode;
    CCRecording* playingItem;
    BOOL isPlaying;
}

@end

@implementation CCRecordingListViewController

@synthesize editModeToggle = _editModeToggle;

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editModeToggle.target = self;
    self.editModeToggle.action = @selector(toggleEditMode);
	[self updateRecordings];
}

- (void)viewWillAppear:(BOOL)animated
{
    isPlaying = NO;
    [self updateRecordings];
}

#pragma mark -
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

+ (NSMutableArray *)loadRecodings
{
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

- (void)updateRecordings
{
    NSArray* files = [[[self class] loadRecodings] copy];
    recordings = [[files reverseObjectEnumerator] allObjects];
    [self.tableView reloadData];
}

#pragma mark -
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
    CCRecording* recording = [recordings objectAtIndex:indexPath.row];
    cell.textLabel.text = [recording name];
    [self fillDetailLabelOfCell:cell forRecoding:recording];
    return cell;
}

- (void)fillDetailLabelOfCell:(UITableViewCell *)cell forRecoding:(CCRecording *)recording
{
    NSUInteger h = [recording durationInHours];
    NSUInteger m = [recording durationInMinutes] - 60*h;
    NSUInteger s = [recording durationInSeconds] - 60*m;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
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

#pragma mark -
#pragma mark Edit mode for table view

- (void)toggleEditMode
{
    isTableInEditMode = !isTableInEditMode;
    [self.tableView setEditing:isTableInEditMode animated:YES];
}

- (IBAction)nextEntry:(UIBarButtonItem *)sender {
}

#pragma mark -
#pragma mark Table navigation methods

- (IBAction)previousEntryWithButton:(UIBarButtonItem *)sender
{
    NSInteger maxSections = 0;
    NSInteger minRows = 0;
    NSInteger maxRows = [self tableView:nil numberOfRowsInSection:maxSections];
    NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath == NULL) {
        selectedIndexPath = [NSIndexPath indexPathForItem:maxRows
                                                inSection:maxSections];
    }
    NSIndexPath* newSelection = [NSIndexPath indexPathForRow:(selectedIndexPath.row > minRows ? selectedIndexPath.row - 1 : 0)
                                                   inSection:selectedIndexPath.section];
    if ([selectedIndexPath compare:newSelection] == NSOrderedSame) {
        return;
    }
    [self.tableView selectRowAtIndexPath:newSelection
                                animated:YES
                          scrollPosition:UITableViewScrollPositionTop];
    if (isPlaying) {
        [self playCurrentItemWithButton:nil];
    }
}

- (IBAction)nextEntryWithButton:(UIBarButtonItem *)sender
{
    NSInteger minSections = 0;
    NSInteger minRows = -1;
    NSInteger maxRows = [self tableView:nil numberOfRowsInSection:minSections] - 1;
    NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath == NULL) {
        selectedIndexPath = [NSIndexPath indexPathForRow:minRows
                                               inSection:minSections];
    }
    NSIndexPath* newSelection = [NSIndexPath indexPathForRow:(selectedIndexPath.row < maxRows ? selectedIndexPath.row + 1 : maxRows)
                                                   inSection:selectedIndexPath.section];
    if ([selectedIndexPath compare:newSelection] == NSOrderedSame) {
        return;
    }
    [self.tableView selectRowAtIndexPath:newSelection
                                animated:YES
                          scrollPosition:UITableViewScrollPositionTop];
    if (isPlaying) {
        [self playCurrentItemWithButton:nil];
    }
}

- (IBAction)playCurrentItemWithButton:(UIBarButtonItem *)sender
{
    isPlaying = YES;
    [playingItem stopPlayback];
    playingItem = recordings[[[self.tableView indexPathForSelectedRow] row]];
    playingItem.delegate = self;
    [playingItem startPlayback];
}

- (IBAction)pausePlayingItemWithButton:(UIBarButtonItem *)sender
{
    isPlaying = NO;
    [playingItem pausePlayback];
}

#pragma mark -
#pragma mark CCRecordingDelegate Methods

- (void)currentTime:(NSTimeInterval)currentTime
{
    NSInteger minSections = 0;
    NSIndexPath* cellPathForCurrentRecording;
    cellPathForCurrentRecording = [NSIndexPath indexPathForRow:[recordings indexOfObject:playingItem]
                                                     inSection:minSections];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPathForCurrentRecording];
    [self fillDetailLabelOfCell:cell forRecoding:playingItem];
    NSUInteger h = round(currentTime) / 60 / 60;
    NSUInteger m = round(currentTime) / 60 - h*60;
    NSUInteger s = round(currentTime) - 60*m - 60*60*h;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d / %@", h, m, s, cell.detailTextLabel.text];
}

- (void)stoppedPlaying:(BOOL)success
{
    NSInteger minSections = 0;
    NSIndexPath* cellPathForCurrentRecording;
    cellPathForCurrentRecording = [NSIndexPath indexPathForRow:[recordings indexOfObject:playingItem]
                                                     inSection:minSections];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPathForCurrentRecording];
    [self fillDetailLabelOfCell:cell forRecoding:playingItem];
}

@end
