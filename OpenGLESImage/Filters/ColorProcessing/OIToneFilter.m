//
//  OIToneFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-10-27.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIToneFilter.h>

@interface OIToneFilter ()
{
    float red_;
    float green_;
    float blue_;
    float percentage_;
    
    float targetRed_;
    float targetGreen_;
    float targetBlue_;
    float targetPercentage_;
    
    float originalRed_;
    float originalGreen_;
    float originalBlue_;
    float originalPercentage_;
}

@end

@implementation OIToneFilter

@synthesize red = red_;
@synthesize green = green_;
@synthesize blue = blue_;
@synthesize percentage = percentage_;

#pragma mark - Lifecycle

- (instancetype)initWithRed:(float)red green:(CGFloat)green blue:(CGFloat)blue percentage:(CGFloat)percentage
{
    self = [super init];
    if (self) {
        self.red = red;
        self.green = green;
        self.blue = blue;
        self.percentage = percentage;
    }
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setRed:(float)red
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetRed_ = OIClampf(red, 0.0, 1.0);
        originalRed_ = red_;
        return;
    }
    
    red_ = OIClampf(red, 0.0, 1.0);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetRed_ = red_;
        originalRed_ = red_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:red_ forUniform:@"red"];
    }];
}

- (void)setGreen:(float)green
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetGreen_ = OIClampf(green, 0.0, 1.0);
        originalGreen_ = green_;
        return;
    }
    
    green_ = OIClampf(green, 0.0, 1.0);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetGreen_ = green_;
        originalGreen_ = green_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:green_ forUniform:@"green"];
    }];
}

- (void)setBlue:(float)blue
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetBlue_ = OIClampf(blue, 0.0, 1.0);
        originalBlue_ = blue_;
        return;
    }
    
    blue_ = OIClampf(blue, 0.0, 1.0);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetBlue_ = blue_;
        originalBlue_ = blue_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:blue_ forUniform:@"blue"];
    }];
}

- (void)setPercentage:(float)percentage
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetPercentage_ = OIClampf(percentage, 0.0, 1.0);
        originalPercentage_ = percentage_;
        return;
    }
    
    percentage_ = OIClampf(percentage, 0.0, 1.0);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetPercentage_ = percentage_;
        originalPercentage_ = percentage_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:percentage_ forUniform:@"percentage"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"Tone";
    return fName;
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.red = originalRed_ + (targetRed_ - originalRed_) * animationFactor;
    self.green = originalGreen_ + (targetGreen_ - originalGreen_) * animationFactor;
    self.blue = originalBlue_ + (targetBlue_ - originalBlue_) * animationFactor;
    self.percentage = originalPercentage_ + (targetPercentage_ - originalPercentage_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    if (self.animationRepeatMode == OIProducerAnimationRepeatModeMirrored) {
        float tempValue = targetRed_;
        targetRed_ = originalRed_;
        originalRed_ = tempValue;
        
        tempValue = targetGreen_;
        targetGreen_ = originalGreen_;
        originalGreen_ = tempValue;
        
        tempValue = targetBlue_;
        targetBlue_ = originalBlue_;
        originalBlue_ = tempValue;
        
        tempValue = targetPercentage_;
        targetPercentage_ = originalPercentage_;
        originalPercentage_ = tempValue;
    }
    
    self.red = originalRed_;
    self.green = originalGreen_;
    self.blue = originalBlue_;
    self.percentage = originalPercentage_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.red = targetRed_;
    self.green = targetGreen_;
    self.blue = targetBlue_;
    self.percentage = targetPercentage_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
