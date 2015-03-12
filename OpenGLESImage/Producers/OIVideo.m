//
//  OIVideo.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-10-20.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIVideo.h"
#import <AVFoundation/AVFoundation.h>
#import "OIContext.h"
#import "OITexture.h"

@interface OIVideo ()
{
    AVAssetReader *assetReader_;
    AVAssetReaderTrackOutput *videoTrackOutput_;
    AVAssetReaderTrackOutput *audioTrackOutput_;
    AVAsset *AVAsset_;
    NSURL *URL_;
    id<OIVideoDelegate> delegate_;
    OIVideoStatus status_;
    BOOL playAtActualSpeed_;
    CMTime previousFrameTime_;
    NSTimeInterval previousFrameActualTime_;
}

@end

@implementation OIVideo

@synthesize AVAsset = AVAsset_;
@synthesize URL = URL_;
@synthesize delegate = delegate_;
@synthesize status = status_;
@synthesize playAtActualSpeed = playAtActualSpeed_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [self deleteAssetReader];
    
    self.AVAsset = nil;
    
    self.URL = nil;
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        assetReader_ = nil;
        videoTrackOutput_ = nil;
        audioTrackOutput_ = nil;
        AVAsset_ = nil;
        URL_ = nil;
        delegate_ = nil;
        status_ = OIVideoStatusWaiting;
        playAtActualSpeed_ = YES;
        
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            outputTexture_ = [[OITexture alloc] init];
            outputTexture_.orientation = OITextureOrientationDown;
        }];
    }
    return self;
}

- (id)initWithAVAsset:(AVAsset *)asset
{
    self = [self init];
    if (self) {
        self.AVAsset = asset;
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [self init];
    if (self) {
        self.URL = URL;
    }
    return self;
}

#pragma mark - Properties' Setter && Getter

- (void)setAVAsset:(AVAsset *)AVAsset
{
    if (AVAsset_ != AVAsset) {
        if (AVAsset_) {
            [AVAsset_ release];
            AVAsset_ = nil;
        }
        if (AVAsset) {
            AVAsset_ = [AVAsset retain];
            [AVAsset_ loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
                NSError *error = nil;
                AVKeyValueStatus tracksStatus = [AVAsset_ statusOfValueForKey:@"tracks" error:&error];
                if (tracksStatus != AVKeyValueStatusLoaded || error)
                {
                    NSLog(@"OpenGLESImage Error at OIVideo setAVAsset: , AVAsset can not be loaded, messege: %@", error);
                    [AVAsset_ release];
                    AVAsset_ = nil;
                    return;
                }
            }];
        }
    }
}

- (void)setURL:(NSURL *)URL
{
    if (URL_ != URL) {
        if (URL_) {
            [URL_ release];
            URL_ = nil;
        }
        if (URL) {
            URL_ = [URL retain];
        }
        else {
            self.AVAsset = nil;
            return;
        }
        
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL_ options:options];
        self.AVAsset = urlAsset;
    }
}

#pragma mark - 

- (BOOL)play
{
    if (self.status != OIVideoStatusWaiting || !self.AVAsset || [OIProducer animationStatus] != OIProducerAnimationStatusNoAnimation) {
        return NO;
    }
    
    status_ = OIVideoStatusPlaying;
    
    NSError *error = nil;
    assetReader_ = [[AVAssetReader alloc] initWithAsset:self.AVAsset error:&error];
    
    if (error) {
        [assetReader_ release];
        assetReader_ = nil;
        
        NSLog(@"OpenGLESImage Error at OIVideo - (BOOL)play: , AVAssetReader can not be init, messege: %@ .", error);
        
        return NO;
    }
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
    // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
    videoTrackOutput_ = [[AVAssetReaderTrackOutput alloc] initWithTrack:[[self.AVAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    if (![assetReader_ canAddOutput:videoTrackOutput_]) {
        [assetReader_ release];
        assetReader_ = nil;
        [videoTrackOutput_ release];
        videoTrackOutput_ = nil;
        
        NSLog(@"OpenGLESImage Error at OIVideo - (BOOL)play: , messege: videoTrackOutput can not be added.");
        
        return NO;
    }
    [assetReader_ addOutput:videoTrackOutput_];
    
    NSArray *audioTracks = [self.AVAsset tracksWithMediaType:AVMediaTypeAudio];
    
    if (audioTracks.count > 0)
    {
        // This might need to be extended to handle movies with more than one audio track
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        audioTrackOutput_ = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:nil];
        if ([assetReader_ canAddOutput:audioTrackOutput_]) {
            [assetReader_ addOutput:audioTrackOutput_];
        }
        else {
            [audioTrackOutput_ release];
            audioTrackOutput_ = nil;
            NSLog(@"OpenGLESImage Error at OIVideo - (BOOL)play: , messege: audioTrackOutput can not be added.");
        }
    }
    
    if (![assetReader_ startReading])
    {
        [assetReader_ release];
        assetReader_ = nil;
        [videoTrackOutput_ release];
        videoTrackOutput_ = nil;
        if (audioTrackOutput_) {
            [audioTrackOutput_ release];
            audioTrackOutput_ = nil;
        }
        
        NSLog(@"OpenGLESImage Error at OIVideo - (BOOL)play: , messege: AVAsset can not be read.");
        
        return NO;
    }
    
    previousFrameTime_ = kCMTimeZero;
    previousFrameActualTime_ = [NSDate timeIntervalSinceReferenceDate];
    
    [OIContext performAsynchronouslyOnImageProcessingQueue:^{
        while (assetReader_.status == AVAssetReaderStatusReading) {
            CMSampleBufferRef videoSampleBuffer = [videoTrackOutput_ copyNextSampleBuffer];
            if (videoSampleBuffer == NULL) {
                continue;
            }
            CMTime frameTime = CMSampleBufferGetOutputPresentationTimeStamp(videoSampleBuffer);
            
            if (self.playAtActualSpeed)
            {
                // Do this outside of the video processing queue to not slow that down while waiting
                CMTime differenceFromLastFrame = CMTimeSubtract(frameTime, previousFrameTime_);
                NSTimeInterval currentActualTime = [NSDate timeIntervalSinceReferenceDate];
                
                NSTimeInterval frameTimeDifference = CMTimeGetSeconds(differenceFromLastFrame);
                NSTimeInterval actualTimeDifference = currentActualTime - previousFrameActualTime_;
                
                if (frameTimeDifference > actualTimeDifference)
                {
                    usleep(1000000.0 * (frameTimeDifference - actualTimeDifference));
                }
                
                previousFrameTime_ = frameTime;
                previousFrameActualTime_ = [NSDate timeIntervalSinceReferenceDate];
            }
            
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer);
            
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            
            [outputTexture_ setupContentWithCVBuffer:imageBuffer];
            
            if (CGRectEqualToRect(outputFrame_, CGRectZero)) {
                outputFrame_ = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
            }
            
            [super produceAtTime:frameTime];
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            CMSampleBufferInvalidate(videoSampleBuffer);
            CFRelease(videoSampleBuffer);
        }
        
        if (assetReader_.status == AVAssetReaderStatusCompleted) {
            [self deleteAssetReader];
            status_ = OIVideoStatusWaiting;
            if (delegate_ && [delegate_ respondsToSelector:@selector(videoDidEnd:)]) {
                [delegate_ videoDidEnd:self];
            }
        }
    }];
    
    
    return YES;
}

- (CMSampleBufferRef)copyNextAudioSampleBuffer
{
    if (!self.isEnabled || self.status != OIVideoStatusPlaying || !audioTrackOutput_) {
        return NULL;
    }
    
    CMSampleBufferRef nextAudioSampleBuffer = [audioTrackOutput_ copyNextSampleBuffer];
    
    return nextAudioSampleBuffer;
}

- (void)produceAtTime:(CMTime)time
{
    if (!self.isEnabled) {
        return;
    }
    
    if (self.status == OIVideoStatusWaiting) {
        NSError *error = nil;
        assetReader_ = [[AVAssetReader alloc] initWithAsset:self.AVAsset error:&error];
        
        if (error) {
            [assetReader_ release];
            assetReader_ = nil;
            
            OIErrorLog(YES, self.class, @"- produceAtTime:", error.description, @"assetReader_ cannot be alloc");
            
            return;
        }
        
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
        // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
        videoTrackOutput_ = [[AVAssetReaderTrackOutput alloc] initWithTrack:[[self.AVAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        if (![assetReader_ canAddOutput:videoTrackOutput_]) {
            [assetReader_ release];
            assetReader_ = nil;
            [videoTrackOutput_ release];
            videoTrackOutput_ = nil;
            
            OIErrorLog(YES, self.class, @"- produceAtTime:", @"videoTrackOutput_ cannot be added to assetReader_", @"An output that reads from a track of an asset other than the asset used to initialize the receiver cannot be added.");
            
            return;
        }
        [assetReader_ addOutput:videoTrackOutput_];
        
        NSArray *audioTracks = [self.AVAsset tracksWithMediaType:AVMediaTypeAudio];
        
        if (audioTracks.count > 0)
        {
            // This might need to be extended to handle movies with more than one audio track
            AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
            audioTrackOutput_ = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:nil];
            if ([assetReader_ canAddOutput:audioTrackOutput_]) {
                [assetReader_ addOutput:audioTrackOutput_];
            }
            else {
                [audioTrackOutput_ release];
                audioTrackOutput_ = nil;
                
                OIErrorLog(YES, self.class, @"- produceAtTime:", @"audioTrackOutput_ cannot be added to assetReader_", @"An output that reads from a track of an asset other than the asset used to initialize the receiver cannot be added.");
            }
        }
        
        if (![assetReader_ startReading])
        {
            [assetReader_ release];
            assetReader_ = nil;
            [videoTrackOutput_ release];
            videoTrackOutput_ = nil;
            if (audioTrackOutput_) {
                [audioTrackOutput_ release];
                audioTrackOutput_ = nil;
            }
            
            NSLog(@"OpenGLESImage Error at OIVideo - (void)produceAtTime: , messege: AVAsset can not be read.");
            OIErrorLog(YES, self.class, @"- produceAtTime:", @"assetReader_ fail to start Reading", @"clients can determine the nature of the failure by checking the value of the status and error properties.");
            
            return;
        }
        
        status_ = OIVideoStatusPlaying;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if (assetReader_.status == AVAssetReaderStatusReading) {
            CMSampleBufferRef videoSampleBuffer = [videoTrackOutput_ copyNextSampleBuffer];
//            CMTime frameTime = CMSampleBufferGetOutputPresentationTimeStamp(videoSampleBuffer);
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer);
            
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            
            [outputTexture_ setupContentWithCVBuffer:imageBuffer];
            
            if (CGRectEqualToRect(outputFrame_, CGRectZero)) {
                outputFrame_ = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
            }
            
            [super produceAtTime:time];
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            CMSampleBufferInvalidate(videoSampleBuffer);
            CFRelease(videoSampleBuffer);
        }
        else if (assetReader_.status == AVAssetReaderStatusCompleted) {
            [self deleteAssetReader];
            status_ = OIVideoStatusWaiting;
            if (delegate_ && [delegate_ respondsToSelector:@selector(videoDidEnd:)]) {
                [delegate_ videoDidEnd:self];
            }
        }
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

- (void)setAnimationParametersToTargetForFinish
{
    [self deleteAssetReader];
    status_ = OIVideoStatusWaiting;
    
    [super setAnimationParametersToTargetForFinish];
}

#pragma mark - Private Methods

- (void)deleteAssetReader
{
    NSLog(@"deleteAssetReader");
    if (assetReader_) {
        [assetReader_ release];
        assetReader_ = nil;
    }
    if (videoTrackOutput_) {
        [videoTrackOutput_ release];
        videoTrackOutput_ = nil;
    }
    if (audioTrackOutput_) {
        [audioTrackOutput_ release];
        audioTrackOutput_ = nil;
    }
}

@end
