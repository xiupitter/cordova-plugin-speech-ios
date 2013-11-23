//
//  XIAudio.m
//  微信
//
//  Created by tom on 11/5/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#import "XIAudio.h"
#import "XISpeex.h"
#import "XIFileHelper.h"
@implementation XIAudio

@synthesize delegate,isCancel;

- (void)dealloc {
    Speex_close();
    [avPlayer stop];
}

-(id)init {
    self = [super init];
    if (self) {
        //Instanciate an instance of the AVAudioSession object.
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        //Setup the audioSession for playback and record.
        //We could just use record and then switch it to playback leter, but
        //since we are going to do both lets set it up once.
        NSError * tmpError;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &tmpError];
        error = tmpError;
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
								 sizeof (audioRouteOverride),
								 &audioRouteOverride);
        
        //Activate the session
        [audioSession setActive:YES error: &tmpError];
        error = tmpError;

        Speex_open(DEFAULT_COMPRESSION);
    }
    return self;
}

-(void) startRecord {
    //Begin the recording session.
    //Error handling removed.  Please add to your own code.
    
    //Setup the dictionary object with all the recording settings that this
    //Recording sessoin will use
    //Its not clear to me which of these are required and which are the bare minimum.
    //This is a good resource: http://www.totodotnet.net/tag/avaudiorecorder/
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                   [NSNumber numberWithFloat:8000.00], AVSampleRateKey,
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                   [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                   nil];
    
    //Now that we have our settings we are going to instanciate an instance of our recorder instance.
    //Generate a temp file for use by the recording.
    //This sample was one I found online and seems to be a good choice for making a tmp file that
    //will not overwrite an existing one.
    //I know this is a mess of collapsed things into 1 call.  I can break it out if need be.
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
    NSLog(@"Using File called: %@",recordedTmpFile);
    
    
    //Setup the recorder to use this file and record to it.
    NSError *tmpError;
    recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&tmpError];
    error = tmpError;
    NSLog(@"record initWithURL");
    //Use the recorder to start the recording.
    //Im not sure why we set the delegate to self yet.
    //Found this in antother example, but Im fuzzy on this still.
    [recorder setDelegate:self];
    //We call this to start the recording process and initialize
    //the subsstems so that when we actually say "record" it starts right away.
    [recorder prepareToRecord];
    NSLog(@"recorder prepareToRecord");
    //Start the actual Recording
    [recorder recordForDuration:60.0f];
    NSLog(@"recorder recordForDuration:60.0");
    //There is an optional method for doing the recording for a limited time see
    //[recorder recordForDuration:(NSTimeInterval) 10]
    
    _mStartRecordTime = [NSDate timeIntervalSinceReferenceDate];
    
}

- (void) stopRecord {
    [recorder stop];
    isCancel = NO;
}

+(NSTimeInterval) getAudioTime:(NSData *) data {
    NSError * error;
    NSData* o = DecodeSpeexToWAV(data);
    if(o==nil){
        return 0;
    }
    AVAudioPlayer*play = [[AVAudioPlayer alloc] initWithData:o error:&error];
    NSTimeInterval n = [play duration];
    return n;
}

//0 播放 1 播放完成 2播放出错 3录音完成 4录音出错 5录音太短
-(void)sendStatus:(int)status withParam:(id) param{
    
    if (status==1||status==2) {
        if (avPlayer!=nil) {
            if ([self.delegate respondsToSelector:@selector(playStatus:withParm:)]) {
                [self.delegate playStatus:status withParm: param];
            }
            [avPlayer stop];
            avPlayer = nil;
        }
    }else if(status==3){
        if (recorder!=nil) {
            if(!isCancel){
            if ([self.delegate respondsToSelector:@selector(recordStatus:withSpeexFile:)]) {
                _mStopRecordTime = [NSDate timeIntervalSinceReferenceDate];
                NSTimeInterval interval =  _mStopRecordTime - _mStartRecordTime;
                if (interval<2.00f) {
                    NSLog(@"录音时间过短,应大于2秒");
                    status=5;
                    [self.delegate recordStatus:status withSpeexFile:nil];
                }else{
                    NSData *dataCaf =[[NSData alloc] initWithContentsOfURL:recorder.url];
                    NSURL *url = [XIFileHelper getSpeechDirectoryTmpFile] ;
                    NSData *dataSpeex =EncodeWAVToSpeex(dataCaf);
                    [dataSpeex writeToURL:url atomically:true];
                    [self.delegate recordStatus:status withSpeexFile:url];
                }
            }
            }
            [recorder stop];
            [recorder deleteRecording];
            recorder = nil;
            
        }
    }else if(status==4){
        if (recorder!=nil) {
            if ([self.delegate respondsToSelector:@selector(recordStatus:withSpeexFile:)]) {
                [self.delegate recordStatus:status withSpeexFile:nil];
            }
            [recorder stop];
            [recorder deleteRecording];
            recorder = nil;
        }
    }
    isCancel = true;
}

-(void) play:(NSData*) data withParam:(id) param{
	//Setup the AVAudioPlayer to play the file that we just recorded.
    //在播放时，只停止
    _playParam = param;
    if (avPlayer!=nil) {
        [self stopPlay];
        return;
    }
    NSLog(@"start decode");
    NSData* o = DecodeSpeexToWAV(data);
    NSLog(@"end decode");
    if(o==nil){
        return;
    }
    NSError *tmpError;
    avPlayer = [[AVAudioPlayer alloc] initWithData:o error:&tmpError];
    error = tmpError;
    avPlayer.delegate = self;
	[avPlayer prepareToPlay];
    [avPlayer setVolume:1.0];
	if(![avPlayer play]){
        [self sendStatus:2 withParam:_playParam];
    } else {
        [self sendStatus:0 withParam:_playParam];
    }
}

-(void) stopPlay {
    if (avPlayer!=nil) {
        [avPlayer stop];
        //stopPlay不会自动调用下面的回调函数，所以要自己调用
        [self sendStatus:1 withParam:_playParam];
        _playParam = nil;
        avPlayer = nil;
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self sendStatus:1 withParam:_playParam];
    _playParam = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    [self sendStatus:2 withParam:_playParam];
    _playParam = nil;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [self sendStatus:3 withParam:nil];
    isCancel =NO;

}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    [self sendStatus:4 withParam:nil];
    isCancel =NO;
}
@end
