//
//  OIImage.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-27.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIImage.h>
#import <UIKit/UIKit.h>
#import "OIContext.h"
#import "OIConsumer.h"
#import "OITexture.h"

@interface OIImage ()
{
    UIImage *sourceImage_;
    UIImage *processedImage_;
    
    // Animated Image
    BOOL animatedImage_;
    BOOL imageAnimating_;
    float animatedImageDuration_;
    int animatedImageRepeatCount_;
    
    double currentAnimationTime_;
    double hasPlayedTime_;
    
    int currentImageIndex_;
    
}

@end

@implementation OIImage

@synthesize sourceImage = sourceImage_;
@synthesize animatedImage = animatedImage_;
@synthesize animatedImageDuration = animatedImageDuration_;
@synthesize animatedImageRepeatCount = animatedImageRepeatCount_;

#pragma mark - Lifecycle

- (void)dealloc
{
    if (sourceImage_) {
        [sourceImage_ release];
    }
    if (processedImage_) {
        [processedImage_ release];
    }
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        sourceImage_ = nil;
        processedImage_ = nil;
        
        animatedImage_ = NO;
        imageAnimating_ = NO;
        animatedImageDuration_ = 0.0;
        animatedImageRepeatCount_ = 0;
        hasPlayedTime_ = 0.0;
        
        currentImageIndex_ = 0;
    }
    return self;
}

- (id)initWithUIImage:(UIImage *)image
{
    self = [self init];
    if (self) {
        self.sourceImage = image;
        
        outputFrame_ = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setSourceImage:(UIImage *)sourceImage
{
    if (sourceImage_ != sourceImage) {
        [sourceImage_ release];
        sourceImage_ = [sourceImage retain];
        animatedImage_ = NO;
        
        if (sourceImage_.images) {
            animatedImage_ = YES;
            self.animatedImageDuration = sourceImage_.duration;
        }
        
        if (processedImage_) {
            [processedImage_ release];
            processedImage_ = nil;
        }
        
        [self initOutputTexture];
    }
}

- (UIImage *)processedImage
{
    if (!self.isEnabled || [consumers_ count] == 0 || !sourceImage_) {
        return nil;
    }
    
    if (!processedImage_) {
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [self produceAtTime:kCMTimeInvalid];
            id <OIConsumer> consumer = [consumers_ objectAtIndex:0];
            if ([consumer respondsToSelector:@selector(imageFromCurrentFrame)]) {
                processedImage_ = [consumer imageFromCurrentFrame];
            }
        }];
    };
    
    return processedImage_;
}

- (void)setAnimatedImageDuration:(float)animatedImageDuration
{
    if (self.isAnimatedImage) {
        animatedImageDuration_ = animatedImageDuration < 0.0 ? 0.0 : animatedImageDuration;
    }
}

- (void)setAnimatedImageRepeatCount:(int)animatedImageRepeatCount
{
    if (self.isAnimatedImage) {
        animatedImageRepeatCount_ = animatedImageRepeatCount < 0 ? 0 : animatedImageRepeatCount;
    }
}

#pragma mark - Consumers Manager

- (void)addConsumer:(id <OIConsumer>)consumer
{
    if (processedImage_) {
        [processedImage_ release];
        processedImage_ = nil;
    }
    
    [super addConsumer:consumer];
}

- (void)replaceConsumerAtIndex:(int)index withNewConsumer:(id <OIConsumer>)newConsumer
{
    if (processedImage_) {
        [processedImage_ release];
        processedImage_ = nil;
    }
    
    [super replaceConsumerAtIndex:index withNewConsumer:newConsumer];
}

- (void)removeConsumerAtIndex:(int)index
{
    if (processedImage_) {
        [processedImage_ release];
        processedImage_ = nil;
    }
    
    [super removeConsumerAtIndex:index];
}

- (void)removeAllConsumers
{
    if (processedImage_) {
        [processedImage_ release];
        processedImage_ = nil;
    }
    
    [super removeAllConsumers];
}

#pragma mark - Animated Image Methods

- (void)startImageAnimating
{
    if (!self.isAnimatedImage || [OIProducer animationStatus] != OIProducerAnimationStatusNoAnimation) {
        return;
    }
    
    [OIProducer beginAnimationConfigurationWithAnimationID:nil];
    self.animationDuration = self.animatedImageDuration * (1 + self.animatedImageRepeatCount);
    [OIProducer commitAnimationConfiguration];
    imageAnimating_ = YES;
}

- (void)stopImageAnimating
{
    hasPlayedTime_ = 0.0;
    
    if (!self.isAnimatedImage || !self.isImageAnimating) {
        return;
    }
    
    [OIProducer cancelAnimation];
}

- (void)pauseAnimating:(BOOL)pause
{
    if (!self.isAnimatedImage || !self.isImageAnimating) {
        return;
    }
    
    if (pause) {
        [OIProducer pauseAnimation];
    }
    else {
        [OIProducer restartAnimaion];
    }
}

- (BOOL)isImageAnimating
{
    return imageAnimating_;
}

#pragma mark - The Methods Be Overrided In Subclass If Need

- (void)setAnimationParametersToTargetForFinish
{
    hasPlayedTime_ += self.animationDuration;
    
    [super setAnimationParametersToTargetForFinish];
}

#pragma mark -

- (void)produceAtTime:(CMTime)time
{
    if (!self.isEnabled) {
        return;
    }
    
    if ([OIProducer animationStatus] == OIProducerAnimationStatusRendering) {
        [self determineAnimationParametersWithTime:time];
        
        if (self.isAnimatedImage) {
            currentAnimationTime_ = CMTimeGetSeconds(time) + hasPlayedTime_;
            
            while (currentAnimationTime_ > self.animatedImageDuration) {
                currentAnimationTime_ -= self.animatedImageDuration;
            }
            currentImageIndex_ = sourceImage_.images.count * currentAnimationTime_ / self.animatedImageDuration - 1;
            
            UIImage *currentImage = [sourceImage_.images objectAtIndex:currentImageIndex_];
            
            [outputTexture_ setupContentWithCGImage:currentImage.CGImage];
        }
    }
    else {
        if (self.isAnimatedImage) {
            
            if (currentImageIndex_ >= sourceImage_.images.count) {
                currentImageIndex_ = 0;
            }
//            NSLog(@"currentImageIndex:%d", currentImageIndex_);
            UIImage *currentImage = [sourceImage_.images objectAtIndex:currentImageIndex_];
            
            [outputTexture_ setupContentWithCGImage:currentImage.CGImage];
            
            ++currentImageIndex_;
        }
    }
    
    if (outputTexture_ && [consumers_ count]) {
        for (id <OIConsumer> consumer in consumers_) {
            [OIContext performSynchronouslyOnImageProcessingQueue:^{
                [consumer setInputTexture:outputTexture_];
                [consumer renderRect:outputFrame_ atTime:time];
            }];
        }
    }
}

- (void)initOutputTexture
{
    if (sourceImage_) {
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            
            if (outputTexture_) {
                [outputTexture_ release];
                outputTexture_ = nil;
            }
            
            outputTexture_ = [[OITexture alloc] initWithCGImage:sourceImage_.CGImage];
            outputTexture_.orientation = [self textureOrientationByImageOrientation:sourceImage_.imageOrientation];
        }];
    }
    else {
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            
            if (outputTexture_) {
                [outputTexture_ release];
                outputTexture_ = nil;
            }
        }];
    }
}

- (OITextureOrientation)textureOrientationByImageOrientation:(UIImageOrientation)imageOrientation
{
    OITextureOrientation textureOrientation = OITextureOrientationUp;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            textureOrientation = OITextureOrientationDown;
            break;
            
        default:
            break;
    }
    return textureOrientation;
}

@end
