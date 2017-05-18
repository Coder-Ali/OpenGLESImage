//
//  OITexture.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-6.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

typedef enum _OITextureOrientation {
    OITextureOrientationUp            = 0,
    OITextureOrientationDown          = 1,
    OITextureOrientationLeft          = 2,
    OITextureOrientationRight         = 3,
    OITextureOrientationUpMirrored    = 4,    // as above but image mirrored along other axis. horizontal flip
    OITextureOrientationDownMirrored  = 5,    // horizontal flip
    OITextureOrientationLeftMirrored  = 6,    // vertical flip
    OITextureOrientationRightMirrored = 7     // vertical flip
} OITextureOrientation;


@class UIImage;
@class CALayer;

@interface OITexture : NSObject

@property (readonly, nonatomic) CGSize size;
@property (readwrite, nonatomic) OITextureOrientation orientation;
@property (readonly, nonatomic) const GLfloat *textureCoordinate;

+ (GLint)maximumTextureSizeForCurrentDevice;

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithCVBuffer:(CVBufferRef)CVBuffer;
- (instancetype)initWithCGImage:(CGImageRef)image;
- (instancetype)initWithCALayer:(CALayer *)caLayer;
- (instancetype)initWithPixelTables:(GLubyte *)tables tableSize:(int)tableSize count:(int)count;  // Uncompleted
- (instancetype)initWithSize:(CGSize)size orientation:(OITextureOrientation)orientation;
- (instancetype)initWithCVBuffer:(CVBufferRef)CVBuffer orientation:(OITextureOrientation)orientation;
- (instancetype)initWithCGImage:(CGImageRef)image orientation:(OITextureOrientation)orientation;

- (void)setupContentWithSize:(CGSize)size;
- (void)setupContentWithCVBuffer:(CVBufferRef)CVBuffer;
- (void)setupContentWithCGImage:(CGImageRef)image;
- (void)setupContentWithCALayer:(CALayer *)caLayer;

- (void)attachToCurrentFrameBufferObject;
- (void)bindToTextureIndex:(GLenum)textureIndex;

- (UIImage *)imageFromContentBuffer;

- (void)copyContentToBuffer:(GLubyte *)buffer;

@end
