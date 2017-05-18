//
//  OIAlphaFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-8-1.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIAlphaFilter.h>

@interface OIAlphaFilter ()
{
    float alpha_;
    float targetAlpha_;
    float originalAlpha_;
}

@end

@implementation OIAlphaFilter

@synthesize alpha = alpha_;

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.alpha = 0.5;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setAlpha:(float)alpha
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetAlpha_ = OIClampf(alpha, 0.0, 1.0);
        originalAlpha_ = alpha_;
        return;
    }
    
    alpha_ = OIClampf(alpha, 0.0, 1.0);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetAlpha_ = alpha_;
        originalAlpha_ = alpha_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:alpha_ forUniform:@"alpha"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"Alpha";
    return fName;
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.alpha = originalAlpha_ + (targetAlpha_ - originalAlpha_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    self.alpha = originalAlpha_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.alpha = targetAlpha_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
