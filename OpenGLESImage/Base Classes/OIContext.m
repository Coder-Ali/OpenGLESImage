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
#import "OIFrameBufferObject.h"

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

static OIContext *sharedContext_ = nil;

+ (OIContext *)sharedContext
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!sharedContext_) {
            sharedContext_ = [[super allocWithZone:NULL] init];
        }
    }) ;
    
    return sharedContext_;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [OIContext sharedContext];
}

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return [OIContext sharedContext];
}

+ (id)mutableCopyWithZone:(struct _NSZone *)zone
{
    return [OIContext sharedContext];
}

+ (void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block
{
//    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label([OIContext sharedContext].imageProcessingQueue)) {
    if (dispatch_get_current_queue() == [OIContext sharedContext].imageProcessingQueue) {
        
        [[OIContext sharedContext] setAsCurrentContext];
        
        block();
        
    }
    else {
        dispatch_sync([OIContext sharedContext].imageProcessingQueue, ^{
            
            [[OIContext sharedContext] setAsCurrentContext];
            
            block();
            
        });
    }
}

+ (void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block
{
//    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label([OIContext sharedContext].imageProcessingQueue)) {
    if (dispatch_get_current_queue() == [OIContext sharedContext].imageProcessingQueue) {
    
        [[OIContext sharedContext] setAsCurrentContext];
        
        block();
    }
    else {
        dispatch_async([OIContext sharedContext].imageProcessingQueue, ^{
            
            [[OIContext sharedContext] setAsCurrentContext];
            
            block();
        });
    }
}

+ (void)finish
{
    [[self class] performSynchronouslyOnImageProcessingQueue:^{
        glFinish();
    }];
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

- (instancetype)init
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

- (void)presentFrameBufferObject:(OIFrameBufferObject *)fbo
{
    [fbo bindToPipeline];
    
    if (fbo.type != OIFrameBufferObjectTypeForDisplay) {
        return;
    }
    
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
