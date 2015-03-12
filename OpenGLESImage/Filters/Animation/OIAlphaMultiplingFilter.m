//
//  OIAlphaMultiplingFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-6.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIAlphaMultiplingFilter.h"

@implementation OIAlphaMultiplingFilter

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"AlphaMultipling";
    return fName;
}

@end
