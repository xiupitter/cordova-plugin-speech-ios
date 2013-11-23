//
//  XISpeex.m
//  微信
//
//  Created by tom on 11/5/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#import "XISpeex.h"

#include <string.h>
#include <unistd.h>

#include "speex.h"

typedef unsigned long long u64;
typedef long long s64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;

u16 readUInt16(char* bis) {
    u16 result = 0;
    result += ((u16)(bis[0])) << 8;
    result += (u8)(bis[1]);
    return result;
}

u32 readUint32(char* bis) {
    u32 result = 0;
    result += ((u32) readUInt16(bis)) << 16;
    bis+=2;
    result += readUInt16(bis);
    return result;
}

s64 readSint64(char* bis) {
    s64 result = 0;
    result += ((u64) readUint32(bis)) << 32;
    bis+=4;
    result += readUint32(bis);
    return result;
}

static int codec_open = 0;
static u32 dec_frame_size;
static u32 enc_frame_size;
static SpeexBits ebits, dbits;
void *enc_state;
void *dec_state;

int Speex_open(int compression) {
    int tmp;
    
    //单例
    if (codec_open++ != 0)
        return 0;
    
    speex_bits_init(&ebits);
    speex_bits_init(&dbits);
    
    enc_state = speex_encoder_init(&speex_nb_mode);
    dec_state = speex_decoder_init(&speex_nb_mode);
    tmp = compression;
    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &tmp);
    speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    
    return 0;
}

/*
 注意encoded必须清零
 @return 被编码的数据量，单位为byte
 */
u32 Speex_encode(const short *inData, int offset, char *encoded, int size) {
    
    short buffer[enc_frame_size];
    int nsamples = size/enc_frame_size;//enc_frame_size:points per frame
    u32 i, tot_bytes = 0;
    int bytesPerFrame = sizeof(short)*dec_frame_size;

    if (!codec_open)
        return 0;
    short *inDataTmp = inData;
    speex_bits_reset(&ebits);
    for (i = 0; i < nsamples; i++) {
        memset(buffer, 0, bytesPerFrame);
        memcpy(buffer, inDataTmp+enc_frame_size*i, bytesPerFrame);
        speex_encode_int(enc_state, buffer, &ebits);
    }
    
    tot_bytes = speex_bits_write(&ebits, (char *)encoded,size);
    return tot_bytes;
}

/*
 注意lin必须清零
 @return 总的数据量，单位为short
 */
u32 Speex_decode(const unsigned char *encoded, short *lin, int size) {
    short output_buffer[dec_frame_size];
    int bytesPerFrame = sizeof(short)*dec_frame_size;
   	if (!codec_open)
        return 0;
    
    speex_bits_reset(&dbits);
    
   	speex_bits_read_from(&dbits, (char *)encoded, size);
	u32 i=0;
   	while(speex_decode_int(dec_state, &dbits, output_buffer)==0){
   		memcpy(lin+i*dec_frame_size, output_buffer,bytesPerFrame);
		i++;
	}
    u32 ret = (dec_frame_size*i);
    return ret;
}

u32 Speex_getFrameSize() {
    
    if (!codec_open)
        return 0;
    return enc_frame_size;
    
}

void Speex_close() {
    
    if (--codec_open != 0)
        return;
    
    speex_bits_destroy(&ebits);
    speex_bits_destroy(&dbits);
    speex_decoder_destroy(dec_state);
    speex_encoder_destroy(enc_state);
}

int SkipCaffHead(char* buf){
    
    if (!buf) {
        return 0;
    }
    char* oldBuf = buf;
    u32 mFileType = readUint32(buf);
    if (0x63616666!=mFileType) {
        return 0;
    }
    buf+=4;
    
    //u16 mFileVersion = readUInt16(buf);
    buf+=2;
    //u16 mFileFlags = readUInt16(buf);
    buf+=2;
    
    //desc free data
    u32 magics[3] = {0x64657363,0x66726565,0x64617461};
    for (int i=0; i<3; ++i) {
        u32 mChunkType = readUint32(buf);buf+=4;
        if (magics[i]!=mChunkType) {
            return 0;
        }
        
        u32 mChunkSize = readSint64(buf);buf+=8;
        if (mChunkSize<=0) {
            return 0;
        }
        if (i==2) {
            return buf-oldBuf;
        }
        buf += mChunkSize;
        
    }
    return 1;
}

/*
 @param channels 声道数
 @param samplesRate 采样率：每秒采样多少个点
 @param byteRate 每秒产生的比特数据量 channels*samplesRate*sampleBits/8
 @param sampleBits 采样位数：一个采样点用多少大的数据保存
 @param dataBytes 音频部分数据的数据量，可以通过帧数nFrame*160*sizeof(short)来计算，这里通过speex直接返回数据量，而不是帧数。
 */
void WriteWAVEHeader(NSMutableData* fpwave, int channels,int samplesRate,int byteRate,int sampleBits,u32 dataBytes)
{
	char tag[10] = "";
	
	// 1. 写RIFF头
	RIFFHEADER riff;
	strcpy(tag, "RIFF");
	memcpy(riff.chRiffID, tag, 4);
	riff.nRiffSize = 4                                     // WAVE
	+ sizeof(XCHUNKHEADER)               // fmt
	+ sizeof(WAVEFORMATX)           // WAVEFORMATX
	+ sizeof(XCHUNKHEADER)               // DATA
	+ dataBytes;    //nFrame*160*sizeof(short)
	strcpy(tag, "WAVE");
	memcpy(riff.chRiffFormat, tag, 4);
	//fwrite(&riff, 1, sizeof(RIFFHEADER), fpwave);
    [fpwave appendBytes:&riff length:sizeof(RIFFHEADER)];
	
	// 2. 写FMT块
	XCHUNKHEADER chunk;
	WAVEFORMATX wfx;
	strcpy(tag, "fmt ");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = sizeof(WAVEFORMATX);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];
	memset(&wfx, 0, sizeof(WAVEFORMATX));
	wfx.nFormatTag = 1;
	wfx.nChannels = channels; // 单声道
	wfx.nSamplesPerSec = samplesRate; // 8khz
	wfx.nAvgBytesPerSec = byteRate;
	wfx.nBlockAlign = 2;
	wfx.nBitsPerSample = sampleBits; // 现在的设备都是16位的
    //fwrite(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    [fpwave appendBytes:&wfx length:sizeof(WAVEFORMATX)];
	
	// 3. 写data块头
	strcpy(tag, "data");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = dataBytes;//nFrame*160*sizeof(short);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];
    
}

NSData* DecodeSpeexToWAV(NSData* speexData){
    NSMutableData* fpwave = nil;
    
    if (speexData.length<=0) {
        return nil;
    }
    short ret[3000*160];//根据8000*0.02=160，得出一帧为0.02秒，这样60秒需要3000帧
    const char* m_speexData = [speexData bytes];
    int maxLen = [speexData length];
    u32 count = Speex_decode(m_speexData,ret,maxLen);//注意这里调用了 decode函数在c语言中如果Speex_decode没有在头文件中声明则该函数必须在Speex_decode后定义，否则Speex_decode会报错：conficting types for xxx函数
    fpwave = [[NSMutableData alloc]init];
    u32 byteSize = 2*count;
    WriteWAVEHeader(fpwave,1,8000,1*8000*16/8,16,byteSize);
    [fpwave appendBytes:ret length:byteSize];

    return fpwave;
}

NSData* EncodeWAVToSpeex(NSData* wavWrapInCafData){
    NSMutableData* fpwave = nil;
    fpwave = [[NSMutableData alloc]init];
    if (wavWrapInCafData.length<=0) {
        return nil;
    }
    const char *a_wavWrapInCafData = [wavWrapInCafData bytes];
    int offset = SkipCaffHead(a_wavWrapInCafData);
    const void *a_wavData = a_wavWrapInCafData+offset;
    char ret[3000*160*2];
    memset(ret, 0, 3000*16*2);
    int byteSize = Speex_encode(a_wavData, 0, ret, ([wavWrapInCafData length]-offset)/2);
    [fpwave appendBytes:ret length:byteSize];

    return fpwave;
}