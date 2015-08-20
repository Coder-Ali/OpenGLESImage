//
//  OIAnimationLayerMixerConfiguration.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/7.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef int OIAnimationLayerMixerMixMode;

static const OIAnimationLayerMixerMixMode kOIAnimationLayerMixerMixModeNormal = 0;
static const OIAnimationLayerMixerMixMode kOIAnimationLayerMixerMixModeMask = 1;
static const OIAnimationLayerMixerMixMode kOIAnimationLayerMixerMixModeImageInMask = 2;
static const OIAnimationLayerMixerMixMode kOIAnimationLayerMixerMixModeLightingEffect = 3;
static const OIAnimationLayerMixerMixMode kOIAnimationLayerMixerMixModeAlphaPreMultiplied = 4;

@interface OIAnimationLayerMixerConfiguration : NSObject

+ (OIAnimationLayerMixerConfiguration *)animationLayerMixerConfigurationWithMixMode:(OIAnimationLayerMixerMixMode)mixMode alpha:(float)alpha tone:(OIColor)tone;

@property (nonatomic) OIAnimationLayerMixerMixMode mixMode;

@property (nonatomic) float alpha;

@property (nonatomic) OIColor tone;

@end
