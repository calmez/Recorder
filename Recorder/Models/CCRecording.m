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

@end

@implementation CCRecording

@synthesize name = _name;
@synthesize audioData = _audioData;

#pragma mark -
#pragma Initialization

- (CCRecording *)initWithName:(NSString *)aName andAudioData:(NSData *)audioData
{
    self = [super init];
    if (self) {
        self.name = [aName copy];
        self.audioData = [audioData copy];
        
        DebugLog(@"data is %@", self.audioData);
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
    NSString *path = [[[[self class] recodingsDirectory] stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:FILE_NAME_EXTENSION];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:_audioData forKey:kAudioDataKey];
    [archiver finishEncoding];
    [data writeToFile:path atomically:YES];
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

@end
