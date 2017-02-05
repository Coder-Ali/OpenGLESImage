//
//  OIProducer.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-2-24.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIProducer.h"
#import "OIContext.h"
#import "OITexture.h"
#import "OIConsumer.h"
#import "OIProducerAnimationTimer.h"

@interface OIProducer()
{
    double previousFrameTime_;
    double currentFrameTime_;
}

@end

@implementation OIProducer

@synthesize enabled = enabled_;
@synthesize outputFrame = outputFrame_;
@synthesize consumers = consumers_;

@synthesize animationDelay = animationDelay_;
@synthesize animationDuration = animationDuration_;
@synthesize animationRepeatCount = animationRepeatCount_;
@synthesize animationRepeatMode = animationRepeatMode_;
@synthesize animationEasingMode = animationEasingMode_;

#pragma mark - Lifecycle

static OIProducerAnimationStatus animationStatus_ = OIProducerAnimationStatusNoAnimation;
static id<OIProducerAnimationDelegate> animationDelegate_ = nil;
static NSString *animationID_ = nil;

- (void)dealloc
{
    [self removeAllConsumers];
    
    [consumers_ release];
    
    [self deleteOutputTexture];
    
    if (imageProcessingSemaphore_) {
        dispatch_release(imageProcessingSemaphore_);
    }
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        imageProcessingSemaphore_ = dispatch_semaphore_create(1);
        enabled_ = YES;
        self.outputFrame = CGRectZero;
        consumers_ = [[NSMutableArray alloc] init];
        outputTexture_ = nil;
        
        animationID_ = nil;
        animationDelegate_ = nil;
        [self initAnimationParameters];
    }
    return self;
}

- (void)initAnimationParameters
{
    animationDelay_ = 0.0;
    animationDuration_ = 1.0;
    animationRepeatCount_ = 0.0;
    animationRepeatMode_ = OIProducerAnimationRepeatModeNormal;
    animationEasingMode_ = OIProducerAnimationEasingModeLinear;
    previousFrameTime_ = 0.0;
    currentFrameTime_ = 0.0;
//    originalOutputFrame_ = outputFrame_;
//    targetOutputFrame_ = outputFrame_;
}

#pragma mark - Properties' Setters & Getters

- (void)setOutputFrame:(CGRect)outputFrame
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        originalOutputFrame_ = outputFrame_;
        targetOutputFrame_ = outputFrame;
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
    }
    else {
        outputFrame_ = outputFrame;
        originalOutputFrame_ = outputFrame_;
        targetOutputFrame_ = outputFrame_;
    }
}

- (void)setAnimationDuration:(double)animationDuration
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        animationDuration_ = animationDuration;
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
    }
}

- (void)setAnimationRepeatCount:(float)animationRepeatCount
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        animationRepeatCount_ = animationRepeatCount;
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
    }
}

- (float)animationRepeatCount
{
    return (animationRepeatCount_ >= 0.0 ? animationRepeatCount_ : 0.0);
}

- (void)setAnimationEasingMode:(OIProducerAnimationEasingMode)animationEasingMode
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        animationEasingMode_ = animationEasingMode;
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
    }
}

#pragma mark - Consumers Manager

- (void)addConsumer:(id <OIConsumer>)consumer
{
    if (!consumer) {
        return;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [consumers_ addObject:consumer];
        
        [consumer setProducer:self];
    }];
}

- (void)replaceConsumer:(id <OIConsumer>)consumer withNewConsumer:(id <OIConsumer>)newConsumer
{
    if (newConsumer == nil || ![consumers_ containsObject:consumer]) {
        return;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [consumer removeProducer:self];
        
        [consumers_ replaceObjectAtIndex:[consumers_ indexOfObject:consumer] withObject:newConsumer];
        
        [newConsumer setProducer:self];
    }];
}

- (void)removeConsumer:(id <OIConsumer>)consumer
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if ([consumers_ containsObject:consumer]) {
            [consumer removeProducer:self];
            
            [consumers_ removeObject:consumer];
        }
    }];
}

- (void)removeAllConsumers
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        for (id <OIConsumer> consumer in consumers_) {
            [consumer removeProducer:self];
        }
        
        [consumers_ removeAllObjects];
    }];
}

#pragma mark - Output Texture Manager

- (void)deleteOutputTexture
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if (outputTexture_) {
            [outputTexture_ release];
            outputTexture_ = nil;
        }
    }];
}

#pragma mark - Animation Motheds

#pragma mark Class Motheds

+ (OIProducerAnimationStatus)animationStatus
{
    return animationStatus_;
}

+ (BOOL)beginAnimationConfigurationWithAnimationID:(NSString *)animationID
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusNoAnimation) {
        return NO;
    }
    
    animationStatus_ = OIProducerAnimationStatusConfiguring;
    
    if (animationID) {
        animationID_ = [animationID copy];
    }
    
    return YES;
}

+ (void)commitAnimationConfiguration
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusConfiguring) {
        return;
    }
    
    animationStatus_ = OIProducerAnimationStatusRendering;
    
    [OIProducerAnimationTimer defaultProducerAnimationTimer].animationTimerWillStopBlock = ^{
        animationStatus_ = OIProducerAnimationStatusNoAnimation;

    };
    
    if (animationDelegate_) {
        if ([animationDelegate_ respondsToSelector:@selector(animationDidBegin:)]) {
            [OIProducerAnimationTimer defaultProducerAnimationTimer].animationTimerDidStartBlock = ^{
                [animationDelegate_ animationDidBegin:animationID_];
            };
        }
        if ([animationDelegate_ respondsToSelector:@selector(animationDidFinish:)]) {
            [OIProducerAnimationTimer defaultProducerAnimationTimer].animationTimerDidStopBlock = ^{
                NSString *animationID = animationID_;
                animationID_ = nil;
                
                [animationDelegate_ animationDidFinish:animationID];
                
                if (animationID) {
                    [animationID release];
                    animationID = nil;
                }
            };
        }
    }
    else {
        [OIProducerAnimationTimer defaultProducerAnimationTimer].animationTimerDidStopBlock = ^{
            if (animationID_) {
                [animationID_ release];
                animationID_ = nil;
            }
        };
    }
    
    [[OIProducerAnimationTimer defaultProducerAnimationTimer] start];
}

+ (void)pauseAnimation{
    if ([[self class] animationStatus] != OIProducerAnimationStatusRendering || [OIProducerAnimationTimer defaultProducerAnimationTimer].paused) {
        return;
    }
    
    animationStatus_ = OIProducerAnimationStatusPaused;
    
    [OIProducerAnimationTimer defaultProducerAnimationTimer].paused = YES;
}

+ (void)restartAnimaion
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusPaused || ![OIProducerAnimationTimer defaultProducerAnimationTimer].paused) {
        return;
    }
    
    animationStatus_ = OIProducerAnimationStatusRendering;
    
    [OIProducerAnimationTimer defaultProducerAnimationTimer].paused = NO;
}

+ (void)cancelAnimation
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusRendering && [[self class] animationStatus] != OIProducerAnimationStatusPaused) {
        return;
    }
    animationStatus_ = OIProducerAnimationStatusNoAnimation;
    [[OIProducerAnimationTimer defaultProducerAnimationTimer] stop];
}

+ (id<OIProducerAnimationDelegate>)animationDelegate
{
    return animationDelegate_;
}

+ (void)setAnimationDelegate:(id<OIProducerAnimationDelegate>)animationDelegate
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusConfiguring) {
        return;
    }
    
    animationDelegate_ = animationDelegate;
}

+ (void)setAnimationFrameRate:(NSInteger)frameRate
{
    if ([[self class] animationStatus] != OIProducerAnimationStatusConfiguring) {
        return;
    }
    
    [OIProducerAnimationTimer defaultProducerAnimationTimer].frameRate = frameRate;
}

- (double)yValueByXValue:(double)xValue onCurveWithEasingMode:(OIProducerAnimationEasingMode)easingMode
{
    switch (easingMode) {
        case OIProducerAnimationEasingModeEaseInSine:
            return -cos(xValue * OI_PI_2) + 1.0;
            
        case OIProducerAnimationEasingModeEaseOutSine:
            return sin(xValue *  OI_PI_2);
            
        case OIProducerAnimationEasingModeEaseInOutSine:
            return (-0.5 * (cos(xValue * OI_PI) - 1.0));
            
        default:
            return xValue;
    }
}

#pragma mark - The Methods Be Overrided In Subclass If Need

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    outputFrame_.origin.x = originalOutputFrame_.origin.x + (targetOutputFrame_.origin.x - originalOutputFrame_.origin.x) * animationFactor;
    outputFrame_.origin.y = originalOutputFrame_.origin.y + (targetOutputFrame_.origin.y - originalOutputFrame_.origin.y) * animationFactor;
    outputFrame_.size.width = originalOutputFrame_.size.width + (targetOutputFrame_.size.width - originalOutputFrame_.size.width) * animationFactor;
    outputFrame_.size.height = originalOutputFrame_.size.height + (targetOutputFrame_.size.height - originalOutputFrame_.size.height) * animationFactor;
}

- (void)determineAnimationParametersWithTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time) || CMTimeGetSeconds(time) < 0.0) {
        OIErrorLog(YES, [self class], @"- determineAnimationParametersWithTime:", @"Time is invalid", nil);
        return;
    }
    
    double currentTime = CMTimeGetSeconds(time) - animationDelay_;
    
    if (currentTime < 0.0) {
        return;
    }
    
    double diff = currentTime - previousFrameTime_;
    
    currentFrameTime_ += diff;
    
    if (currentFrameTime_ >= animationDuration_ - 0.01) {
        if (animationRepeatCount_ > 1.0) {
            currentFrameTime_ = 0.0;
            animationRepeatCount_ -= 1.0;
            [self setAnimationParametersToOriginalForRepeat];
        }
        else if (animationRepeatCount_ > 0.0) {
            currentFrameTime_ = 0.0;
            animationDuration_ *= animationRepeatCount_;
            animationRepeatCount_ = 0.0;
            [self setAnimationParametersToOriginalForRepeat];
        }
        else {
//            [self setAnimationParametersToTargetForFinish];
            return;
        }
    }
    
    double animationFactor = [self yValueByXValue:currentFrameTime_ / animationDuration_ onCurveWithEasingMode:animationEasingMode_];
    
    [self calculateAnimationParametersWithFactor:animationFactor];
    
    previousFrameTime_ = currentTime;
}

- (void)setAnimationParametersToOriginalForRepeat
{
    if (self.animationRepeatMode == OIProducerAnimationRepeatModeMirrored) {
        CGRect tempTargetOutputFrame = targetOutputFrame_;
        targetOutputFrame_ = originalOutputFrame_;
        originalOutputFrame_ = tempTargetOutputFrame;
    }
    
    outputFrame_ = originalOutputFrame_;
}

- (void)setAnimationParametersToTargetForFinish
{
    outputFrame_ = targetOutputFrame_;
    originalOutputFrame_ = outputFrame_;
    
    [self initAnimationParameters];
}

#pragma mark -

- (void)produceAtTime:(CMTime)time
{
    if (!self.isEnabled) {
        return;
    }
    
    if ([OIProducer animationStatus] == OIProducerAnimationStatusRendering) {
        [self determineAnimationParametersWithTime:time];
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if (outputTexture_ && [consumers_ count]) {
            for (id <OIConsumer> consumer in consumers_) {
                [consumer setInputTexture:outputTexture_];
                [consumer renderRect:self.outputFrame atTime:time];
            }
        }
    }];
}

@end
