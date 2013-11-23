#import "XISpeech.h"
#import "XIFileHelper.h"

@implementation XISpeech

- (id)initWithWebView:(UIWebView*)theWebView
{
    self = (NGSpeech*)[super initWithWebView:theWebView];
    if (self) {
        // get the documents directory path
        _mXIAudio = [[XIAudio alloc]init];
        _mXIAudio.delegate = self;
    }
    return self;
}

- (void)startRecord:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    [_mXIAudio stopPlay];

    [_mXIAudio startRecord];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopRecord:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    [_mXIAudio stopRecord];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)play:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* fileid;
    NSString* param;
    if ([command.arguments count]==0) {
        NSLog(@"play parameter cannot be null");
    }else if([command.arguments count]==1){
        fileid = [command.arguments objectAtIndex:0];
    }else{
        fileid = [command.arguments objectAtIndex:0];
        param = [command.arguments objectAtIndex:1];
    }
    
    if (fileid != nil) {
        [_mXIAudio play:[NSData dataWithContentsOfURL:[XIFileHelper getSpeechDirectoryFile:[NSString stringWithFormat:@"%@.spx", fileid]]] withParam:param];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopPlay:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    [_mXIAudio stopPlay];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCancel:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSNumber* isCancel = [command.arguments objectAtIndex:0];
    
    if (isCancel != nil) {
        _mXIAudio.isCancel = [isCancel boolValue];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)renameSpeechFile:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* sourceName = [command.arguments objectAtIndex:0];
    NSString* destName = [command.arguments objectAtIndex:1];
    
    if (sourceName != nil&&destName!=nil) {
        [XIFileHelper renameSpeechDirectoryFile:sourceName to:destName];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)recordStatus:(int)status withSpeexFile:(NSURL*) speexFileUrl{
    NSString* jsString = [NSString stringWithFormat:@"%@(%d,\"%@\");", @"cordova.require('com.xiupitter.cordova.speech.Speech').onRecordStatus", status, [speexFileUrl absoluteString]];
    [self.commandDelegate evalJs:jsString];

}
//0 播放 1 播放完成 2出错
-(void)playStatus:(int)status withParm:(id) param{
    NSString* jsString = [NSString stringWithFormat:@"%@(%d,\"%@\");", @"cordova.require('com.xiupitter.cordova.speech.Speech').onPlayStatus", status,param];
    [self.commandDelegate evalJs:jsString];
}

@end
