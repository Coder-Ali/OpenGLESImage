//
//  OIRotationFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-7-21.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIRotationFilter.h"

@interface OIRotationFilter ()
{
    CGPoint anchorPoint_;
    float degrees_;
    
    float originalDegrees_;
    float targetDegrees_;
}

@end

@implementation OIRotationFilter

@synthesize anchorPoint = anchorPoint_;
@synthesize degrees = degrees_;

- (id)init
{
    self = [super init];
    if (self) {
        self.anchorPoint = CGPointZero;
        self.degrees = 0.0;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
    anchorPoint_ = anchorPoint;
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        OI2DFloatVector anchorPointVector = {anchorPoint_.x, anchorPoint_.y};
        [filterProgram_ set2DFloatVector:anchorPointVector forUniform:@"anchorPoint"];
    }];
}

- (void)setDegrees:(float)degrees
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetDegrees_ = degrees;
        originalDegrees_ = degrees_;
        return;
    }
    degrees_ = degrees;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetDegrees_ = degrees_;
        originalDegrees_ = degrees_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        float radians = degrees_ * OI_PI / 180.0;
        float s = sin(-radians);
        float c = cos(-radians);
        
        float m[16];
        m[0] =  c; m[1] = s; m[2] = 0; m[3] = 0;
        m[4] = -s; m[5] = c; m[6] = 0; m[7] = 0;
        m[8] =  0; m[9] = 0; m[10] = 1; m[11] = 0;
        m[12] =  0; m[13] = 0; m[14] = 0; m[15] = 1;
        
        [filterProgram_ use];
        [filterProgram_ set4x4Matrix:m forUniform:@"rotationMatrix"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"Rotation";
    return vName;
}

- (void)setProgramUniform
{
    float rate = self.contentSize.width / self.contentSize.height;
    
    [filterProgram_ setFloat:rate forUniform:@"whRate"];
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.degrees = originalDegrees_ + (targetDegrees_ - originalDegrees_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}


- (void)setAnimationParametersToOriginalForRepeat
{
    self.degrees = originalDegrees_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.degrees = targetDegrees_;
    originalDegrees_ = self.degrees;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
