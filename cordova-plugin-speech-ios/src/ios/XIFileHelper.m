//
//  XIFileHelper.m
//  微信
//
//  Created by tom on 11/6/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#import "XIFileHelper.h"

@implementation XIFileHelper

+(NSURL *) getSpeechDirectory{
    NSString* speechsDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"speech"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:speechsDirectory isDirectory:&isDir];
    if(!isExist||!isDir){
        [fileManager createDirectoryAtPath:speechsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return [NSURL fileURLWithPath:speechsDirectory];
}
+(NSURL *) getSpeechDirectoryFile:(NSString*)fileName{
    NSString* speechsDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"speech"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:speechsDirectory isDirectory:&isDir];
    if(!isExist||!isDir){
        [fileManager createDirectoryAtPath:speechsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString* speechFile = [speechsDirectory stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:speechFile];
}
+(NSURL *) getSpeechDirectoryTmpFile{
    NSString* speechsDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"speech"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:speechsDirectory isDirectory:&isDir];
    if(!isExist||!isDir){
        [fileManager createDirectoryAtPath:speechsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString* speechsDirectoryTmpFile = [speechsDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"spx"]];
    return [NSURL fileURLWithPath:speechsDirectoryTmpFile];
}

+(NSURL *) getImageDirectory{
    NSString* imagesDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"image"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:imagesDirectory isDirectory:&isDir];
    if(!isExist||!isDir){
        [fileManager createDirectoryAtPath:imagesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [NSURL fileURLWithPath:imagesDirectory];
}

+(NSURL *) getDocumentDirectory{
    NSString* documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return [NSURL fileURLWithPath:documentsDirectory];
}


+(void) renameSpeechDirectoryFile:(NSString*) sourceFileName to:(NSString*) destFileName{
    NSString* speechsDirectorySourceFile = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"speech"]stringByAppendingPathComponent:sourceFileName];
    NSString* speechsDirectoryDestFile = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"speech"]stringByAppendingPathComponent:destFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:speechsDirectorySourceFile isDirectory:&isDir];
    if(isExist&&!isDir){
        NSError *error;
        if ([fileManager moveItemAtPath:speechsDirectorySourceFile toPath:speechsDirectoryDestFile error:&error] != YES)
            NSLog(@"Unable to move file: %@", [error localizedDescription]);
    }
}

@end
