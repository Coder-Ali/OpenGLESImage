//
//  OIProducerAnimationTimer.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-9-19.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIProducerAnimationTimer.h"
#import <QuartzCore/QuartzCore.h>
#import "OIProducer.h"
#import "OIFilter.h"


@interface OIProducerAnimationTimer ()
{
    NSMutableArray *targets_;
    CADisplayLink *animationDisplayLink_;
    double totalTime_;
    double currentTime_;
    NSInteger frameRate_;
    BOOL running_;
    BOOL paused_;
    
//    void (^animationTimerDidStartBlock)(void);
//    void (^animationTimerDidStopBlock)(void);
}

@end

@implementation OIProducerAnimationTimer

@synthesize frameRate = frameRate_;
@synthesize animationTimerDidStartBlock;
@synthesize animationTimerWillStopBlock;
@synthesize animationTimerDidStopBlock;
@synthesize running = running_;
@synthesize paused = paused_;

#pragma mark - Class Methods

+ (OIProducerAnimationTimer *)defaultProducerAnimationTimer
{
    static OIProducerAnimationTimer *defaultProducerAnimationTimer = nil;
    if (!defaultProducerAnimationTimer) {
        defaultProducerAnimationTimer = [[[self class] alloc] init];
    }
    return defaultProducerAnimationTimer;
}

#pragma mark - Lifecycle

- (void)dealloc
{
    [self invalidateDisplayLink];
    [targets_ release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        targets_ = [[NSMutableArray alloc] init];
        animationDisplayLink_ = nil;
        totalTime_ = 0.0;
        currentTime_ = 0.0;
        running_ = NO;
        paused_ = NO;
        frameRate_ = 30;
        self.animationTimerDidStartBlock = NULL;
        self.animationTimerDidStopBlock = NULL;
    }
    return self;
}

#pragma mark - Properties' setters & getters

- (void)setframeRate:(NSInteger)frameRate
{
    if (self.isRunning || frameRate <= 0) {
        return;
    }
    
    frameRate_ = frameRate;
}

- (void)setPaused:(BOOL)paused
{
    if (!self.isRunning) {
        return;
    }
    
    paused_ = paused;
    animationDisplayLink_.paused = paused_;
}

#pragma mark - Target Manager

- (void)setTarget:(OIProducer *)target
{
    if (self.isRunning) {
        return;
    }
    
    double targetAnimationDuration = target.animationDelay + target.animationDuration * (target.animationRepeatCount + 1.0);
    if (targetAnimationDuration > totalTime_) {
        totalTime_ = targetAnimationDuration;
    }
    
    if ([target isKindOfClass:[OIFilter class]]) {
        [self getTopLevelProducersFromConsumer:(id<OIConsumer>)target];
    }
//    else {
        if (![targets_ containsObject:target]) {
            [targets_ addObject:target];
        }
//    }
}

- (void)getTopLevelProducersFromConsumer:(id<OIConsumer>)consumer
{
    OIProducer *producer = nil;
    
    if (consumer.producers.count > 0) {
        producer = [consumer.producers objectAtIndex:0];
        if ([producer isKindOfClass:[OIFilter class]] /*|| [producer conformsToProtocol:@protocol(OIConsumer)]*/) {
            [self getTopLevelProducersFromConsumer:(id<OIConsumer>)producer];
        }
        else {
            if (![targets_ containsObject:producer]) {
                [targets_ addObject:producer];
            }
        }
    }
    
    if (consumer.producers.count > 1) {
        producer = [consumer.producers objectAtIndex:1];
        if ([producer isKindOfClass:[OIFilter class]]) {
            [self getTopLevelProducersFromConsumer:(id<OIConsumer>)producer];
        }
        else {
            if (![targets_ containsObject:producer]) {
                [targets_ addObject:producer];
            }
        }
    }
}

#pragma mark - Animation Control

- (BOOL)start
{
    if (self.isRunning || targets_.count == 0) {
        return NO;
    }
    
    animationDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(triggerNextFrame:)];
    animationDisplayLink_.frameInterval = 60 / self.frameRate;
    [animationDisplayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    running_ = YES;
    
    if (self.animationTimerDidStartBlock != NULL) {
        animationTimerDidStartBlock();
    }
    
    return YES;
}

- (void)stop
{
    [self invalidateDisplayLink];
    [targets_ removeAllObjects];
    currentTime_ = 0.0;
    totalTime_ = 0.0;
    running_ = NO;
}

#pragma mark - 

- (void)triggerNextFrame:(CADisplayLink *)displayLink
{
    currentTime_ += displayLink.duration * displayLink.frameInterval;
    if (currentTime_ <= totalTime_) {
        for (OIProducer *target in targets_) {
            if (![target isKindOfClass:[OIFilter class]]) {
                [target produceAtTime:CMTimeMakeWithSeconds(currentTime_, 1000)];
            }
        }
    }
    else {
        if (self.animationTimerWillStopBlock) {
            animationTimerWillStopBlock();
        }
        
        for (OIProducer *target in targets_) {
            [target setAnimationParametersToTargetForFinish];
        }
        
        [self stop];
        
        if (self.animationTimerDidStopBlock) {
            animationTimerDidStopBlock();
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
