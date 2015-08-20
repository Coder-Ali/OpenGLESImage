//
//  OIAnimationLayerMixer.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 15/8/5.
//  Copyright (c) 2015年 Kwan Yiuleung. All rights reserved.
//

#import "OIAnimationLayerMixer.h"
#import "OIAnimationLayerMixerConfiguration.h"

@interface OIAnimationLayerMixer ()
{
    NSArray *configurations_;
}

@end

@implementation OIAnimationLayerMixer

@synthesize configurations = configurations_;

#pragma mark - Properties' Setter & Getter

- (void)setConfigurations:(NSArray *)configurations
{
    if (configurations_) {
        [configurations_ release];
        configurations_ = nil;
    }
    
    if (configurations) {
        configurations_ = [configurations retain];
    }
    
    if (configurations_) {
        self.inputCount = (unsigned int)configurations_.count;
    }
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"AnimationLayerMixer";
    return fName;
}

- (void)setProgramUniform
{
    OIAnimationLayerMixerMixMode mixModes[self.configurations.count];
    float alphas[self.configurations.count];
    OIColor tones[self.configurations.count];
    
    for (int i = 0; i < self.configurations.count; ++i) {
        OIAnimationLayerMixerConfiguration *configuration = self.configurations[i];
        mixModes[i] = configuration.mixMode;
        alphas[i] = configuration.alpha;
        tones[i] = configuration.tone;
    }
    
    [filterProgram_ setIntArray:mixModes withArrayCount:(int)self.configurations.count forUniform:@"mixModes"];
    [filterProgram_ setFloatArray:alphas withArrayCount:(int)self.configurations.count forUniform:@"alphas"];
    [filterProgram_ set4DFloatVectorArray:(OI4DFloatVector *)tones withArrayCount:(int)self.configurations.count forUniform:@"tones"];
}

@end
