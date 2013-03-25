//
//  utilities.h
//  Recorder
//
//  Created by Conrad Calmez on 3/25/13.
//  Copyright (c) 2013 Conrad Calmez. All rights reserved.
//

#ifndef Recorder_utilities_h
#define Recorder_utilities_h

#define AppDelegate ((CCAppDelegate *)[UIApplication sharedApplication].delegate)

#ifdef DEBUG
    #define DebugLog(formatString, args...) NSLog(formatString, args);
#else
    #define DebugLog(formatString, args...)
#endif

#endif
