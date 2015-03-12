//
//  OIBlendFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-7-25.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIBlendFilter.h>

@interface OIBlendFilter ()
{
    float opacity_;
    float originalOpacity_;
    float targetOpacity_;
}

@end

@implementation OIBlendFilter

@synthesize opacity = opacity_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.opacity = -1.0;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setOpacity:(float)opacity
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetOpacity_ = opacity;
        originalOpacity_ = opacity_;
        return;
    }
    
    opacity_ = opacity;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetOpacity_ = opacity_;
        originalOpacity_ = opacity_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [filterProgram_ use];
        [filterProgram_ setFloat:opacity_ forUniform:@"opacity"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"Blend";
    return fName;
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.opacity = originalOpacity_ + (targetOpacity_ - originalOpacity_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    self.opacity = originalOpacity_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.opacity = targetOpacity_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
