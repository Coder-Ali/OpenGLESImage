//
//  OIRGBAFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-8-21.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIRGBAFilter.h"

@interface OIRGBAFilter ()
{
    float redFactor_;
    float greenFactor_;
    float blueFactor_;
    float alphaFactor_;
    
    float targetRedFactor_;
    float targetGreenFactor_;
    float targetBlueFactor_;
    float targetAlphaFactor_;
    
    float originalRedFactor_;
    float originalGreenFactor_;
    float originalBlueFactor_;
    float originalAlphaFactor_;
}

@end

@implementation OIRGBAFilter

@synthesize redFactor = redFactor_;
@synthesize greenFactor = greenFactor_;
@synthesize blueFactor = blueFactor_;
@synthesize alphaFactor = alphaFactor_;

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.redFactor = 1.0;
        self.greenFactor = 1.0;
        self.blueFactor = 1.0;
        self.alphaFactor = 1.0;
    }
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setRedFactor:(float)redFactor
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetRedFactor_ = redFactor < 0.0 ? 0.0 : redFactor;
        originalRedFactor_ = redFactor_;
        return;
    }
    
    redFactor_ = redFactor < 0.0 ? 0.0 : redFactor;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetRedFactor_ = redFactor_;
        originalRedFactor_ = redFactor_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:redFactor_ forUniform:@"redFactor"];
    }];
}

- (void)setGreenFactor:(float)greenFactor
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetGreenFactor_ = greenFactor < 0.0 ? 0.0 : greenFactor;
        originalGreenFactor_ = greenFactor_;
        return;
    }
    
    greenFactor_ = greenFactor < 0.0 ? 0.0 : greenFactor;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetGreenFactor_ = greenFactor_;
        originalGreenFactor_ = greenFactor_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:greenFactor_ forUniform:@"greenFactor"];
    }];
}

- (void)setBlueFactor:(float)blueFactor
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetBlueFactor_ = blueFactor < 0.0 ? 0.0 : blueFactor;
        originalBlueFactor_ = blueFactor_;
        return;
    }
    
    blueFactor_ = blueFactor < 0.0 ? 0.0 : blueFactor;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetBlueFactor_ = blueFactor_;
        originalBlueFactor_ = blueFactor_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:blueFactor_ forUniform:@"blueFactor"];
    }];
}

- (void)setAlphaFactor:(float)alphaFactor
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetAlphaFactor_ = alphaFactor < 0.0 ? 0.0 : alphaFactor;
        originalAlphaFactor_ = alphaFactor_;
        return;
    }
    
    alphaFactor_ = alphaFactor < 0.0 ? 0.0 : alphaFactor;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetAlphaFactor_ = alphaFactor_;
        originalAlphaFactor_ = alphaFactor_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:alphaFactor_ forUniform:@"alphaFactor"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"RGBA";
    return fName;
}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    self.redFactor = originalRedFactor_ + (targetRedFactor_ - originalRedFactor_) * animationFactor;
    self.greenFactor = originalGreenFactor_ + (targetGreenFactor_ - originalGreenFactor_) * animationFactor;
    self.blueFactor = originalBlueFactor_ + (targetBlueFactor_ - originalBlueFactor_) * animationFactor;
    self.alphaFactor = originalAlphaFactor_ + (targetAlphaFactor_ - originalAlphaFactor_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    self.redFactor = originalRedFactor_;
    self.greenFactor = originalGreenFactor_;
    self.blueFactor = originalBlueFactor_;
    self.alphaFactor = originalAlphaFactor_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.redFactor = targetRedFactor_;
    self.greenFactor = targetGreenFactor_;
    self.blueFactor = targetBlueFactor_;
    self.alphaFactor = targetAlphaFactor_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
