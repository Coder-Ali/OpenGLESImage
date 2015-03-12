//
//  OIAnimationConfigurationTextDescription.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15-1-6.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationConfigurationDescription.h"

@interface OIAnimationConfigurationTextDescription : OIAnimationConfigurationDescription

// Text Description
@property (copy, nonatomic) NSString *textFontName;
@property (nonatomic) float textFontSize;
@property (nonatomic) int textColor;
@property (copy, nonatomic) NSString *text;
@property (nonatomic) int textAlignment;

@end
