//
//  CCRecording.m
//  Recorder
//
//  Created by Conrad Calmez on 3/25/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import "utilities.h"
#import "CCRecording.h"

@interface CCRecording ()
{
    NSString* tempFilePath;
}
@property (nonatomic) AVAudioRecorder* recorder;
@property (strong, nonatomic) AVAudioPlayer* player;
@end

@implementation CCRecording

@synthesize name = _name;
@synthesize audioData = _audioData;
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
    NSString *path = [[RECODINGS_PATH stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:FILE_NAME_EXTENSION];
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:path];
    if (codedData == nil) return nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
    _audioData = [unarchiver decodeObjectForKey:kAudioDataKey];
    [unarchiver finishDecoding];
    return _audioData;
}

#pragma mark -
#pragma mark File Saving and Deleting

+ (NSString *)recodingsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *recodingsDirectory = [paths objectAtIndex:0];
    recodingsDirectory = [recodingsDirectory stringByAppendingPathComponent:RECODINGS_PATH];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:recodingsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    return recodingsDirectory;
}

- (BOOL)createPath {
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:RECODINGS_PATH withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        NSLog(@"Error creating data path: %@", [error localizedDescription]);
    }
    return success;
}

- (void)saveFile
{
    if (self.audioData == nil) return;
    [self createPath];
    NSString* path = [[[[self class] recodingsDirectory] stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:FILE_NAME_EXTENSION];
    [self.audioData writeToFile:path atomically:YES];
    DebugLog(@"Save file with name %@ to %@", self.name, path);
}

- (void)deleteFile
{
    NSString *path = [[[[self class] recodingsDirectory] stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:FILE_NAME_EXTENSION];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success) {
        NSLog(@"Error removing document at path %@ : %@", path, error.localizedDescription);
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
    [self.player play];
}

- (void)stopPlayback
{
    [self.player stop];
}

- (void)pausePlayback
{
    [self.player pause];
}

#pragma mark -
#pragma mark AudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    DebugLog(@"Finished playing audio with %@", flag ? @"success" : @"errors");
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    DebugLog(@"Error decoding audio data : %@", error);
}

@end
