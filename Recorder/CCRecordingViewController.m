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
- (IBAction)toggleRecording:(UIButton *)sender;
- (IBAction)playRecording:(UIBarButtonItem *)sender;
- (IBAction)pauseRecording:(UIBarButtonItem *)sender;
- (IBAction)deleteRecording:(UIBarButtonItem *)sender;
@end

@implementation CCRecordingViewController

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isRecoding = NO;
    }
    return self;
}

- (void)dealloc
{
    currentRecording = nil;
}

#pragma mark -
#pragma mark Button Actions

- (void)toggleRecording:(UIButton *)sender
{
    isRecoding = !isRecoding;
    [sender setTitle:(isRecoding ? @"Stop" : @"Record") forState:UIControlStateNormal];
    
    if (isRecoding) {
        NSDate* now = [NSDate date];
        NSDateFormatter* format = [[NSDateFormatter alloc] init];
        NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-DE"];
        format.locale = locale;
        format.dateStyle = NSDateFormatterMediumStyle;
        format.timeStyle = NSDateFormatterMediumStyle;
        NSString* filename = [format stringFromDate:now];
        currentRecording = [[CCRecording alloc] initWithName:filename
                                                andAudioData:[NSData data]];
        [currentRecording startRecording];
    } else {
        [currentRecording stopRecording];
        UIAlertView* filenameDialog = [[UIAlertView alloc]
                                                initWithTitle:@"Enter a filename :"
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Save", nil];
        filenameDialog.alertViewStyle = UIAlertViewStylePlainTextInput;
        [filenameDialog textFieldAtIndex:0].text = currentRecording.name;
        [filenameDialog show];
    }
    DebugLog(@"Recoding was %@ from %@", isRecoding ? @"started" : @"stopped", sender);
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
