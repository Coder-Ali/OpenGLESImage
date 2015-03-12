//
//  OIConsumer.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-15.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>

@class UIImage;
@class OIProducer;
@class OITexture;

@protocol OIConsumer <NSObject>

@required

@property (readwrite, nonatomic, getter=isEnabled) BOOL enabled;
@property (readwrite, nonatomic) CGSize contentSize;
@property (readonly, nonatomic) NSArray *producers;

- (void)setProducer:(OIProducer *)producer;
- (void)removeProducer:(OIProducer *)producer;
- (void)setInputTexture:(OITexture *)inputTexture;
- (void)renderRect:(CGRect)rect atTime:(CMTime)time;

@optional
- (UIImage *)imageFromCurrentFrame;

@end
