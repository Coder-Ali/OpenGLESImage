//
//  OIAnimationScript.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/4.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationScript.h"
#import "OIAnimationScriptItem.h"

@interface OIAnimationScript ()
{
    NSArray *items_;
}

@end

@implementation OIAnimationScript

#pragma mark - Lifecycle

- (void)dealloc
{
    [items_ release];
    
    [super dealloc];
}

- (instancetype)initWithScriptItems:(NSArray *)items
{
    self = [super init];
    
    if (self) {
        items_ = [items retain];
    }
    
    return self;
}

#pragma mark - Public Methods

- (NSArray *)layerConfigurationsAtTime:(float)seconds
{
    NSArray *currentItems = [self scriptItemsAtTime:seconds];
    
    NSMutableArray *layerConfigurations = [[NSMutableArray alloc] init];
    
    for (OIAnimationScriptItem *item in currentItems) {
        [layerConfigurations addObject:[item layerConfigurationAtTime:seconds]];
    }
    
    return layerConfigurations;
}

- (NSArray *)layerMixerConfigurationsAtTime:(float)seconds
{
    NSArray *currentItems = [self scriptItemsAtTime:seconds];
    
    NSMutableArray *layerMixerConfigurations = [[NSMutableArray alloc] init];
    
    for (OIAnimationScriptItem *item in currentItems) {
        [layerMixerConfigurations addObject:[item layerMixerConfigurationAtTime:seconds]];
    }
    
    return layerMixerConfigurations;
}

#pragma mark - Private Methods

- (NSArray *)scriptItemsAtTime:(float)time
{
    NSMutableArray *targetScriptItems = [[NSMutableArray alloc] init];
    
    for (OIAnimationScriptItem *item in items_) {
        if ([item isAvailableAtTime:time]) {
            for (OIAnimationScriptItem *lowerItem in targetScriptItems) {
                if (item.targetIndex < lowerItem.targetIndex) {
                    [targetScriptItems insertObject:item atIndex:[targetScriptItems indexOfObject:lowerItem]];
                    break;
                }
            }
            
            if (![targetScriptItems containsObject:item]) {
                [targetScriptItems addObject:item];
            }
        }
    }
    
    return [targetScriptItems autorelease];
}

@end
