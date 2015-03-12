//
//  OIMaskFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-8-20.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIMaskFilter.h"

@interface OIMaskFilter ()
{
    CGRect maskBounds_;
    float maskAlpha_;
    
    CGRect targetMaskBounds_;
    CGRect originalMaskBounds_;
    float targetMaskAlpha_;
    float originalMaskAlpha_;
}

@end

@implementation OIMaskFilter

@synthesize maskBounds = maskBounds_;
@synthesize maskAlpha = maskAlpha_;

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.maskBounds = CGRectZero;
        self.maskAlpha = 1.0;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    
    if (CGRectEqualToRect(maskBounds_, CGRectZero)) {
        self.maskBounds = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    }
}

- (void)setMaskAlpha:(float)maskAlpha
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetMaskAlpha_ = maskAlpha > 1.0 ? 1.0 : (maskAlpha < 0.0 ? 0.0 : maskAlpha);
        originalMaskAlpha_ = maskAlpha_;
        return;
    }
    
    maskAlpha_ = maskAlpha > 1.0 ? 1.0 : (maskAlpha < 0.0 ? 0.0 : maskAlpha);
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetMaskAlpha_ = maskAlpha_;
        originalMaskAlpha_ = maskAlpha_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:maskAlpha_ forUniform:@"maskAlpha"];
    }];
}

- (void)setMaskBounds:(CGRect)maskBounds
{
    if ([OIProducer animationStatus] == OIProducerAnimationStatusConfiguring) {
        targetMaskBounds_ = maskBounds;
        originalMaskBounds_ = maskBounds_;
        return;
    }
    
    maskBounds_ = maskBounds;
    
    if ([OIProducer animationStatus] != OIProducerAnimationStatusRendering) {
        targetMaskBounds_ = maskBounds_;
        originalMaskBounds_ = maskBounds_;
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [filterProgram_ use];
        [filterProgram_ setFloat:(maskBounds_.origin.x / self.contentSize.width) * 2.0 - 1.0 forUniform:@"maskBoundsX1"];
        [filterProgram_ setFloat:-((maskBounds_.origin.y / self.contentSize.height) * 2.0 - 1.0) forUniform:@"maskBoundsY1"];
        [filterProgram_ setFloat:((maskBounds_.origin.x + maskBounds_.size.width) / self.contentSize.width) * 2.0 - 1.0 forUniform:@"maskBoundsX2"];
        [filterProgram_ setFloat:-(((maskBounds_.origin.y + maskBounds_.size.height) / self.contentSize.height) * 2.0 - 1.0) forUniform:@"maskBoundsY2"];
    }];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"Mask";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"Mask";
    return fName;
}

//- (void)setProgramUniform
//{
//    NSLog(@"%f", -((maskBounds_.origin.y / self.contentSize.height) * 2.0 - 1.0));
//    [OIContext performSynchronouslyOnImageProcessingQueue:^{
//        [filterProgram_ use];
//        [filterProgram_ setFloat:(maskBounds_.origin.x / self.contentSize.width) * 2.0 - 1.0 forUniform:@"maskBoundsX1"];
//        [filterProgram_ setFloat:-((maskBounds_.origin.y / self.contentSize.height) * 2.0 - 1.0) forUniform:@"maskBoundsY1"];
//        [filterProgram_ setFloat:((maskBounds_.origin.x + maskBounds_.size.width) / self.contentSize.width) * 2.0 - 1.0 forUniform:@"maskBoundsX2"];
//        [filterProgram_ setFloat:-(((maskBounds_.origin.y + maskBounds_.size.height) / self.contentSize.height) * 2.0 - 1.0) forUniform:@"maskBoundsY2"];
//    }];
//}

- (void)calculateAnimationParametersWithFactor:(double)animationFactor
{
    float x = originalMaskBounds_.origin.x + (targetMaskBounds_.origin.x - originalMaskBounds_.origin.x) * animationFactor;
    float y = originalMaskBounds_.origin.y + (targetMaskBounds_.origin.y - originalMaskBounds_.origin.y) * animationFactor;
    float width = originalMaskBounds_.size.width + (targetMaskBounds_.size.width - originalMaskBounds_.size.width) * animationFactor;
    float height = originalMaskBounds_.size.height + (targetMaskBounds_.size.height - originalMaskBounds_.size.height) * animationFactor;
    
    self.maskBounds = CGRectMake(x, y, width, height);
    
    self.maskAlpha = originalMaskAlpha_ + (targetMaskAlpha_ - originalMaskAlpha_) * animationFactor;
    
    [super calculateAnimationParametersWithFactor:animationFactor];
}

- (void)setAnimationParametersToOriginalForRepeat
{
    self.maskBounds = originalMaskBounds_;
    
    self.maskAlpha = originalMaskAlpha_;
    
    [super setAnimationParametersToOriginalForRepeat];
}

- (void)setAnimationParametersToTargetForFinish
{
    self.maskBounds = targetMaskBounds_;
    
    self.maskAlpha = targetMaskAlpha_;
    
    [super setAnimationParametersToTargetForFinish];
}

@end
