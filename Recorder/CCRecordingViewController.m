//
//  CCRecordingViewController.m
//  Recorder
//
//  Created by Conrad Calmez on 3/24/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import "utilities.h"
#import "CCRecording.h"
#import "CCRecordingViewController.h"

@interface CCRecordingViewController ()
{
    BOOL isRecoding;
    CCRecording *currentRecording;
}

@end

@implementation CCRecordingViewController

@synthesize recButton = _recButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isRecoding = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.recButton setTarget:self];
	[self.recButton setAction:@selector(toggleRecording:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    currentRecording = nil;
}

#pragma mark Button Actions

- (void)toggleRecording:(UIBarButtonItem *)button
{
    isRecoding = !isRecoding;
    [button setTitle:isRecoding ? @"Stop" : @"Rec"];
    
    if (isRecoding) {
        // just inserting dummy data
        currentRecording = [[CCRecording alloc] initWithName:@"foobar" andAudioData:[@"foobar" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [currentRecording saveFile];
    }
    DebugLog(@"Recoding was %@ from %@", isRecoding ? @"started" : @"stopped", button);
}

@end
