//
//  OIAnimationLayerConfiguration.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationLayerConfiguration.h"

@implementation OIAnimationLayerConfiguration

#pragma mark - Lifecycle

- (void)dealloc
{
    self.source = nil;
    
    [super dealloc];
}

#pragma mark - Class Methods

+ (OIAnimationLayerConfiguration *)animationLayerConfigurationWithSource:(OIProducer *)source sourceBounds:(CGRect)sourceBounds blurSize:(float)blurSize
{
    OIAnimationLayerConfiguration *layerConfiguration = [[OIAnimationLayerConfiguration alloc] init];
    
    layerConfiguration.source = source;
    
    layerConfiguration.sourceBounds = sourceBounds;
    
    layerConfiguration.blurSize = blurSize;
    
    return [layerConfiguration autorelease];
}

@end
