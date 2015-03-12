//
//  OIScreenBlendFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-10-23.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIScreenBlendFilter.h"

@implementation OIScreenBlendFilter

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"ScreenBlend";
    return fName;
}

@end
