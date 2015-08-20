//
//  OIAnimationLayerConfiguration.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

static const float kOIAnimationLayerConfigurationNoBlur = -1.0;

@class OIProducer;

@interface OIAnimationLayerConfiguration : NSObject

+ (OIAnimationLayerConfiguration *)animationLayerConfigurationWithSource:(OIProducer *)source sourceBounds:(CGRect)sourceBounds blurSize:(float)blurSize;

@property (retain, nonatomic) OIProducer *source;

@property (nonatomic) CGRect sourceBounds;

@property (nonatomic) float blurSize;

@property (nonatomic) int tag;

@end
