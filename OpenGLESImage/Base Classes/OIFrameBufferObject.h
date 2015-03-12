//
//  OIFrameBufferObject.h
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-6.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OITexture;
@class CAEAGLLayer;

typedef enum _OIFrameBufferObjectType {
    OIFrameBufferObjectTypeUnknow            = 0,
    OIFrameBufferObjectTypeOffscreen         = 1,
    OIFrameBufferObjectTypeForDisplay        = 2,
    OIFrameBufferObjectTypeSpecifiedCVBuffer = 3
} OIFrameBufferObjectType;

@interface OIFrameBufferObject : NSObject

@property (readonly, nonatomic) CGSize size;
@property (readonly, nonatomic) OITexture *texture;

- (id)init;

- (void)setupStorageForOffscreenWithSize:(CGSize)fboSize;
- (void)setupStorageForDisplayFromLayer:(CAEAGLLayer *)layer;
- (void)setupStorageWithSpecifiedCVBuffer:(CVBufferRef)CVBuffer;

- (void)bindToPipeline;
- (void)clearBufferWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

- (const GLfloat *)verticesCoordinateForDrawableRect:(CGRect)rect;

@end
