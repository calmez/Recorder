//
//  CCRecording.m
//  Recorder
//
//  Created by Conrad Calmez on 3/25/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import "CCRecording.h"

@interface CCRecording ()
{
    NSString* tempFilePath;
    NSTimer* currentTimeFetch;
}
@property (strong, nonatomic) AVAudioRecorder* recorder;
@property (strong, nonatomic) AVAudioPlayer* player;
@end

@implementation CCRecording

@synthesize name = _name;
@synthesize audioData = _audioData;
@synthesize delegate = _delegate;
@synthesize player = _player;
@synthesize recorder = _recorder;

#pragma mark -
#pragma Initialization

- (CCRecording *)initWithName:(NSString *)aName andAudioData:(NSData *)audioData
{
    self = [super init];
    if (self) {
        self.name = [aName copy];
        self.audioData = [audioData copy];
    }
    return self;
}

- (CCRecording *)initWithName:(NSString *)aName
{
    self = [super init];
    if (self) {
        self = [self initWithName:aName andAudioData:nil];
    }
    return self;
}

- (CCRecording *)init
{
    self = [super init];
    if (self) {
        self = [self initWithName:nil andAudioData:nil];
    }
    return self;
}

- (void)dealloc
{
    self.name = nil;
    self.audioData = nil;
}

#pragma mark -
#pragma mark NSCoding Implementation

#define kNameKey @"name"
#define kAudioDataKey @"audioData"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:kNameKey];
    [aCoder encodeObject:_audioData forKey:kAudioDataKey];
}

- (CCRecording *)initWithCoder:(NSCoder *)aCoder
{
    NSString *name = [aCoder decodeObjectForKey:kNameKey];
    NSData *audioData = [aCoder decodeObjectForKey:kAudioDataKey];
    return [self initWithName:name andAudioData:audioData];
}

- (NSData *)audioData {
    if (_audioData != nil) return _audioData;
    _audioData = [[NSData alloc] initWithContentsOfFile:[self filePath]];
    return _audioData;
}

#pragma mark -
#pragma mark File Saving and Deleting

+ (NSString *)recodingsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *recodingsDirectory = [paths objectAtIndex:0];
    recodingsDirectory = [recodingsDirectory stringByAppendingPathComponent:RECODINGS_PATH];
    return recodingsDirectory;
}

+ (BOOL)createPath {
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:[self recodingsDirectory] withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        NSLog(@"Error creating data path: %@", [error localizedDescription]);
    }
    return success;
}

- (NSString *)filePath
{
    [[self class] createPath];
    return [[[[self class] recodingsDirectory] stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:FILE_NAME_EXTENSION];
}

- (void)saveFile
{
    if (self.audioData == nil) return;
    [self.audioData writeToFile:[self filePath] atomically:YES];
    DebugLog(@"Save file with name %@ to %@", self.name, [self filePath]);
}

- (void)deleteFile
{
    NSError *error;
    BOOL success = [[NSFileManager defaultManager]
                                        removeItemAtPath:[self filePath]
                                                   error:&error];
    if (!success) {
        NSLog(@"Error removing document at path %@ : %@",
              [self filePath],
              error.localizedDescription
        );
    }
}

#pragma mark -
#pragma mark Audio Recording

- (void)initializeRecorder
{
    NSString* dir = [[self class] recodingsDirectory];
    NSString* file = [[self.name stringByAppendingString:@"_temp"]
                      stringByAppendingPathExtension:FILE_NAME_EXTENSION];
    NSString* path = [dir stringByAppendingPathComponent:file];
    tempFilePath = path;
    
    NSDictionary* recSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:AVAudioQualityMin],
                                 AVEncoderAudioQualityKey,
                                 [NSNumber numberWithInt:16],
                                 AVEncoderBitRateKey,
                                 [NSNumber numberWithInt: 2],
                                 AVNumberOfChannelsKey,
                                 [NSNumber numberWithFloat:44100.0],
                                 AVSampleRateKey,
                                 nil];
    
    NSError* error = nil;
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                settings:recSettings
                                                   error:&error];
    
    if (error) {
        DebugLog(@"Error initializing recorder : %@", error);
    } else {
        [self.recorder prepareToRecord];
    }
}

- (void)startRecording
{
    [self initializeRecorder];
    [self.recorder record];
}

- (void)stopRecording
{
    [self.recorder stop];
    NSData* soundData = [[NSData alloc] initWithContentsOfFile:tempFilePath];
    self.audioData = soundData;
    [self.recorder deleteRecording];
}

#pragma mark -
#pragma Audio Playback

- (void)initializePlayer
{
    NSError* error = nil;
    
    self.player = [[AVAudioPlayer alloc] initWithData:self.audioData error:&error];
    self.player.delegate = self;
    
    if (error) {
        DebugLog(@"Error initializing player : %@", error);
    }
}

- (void)startPlayback
{
    [self initializePlayer];
    currentTimeFetch = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                interval:1
                                                  target:self
                                                selector:@selector(fetchCurrentTimeWithTimer:)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:currentTimeFetch
                                 forMode:NSDefaultRunLoopMode];
    [self.player play];
    if ([self.delegate respondsToSelector:@selector(statedPlaying)]) {
        [self.delegate statedPlaying];
    }
}

- (void)stopPlayback
{
    if (currentTimeFetch != nil) {
        [currentTimeFetch invalidate];
    }
    if ([self.delegate respondsToSelector:@selector(stoppedPlaying:)]) {
        [self.delegate stoppedPlaying:YES];
    }
    [self.player stop];
}

- (void)pausePlayback
{
    if (currentTimeFetch != nil) {
        [currentTimeFetch invalidate];
    }
    if ([self.delegate respondsToSelector:@selector(stoppedPlaying:)]) {
        [self.delegate stoppedPlaying:YES];
    }
    [self.player pause];
}

- (void)fetchCurrentTimeWithTimer:(NSTimer *)timer
{
    if ([self.delegate respondsToSelector:@selector(currentTime:)]) {
        [self.delegate currentTime:[self.player currentTime]];
    }
}

#pragma mark -
#pragma mark AudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (currentTimeFetch) {
        [currentTimeFetch invalidate];
    }
    if ([self.delegate respondsToSelector:@selector(stoppedPlaying:)]) {
        [self.delegate stoppedPlaying:YES];
    }
    DebugLog(@"Finished playing audio with %@", flag ? @"success" : @"errors");
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    if (currentTimeFetch) {
        [currentTimeFetch invalidate];
    }
    if ([self.delegate respondsToSelector:@selector(stoppedPlaying:)]) {
        [self.delegate stoppedPlaying:NO];
    }
    DebugLog(@"Error decoding audio data : %@", error);
}

#pragma mark -
#pragma mark Duration of the Audio File

- (NSUInteger)durationInSeconds
{
    NSURL *fileURL = [NSURL fileURLWithPath:[self filePath]];
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    CMTime audioDuration = audioAsset.duration;
    float durationInSeconds = CMTimeGetSeconds(audioDuration);
    return [[NSNumber numberWithFloat:durationInSeconds] integerValue];
}

- (NSUInteger)durationInMinutes
{
    return ([self durationInSeconds] / 60);
}

- (NSUInteger)durationInHours
{
    return ([self durationInMinutes] / 60);
}

@end
