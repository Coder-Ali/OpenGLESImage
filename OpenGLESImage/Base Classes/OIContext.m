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

@synthesize imageProcessingQueue;
@synthesize context;
@synthesize sharegroup;

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
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    [context release];
    context = nil;
    [sharegroup release];
    sharegroup = nil;
    dispatch_release(imageProcessingQueue);
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        context = nil;
        sharegroup = nil;
        imageProcessingQueue = dispatch_queue_create("com.shuliansoftware.OpenGLESImage.imageProcessingQueue", NULL);
    }
    return self;
}

#pragma mark -

- (void)setAsCurrentContext
{
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
    }
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
}

- (void)renderBufferStorageFromDrawable:(id<EAGLDrawable>)drawable
{
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
}

- (void)presentRenderBufferToScreen
{
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Propertys' Setters & Getters

- (void)setSharegroup:(EAGLSharegroup *)newSharegroup
{
    if (context == nil) {
        if (sharegroup != newSharegroup) {
            [sharegroup release];
        }
        sharegroup = [newSharegroup retain];
    }
}

@end
