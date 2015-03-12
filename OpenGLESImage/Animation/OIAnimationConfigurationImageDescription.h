//
//  OIAnimationConfigurationImageDescription.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15-1-6.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationConfigurationDescription.h"
#import <CoreGraphics/CoreGraphics.h>

@interface OIAnimationConfigurationImageDescription : OIAnimationConfigurationDescription

// Moving Description
@property (nonatomic) float movingStartTime;
@property (nonatomic) float movingEndTime;
@property (nonatomic) CGPoint originalPoint;
@property (nonatomic) CGPoint targetPoint;
@property (nonatomic) int movingEaseMode;

// Scale Description
@property (nonatomic) float scaleStartTime;
@property (nonatomic) float scaleEndTime;
@property (nonatomic) float originalScale;
@property (nonatomic) float targetScale;
@property (nonatomic) int scaleEaseMode;

// Transparency Description
@property (nonatomic) float transparencyStartTime;
@property (nonatomic) float transparencyEndTime;
@property (nonatomic) float originalAlpha;
@property (nonatomic) float targetAlpha;
@property (nonatomic) int transparencyEaseMode;

// Blur Description
@property (nonatomic) float blurStartTime;
@property (nonatomic) float blurEndTime;
@property (nonatomic) float originalBlurSize;
@property (nonatomic) float targetBlurSize;
@property (nonatomic) int blurEaseMode;

// Tone Description
@property (nonatomic) float toneStartTime;
@property (nonatomic) float toneEndTime;
@property (nonatomic) float toneRed;
@property (nonatomic) float toneGreen;
@property (nonatomic) float toneBlue;
@property (nonatomic) float originalTonePercentage;
@property (nonatomic) float targetTonePercentage;
@property (nonatomic) int toneEaseMode;

// Rotation Description
@property (nonatomic) float rotationStartTime;
@property (nonatomic) float rotationEndTime;
@property (nonatomic) float originalDegrees;
@property (nonatomic) float targetDegrees;
@property (nonatomic) int rotationEaseMode;

@end
