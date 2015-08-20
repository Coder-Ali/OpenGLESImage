//
//  OIAnimationLayerManager.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/7.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationLayerManager.h"
#import "OIAnimationLayer.h"
#import "OIAnimationLayerConfiguration.h"

#define MAX_LAYER_COUNT 8

@interface OIAnimationLayerManager ()
{
    NSMutableArray *layerStack_;
    OIAnimationLayer *currentLayerChain_;
}

@end

@implementation OIAnimationLayerManager

#pragma mark - Lifecycle

- (void)dealloc
{
    [self freeLayerChain];
    
    [layerStack_ release];
    
    [super dealloc];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        layerStack_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - Public Methods

- (OIAnimationLayer *)getLayerChainWithConfigurations:(NSArray *)configurations
{
    [self freeLayerChain];
    
    OIAnimationLayer *lastLayer = nil;
    
    for (OIAnimationLayerConfiguration *configuration in configurations) {
        if (!currentLayerChain_) {
            currentLayerChain_ = [self layerNotInUse];
            currentLayerChain_.configuration = configuration;
            lastLayer = currentLayerChain_;
        }
        else {
            OIAnimationLayer *layer = [self layerNotInUse];
            
            if (!layer) {
                break;
            }
            
            layer.configuration = configuration;
            lastLayer.nextLayer = layer;
            lastLayer = layer;
        }
    }
    return currentLayerChain_;
}

- (void)freeLayerChain
{
    OIAnimationLayer *lowestLayer = currentLayerChain_;
    
    while (lowestLayer) {
        OIAnimationLayer *nextLayer = lowestLayer.nextLayer;
        
        lowestLayer.nextLayer = nil;
        
        [self layerStackPush:lowestLayer];
        
        lowestLayer = nextLayer;
    }
    
    currentLayerChain_ = nil;
}

#pragma mark - Private Methods

- (OIAnimationLayer *)layerNotInUse
{
    OIAnimationLayer *layer = [self layerStackPop];
    
    if (!layer) {
        if (layerStack_.count < MAX_LAYER_COUNT) {
            layer = [[OIAnimationLayer alloc] initWithSize:self.layerSize];
        }
    }
    
    return layer;
}

- (OIAnimationLayer *)layerStackPop
{
    OIAnimationLayer *layer = nil;
    
    if (layerStack_.count > 0) {
        layer = [[layerStack_ lastObject] retain];
        [layerStack_ removeObject:layer];
    }
    
    return layer;
}

- (void)layerStackPush:(OIAnimationLayer *)layer
{
    [layerStack_ addObject:layer];
    
    [layer release];
}

@end
