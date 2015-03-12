//
//  OIAnimationConfigurationDescription.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15-1-5.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>

enum OIAnimationConfigurationDescriptionItemType_ {
    OIAnimationConfigurationDescriptionItemTypeImage,
    OIAnimationConfigurationDescriptionItemTypeText,
    OIAnimationConfigurationDescriptionItemTypeTextBackground
};

typedef enum OIAnimationConfigurationDescriptionItemType_ OIAnimationConfigurationDescriptionItemType;

@interface OIAnimationConfigurationDescription : NSObject

@property (retain, nonatomic) NSString *itemIdentifier;

@property (nonatomic) OIAnimationConfigurationDescriptionItemType *itemType;

@property (nonatomic) float startTime;
@property (nonatomic) float endTime;

@property (nonatomic) float width;
@property (nonatomic) float height;

@end
