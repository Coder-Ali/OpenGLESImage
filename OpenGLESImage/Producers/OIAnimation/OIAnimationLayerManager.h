//
//  OIAnimationLayerManager.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/7.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class OIAnimationLayer;

@interface OIAnimationLayerManager : NSObject

@property (nonatomic) CGSize layerSize;

- (OIAnimationLayer *)getLayerChainWithConfigurations:(NSArray *)configurations;

@end
