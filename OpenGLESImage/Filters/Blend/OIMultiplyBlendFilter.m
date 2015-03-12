//
//  OIMultiplyBlendFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-12-19.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIMultiplyBlendFilter.h"

@implementation OIMultiplyBlendFilter

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"MultiplyBlend";
    return fName;
}

@end
