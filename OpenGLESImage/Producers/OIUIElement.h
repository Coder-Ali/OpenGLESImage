//
//  OIUIElement.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-31.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIProducer.h"


@class UIView;

@interface OIUIElement : OIProducer

- (instancetype)initWithUIView:(UIView *)uiView;
- (instancetype)initWithCALayer:(CALayer *)caLayer;

- (void)refresh;

@end
