//
//  OIAudioVideoWriter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-8-25.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIAudioVideoWriter.h"
#import "OIContext.h"
#import "OIFrameBufferObject.h"
#import "OITexture.h"
#import "OIProgram.h"

@interface OIAudioVideoWriter ()
{
    BOOL enabled_;
    CGSize contentSize_;
    NSMutableArray *producers_;
    id<OIAudioVideoWriterDelegate> delegate_;
    OIAudioVideoWriterStatus status_;
    int frameRate_;
    BOOL writingInRealTime_;
    OIFrameBufferObject *writerFBO_;
    OIProgram *writerProgram_;
    OITexture *inputTexture_;
    NSURL *outputURL_;
    NSString *outputFileType_;
    AVAssetWriter *assetWriter_;
    AVAssetWriterInput *assetWriterAudioInput_;
    AVAssetWriterInput *assetWriterVideoInput_;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferAdaptor_;
    
    NSMutableDictionary *outputSettings_;
    CVPixelBufferRef wrotePixelBuffer_;
    
    BOOL shouldWriteWithAudio_;
    NSDictionary *compressionAudioSettings_;
    
    CMTime frameTime_;
    CMTime preFrameTime_;
    NSTimeInterval previousFrameActualTime_;
    
    BOOL audioWritingCompleted_;
}

@end

@implementation OIAudioVideoWriter

@synthesize enabled = enabled_;
@synthesize contentSize = contentSize_;
@synthesize producers = producers_;
@synthesize delegate = delegate_;
@synthesize status = status_;
@synthesize outputURL = outputURL_;
@synthesize frameRate = frameRate_;
@synthesize shouldWriteWithAudio = shouldWriteWithAudio_;
@synthesize compressionAudioSettings = compressionAudioSettings_;
@synthesize writingInRealTime = writingInRealTime_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [producers_ release];
    
    [self deleteAssetWriter];
    
    if (outputSettings_) {
        [outputSettings_ release];
    }
    
    self.outputURL = nil;
    
    if (outputFileType_) {
        [outputFileType_ release];
    }
    
    self.compressionAudioSettings = nil;
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if (writerFBO_) {
            [writerFBO_ release];
        }
        if (writerProgram_) {
            [writerProgram_ release];
        }
        if (inputTexture_) {
            [inputTexture_ release];
        }
    }];
    
    if (wrotePixelBuffer_) {
        CVPixelBufferRelease(wrotePixelBuffer_);
        wrotePixelBuffer_ = NULL;
    }
    
    [super dealloc];
}

- (id)initWithContentSize:(CGSize)contentSize outputURL:(NSURL *)outputURL
{
    self = [self initWithContentSize:contentSize outputURL:outputURL fileType:AVFileTypeQuickTimeMovie settings:nil];
    
    return self;
}

- (id)initWithContentSize:(CGSize)contentSize outputURL:(NSURL *)outputURL fileType:(NSString *)outputFileType settings:(NSDictionary *)outputSettings
{
    self = [super init];
    if (self) {
        self.enabled = YES;
        self.contentSize = contentSize;
        self.frameRate = 0;
//        self.shouldWriteWithAudio = NO;
        self.compressionAudioSettings = nil;
        
        producers_ = [[NSMutableArray alloc] init];
        delegate_ = nil;
        status_ = OIAudioVideoWriterStatusWaiting;
        self.writingInRealTime = NO;
        outputSettings_ = nil;
        wrotePixelBuffer_ = NULL;
        inputTexture_ = nil;
        assetWriter_ = nil;
        assetWriterAudioInput_ = nil;
        assetWriterVideoInput_ = nil;
        shouldWriteWithAudio_ = NO;
        audioWritingCompleted_ = NO;
        
        self.outputURL = outputURL;
        
        outputFileType_ = [outputFileType copy];
        
        if (outputSettings) {
            outputSettings_ = [[NSMutableDictionary alloc] initWithDictionary:outputSettings];
        }
        
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            writerFBO_ = [[OIFrameBufferObject alloc] init];
            
            writerProgram_ = [[OIProgram alloc] initWithVertexShaderFilename:@"UpsideDown" fragmentShaderFilename:@"Default"];
        }];
    }
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setFrameRate:(int)frameRate
{
    if (self.status != OIAudioVideoWriterStatusWaiting) {
        return;
    }
    
    frameRate_ = frameRate < 0 ? 0 : frameRate;
}

- (void)setShouldWriteWithAudio:(BOOL)shouldWriteWithAudio
{
    if (self.status != OIAudioVideoWriterStatusWaiting) {
        return;
    }
    
    shouldWriteWithAudio_ = shouldWriteWithAudio;
}

#pragma mark - OIConsumer Methods

- (void)setProducer:(OIProducer *)producer
{
    if (![self.producers containsObject:producer]) {
        [producers_ addObject:producer];
    }
}

- (void)removeProducer:(OIProducer *)producer
{
    if ([self.producers containsObject:producer]) {
        [producers_ removeObject:producer];
    }
}

- (void)setInputTexture:(OITexture *)texture
{
    if (inputTexture_ != texture) {
        [inputTexture_ release];
        inputTexture_ = texture;
        [inputTexture_ retain];
    }
}

- (void)renderRect:(CGRect)rect atTime:(CMTime)time
{
    if (!inputTexture_ || !self.isEnabled || self.status == OIAudioVideoWriterStatusCompleted) {
        return;
    }
    
    if (CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        self.contentSize = inputTexture_.size;
    }
    
    if (self.status == OIAudioVideoWriterStatusWaiting) {
        [self startWriting];
        BOOL startingSuccess = [assetWriter_ startWriting];
        if (startingSuccess) {
            CVReturn success = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterInputPixelBufferAdaptor_ pixelBufferPool], &wrotePixelBuffer_);
            
            if (success != kCVReturnSuccess) {
                NSLog(@"OpenGLESImage Error at OIAudioVideoWriter renderRect:atTime: , message: PixelBuffer can not be create because error %d.", success);
            }

            [writerFBO_ setupStorageWithSpecifiedCVBuffer:wrotePixelBuffer_];
//            previousFrameActualTime_ = [NSDate timeIntervalSinceReferenceDate];
            frameTime_ = CMTimeMakeWithSeconds(0, 1000);
            if (frameRate_) {
                frameTime_ = CMTimeMakeWithSeconds(0, 1000);
            }
            else {
                frameTime_ = time;
            }
            [assetWriter_ startSessionAtSourceTime:frameTime_];
            status_ = OIAudioVideoWriterStatusWriting;
        }
        else {
            NSLog(@"OpenGLESImage Error at OIAudioVideoWriter renderRect:atTime: , message: OIAudioVideoWriter can not be start in status: %d, error description:%@.", (int)assetWriter_.status, assetWriter_.error);
            return;
        }
    }
    else if (self.status == OIAudioVideoWriterStatusWriting) {
//        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
//        NSTimeInterval diff = now - previousFrameActualTime_;
//        frameTime_ = CMTimeAdd(frameTime_, CMTimeMakeWithSeconds(diff, 1000));
//        previousFrameActualTime_ = now;
        if (frameRate_) {
            frameTime_ = CMTimeAdd(frameTime_, CMTimeMakeWithSeconds(1.0 / frameRate_, 1000));
        }
        else {
            frameTime_ = time;
        }
    }
    
    [writerFBO_ bindToPipeline];
    [writerFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [inputTexture_ bindToTextureIndex:GL_TEXTURE0];
    
    if (self.isWritingInRealTime) {
        inputTexture_.orientation = OITextureOrientationLeftMirrored;
    }
    
    [writerProgram_ use];
    [writerProgram_ setCoordinatePointer:[writerFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [writerProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [writerProgram_ draw];
    glFinish();
    
    if (assetWriterVideoInput_.isReadyForMoreMediaData) {
        CVPixelBufferLockBaseAddress(wrotePixelBuffer_, 0);
        
        BOOL appendingSuccess = [assetWriterInputPixelBufferAdaptor_ appendPixelBuffer:wrotePixelBuffer_ withPresentationTime:frameTime_];
        if(!appendingSuccess)
        {
            NSLog(@"OpenGLESImage Error at OIAudioVideoWriter renderRect:atTime: , message: Problem appending pixel buffer at time: %f .", CMTimeGetSeconds(frameTime_));
        }
        CVPixelBufferUnlockBaseAddress(wrotePixelBuffer_, 0);
    }
    
    if (self.shouldWriteWithAudio) {
        if (delegate_ && [delegate_ respondsToSelector:@selector(audioVideoWriterRequestNextAudioSampleBuffer:)]) {
            if (assetWriterAudioInput_.isReadyForMoreMediaData) {
                [delegate_ audioVideoWriterRequestNextAudioSampleBuffer:self];
            }
        }
    }
}

- (UIImage *)imageFromCurrentFrame
{
    return nil;
}

#pragma - Audio Sample Buffer Writing Methods

- (void)writeWithAudioSampleBuffer:(CMSampleBufferRef)audioSampleBuffer
{
    if (!self.isEnabled || !self.shouldWriteWithAudio || self.status != OIAudioVideoWriterStatusWriting || audioWritingCompleted_) {
        return;
    }
    
    if (audioSampleBuffer == NULL || CMTIME_IS_INVALID(CMSampleBufferGetPresentationTimeStamp(audioSampleBuffer))) {
        if (!audioWritingCompleted_) {
            [assetWriterAudioInput_ markAsFinished];
            audioWritingCompleted_ = YES;
        }
        return;
    }
    
    if (assetWriterAudioInput_.isReadyForMoreMediaData) {
        BOOL secussed = [assetWriterAudioInput_ appendSampleBuffer:audioSampleBuffer];
        if (!secussed) {
            NSLog(@"OpenGLESImage Error at OIAudioVideoWriter writeWithAudioSampleBuffer:, message: fail to append audio SampleBuffer.");
            if (assetWriter_.status == AVAssetWriterStatusFailed) {
                NSLog(@"Writer status is AVAssetWriterStatusFailed, because of error: %@.", assetWriter_.error);
            }
        }
    }
}

#pragma mark - 

- (BOOL)startWriting
{
    NSError *error = nil;
    assetWriter_ = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:outputFileType_ error:&error];
    if (error) {
        NSLog(@"OpenGLESImage Error at OIAudioVideoWriter initWithContentSize:outputURL:fileType:outputSetting: , message: %@", error);
        return NO;
    }
    assetWriter_.movieFragmentInterval = CMTimeMakeWithSeconds(0.1, 1000);
    
    // use default output settings if none specified
    if (outputSettings_ == nil)
    {
        outputSettings_ = [[NSMutableDictionary alloc] init];
        [outputSettings_ setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    }
    // custom output settings specified
    else
    {
        NSString *videoCodec = [outputSettings_ objectForKey:AVVideoCodecKey];
        
        if (!videoCodec) {
            NSLog(@"OpenGLESImage Error at OIAudioVideoWriter initWithContentSize:outputURL:fileType:outputSetting: , message: OutputSettings is missing required parameters.");
            return NO;
        }
    }
    [outputSettings_ setObject:[NSNumber numberWithInt:self.contentSize.width] forKey:AVVideoWidthKey];
    [outputSettings_ setObject:[NSNumber numberWithInt:self.contentSize.height] forKey:AVVideoHeightKey];
    
    assetWriterVideoInput_ = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outputSettings_];
    assetWriterVideoInput_.expectsMediaDataInRealTime = self.isWritingInRealTime;
    
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:self.contentSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:self.contentSize.height], kCVPixelBufferHeightKey,
                                                           nil];
    
    assetWriterInputPixelBufferAdaptor_ = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:assetWriterVideoInput_ sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    if ([assetWriter_ canAddInput:assetWriterVideoInput_]) {
        [assetWriter_ addInput:assetWriterVideoInput_];
    }
    else {
        NSLog(@"OpenGLESImage Error at OIAudioVideoWriter - (BOOL)startWriting, message: output settings maybe not compatible with the receiver.");
        return NO;
    }
    
//    double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
    
//    AudioChannelLayout acl;
//    bzero( &acl, sizeof(acl));
//    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
//    NSDictionary* audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                            [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
//                                            [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
//                                            [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
//                                            [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
//                                            //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
//                                            [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
//                                            nil];
    
    // Configure the channel layout as stereo.
    if (self.shouldWriteWithAudio) {
        AudioChannelLayout stereoChannelLayout = {
            .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
            .mChannelBitmap = 0,
            .mNumberChannelDescriptions = 0
        };
        
        // Convert the channel layout object to an NSData object.
        NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
        
        // Get the compression settings for 128 kbps AAC.
        if (!self.compressionAudioSettings) {
            NSDictionary *compressionAudioSettings = @{
                                                       AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                                       AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                                                       AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                                                       AVChannelLayoutKey    : channelLayoutAsData,
                                                       AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
                                                       };
            
            self.compressionAudioSettings = compressionAudioSettings;
        }
        
        assetWriterAudioInput_ = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:self.compressionAudioSettings];
        assetWriterAudioInput_.expectsMediaDataInRealTime = self.isWritingInRealTime;
        
        if ([assetWriter_ canAddInput:assetWriterAudioInput_]) {
            [assetWriter_ addInput:assetWriterAudioInput_];
        }
        else {
            NSLog(@"OpenGLESImage Error at OIAudioVideoWriter - (BOOL)startWriting, message: Audio input can not be add. Compression audio settings maybe not compatible with the receiver.");
            return NO;
        }
    }
    
    return YES;
}

- (void)finishWriting
{
    if (self.status != OIAudioVideoWriterStatusWriting) {
        return;
    }
    
    status_ = OIAudioVideoWriterStatusCompleted;
    
    [assetWriterVideoInput_ markAsFinished];
    
    if (!audioWritingCompleted_ && self.shouldWriteWithAudio) {
        [assetWriterAudioInput_ markAsFinished];
        audioWritingCompleted_ = YES;
    }

    [assetWriter_ finishWritingWithCompletionHandler:^{
        [self deleteAssetWriter];
        audioWritingCompleted_ = NO;
        status_ = OIAudioVideoWriterStatusWaiting;
        if (delegate_ && [delegate_ respondsToSelector:@selector(audioVideoWriterDidfinishWriting:)]) {
            [delegate_ audioVideoWriterDidfinishWriting:self];
        }
    }];
}

#pragma mark - Private Methods

- (void)deleteAssetWriter
{
    if (assetWriter_) {
        [assetWriter_ release];
        assetWriter_ = nil;
    }
    if (assetWriterAudioInput_) {
        [assetWriterAudioInput_ release];
        assetWriterAudioInput_ = nil;
    }
    if (assetWriterVideoInput_) {
        [assetWriterVideoInput_ release];
        assetWriterVideoInput_ = nil;
    }
    if (assetWriterInputPixelBufferAdaptor_) {
        [assetWriterInputPixelBufferAdaptor_ release];
        assetWriterInputPixelBufferAdaptor_ = nil;
    }
}

@end
