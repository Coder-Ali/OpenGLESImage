//
//  OIContext.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-2-19.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>


@class EAGLContext;
@class EAGLSharegroup;
@protocol EAGLDrawable;

@interface OIContext : NSObject

@property (readonly, nonatomic) dispatch_queue_t imageProcessingQueue;

@property (readwrite, retain, nonatomic) EAGLSharegroup *sharegroup;

+ (OIContext *)sharedContext;
+ (dispatch_queue_t)sharedImageProcessingQueue;
+ (void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block;
+ (void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block;
+ (void)noLongerBeNeed;

- (void)setAsCurrentContext;
- (void)renderBufferStorageFromDrawable:(id<EAGLDrawable>)drawable;
- (void)presentRenderBufferToScreen;

@end
