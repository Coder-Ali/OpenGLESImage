//
//  OIUIElement.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-31.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIUIElement.h"
#import <UIKit/UIKit.h>
#import "OIContext.h"
#import "OITexture.h"

@interface OIUIElement ()
{
    CALayer *sourceLayer_;
}

@end

@implementation OIUIElement

#pragma mark - Life Cycle

- (void)dealloc
{
    if (sourceLayer_) {
        [sourceLayer_ release];
    }
    
    [super dealloc];
}

- (instancetype)initWithUIView:(UIView *)uiView;
{
    self = [self initWithCALayer:uiView.layer];
    
    return self;
}

- (instancetype)initWithCALayer:(CALayer *)caLayer
{
    if (!caLayer) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        sourceLayer_ = [caLayer retain];
        
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            outputTexture_ = [[OITexture alloc] initWithCALayer:sourceLayer_];
        }];
        
        outputFrame_ = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
    }
    return self;
}

- (void)refresh
{
    if (!self.isEnabled) {
        return;
    }
    
    
}

@end
