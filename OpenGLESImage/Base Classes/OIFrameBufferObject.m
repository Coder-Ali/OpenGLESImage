//
//  OIFrameBufferObject.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-6.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIFrameBufferObject.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "OITexture.h"

@interface OIFrameBufferObject()
{
    GLuint frameBuffer_;
    GLuint renderBuffer_;
    OITexture *texture_;
    CGSize size_;
    OIFrameBufferObjectType type_;
    
    CAEAGLLayer *eaglLayer_;
    CVBufferRef specifiedCVBuffer_;
}

@end

@implementation OIFrameBufferObject

@synthesize size = size_;
@synthesize texture = texture_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [self deleteFrameBufferObject];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        frameBuffer_ = 0;
        renderBuffer_ = 0;
        texture_ = nil;
        size_ = CGSizeZero;
        type_ = OIFrameBufferObjectTypeUnknow;
        eaglLayer_ = nil;
        specifiedCVBuffer_ = NULL;
    }
    return self;
}

#pragma mark - Property Setters & Getters

//- (CGSize)size
//{
//    GLint bufferWidth, bufferHeight;
//    
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &bufferWidth);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &bufferHeight);
//    size_ = CGSizeMake(bufferWidth, bufferHeight);
//    return size_;
//}

#pragma mark - Setup FBO Storage

- (void)setupStorageForOffscreenWithSize:(CGSize)size
{
    if ((type_ != OIFrameBufferObjectTypeOffscreen && type_ != OIFrameBufferObjectTypeUnknow) || !CGSizeEqualToSize(size_, size)) {
        [self deleteFrameBufferObject];
    }
    size_ = size;
    type_ = OIFrameBufferObjectTypeOffscreen;
}

- (void)setupStorageForDisplayFromLayer:(CAEAGLLayer *)layer
{
    if ((type_ != OIFrameBufferObjectTypeForDisplay && type_ != OIFrameBufferObjectTypeUnknow) || eaglLayer_ != layer || !CGSizeEqualToSize(size_, layer.frame.size)) {
        [self deleteFrameBufferObject];
    }
    eaglLayer_ = layer;
    size_ = CGSizeMake(eaglLayer_.frame.size.width * eaglLayer_.contentsScale, eaglLayer_.frame.size.height * eaglLayer_.contentsScale);
    type_ = OIFrameBufferObjectTypeForDisplay;
}

- (void)setupStorageWithSpecifiedCVBuffer:(CVBufferRef)CVBuffer
{
    if ((type_ != OIFrameBufferObjectTypeSpecifiedCVBuffer && type_ != OIFrameBufferObjectTypeUnknow) || specifiedCVBuffer_  != CVBuffer /*|| !CGSizeEqualToSize(size_, layer.frame.size)*/) {
        [self deleteFrameBufferObject];
    }
    specifiedCVBuffer_ = CVBuffer;
    size_ = CGSizeMake(CVPixelBufferGetWidth(specifiedCVBuffer_), CVPixelBufferGetHeight(specifiedCVBuffer_));
    type_ = OIFrameBufferObjectTypeSpecifiedCVBuffer;
}

#pragma mark - FBO Maneger

- (void)generateFrameBufferObject
{
    glGenFramebuffers(1, &frameBuffer_);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer_);
    if (type_ == OIFrameBufferObjectTypeOffscreen) {
        texture_ = [[OITexture alloc] initWithSize:size_];
        [texture_ bindToTextureIndex:GL_TEXTURE0];
        [texture_ attachToCurrentFrameBufferObject];
    }
    else if (type_ == OIFrameBufferObjectTypeForDisplay) {
        glGenRenderbuffers(1, &renderBuffer_);
        glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer_);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer_);
        
        if ([EAGLContext currentContext]) {
            [[EAGLContext currentContext] renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer_];
        }
    }
    else if (type_ == OIFrameBufferObjectTypeSpecifiedCVBuffer) {
        texture_ = [[OITexture alloc] initWithCVBuffer:specifiedCVBuffer_];
        [texture_ bindToTextureIndex:GL_TEXTURE0];
        [texture_ attachToCurrentFrameBufferObject];
    }
}

- (void)bindToPipeline
{
    if (!frameBuffer_) {
        [self generateFrameBufferObject];
    }
    
    if (renderBuffer_) {
        glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer_);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer_);
    
    glViewport(0, 0, size_.width, size_.height);
}

- (void)clearBufferWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self bindToPipeline];
    glClearColor(red, green, blue, alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)deleteFrameBufferObject
{
    if (texture_) {
        [texture_ release];
    }
    if (renderBuffer_) {
        glDeleteRenderbuffers(1, &renderBuffer_);
    }
    if (frameBuffer_) {
        glDeleteFramebuffers(1, &frameBuffer_);
    }
    frameBuffer_ = 0;
    renderBuffer_ = 0;
    texture_ = nil;
    size_ = CGSizeZero;
    type_ = OIFrameBufferObjectTypeUnknow;
    eaglLayer_ = nil;
    specifiedCVBuffer_ = NULL;
}

#pragma mark - 

- (const GLfloat *)verticesCoordinateForDrawableRect:(CGRect)rect
{
    static CGRect preRect = {0.0, 0.0, 0.0, 0.0};
    static GLfloat vCoordinate[8] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    
    if (!CGRectEqualToRect(preRect, rect)) {
        GLfloat left   = rect.origin.x / size_.width * 2.0 - 1.0;
        GLfloat right  = (rect.origin.x + rect.size.width) / size_.width * 2.0 - 1.0;
        GLfloat top    = (1.0 - rect.origin.y / size_.height) * 2.0 - 1.0;
        GLfloat bottom = (1.0 - (rect.origin.y + rect.size.height) / size_.height) * 2.0 - 1.0;
        
        vCoordinate[0] = left;
        vCoordinate[1] = bottom;
        vCoordinate[2] = right;
        vCoordinate[3] = bottom;
        vCoordinate[4] = left;
        vCoordinate[5] = top;
        vCoordinate[6] = right;
        vCoordinate[7] = top;
    }
    
    return vCoordinate;
}

@end
