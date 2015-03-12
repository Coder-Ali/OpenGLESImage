//
//  OIVideoCamera.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-12-1.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIVideoCamera.h"
#import "OIContext.h"

@interface OIVideoCamera ()
{
    dispatch_queue_t microphoneQueue_;
    
    AVCaptureDevice *microphone_;
    AVCaptureDeviceInput *audioInput_;
    AVCaptureAudioDataOutput *audioOutput_;
}

@end

@implementation OIVideoCamera

#pragma mark - Lifecycle

- (void)dealloc
{
    microphone_ = nil;
    
    if (cameraSession_) {
        [self stopRunning];
        
        if (audioInput_) {
            [cameraSession_ removeInput:audioInput_];
            [audioInput_ release];
        }
        if (audioOutput_) {
            [audioOutput_ setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
            [cameraSession_ removeOutput:audioOutput_];
            [audioOutput_ release];
        }
    }
    
    if (microphoneQueue_) {
        dispatch_release(microphoneQueue_);
    }
    
    [super dealloc];
}

- (id)init
{
    self = [self initWithCameraPosition:AVCaptureDevicePositionBack sessionPreset:AVCaptureSessionPresetHigh];
    if (self) {
        //
    }
    return self;
}

- (id)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition sessionPreset:(NSString *)sessionPreset
{
    self = [super initWithCameraPosition:cameraPosition sessionPreset:sessionPreset];
    
    if (self) {
        microphoneQueue_ = dispatch_queue_create("com.shuliansoftware.OpenGLESImage.microphoneQueue", NULL);
        
        [cameraSession_ beginConfiguration];
        
        microphone_ = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        NSError *error = nil;
        
        audioInput_ = [[AVCaptureDeviceInput alloc] initWithDevice:microphone_ error:&error];
        
        if (error) {
            NSLog(@"OpenGLESImage Error at OIVideoCamera - (id)initWithCameraPosition: sessionPreset:, message: %@.", error);
        }
        
        if ([cameraSession_ canAddInput:audioInput_])
        {
            [cameraSession_ addInput:audioInput_];
        }
        else {
            NSLog(@"OpenGLESImage Error at OIVideoCamera - (id)initWithCameraPosition: sessionPreset:, message: audio input can not be add.");
        }
        
        audioOutput_ = [[AVCaptureAudioDataOutput alloc] init];
        
        if ([cameraSession_ canAddOutput:audioOutput_])
        {
            [cameraSession_ addOutput:audioOutput_];
        }
        else
        {
            NSLog(@"OpenGLESImage Error at OIVideoCamera - (id)initWithCameraPosition: sessionPreset:, message: audio output can not be add.");
        }
        
        [audioOutput_ setSampleBufferDelegate:self queue:microphoneQueue_];
        
        [cameraSession_ commitConfiguration];
    }
    
    return self;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!self.isEnabled) {
        return;
    }
    
    if (captureOutput == audioOutput_)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoCamera:didReceiveAudioSampleBuffer:)]) {
            CFRetain(sampleBuffer);
            
            [OIContext performAsynchronouslyOnImageProcessingQueue:^{
                
                [self.delegate videoCamera:self didReceiveAudioSampleBuffer:sampleBuffer];
                
                CFRelease(sampleBuffer);
            }];
        }
    }
    else if (captureOutput == videoOutput_)
    {
        [super captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
}

@end
