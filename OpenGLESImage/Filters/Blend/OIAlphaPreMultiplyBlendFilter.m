//
//  OIAlphaPreMultiplyBlendFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-10-28.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIAlphaPreMultiplyBlendFilter.h>

@implementation OIAlphaPreMultiplyBlendFilter

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"AlphaPreMultiplyBlend";
    return fName;
}

@end
