//
//  OIBoxBlurFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-8-13.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIBoxBlurFilter.h>

@interface OIBoxBlurFilter ()
{
    float blurSize_;
    float targetBlurSize_;
    float originalBlurSize_;
}

@end

@implementation OIBoxBlurFilter

@synthesize blurSize = blurSize_;

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.blurSize = 1.0;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setBlurSize:(float)blurSize
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
        targetBlurSize_ = blurSize;
        originalBlurSize_ = blurSize_;
        return;
    }
    else if ([OIProducer animationStatus] == OIProducerAnimationStatusRendering) {
        blurSize_ = blurSize;
    }
    else {
        blurSize_ = blurSize;
        targetBlurSize_ = blurSize_;
        originalBlurSize_ = blurSize_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:blurSize_ forUniform:@"blurSize"];
        [secondFilterProgram_ use];
        [secondFilterProgram_ setFloat:blurSize_ forUniform:@"blurSize"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"BoxBlur";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"BoxBlur";
    return fName;
}

- (void)setProgramUniform
{
    [filterProgram_ setFloat:1.0 / contentSize_.width forUniform:@"horizontalOffset"];
    [filterProgram_ setFloat:0.0 forUniform:@"verticalOffset"];
}

- (void)setSecondProgramUniform
{
    [secondFilterProgram_ setFloat:0.0 forUniform:@"horizontalOffset"];
    [secondFilterProgram_ setFloat:1.0 / contentSize_.height forUniform:@"verticalOffset"];
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.blurSize = originalBlurSize_ + (targetBlurSize_ - originalBlurSize_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.blurSize = targetBlurSize_;
    
    [super setAnimationParametersToTargetForFinish];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    if (self.animationRepeatMode == OIProducerAnimationRepeatModeMirrored) {
        float tempTargetBlurSize = targetBlurSize_;
        targetBlurSize_ = originalBlurSize_;
        originalBlurSize_ = tempTargetBlurSize;
    }
    
    self.blurSize = originalBlurSize_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

@end
