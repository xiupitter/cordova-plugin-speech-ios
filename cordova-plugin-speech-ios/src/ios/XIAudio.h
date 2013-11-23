//
//  XIAudio.h
//  微信
//
//  Created by tom on 11/5/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#define DEFAULT_COMPRESSION 8

@protocol XIRecordAudioDelegate <NSObject>
@optional
-(void)recordStatus:(int)status withSpeexFile:(NSURL*) speexFileUrl;
//0 播放 1 播放完成 2出错
-(void)playStatus:(int)status withParm:(id) param;
@end

@interface XIAudio : NSObject <AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    //Variables setup for access in the class:
	AVAudioRecorder * recorder;
	NSError * error;
    AVAudioPlayer * avPlayer;
    NSTimeInterval _mStartRecordTime;
    NSTimeInterval _mStopRecordTime;
    id _playParam;
}

@property (nonatomic,assign)id<XIRecordAudioDelegate> delegate;

#pragma mark -------录音---------------
- (void) stopRecord ;
- (void) startRecord;
@property BOOL isCancel;

#pragma mark ------------播放----------
-(void) play:(NSData*) data withParam:(id) param;
-(void) stopPlay;

+(NSTimeInterval) getAudioTime:(NSData *) data;

@end
