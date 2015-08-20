//
//  OIAnimationScriptItem.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationScriptItem.h"
#import "OIAnimationLayerConfiguration.h"
#import "OIAnimationLayerMixerConfiguration.h"

@implementation OIAnimationScriptItem

#pragma mark - Class Methods

+ (OIAnimationScriptItem *)animationScriptItemWithTarget:(OIProducer *)target targetType:(OIAnimationScriptItemTargetType)targetType targetIndex:(int)targetIndex startTime:(float)startTime endTime:(float)endTime
{
    OIAnimationScriptItem *item = [[OIAnimationScriptItem alloc] init];
    
    item.target = target;
    item.targetType = targetType;
    item.targetIndex = targetIndex;
    item.startTime = startTime;
    item.endTime = endTime;
    
    return [item autorelease];
}

#pragma mark - Public Methods

- (BOOL)isAvailableAtTime:(float)seconds
{
    if (seconds >= self.startTime && seconds <= self.endTime) {
        return YES;
    }
    
    return NO;
}

- (OIAnimationLayerConfiguration *)layerConfigurationAtTime:(float)seconds
{
    if (![self isAvailableAtTime:seconds]) {
        return nil;
    }
    
    float factor = [self yValueByXValue:(seconds - self.startTime)/(self.endTime - self.startTime) inEasingMode:self.easingMode];
    
    float x = CGRectGetMinX(self.originalBounds) + (CGRectGetMinX(self.finalBounds) - CGRectGetMinX(self.originalBounds)) * factor;
    float y = CGRectGetMinY(self.originalBounds) + (CGRectGetMinY(self.finalBounds) - CGRectGetMinY(self.originalBounds)) * factor;
    float w = CGRectGetWidth(self.originalBounds) + (CGRectGetWidth(self.finalBounds) - CGRectGetWidth(self.originalBounds)) * factor;
    float h = CGRectGetHeight(self.originalBounds) + (CGRectGetHeight(self.finalBounds) - CGRectGetHeight(self.originalBounds)) * factor;
    
    float blurSize = self.originalBlurSize + (self.finalBlurSize - self.originalBlurSize) * factor;
    
    return [OIAnimationLayerConfiguration animationLayerConfigurationWithSource:self.target sourceBounds:CGRectMake(x, y, w, h) blurSize:blurSize];
}

- (OIAnimationLayerMixerConfiguration *)layerMixerConfigurationAtTime:(float)seconds;
{
    if (![self isAvailableAtTime:seconds]) {
        return nil;
    }
    
    float factor = [self yValueByXValue:seconds - self.startTime inEasingMode:self.easingMode];
    
    OIAnimationLayerMixerMixMode mixMode = [self mixModeAccordingToTargetType:self.targetType];
    
    float alpha = self.originalAlpha + (self.finalAlpha - self.originalAlpha) * factor;
    
    OIColor color;
    color.red = self.originalTone.red + (self.finalTone.red - self.originalTone.red) * factor;
    color.green = self.originalTone.green + (self.finalTone.green - self.originalTone.green) * factor;
    color.blue = self.originalTone.blue + (self.finalTone.blue - self.originalTone.blue) * factor;
    color.alpha = self.originalTone.alpha + (self.finalTone.alpha - self.originalTone.alpha) * factor;
    
    return [OIAnimationLayerMixerConfiguration animationLayerMixerConfigurationWithMixMode:mixMode alpha:alpha tone:color];
}

#pragma mark - Private Methods

- (float)yValueByXValue:(float)xValue inEasingMode:(OIAnimationEasingMode)easingMode
{
    switch (easingMode) {
        case OIAnimationEasingModeEaseInSine:
            return -cos(xValue * OI_PI_2) + 1.0;
            
        case OIAnimationEasingModeEaseOutSine:
            return sin(xValue *  OI_PI_2);
            
        case OIAnimationEasingModeEaseInOutSine:
            return (-0.5 * (cos(xValue * OI_PI) - 1.0));
            
        default:
            return xValue;
    }
}

- (OIAnimationLayerMixerMixMode)mixModeAccordingToTargetType:(OIAnimationScriptItemTargetType)targetType
{
    OIAnimationLayerMixerMixMode mixMode = kOIAnimationLayerMixerMixModeNormal;
    
    switch (targetType) {
        case OIAnimationScriptItemTargetTypeCover:
            mixMode = kOIAnimationLayerMixerMixModeAlphaPreMultiplied;
            break;
            
        case OIAnimationScriptItemTargetTypeImageInMask:
            mixMode = kOIAnimationLayerMixerMixModeImageInMask;
            break;
            
        case OIAnimationScriptItemTargetTypeLightingEffect:
            mixMode = kOIAnimationLayerMixerMixModeLightingEffect;
            break;
            
        case OIAnimationScriptItemTargetTypeMask:
            mixMode = kOIAnimationLayerMixerMixModeMask;
            break;
            
        default:
            break;
    }
    
    return mixMode;
}

@end
