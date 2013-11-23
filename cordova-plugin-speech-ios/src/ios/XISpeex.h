//
//  XISpeex.h
//  微信
//
//  Created by tom on 11/5/13.
//  Copyright (c) 2013 Reese. All rights reserved.
//

#ifndef XISPEEX_H
#define XISPEEX_H
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define PCM_FRAME_SIZE 160 // 8khz 8000*0.02=160

typedef struct
{
	char chChunkID[4];
	int nChunkSize;
}XCHUNKHEADER;

typedef struct
{
	short nFormatTag;
	short nChannels;
	int nSamplesPerSec;
	int nAvgBytesPerSec;
	short nBlockAlign;
	short nBitsPerSample;
}WAVEFORMAT;

typedef struct
{
	short nFormatTag;
	short nChannels;
	int nSamplesPerSec;
	int nAvgBytesPerSec;
	short nBlockAlign;
	short nBitsPerSample;
	short nExSize;
}WAVEFORMATX;

typedef struct
{
	char chRiffID[4];
	int nRiffSize;
	char chRiffFormat[4];
}RIFFHEADER;

typedef struct
{
	char chFmtID[4];
	int nFmtSize;
	WAVEFORMAT wf;
}FMTBLOCK;

int Speex_open(int compression);
void Speex_close();

// WAVE音频采样频率是8khz
// 音频样本单元数 = 8000*0.02 = 160 (由采样频率决定)
// 声道数 1 : 160
//        2 : 160*2 = 320
// bps决定样本(sample)大小
// bps = 8 --> 8位 unsigned char
//       16 --> 16位 unsigned short
NSData* DecodeSpeexToWAV(NSData* speexData);
NSData* EncodeWAVToSpeex(NSData* wavWrapInCafData);
#endif