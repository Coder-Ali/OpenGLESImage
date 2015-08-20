//
//  OIAnimationLayer.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationLayer.h"
#import "OIAnimationLayerConfiguration.h"
#import "OIAnimationLayerMixer.h"
//#import "OIBoxBlurFilter.h"

@interface OIAnimationLayer ()
{
    CGSize size_;
    OIFilter *positionFilter_;
    OIBoxBlurFilter *blurFilter_;
    OIAnimationLayerMixer *mixer_;
}

@end

@implementation OIAnimationLayer

@synthesize mixer = mixer_;

#pragma mark - Lifecycle

- (void)dealloc
{
    self.configuration = nil;
    self.nextLayer = nil;
    self.mixer = nil;
    
    [super dealloc];
}

- (instancetype)initWithSize:(CGSize)size
{
    self = [super init];
    
    if (self) {
        size_ = size;
        positionFilter_ = [[OIFilter alloc] initWithContentSize:size_];
        blurFilter_ = [[OIBoxBlurFilter alloc] initWithContentSize:size_];
    }
    
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setMixer:(OIAnimationLayerMixer *)mixer
{
    if (mixer_) {
        [mixer_ release];
        mixer_ = nil;
    }
    
    if (mixer) {
        mixer_ = [mixer retain];
    }
    
    if (self.nextLayer) {
        self.nextLayer.mixer = mixer_;
    }
}

#pragma mark - Public Methods

- (void)outputAtTime:(CMTime)time
{
    if (!self.configuration || !self.mixer) {
        return;
    }
    
    OIProducer *source = self.configuration.source;
    
    source.outputFrame = self.configuration.sourceBounds;
    
    [source addConsumer:positionFilter_];
    
    OIProducer *lastOfChain = positionFilter_;
    
    if (self.configuration.blurSize > 0.0) {
        
        [lastOfChain addConsumer:blurFilter_];
        
        lastOfChain = blurFilter_;
    }
    
    [lastOfChain addConsumer:self.mixer];
    
    [source produceAtTime:time];
    
    if (self.nextLayer) {
        [self.nextLayer outputAtTime:time];
    }
    
    [source removeAllConsumers];
    [positionFilter_ removeAllConsumers];
    [blurFilter_ removeAllConsumers];
}

@end
