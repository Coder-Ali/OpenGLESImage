//
//  OIMultiImagesSplicingFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-5.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIMultiImagesSplicingFilter.h>

@implementation OIMultiImagesSplicingFilter

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"MultiImagesSplicing";
    return fName;
}

@end
