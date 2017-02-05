//
//  OIProgram.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-3.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIProgram.h"
#import "OIContext.h"

@interface OIProgram()
{
    GLuint program_;
    GLuint vertexShader_;
    GLuint fragmentShader_;
    
    NSMutableDictionary *attributes_;
    NSMutableDictionary *uniforms_;
}

@end

@implementation OIProgram

#pragma mark - Lifecycle

- (void)dealloc
{
    glDeleteShader(vertexShader_);
    glDeleteShader(fragmentShader_);
    glDeleteProgram(program_);
    [attributes_ release];
    [uniforms_ release];
    [super dealloc];
}

- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString
{
    self = [super init];
    if (self && vShaderString != nil && fShaderString != nil) {
        attributes_ = [[NSMutableDictionary alloc] init];
        uniforms_ = [[NSMutableDictionary alloc] init];
        
        vertexShader_ = [self buildShaderWithSourceChar:[vShaderString UTF8String] type:GL_VERTEX_SHADER];
        fragmentShader_ = [self buildShaderWithSourceChar:[fShaderString UTF8String] type:GL_FRAGMENT_SHADER];
        program_ = [self buildProgramWithVertexShader:vertexShader_ fragmentShader:fragmentShader_];
    }
    return self;
}

- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename
{
    if (vShaderFilename == nil || fShaderFilename == nil) {
        return nil;
    }
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"OpenGLESImage" withExtension:@"bundle"];
    
    NSBundle *bundle = nil;
    if (bundleURL) {
        bundle = [NSBundle bundleWithURL:bundleURL];
    }
    
    
    NSString *vShaderFilePath = nil;
    NSString *fShaderFilePath = nil;
    
    if (bundle) {
        vShaderFilePath = [bundle pathForResource:vShaderFilename ofType:@"vsh"];
        fShaderFilePath = [bundle pathForResource:fShaderFilename ofType:@"fsh"];
    }
    
    if (!vShaderFilePath) {
        vShaderFilePath = [[NSBundle mainBundle] pathForResource:vShaderFilename ofType:@"vsh"];
        
        if (!vShaderFilePath) {
            NSLog(@"OpenGLESImage Error at initWithVertexShaderFilename:fragmentShaderFilename: : %@ vertex shader file is not found", vShaderFilename);
        }
    }
    if (!fShaderFilePath) {
        fShaderFilePath = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
        
        if (!fShaderFilePath) {
            NSLog(@"OpenGLESImage Error at initWithVertexShaderFilename:fragmentShaderFilename: : %@ fragment shader file is not found", fShaderFilename);
        }
    }
    
    NSString *vShaderString = [self getShaderStringFromFilePath:vShaderFilePath];
    NSString *fShaderString = [self getShaderStringFromFilePath:fShaderFilePath];
    
    if (!vShaderString) {
        NSLog(@"OpenGLESImage Error at initWithVertexShaderFilename:fragmentShaderFilename: : %@ vertex shader string can not be loaded", vShaderFilename);
    }
    if (!fShaderString) {
        NSLog(@"OpenGLESImage Error at initWithVertexShaderFilename:fragmentShaderFilename: : %@ fragment shader string can not be loaded", fShaderFilename);
    }
    
    self = [self initWithVertexShaderString:vShaderString fragmentShaderString:fShaderString];
    
    return self;
}

#pragma mark - OpenGLES 2.0 Program Building Methods

- (GLuint)buildShaderWithSourceChar:(const char *)source type:(GLenum)shaderType
{
    if (source == nil) {
        return 0;
    }
    GLuint shaderHandle = glCreateShader(shaderType);
    glShaderSource(shaderHandle, 1, &source, 0);
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSLog(@"OpenGLESImage Error at compiling shader message:%s", message);
    }
    return shaderHandle;
}

- (GLuint)buildProgramWithVertexShader:(GLuint)vShader fragmentShader:(GLuint)fShader
{
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vShader);
    glAttachShader(programHandle, fShader);
    glLinkProgram(programHandle);
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(programHandle, sizeof(message), 0, &message[0]);
        NSLog(@"OpenGLESImage Error at linking program message:%s", message);
    }
    return programHandle;
}

- (NSString *)getShaderStringFromFilePath:(NSString *)filePath
{
    if (filePath == nil) {
        return nil;
    }
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString || shaderString == NULL) {
        NSLog(@"OpenGLESImage Error at loading shader file at path:%@ message: %@", filePath, error.localizedDescription);
    }

    return shaderString;
}

#pragma mark -

- (void)use
{
    glUseProgram(program_);
}

- (void)draw
{
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)drawWithIndexCount:(GLsizei)count
{
    glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_SHORT, 0);
}

#pragma mark - Getting Attribute or Uniform Location Methods

- (NSNumber *)locationForAttributeName:(NSString *)attributeName
{
    NSNumber *attributeLocation = [attributes_ objectForKey:attributeName];
    if (!attributeLocation) {
        GLint location = glGetAttribLocation(program_, [attributeName UTF8String]);
        glEnableVertexAttribArray(location);
        
        attributeLocation = [NSNumber numberWithInt:location];
        [attributes_ setObject:attributeLocation forKey:attributeName];
    }
    return attributeLocation;
}

- (NSNumber *)locationForUniformName:(NSString *)uniformName
{
    NSNumber *uniformLocation = [uniforms_ objectForKey:uniformName];
    if (!uniformLocation) {
        GLint location = glGetUniformLocation(program_, [uniformName UTF8String]);
        uniformLocation = [NSNumber numberWithInt:location];
        [uniforms_ setObject:uniformLocation forKey:uniformName];
    }
    return uniformLocation;
}

#pragma mark - Setting Attribute Methods

- (void)setCoordinatePointer:(const GLfloat *)pointer coordinateSize:(GLint)size forAttribute:(NSString *)attributeName
{
    NSNumber *attributeLocation = [self locationForAttributeName:attributeName];
    
    glVertexAttribPointer([attributeLocation intValue], size, GL_FLOAT, GL_FALSE, 0, pointer);
}

#pragma mark - Setting Uniform Methods

- (void)setInt:(int)intValue forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform1i([uniformLocation intValue], intValue);
}

- (void)setIntArray:(int *)intArray withArrayCount:(int)count forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform1iv([uniformLocation intValue], count, intArray);
}

- (void)setFloat:(float)floatValue forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform1f([uniformLocation intValue], floatValue);
}

- (void)setTextureIndex:(int)index forTexture:(NSString *)textureName
{
    [self setInt:index forUniform:textureName];
}

- (void)setFloatArray:(float *)floatArray withArrayCount:(int)count forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform1fv([uniformLocation intValue], count, floatArray);
}

- (void)set2DFloatVector:(OI2DFloatVector)vector forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform2f([uniformLocation intValue], vector.x, vector.y);
}

- (void)set4DFloatVectorArray:(OI4DFloatVector *)vectorArray withArrayCount:(int)count forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniform4fv([uniformLocation intValue], count * 4, (GLfloat *)vectorArray);
}

- (void)set4x4Matrix:(float *)matrix forUniform:(NSString *)uniformName
{
    NSNumber *uniformLocation = [self locationForUniformName:uniformName];
    
    glUniformMatrix4fv([uniformLocation intValue], 1, GL_FALSE, matrix);
}

@end
