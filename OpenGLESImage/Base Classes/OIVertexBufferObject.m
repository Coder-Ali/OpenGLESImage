//
//  OIVertexBufferObject.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 16/8/8.
//  Copyright © 2016年 Kwan Yiuleung. All rights reserved.
//

#import "OIVertexBufferObject.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface OIVertexBufferObject ()
{
    GLuint vertexBuffer;
}

@property (nonatomic) OIVertexBufferObjectType type;

@end

@implementation OIVertexBufferObject

#pragma mark - 生命周期

- (void)dealloc
{
    [self deleteVertexBufferObject];
    
    [super dealloc];
}

- (instancetype)initWithType:(OIVertexBufferObjectType)type buffer:(void *)buffer size:(long)bufferSize usage:(OIVertexBufferObjectUsage)usage
{
    self = [super init];
    
    if (self) {
        _type = type;
        
        GLenum target = GL_ARRAY_BUFFER;
        GLenum vboUsage = GL_STATIC_DRAW;
        
        if (_type == OIVertexBufferObjectTypeIndices) {
            target = GL_ELEMENT_ARRAY_BUFFER;
        }
        
        if (usage == OIVertexBufferObjectUsageDynamic) {
            vboUsage = GL_DYNAMIC_DRAW;
        }
        else if (usage == OIVertexBufferObjectUsageStream) {
            vboUsage = GL_STREAM_DRAW;
        }
        
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(target, vertexBuffer);
        glBufferData(target, bufferSize, buffer, vboUsage);
        glBindBuffer(target, 0);
    }
    
    return self;
}

#pragma mark - 公有方法

- (void)updateLocation:(int)offset byBuffer:(void *)buffer withSize:(long)bufferSize
{
    glBufferSubData([self vboTarget], offset, bufferSize, buffer);
}


- (void)bind
{
    glBindBuffer([self vboTarget], vertexBuffer);
}

- (void)unbind
{
    glBindBuffer([self vboTarget], 0);
}

#pragma mark - 私有方法

- (GLenum)vboTarget
{
    GLenum target = GL_ARRAY_BUFFER;
    
    if (self.type == OIVertexBufferObjectTypeIndices) {
        target = GL_ELEMENT_ARRAY_BUFFER;
    }
    
    return target;
}

- (void)deleteVertexBufferObject
{
    if (vertexBuffer) {
        glDeleteBuffers(1, &vertexBuffer);
        vertexBuffer = 0;
    }
}

@end
