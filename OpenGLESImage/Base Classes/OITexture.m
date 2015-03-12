//
//  OITexture.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-6.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OITexture.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <UIKit/UIKit.h>
#import "OIContext.h"

@interface OITexture()
{
    CVOpenGLESTextureCacheRef textureCacheRef_;
    CVBufferRef contentBuffer_;
    CVOpenGLESTextureRef textureRef_;
    CGSize size_;
    OITextureOrientation orientation_;
    
    GLubyte *animatedImageData_;
}

@end

@implementation OITexture

@synthesize size = size_;
@synthesize orientation = orientation_;

#pragma mark - Class Methods

+ (GLint)maximumTextureSizeForCurrentDevice
{
    static dispatch_once_t pred;
    static GLint maxTextureSize = 0;
    
    dispatch_once(&pred, ^{
        [[OIContext sharedContext] setAsCurrentContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });
    
    return maxTextureSize;
}

#pragma mark - Lifecycle

- (void)dealloc
{
    if (textureCacheRef_ != NULL) {
        [self deleteTextureBuffer];
        CFRelease(textureCacheRef_);
        textureCacheRef_ = NULL;
        size_ = CGSizeZero;
    };
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        contentBuffer_ = NULL;
        textureRef_ = NULL;
        size_ = CGSizeZero;
        orientation_ = OITextureOrientationUp;
        animatedImageData_ = NULL;
#if defined(__IPHONE_6_0)
        CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &textureCacheRef_);
#else
        CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[EAGLContext currentContext], NULL, &textureCacheRef);
#endif
        
        if (error)
        {
            NSLog(@"OpenGLESImage Error at CVOpenGLESTextureCacheCreate %d", error);
            [self release];
            return nil;
        }
        
    }
    return self;
}

- (id)initWithSize:(CGSize)size
{
    self = [self initWithSize:size orientation:OITextureOrientationUp];
    return self;
}

- (id)initWithCVBuffer:(CVBufferRef)CVBuffer;
{
    self = [self initWithCVBuffer:CVBuffer orientation:OITextureOrientationUp];
    return self;
}

- (id)initWithCGImage:(CGImageRef)image
{
    self = [self initWithCGImage:image orientation:OITextureOrientationUp];
    return self;
}

- (id)initWithCALayer:(CALayer *)caLayer
{
    self = [self init];
    if (self) {
        [self setupContentWithCALayer:caLayer];
    }
    return self;
}

- (id)initWithPixelTables:(GLubyte *)tables tableSize:(int)tableSize count:(int)count
{
    self = [self init];
    if (self) {
        size_ = CGSizeMake(tableSize, count);
        CVReturn error = 0;
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (size_t)size_.width, (size_t)size_.height, kCVPixelFormatType_OneComponent32Float, tables, (size_t)size_.width, NULL, NULL, attrs, &contentBuffer_);
        if (error)
        {
            NSLog(@"Pixel tables size: %f, count:%f", size_.width, size_.height);
            NSLog(@"OpenGLESImage Error at CVPixelBufferCreateWithBytes %d", error);
        }
    }
    return self;
}

- (id)initWithSize:(CGSize)size orientation:(OITextureOrientation)orientation
{
    self = [self init];
    if (self) {
        [self setupContentWithSize:size];
        orientation_ = orientation;
    }
    return self;
}

- (id)initWithCVBuffer:(CVBufferRef)CVBuffer orientation:(OITextureOrientation)orientation;
{
    self = [self init];
    if (self) {
        [self setupContentWithCVBuffer:CVBuffer];
        orientation_ = orientation;
    }
    return self;
}

- (id)initWithCGImage:(CGImageRef)image orientation:(OITextureOrientation)orientation
{
    self = [self init];
    if (self) {
        [self setupContentWithCGImage:image];
        orientation_ = orientation;
    }
    return self;
}

#pragma mark - Setuping Content Buffer Methods

- (void)setupContentWithSize:(CGSize)size
{
    if (CGSizeEqualToSize(size_, size)) {
        return;
    }
    [self deleteTextureBuffer];
    size_ = [self scaleSizeBasingOnMaxTextureSize:size];
}

- (void)setupContentWithCVBuffer:(CVBufferRef)CVBuffer
{
//    if (contentBuffer_ == buffer) {
//        return;
//    }
    [self deleteTextureBuffer];
    if (CVPixelBufferGetWidth(CVBuffer) > [[self class] maximumTextureSizeForCurrentDevice] || CVPixelBufferGetHeight(CVBuffer) > [[self class] maximumTextureSizeForCurrentDevice]) {
        CGSize scaledSize = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(CVPixelBufferGetWidth(contentBuffer_), CVPixelBufferGetHeight(contentBuffer_))];
        
        size_ = scaledSize;
        contentBuffer_ = [self createResizedCVBufferWithBuffer:CVBuffer newSize:scaledSize];
    }
    else {
        contentBuffer_ = CVBuffer;
        CFRetain(contentBuffer_);
        size_ = CGSizeMake(CVPixelBufferGetWidth(contentBuffer_), CVPixelBufferGetHeight(contentBuffer_));
    }
}

- (void)setupContentWithCGImage:(CGImageRef)image
{
    [self deleteTextureBuffer];
    CGFloat widthOfImage = CGImageGetWidth(image);
    CGFloat heightOfImage = CGImageGetHeight(image);
    size_ = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(widthOfImage, heightOfImage)];
    
    GLubyte *imageData = (GLubyte *) calloc(1, (int)size_.width * (int)size_.height * 4);
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (size_t)size_.width, (size_t)size_.height, 8, (size_t)size_.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, size_.width, size_.height), image);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    CVReturn error = 0;
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (size_t)size_.width, (size_t)size_.height, kCVPixelFormatType_32BGRA, imageData, (size_t)size_.width * 4, contentBufferReleaseBytesCallback, NULL, attrs, &contentBuffer_);
    if (error)
    {
        NSLog(@"CGImage size: %f, %f", size_.width, size_.height);
        NSLog(@"OpenGLESImage Error at CVPixelBufferCreateWithBytes %d", error);
    }
}

- (void)setupContentWithAnimatedCGImage:(CGImageRef)image
{
    [self deleteTextureBuffer];
    
    CGFloat widthOfImage = CGImageGetWidth(image);
    CGFloat heightOfImage = CGImageGetHeight(image);
    size_ = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(widthOfImage, heightOfImage)];
    
//    if (animatedImageData_ != NULL) {
//        
//        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
//        
//        CGContextRef imageContext = CGBitmapContextCreate(animatedImageData_, (size_t)size_.width, (size_t)size_.height, 8, (size_t)size_.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//        //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
//        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, size_.width, size_.height), image);
//        CGContextRelease(imageContext);
//        CGColorSpaceRelease(genericRGBColorspace);
//        
//        CVReturn error = 0;
//        CFDictionaryRef empty; // empty value for attr value.
//        CFMutableDictionaryRef attrs;
//        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
//        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
//        
//        error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (size_t)size_.width, (size_t)size_.height, kCVPixelFormatType_32BGRA, animatedImageData_, (size_t)size_.width * 4, NULL, NULL, attrs, &contentBuffer_);
//        if (error)
//        {
//            NSLog(@"CGImage size: %f, %f", size_.width, size_.height);
//            NSLog(@"OpenGLESImage Error at CVPixelBufferCreateWithBytes %d", error);
//        }
//    }
//    else {
        animatedImageData_ = (GLubyte *) calloc(1, (int)size_.width * (int)size_.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef imageContext = CGBitmapContextCreate(animatedImageData_, (size_t)size_.width, (size_t)size_.height, 8, (size_t)size_.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, size_.width, size_.height), image);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
        
        CVReturn error = 0;
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (size_t)size_.width, (size_t)size_.height, kCVPixelFormatType_32BGRA, animatedImageData_, (size_t)size_.width * 4, NULL, NULL, attrs, &contentBuffer_);
        if (error)
        {
            NSLog(@"CGImage size: %f, %f", size_.width, size_.height);
            NSLog(@"OpenGLESImage Error at CVPixelBufferCreateWithBytes %d", error);
        }
//    }
}

- (void)setupContentWithCALayer:(CALayer *)caLayer
{
    [self deleteTextureBuffer];
    
    size_ = CGSizeMake(caLayer.contentsScale * caLayer.bounds.size.width, caLayer.contentsScale * caLayer.bounds.size.height);;
    
    GLubyte *imageData = (GLubyte *) calloc(1, (int)size_.width * (int)size_.height * 4);
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)size_.width, (int)size_.height, 8, (int)size_.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //    CGContextRotateCTM(imageContext, M_PI_2);
    CGContextTranslateCTM(imageContext, 0.0f, size_.height);
    CGContextScaleCTM(imageContext, caLayer.contentsScale, -caLayer.contentsScale);
    //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
    
    [caLayer renderInContext:imageContext];
    
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    CVReturn error = 0;
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (size_t)size_.width, (size_t)size_.height, kCVPixelFormatType_32BGRA, imageData, (size_t)size_.width * 4, contentBufferReleaseBytesCallback, NULL, attrs, &contentBuffer_);
    if (error)
    {
        NSLog(@"CALayer pixel size: %f, %f", size_.width, size_.height);
        NSLog(@"OpenGLESImage Error at OITexture setupContentWithCALayer, messege: CVReturn code %d", error);
    }
}

#pragma mark - Properties' Setter & Getter

- (CGSize)size
{
    if (orientation_ == OITextureOrientationLeft || orientation_ == OITextureOrientationLeftMirrored || orientation_ == OITextureOrientationRight || orientation_ == OITextureOrientationRightMirrored) {
        return CGSizeMake(size_.height, size_.width);
    }
    return size_;
}

- (const GLfloat *)textureCoordinate
{
    static const GLfloat orientationUpTextureCoordinate[8] = {
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0
    };
    
    static const GLfloat orientationDownTextureCoordinate[8] = {
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0
    };
    
    static const GLfloat orientationLeftTextureCoordinate[8] = {
        0.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0
    };
    
    static const GLfloat orientationRightTextureCoordinate[8] = {
        1.0, 0.0,
        1.0, 1.0,
        0.0, 0.0,
        0.0, 1.0
    };
    
    static const GLfloat orientationUpMirroredTextureCoordinate[8] = {
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0
    };
    
    static const GLfloat orientationDownMirroredTextureCoordinate[8] = {
        1.0, 0.0,
        0.0, 0.0,
        1.0, 1.0,
        0.0, 1.0
    };
    
    static const GLfloat orientationLeftMirroredTextureCoordinate[8] = {
        0.0, 0.0,
        0.0, 1.0,
        1.0, 0.0,
        1.0, 1.0
    };
    
    static const GLfloat orientationRightMirroredTextureCoordinate[8] = {
        1.0, 1.0,
        1.0, 0.0,
        0.0, 1.0,
        0.0, 0.0
    };
    
    switch (orientation_) {
        case OITextureOrientationUp:
            return orientationUpTextureCoordinate;
            
        case OITextureOrientationDown:
            return orientationDownTextureCoordinate;
            
        case OITextureOrientationLeft:
            return orientationLeftTextureCoordinate;
            
        case OITextureOrientationRight:
            return orientationRightTextureCoordinate;
            
        case OITextureOrientationUpMirrored:
            return orientationUpMirroredTextureCoordinate;
            
        case OITextureOrientationDownMirrored:
            return orientationDownMirroredTextureCoordinate;
            
        case OITextureOrientationLeftMirrored:
            return orientationLeftMirroredTextureCoordinate;
            
        case OITextureOrientationRightMirrored:
            return orientationRightMirroredTextureCoordinate;
            
        default:
            return orientationUpTextureCoordinate;
    }
}

#pragma mark - Texture Manager

- (void)generateTexture
{
    // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
    
    CVReturn error;
    if (!contentBuffer_) {
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        error = CVPixelBufferCreate(kCFAllocatorDefault, (int)size_.width, (int)size_.height, kCVPixelFormatType_32BGRA, attrs, &contentBuffer_);
        if (error)
        {
            NSLog(@"FBO size: %f, %f", size_.width, size_.height);
            NSLog(@"OpenGLESImage Error at CVPixelBufferCreate %d", error);
        }
        
        
        
        CFRelease(attrs);
        CFRelease(empty);

    }
    error = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                        textureCacheRef_, contentBuffer_,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)size_.width,
                                                        (int)size_.height,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &textureRef_);
    if (error)
    {
        NSLog(@"OpenGLESImage Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(textureRef_), CVOpenGLESTextureGetName(textureRef_));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)attachToCurrentFrameBufferObject
{
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(textureRef_), 0);
}

- (void)bindToTextureIndex:(GLenum)textureIndex
{
    glActiveTexture(textureIndex);
    if (textureRef_ == NULL) {
        [self generateTexture];
    }
    glBindTexture(CVOpenGLESTextureGetTarget(textureRef_), CVOpenGLESTextureGetName(textureRef_));
}

- (void)deleteTextureBuffer
{
    CVOpenGLESTextureCacheFlush(textureCacheRef_, 0);
    if (contentBuffer_) {
        CFRelease(contentBuffer_);
        contentBuffer_ = NULL;
    }
    
    if (textureRef_) {
        CFRelease(textureRef_);
        textureRef_ = NULL;
    }
}

- (UIImage *)imageFromContentBuffer
{
    NSUInteger contentBufferBytesPerRow = CVPixelBufferGetBytesPerRow(contentBuffer_);
    NSUInteger bytesForImage = contentBufferBytesPerRow * (int)size_.height * 4;
    
    glFinish();
    CFRetain(contentBuffer_); // I need to retain the pixel buffer here and release in the data source callback to prevent its bytes from being prematurely deallocated during a photo write operation
    CVPixelBufferLockBaseAddress(contentBuffer_, 0);
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(contentBuffer_, (GLubyte *)CVPixelBufferGetBaseAddress(contentBuffer_), bytesForImage, dataProviderUnlockCallback);
    
    
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImageFromBytes = CGImageCreate((int)size_.width, (int)size_.height, 8, 32, contentBufferBytesPerRow, defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    
    int orientation = orientation_;
    UIImage *image = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:orientation];
    CGImageRelease(cgImageFromBytes);
    
    return image;
}

#pragma mark - CVPixelBuffer Release Bytes Callback

void contentBufferReleaseBytesCallback( void *releaseRefCon, const void *baseAddress )
{
    if (baseAddress) {
        free((void *)baseAddress);
    }
}

void dataProviderUnlockCallback (void *info, const void *data, size_t size)
{
    CVBufferRef contentBuffer = (CVBufferRef)info;
    
    CVPixelBufferUnlockBaseAddress(contentBuffer, 0);
    CFRelease(contentBuffer);
}

#pragma mark - 

- (CGSize)scaleSizeBasingOnMaxTextureSize:(CGSize)size
{
    GLint maxTextureSize = [OITexture maximumTextureSizeForCurrentDevice];
    if ( (size.width < maxTextureSize) && (size.height < maxTextureSize) )
    {
        return size;
    }
    
    CGSize scaledSize;
    if (size.width > size.height)
    {
        scaledSize.width = (CGFloat)maxTextureSize;
        scaledSize.height = ((CGFloat)maxTextureSize / size.width) * size.height;
    }
    else
    {
        scaledSize.height = (CGFloat)maxTextureSize;
        scaledSize.width = ((CGFloat)maxTextureSize / size.height) * size.width;
    }
    
    return scaledSize;
}

- (CVBufferRef)createResizedCVBufferWithBuffer:(CVBufferRef)buffer newSize:(CGSize)newSize
{
    CGSize originalSize = CGSizeMake(CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer));
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    GLubyte *sourceImageBytes =  CVPixelBufferGetBaseAddress(buffer);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBytes, CVPixelBufferGetBytesPerRow(buffer) * originalSize.height, NULL);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate((int)originalSize.width, (int)originalSize.height, 8, 32, CVPixelBufferGetBytesPerRow(buffer), genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    GLubyte *imageData = (GLubyte *) calloc(1, (int)newSize.width * (int)newSize.height * 4);
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)newSize.width, (int)newSize.height, 8, (int)newSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, newSize.width, newSize.height), cgImageFromBytes);
    CGImageRelease(cgImageFromBytes);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    CGDataProviderRelease(dataProvider);
    
    CVPixelBufferRef resizedBuffer = NULL;
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, newSize.width, newSize.height, kCVPixelFormatType_32BGRA, imageData, newSize.width * 4, contentBufferReleaseBytesCallback, NULL, NULL, &resizedBuffer);
    return resizedBuffer;
}

@end
