//
//  CCRecording.h
//  Recorder
//
//  Created by Conrad Calmez on 3/25/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define FILE_NAME_EXTENSION @"wav"
#define RECODINGS_PATH @"Recordings"

@interface CCRecording : NSObject <NSCoding>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSData *audioData;

- (CCRecording *)init;
- (CCRecording *)initWithName:(NSString *)aName;
- (CCRecording *)initWithName:(NSString *)aName andAudioData:(NSData *)audioData; // this is the designated initializer
- (void)saveFile;
- (void)deleteFile;
- (void)startRecording;
- (void)stopRecording;

@end
