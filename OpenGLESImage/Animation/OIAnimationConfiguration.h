//
//  OIAnimationConfiguration.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-12-31.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OIAnimationConfigurationDescription;

@interface OIAnimationConfiguration : NSObject

@property (nonatomic) float totalTime;

@property (copy, nonatomic) NSString *coverImagePath;

@property (copy, nonatomic) NSString *backgroundMusicPath;

@property (readonly, nonatomic) NSArray *allItemIdentifiers;

- (id)init;

- (NSArray *)configurationDescriptionsAtTime:(double)time;
- (NSArray *)configurationDescriptionsInOrderAtTime:(double)time;


@end
