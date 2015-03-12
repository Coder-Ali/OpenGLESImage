//
//  OIOverlayBlendFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-12-17.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIOverlayBlendFilter.h"

@implementation OIOverlayBlendFilter

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"OverlayBlend";
    return fName;
}

@end
