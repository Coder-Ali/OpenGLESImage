//
//  OIAnimation.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/6/26.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimation.h"
#import "OIAnimationScript.h"
#import "OIAnimationLayerManager.h"
#import "OIAnimationLayer.h"
#import "OIAnimationLayerConfiguration.h"
#import "OIAnimationLayerMixer.h"

@interface OIAnimation ()
{
    CADisplayLink *animationDisplayLink_;
    OIAnimationScript *script_;
    OIAnimationStatus status_;
    OIAnimationLayerManager *layerManager_;
    OIAnimationLayerMixer *layerMixer_;
    float currentTime_;
}

@end

@implementation OIAnimation

@synthesize status = status_;

#pragma mark - Liftcycle

- (void)dealloc
{
    self.delegate = nil;
    [self invalidateDisplayLink];
    [script_ release];
    [layerManager_ release];
    
    [super dealloc];
}

- (instancetype)initWithScript:(OIAnimationScript *)script
{
    self = [super init];
    
    if (self) {
        script_ = [script retain];
        layerManager_ = [[OIAnimationLayerManager alloc] init];
        layerManager_.layerSize = script_.frameSize;
        
        layerMixer_ = [[OIAnimationLayerMixer alloc] init];
        layerMixer_.contentSize = script_.frameSize;
        
        status_ = OIAnimationStatusReady;
        
        currentTime_ = 0.0;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)addConsumer:(id <OIConsumer>)consumer
{
    [layerMixer_ addConsumer:consumer];
}

- (void)replaceConsumer:(id <OIConsumer>)consumer withNewConsumer:(id <OIConsumer>)newConsumer
{
    [layerMixer_  replaceConsumer:consumer withNewConsumer:newConsumer];
}

- (void)removeConsumer:(id <OIConsumer>)consumer
{
    [layerMixer_ removeConsumer:consumer];
}

- (void)removeAllConsumers
{
    [layerMixer_ removeAllConsumers];
}

- (void)produceAtTime:(CMTime)time
{
    OIAnimationLayer *layerChain = [layerManager_ getLayerChainWithConfigurations:[script_ layerConfigurationsAtTime:CMTimeGetSeconds(time)]];
    
    layerMixer_.configurations = [script_ layerMixerConfigurationsAtTime:CMTimeGetSeconds(time)];
    
    layerChain.mixer = layerMixer_;
    
    [layerChain outputAtTime:time];
}

- (void)start
{
    if (self.status == OIAnimationStatusPlaying) {
        return;
    }
    else if (self.status == OIAnimationStatusReady) {
        animationDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderNextFrame:)];
        animationDisplayLink_.frameInterval = 60 / script_.frameRate;
        [animationDisplayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    else if (self.status == OIAnimationStatusPaused) {
        animationDisplayLink_.paused = NO;
    }
    
    status_ = OIAnimationStatusPlaying;
}

- (void)pause
{
    animationDisplayLink_.paused = YES;
    
    status_ = OIAnimationStatusPaused;
}

- (void)stop
{
    [self invalidateDisplayLink];
    
    currentTime_ = 0.0;
    
    status_ = OIAnimationStatusReady;
}

#pragma mark - Private Methods

- (void)renderNextFrame:(CADisplayLink *)displayLink
{
    currentTime_ += displayLink.duration * displayLink.frameInterval;
    
    if (currentTime_ <= script_.totalTime) {
        [self produceAtTime:CMTimeMakeWithSeconds(currentTime_, 1000)];
    }
    else {
        [self invalidateDisplayLink];
        currentTime_ = 0.0;
        status_ = OIAnimationStatusReady;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
            [self.delegate animationDidEnd:self];
        }
    }
}

- (void)invalidateDisplayLink
{
    if (animationDisplayLink_) {
        [animationDisplayLink_ invalidate];
        animationDisplayLink_ = nil;
    }
}

@end
