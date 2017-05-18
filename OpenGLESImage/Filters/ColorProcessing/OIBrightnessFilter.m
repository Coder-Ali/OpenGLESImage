//
//  OIBrightnessFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-4.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIBrightnessFilter.h"

@interface OIBrightnessFilter ()
{
    float brightnessValue_;
}

@end

@implementation OIBrightnessFilter

@synthesize brightnessValue = brightnessValue_;

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.brightnessValue = 0.5;
    }
    return self;
}

@end
