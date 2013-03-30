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
        NSDate* now = [NSDate date];
        NSDateFormatter* format = [[NSDateFormatter alloc] init];
        NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-DE"];
        format.locale = locale;
        format.dateStyle = NSDateFormatterMediumStyle;
        format.timeStyle = NSDateFormatterMediumStyle;
        NSString* filename = [format stringFromDate:now];
        currentRecording = [[CCRecording alloc] initWithName:filename
                                                andAudioData:[@"foobar" dataUsingEncoding:NSUTF8StringEncoding]];
        // TODO actually capture audio data from mic
    } else {
        UIAlertView* filenameDialog = [[UIAlertView alloc] initWithTitle:@"Enter a filename :"
                                                                 message:nil
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:@"Save", nil];
        filenameDialog.alertViewStyle = UIAlertViewStylePlainTextInput;
        [filenameDialog textFieldAtIndex:0].text = currentRecording.name;
        [filenameDialog show];
    }
    DebugLog(@"Recoding was %@ from %@", isRecoding ? @"started" : @"stopped", button);
}

#pragma mark -
#pragma mark UIAlertViewDelegate protocol implemetation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* filename = [alertView textFieldAtIndex:0].text;
    currentRecording.name = filename;
    [currentRecording saveFile];
}

@end
