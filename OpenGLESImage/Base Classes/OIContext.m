//
//  OIContext.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-2-19.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIContext.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>

@interface OIContext()
{
    dispatch_queue_t imageProcessingQueue_;
    EAGLContext *context_;
    EAGLSharegroup *sharegroup_;
}

@end

@implementation OIContext

@synthesize imageProcessingQueue = imageProcessingQueue_;
@synthesize sharegroup = sharegroup_;

#pragma mark - Class Methods

+ (OIContext *)sharedContext
{
    static OIContext *sharedContext = nil;
    if (sharedContext == nil) {
        sharedContext = [[[self class] alloc] init];
    }
    return sharedContext;
}

+ (dispatch_queue_t)sharedImageProcessingQueue
{
    return [OIContext sharedContext].imageProcessingQueue;
}

+ (void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block
{
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label([OIContext sharedImageProcessingQueue])) {
        
        [[OIContext sharedContext] setAsCurrentContext];
        
        block();
    }
    else {
        dispatch_sync([OIContext sharedImageProcessingQueue], ^{
            
            [[OIContext sharedContext] setAsCurrentContext];
            
            block();
        });
    }
}

+ (void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block
{
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label([OIContext sharedImageProcessingQueue])) {
        
        [[OIContext sharedContext] setAsCurrentContext];
        
        block();
    }
    else {
        dispatch_async([OIContext sharedImageProcessingQueue], ^{
            
            [[OIContext sharedContext] setAsCurrentContext];
            
            block();
        });
    }
}

+ (void)noLongerBeNeed
{
    [OIContext performAsynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] release];
    }];
}

#pragma mark - Lifecycle

- (void)dealloc
{
    if ([EAGLContext currentContext] == context_) {
        [EAGLContext setCurrentContext:nil];
    }
    [context_ release];
    context_ = nil;
    [sharegroup_ release];
    sharegroup_ = nil;
    dispatch_release(imageProcessingQueue_);
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        context_ = nil;
        sharegroup_ = nil;
        imageProcessingQueue_ = dispatch_queue_create("KwanYiuleung.OpenGLESImage.imageProcessingQueue", NULL);
    }
    return self;
}

#pragma mark -

- (void)setAsCurrentContext
{
    if (context_ == nil) {
        context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup_];
    }
    if ([EAGLContext currentContext] != context_) {
        [EAGLContext setCurrentContext:context_];
    }
}

- (void)renderBufferStorageFromDrawable:(id<EAGLDrawable>)drawable
{
    [context_ renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
}

- (void)presentRenderBufferToScreen
{
    [context_ presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Propertys' Setters & Getters

- (void)setSharegroup:(EAGLSharegroup *)sharegroup
{
    if (context_ == nil) {
        if (sharegroup_ != sharegroup) {
            [sharegroup_ release];
        }
        sharegroup_ = [sharegroup retain];
    }
}

@end
