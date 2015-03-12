//
//  OIGaussianBlurFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-4-23.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#define MAX_KERNEL_COUNT 11

#import "OIGaussianBlurFilter.h"

@interface OIGaussianBlurFilter ()
{
    int radius_;
    float sigma_;
    float *kernels_;
    float offsets_[MAX_KERNEL_COUNT];
    float *offsetsZero_;
    
    float floatRadius_;
    int originalRadius_;
    int targetRadius_;
}

@end

@implementation OIGaussianBlurFilter

@synthesize radius = radius_;

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.radius = 3;
        float offsetsZero[MAX_KERNEL_COUNT] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
        offsetsZero_ = offsetsZero;
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [[OIContext sharedContext] setAsCurrentContext];
            [filterProgram_ use];
            [filterProgram_ setFloatArray:offsetsZero_ ofArrayCount:MAX_KERNEL_COUNT forUniform:@"vOffsets"];
            
            [secondFilterProgram_ use];
            [secondFilterProgram_ setFloatArray:offsetsZero_ ofArrayCount:MAX_KERNEL_COUNT forUniform:@"hOffsets"];
        }];
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setRadius:(int)radius
{
    int optimizedKernelCount = (radius % 2 == 0) ? radius + 1 : radius + 2;
    
    if (optimizedKernelCount > MAX_KERNEL_COUNT) {
        NSLog(@"OpenGLESImage Error at setRadius: , message: Radius is excess");
        return;
    }
    
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        [[OIProducerAnimationTimer defaultProducerAnimationTimer] setTarget:self];
        targetRadius_ = radius;
        originalRadius_ = radius_;
        return;
    }
    else if ([OIProducer animationStatus] == OIProducerAnimationStatusRendering) {
        radius_ = radius;
    }
    else {
        radius_ = radius;
        floatRadius_ = radius_;
        originalRadius_ = radius_;
        targetRadius_ = radius_;
    }
    
    sigma_ = radius_ / 3.0;
    
    float kernels[21] = {0.0};
    float kernelSum = 0.0;
    
    for(long n = 0, i = -radius_; i <= radius_; ++i, ++n) {
        kernels[n] = exp(-(i * i) / (2.0 * sigma_ * sigma_)) / (sigma_ * OI_SQRT_2PI);
        kernelSum += kernels[n];
    }
    
    for (int i = 0; i <= 2 * radius_; i++) {
        kernels[i] /= kernelSum;
    }
    
    float optimizedKernels[MAX_KERNEL_COUNT] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    float offsets[MAX_KERNEL_COUNT] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    int i = 0, j = 0;
    if (radius_ % 2 == 0) {
        for (i = 0, j = 0; i < radius_; i += 2, j++) {
            optimizedKernels[j] = kernels[i] + kernels[i + 1];
            optimizedKernels[optimizedKernelCount - 1 - j] = optimizedKernels[j];
            offsets[j] = -(radius_ - 1 - i + kernels[i] / optimizedKernels[j]);
            offsets[optimizedKernelCount - 1 - j] = -offsets[j];
        }
        optimizedKernels[j] = kernels[i];
        offsets[j] = 0.0f;
    }
    else {
        for (i = 1, j = 1; i < radius_; i += 2, j++) {
            optimizedKernels[j] = kernels[i] + kernels[i + 1];
            optimizedKernels[optimizedKernelCount - 1 - j] = optimizedKernels[j];
            offsets[j] = -(radius_ - 1 - i + kernels[i] / optimizedKernels[j]);
            offsets[optimizedKernelCount - 1 - j] = -offsets[j];
        }
        optimizedKernels[j] = kernels[i];
        offsets[j] = 0.0f;
        optimizedKernels[0] = kernels[0];
        optimizedKernels[optimizedKernelCount - 1] = optimizedKernels[0];
        offsets[0] = - (float)radius_;
        offsets[optimizedKernelCount - 1] = - offsets[0];
    }
    
    kernels_ = optimizedKernels;
//    offsets_ = offsets;
    
    for (int i = 0; i < MAX_KERNEL_COUNT; i++) {
        offsets_[i] = offsets[i];
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [filterProgram_ use];
        [filterProgram_ setInt:optimizedKernelCount forUniform:@"kernelCount"];
        [filterProgram_ setFloatArray:kernels_ ofArrayCount:optimizedKernelCount forUniform:@"kernels"];
        
        [secondFilterProgram_ use];
        [secondFilterProgram_ setInt:optimizedKernelCount forUniform:@"kernelCount"];
        [secondFilterProgram_ setFloatArray:kernels_ ofArrayCount:optimizedKernelCount forUniform:@"kernels"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"GaussianBlur";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"GaussianBlur";
    return fName;
}

- (void)setProgramUniform
{
    float offsets[MAX_KERNEL_COUNT];
    for (int i = 0; i < MAX_KERNEL_COUNT; i++) {
        offsets[i] = offsets_[i] / contentSize_.width;
    }
    [filterProgram_ setFloatArray:offsets ofArrayCount:MAX_KERNEL_COUNT forUniform:@"hOffsets"];
}

- (void)setSecondProgramUniform
{
    float offsets[MAX_KERNEL_COUNT];
    for (int i = 0; i < MAX_KERNEL_COUNT; i++) {
        offsets[i] = offsets_[i] / contentSize_.height;
    }
    [secondFilterProgram_ setFloatArray:offsets ofArrayCount:MAX_KERNEL_COUNT forUniform:@"vOffsets"];
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.radius = floatRadius_ + (targetRadius_ - originalRadius_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    self.radius = originalRadius_;
    floatRadius_ = originalRadius_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.radius = targetRadius_;
    floatRadius_ = targetRadius_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
