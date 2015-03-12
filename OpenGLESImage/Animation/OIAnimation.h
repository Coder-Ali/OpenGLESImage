//
//  OIAnimation.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-25.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OIAudioVideoWriter.h"


@class OIAnimation;

@protocol OIAnimationDelegate <NSObject>

@optional
- (void)animationDidFinish:(OIAnimation *)animation;
- (void)animationDidRecord:(OIAnimation *)animation;

@end

@class OIView;
@class OIImage;
@class OIAnimationConfiguration;

@interface OIAnimation : NSObject <OIAudioVideoWriterDelegate>

- (id)initWithAnimationConfiguration:(OIAnimationConfiguration *)configuration;

- (id)initWithConfigurations:(NSArray *)configurations;

- (void)playAtView:(OIView *)view;  // The receiver will start to play when this method be call in the specified view.

@property (assign, nonatomic) id <OIAnimationDelegate> delegate;

@property (retain, nonatomic) OIAudioVideoWriter *recorder;  // Set your AV writer to record the animation. Default is nil.

@property (retain, nonatomic) NSURL *outputFileURL;

@property (retain, nonatomic) OIImage *coverImage;

@property (copy, nonatomic) NSString *backgroundMusic;

/***************************************/

@property (copy, nonatomic) OIAnimationConfiguration *configuration;

- (void)registerProducers:(NSArray *)producers;
- (void)registerProducer:(OIProducer *)Producer forItemIdentifier:(NSString *)identifier;

@end
