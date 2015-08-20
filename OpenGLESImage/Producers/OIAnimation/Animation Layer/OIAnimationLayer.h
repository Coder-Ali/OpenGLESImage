//
//  OIAnimationLayer.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class OIAnimationLayerConfiguration;
@class OIAnimationLayerMixer;

@interface OIAnimationLayer : NSObject

- (instancetype)initWithSize:(CGSize)size;

@property (retain, nonatomic) OIAnimationLayerConfiguration *configuration;

@property (retain, nonatomic) OIAnimationLayerMixer *mixer;

@property (retain, nonatomic) OIAnimationLayer *nextLayer;

@property (nonatomic) int tag;

- (void)outputAtTime:(CMTime)time;

@end
