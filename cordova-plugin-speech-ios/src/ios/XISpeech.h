#import "CDVPlugin.h"
#import "XIAudio.h"

@interface XISpeech : CDVPlugin <XIRecordAudioDelegate>{
    XIAudio *_mXIAudio;
    NSString *_mplayStatusFunName;
    NSString *_mrecordStatusFunName;
}
- (void)startRecord:(CDVInvokedUrlCommand*)command;
- (void)stopRecord:(CDVInvokedUrlCommand*)command;
- (void)play:(CDVInvokedUrlCommand*)command;
- (void)stopPlay:(CDVInvokedUrlCommand*)command;
- (void)setCancel:(CDVInvokedUrlCommand*)command;
-(void)renameSpeechFile:(CDVInvokedUrlCommand*)command;
@end
