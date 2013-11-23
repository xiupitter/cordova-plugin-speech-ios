//
//  XIFileHelper.h
//  微信
//
//  Created by tom on 11/6/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XIFileHelper : NSObject

+(NSURL *) getSpeechDirectory;
+(NSURL *) getImageDirectory;
+(NSURL *) getDocumentDirectory;
+(NSURL *) getSpeechDirectoryTmpFile;
+(NSURL *) getSpeechDirectoryFile:(NSString*)fileName;
+(void) renameSpeechDirectoryFile:(NSString*) sourceFileName to:(NSString*) destFileName;
@end
