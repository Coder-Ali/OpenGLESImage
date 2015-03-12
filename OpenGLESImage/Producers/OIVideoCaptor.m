//
//  OIVideoCaptor.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-31.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIVideoCaptor.h"
#import "OIContext.h"
#import "OITexture.h"

@implementation OIVideoCaptor

@synthesize delegate = delegate_;
@synthesize position = position_;
@synthesize sessionPreset = sessionPreset_;
@synthesize frameRate = frameRate_;
@synthesize focusMode = focusMode_;
@synthesize focusPoint = focusPoint_;
@synthesize exposureMode = exposureMode_;
@synthesize exposurePoint = exposurePoint_;

#pragma mark - Lifecycle

- (void)dealloc
{
    if (VideoCaptorMotionManager_) {
        if (VideoCaptorMotionManager_.isDeviceMotionActive) {
            [VideoCaptorMotionManager_ stopDeviceMotionUpdates];
        }
        
        [VideoCaptorMotionManager_ release];
    }
    
    camera_ = nil;
    
    if (cameraSession_) {
        [self stopRunning];
        if (videoInput_) {
            [cameraSession_ removeInput:videoInput_];
            [videoInput_ release];
        }
        if (videoOutput_) {
            [videoOutput_ setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
            [cameraSession_ removeOutput:videoOutput_];
            [videoOutput_ release];
        }
        
        [cameraSession_ release];
    }
    
    if (cameraQueue_) {
        dispatch_release(cameraQueue_);
    }
    
    [super dealloc];
}

- (id)init
{
    self = [self initWithCameraPosition:AVCaptureDevicePositionBack sessionPreset:AVCaptureSessionPresetPhoto];
    if (self) {
        //
    }
    return self;
}

- (id)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition sessionPreset:(NSString *)sessionPreset
{
    self = [super init];
    if (self) {
        self.delegate = nil;
        
        cameraQueue_ = dispatch_queue_create("com.shuliansoftware.OpenGLESImage.cameraQueue", NULL);
        
        frameRate_ = 0; // This will not set frame rate unless this value gets set to 1 or above
        
        focusMode_ = OIVideoCaptorFocusModeContinuousAutoFocus;
        focusPoint_ = CGPointMake(0.5f, 0.5f);
        
        exposureMode_ = OIVideoCaptorExposureModeContinuousAutoExposure;
        exposurePoint_ = CGPointMake(0.5f, 0.5f);
        
        // Grab the back-facing or front-facing camera
        camera_ = nil;
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices)
        {
            if ([device position] == cameraPosition)
            {
                camera_ = device;
            }
        }
        
        if (!camera_) {
            [self release];
            OIErrorLog(YES, self.class, @"- initWithCameraPosition: sessionPreset:", @"Camera in specified position is not found", nil);
            return nil;
        }
        
        position_ = cameraPosition;
        [self setOutputTextureOrientaionBasingOnCameraPosition:position_];
        
        // Create the capture session
        cameraSession_ = [[AVCaptureSession alloc] init];
        
        [cameraSession_ beginConfiguration];
        
        // Add the video input
        NSError *error = nil;
        videoInput_ = [[AVCaptureDeviceInput alloc] initWithDevice:camera_ error:&error];
        if ([cameraSession_ canAddInput:videoInput_])
        {
            [cameraSession_ addInput:videoInput_];
        }
        else {
            OIErrorLog(YES, self.class, @"- initWithCameraPosition: sessionPreset:", @"Couldn't add video input", nil);
            [self release];
            return nil;
        }
        
        // Add the video frame output
        videoOutput_ = [[AVCaptureVideoDataOutput alloc] init];
        [videoOutput_ setAlwaysDiscardsLateVideoFrames:NO];
        
        [videoOutput_ setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        [videoOutput_ setSampleBufferDelegate:self queue:cameraQueue_];
        
        if ([cameraSession_ canAddOutput:videoOutput_])
        {
            [cameraSession_ addOutput:videoOutput_];
        }
        else
        {
            OIErrorLog(YES, self.class, @"- initWithCameraPosition: sessionPreset:", @"Couldn't add video output", nil);
            [self release];
            return nil;
        }
        
        sessionPreset_ = sessionPreset;
        [cameraSession_ setSessionPreset:sessionPreset_];
        
        // This will let you get 60 FPS video from the 720p preset on an iPhone 4S, but only that device and that preset
        //    AVCaptureConnection *conn = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
        //
        //    if (conn.supportsVideoMinFrameDuration)
        //        conn.videoMinFrameDuration = CMTimeMake(1,60);
        //    if (conn.supportsVideoMaxFrameDuration)
        //        conn.videoMaxFrameDuration = CMTimeMake(1,60);
        
        [cameraSession_ commitConfiguration];
        
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [[OIContext sharedContext] setAsCurrentContext];
            outputTexture_ = [[OITexture alloc] init];
        }];
        
        VideoCaptorMotionManager_ = nil;
    }
    return self;
}

#pragma mark - Camera Controllers

- (void)startRunning
{
    if (![cameraSession_ isRunning]) {
        [cameraSession_ startRunning];
    }
}

- (void)stopRunning
{
    if ([cameraSession_ isRunning]) {
        [cameraSession_ stopRunning];
    }
}

- (void)rotateCamera
{
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition newPosition;
    
    if (position_ == AVCaptureDevicePositionBack)
    {
        newPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        newPosition = AVCaptureDevicePositionBack;
    }
    
    camera_ = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == newPosition)
		{
			camera_ = device;
		}
	}
    if (!camera_) {
        return;
    }
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera_ error:&error];
    
    if (newVideoInput != nil)
    {
        [cameraSession_ beginConfiguration];
        
        [cameraSession_ removeInput:videoInput_];
        if ([cameraSession_ canAddInput:newVideoInput])
        {
            [cameraSession_ addInput:newVideoInput];
            [videoInput_ release];
            videoInput_ = newVideoInput;
        }
        else
        {
            [cameraSession_ addInput:videoInput_];
        }
        
        [cameraSession_ commitConfiguration];
    }
    
    position_ = newPosition;
    frameRate_ = 0;
    
    [self setOutputTextureOrientaionBasingOnCameraPosition:position_];
}

#pragma mark - Properties' Setters & Getters

- (void)setSessionPreset:(NSString *)sessionPreset
{
    [cameraSession_ beginConfiguration];
	
	sessionPreset_ = sessionPreset;
	[cameraSession_ setSessionPreset:sessionPreset_];
	
	[cameraSession_ commitConfiguration];
    
    frameRate_ = 0;
}

- (void)setFrameRate:(int)frameRate;
{
	frameRate_ = frameRate;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    NSError *error = nil;
    [videoInput_.device lockForConfiguration:&error];
    if (error) {
        OIErrorLog(YES, self.class, @"- setFrameRate:", error.description, @"device can not be lock to Configure");
        return;
    }
    if (frameRate_ > 0)
	{
        videoInput_.device.activeVideoMinFrameDuration = CMTimeMake(1, frameRate_);
        videoInput_.device.activeVideoMaxFrameDuration = CMTimeMake(1, frameRate_);
	}
	else
	{
        videoInput_.device.activeVideoMinFrameDuration = kCMTimeInvalid;
        videoInput_.device.activeVideoMaxFrameDuration = kCMTimeInvalid;
	}
    [videoInput_.device unlockForConfiguration];
#else
	if (frameRate_ > 0)
	{
		for (AVCaptureConnection *connection in videoOutput_.connections)
		{
			if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
				connection.videoMinFrameDuration = CMTimeMake(1, frameRate_);
			
			if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
				connection.videoMaxFrameDuration = CMTimeMake(1, frameRate_);
		}
	}
	else
	{
		for (AVCaptureConnection *connection in videoOutput_.connections)
		{
			if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
				connection.videoMinFrameDuration = kCMTimeInvalid; // This sets videoMinFrameDuration back to default
			
			if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
				connection.videoMaxFrameDuration = kCMTimeInvalid; // This sets videoMaxFrameDuration back to default
		}
	}
#endif
}

- (void)setFocusPoint:(CGPoint)focusPoint
{
    if ([videoInput_.device isFocusPointOfInterestSupported] && [videoInput_.device isFocusModeSupported:(AVCaptureFocusMode)focusMode_]) {
		NSError *error;
        CGPoint adjustedPoint = focusPoint;
        if (position_ == AVCaptureDevicePositionBack) {
            adjustedPoint = CGPointMake(adjustedPoint.y, 1.0f - adjustedPoint.x);
        }
        else if (position_ == AVCaptureDevicePositionFront) {
            adjustedPoint = CGPointMake(adjustedPoint.y, adjustedPoint.x);
        }
		if ([videoInput_.device lockForConfiguration:&error]) {
			[videoInput_.device setFocusPointOfInterest:adjustedPoint];
			[videoInput_.device setFocusMode:(AVCaptureFocusMode)focusMode_];
			[videoInput_.device unlockForConfiguration];
		}
        else {
			OIErrorLog(YES, self.class, @"- setFocusPoint:", error.description, @"device can not be lock to Configure");
		}
        focusPoint_ = focusPoint;
	}
    else {
        OIErrorLog(YES, self.class, @"- setFocusPoint:", @"focusPoint or focusMode does not be supported in this device", nil);
    }
}

- (void)setExposurePoint:(CGPoint)exposurePoint
{
    if ([videoInput_.device isExposurePointOfInterestSupported] && [videoInput_.device isExposureModeSupported:(AVCaptureExposureMode)exposureMode_]) {
        NSError *error;
        CGPoint adjustedPoint = exposurePoint;
        if (position_ == AVCaptureDevicePositionBack) {
            adjustedPoint = CGPointMake(adjustedPoint.y, 1.0f - adjustedPoint.x);
        }
        else if (position_ == AVCaptureDevicePositionFront) {
            adjustedPoint = CGPointMake(adjustedPoint.y, adjustedPoint.x);
        }
        if ([videoInput_.device lockForConfiguration:&error]) {
            [videoInput_.device setExposurePointOfInterest:adjustedPoint];
            [videoInput_.device setExposureMode:(AVCaptureExposureMode)exposureMode_];
            [videoInput_.device unlockForConfiguration];
        } else {
            OIErrorLog(YES, self.class, @"- setExposurePoint:", error.description, @"device can not be lock to Configure");
        }
        exposurePoint_ = exposurePoint;
    }
    else {
        OIErrorLog(YES, self.class, @"- setExposurePoint:", @"exposurePoint or exposureMode does not be supported in this device", nil);
    }
}

- (OIVideoCaptorOrientation)orientaion
{
    if (!VideoCaptorMotionManager_) {
        VideoCaptorMotionManager_ = [[CMMotionManager alloc] init];
        if (VideoCaptorMotionManager_.isDeviceMotionAvailable) {
            [VideoCaptorMotionManager_ startDeviceMotionUpdates];
        }
    }
    
    OIVideoCaptorOrientation orientation = OIVideoCaptorOrientationUnknown;
    
    if (VideoCaptorMotionManager_.isDeviceMotionActive && VideoCaptorMotionManager_.deviceMotion) {
        float x = -VideoCaptorMotionManager_.deviceMotion.gravity.x;//-[acceleration x];
        float y =  VideoCaptorMotionManager_.deviceMotion.gravity.y;//[acceleration y];
        float radian = atan2(y, x);
        
        if(radian >= -2.25 && radian <= -0.75)
        {
            if(orientation != OIVideoCaptorOrientationPortrait)
            {
                orientation = OIVideoCaptorOrientationPortrait;
            }
        }
        else if(radian >= -0.75 && radian <= 0.75)
        {
            if(orientation != OIVideoCaptorOrientationLandscapeLeft)
            {
                orientation = OIVideoCaptorOrientationLandscapeLeft;
            }
        }
        else if(radian >= 0.75 && radian <= 2.25)
        {
            if(orientation != OIVideoCaptorOrientationPortraitUpsideDown)
            {
                orientation = OIVideoCaptorOrientationPortraitUpsideDown;
            }
        }
        else if(radian <= -2.25 || radian >= 2.25)
        {
            if(orientation != OIVideoCaptorOrientationLandscapeRight)
            {
                orientation = OIVideoCaptorOrientationLandscapeRight;
            }
        }
    }
    else {
        OIErrorLog(YES, self.class, @"- orientaion", @"Cannot get the deviceMotion data", nil);
    }
    
    return orientation;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!self.isEnabled) {
        return;
    }
    if (dispatch_semaphore_wait(imageProcessingSemaphore_, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    CFRetain(sampleBuffer);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoCaptor:willOutputVideoSampleBuffer:)])
    {
        [self.delegate videoCaptor:self willOutputVideoSampleBuffer:sampleBuffer];
    }
    [OIContext performAsynchronouslyOnImageProcessingQueue:^{
        
        [self processVideoSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(imageProcessingSemaphore_);
    }];
}

#pragma mark Processing Sample Buffer Motheds

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    [[OIContext sharedContext] setAsCurrentContext];
    [outputTexture_ setupContentWithCVBuffer:cameraFrame];
    [self setOutputTextureOrientaionBasingOnCameraPosition:position_];
    
    if (CGRectEqualToRect(outputFrame_, CGRectZero)) {
        outputFrame_ = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
    }
    
    [self produceAtTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}

- (void)setOutputTextureOrientaionBasingOnCameraPosition:(AVCaptureDevicePosition)position
{
    if (!outputTexture_) {
        return;
    }
    if (position == AVCaptureDevicePositionBack) {
        outputTexture_.orientation = OITextureOrientationRightMirrored;
    }
    else if (position == AVCaptureDevicePositionFront) {
        outputTexture_.orientation = OITextureOrientationRight;
    }
}

@end
