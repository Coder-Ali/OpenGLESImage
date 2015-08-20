//
//  OIAnimationLayerMixerConfiguration.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/7.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationLayerMixerConfiguration.h"

@implementation OIAnimationLayerMixerConfiguration

+ (OIAnimationLayerMixerConfiguration *)animationLayerMixerConfigurationWithMixMode:(OIAnimationLayerMixerMixMode)mixMode alpha:(float)alpha tone:(OIColor)tone
{
    OIAnimationLayerMixerConfiguration *configuration = [[OIAnimationLayerMixerConfiguration alloc] init];
    
    configuration.mixMode = mixMode;
    configuration.alpha = alpha;
    configuration.tone = tone;
    
    return [configuration autorelease];
}

@end
