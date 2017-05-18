//
//  OITwoInputsFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-4-16.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OITwoInputsFilter.h"

@implementation OITwoInputsFilter

#pragma mark - Lifecycle

- (void)dealloc
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [secondInputTexture_ release];
    }];
    
    [super dealloc];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [[OIContext sharedContext] setAsCurrentContext];
            [filterProgram_ use];
            [filterProgram_ setTextureIndex:1 forTexture:@"secondSourceImage"];
        }];
        secondInputTexture_ = nil;
    }
    return self;
}

#pragma mark - OIConsumer Methods

- (void)setInputTexture:(OITexture *)texture
{
    if (!inputTexture_) {
        [inputTexture_ release];
        inputTexture_ = texture;
        [inputTexture_ retain];
    }
    else if (!secondInputTexture_) {
        [secondInputTexture_ release];
        secondInputTexture_ = texture;
        [secondInputTexture_ retain];
    }
}

- (void)renderRect:(CGRect)rect atTime:(CMTime)time
{
    if (!inputTexture_ || !secondInputTexture_ || !enabled_) {
        return;
    }
    
    if (CGSizeEqualToSize(contentSize_, CGSizeZero)) {
        self.contentSize = inputTexture_.size;
    }
    if (CGRectEqualToRect(self.outputFrame, CGRectZero)) {
        self.outputFrame = CGRectMake(0, 0, contentSize_.width, contentSize_.height);
    }
    
    if (!CGSizeEqualToSize(filterFBO_.size, contentSize_)) {
        [filterFBO_ setupStorageForOffscreenWithSize:contentSize_];
    }
    [filterFBO_ bindToPipeline];
    [filterFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [inputTexture_ bindToTextureIndex:GL_TEXTURE0];
    [secondInputTexture_ bindToTextureIndex:GL_TEXTURE1];
    
    [filterProgram_ use];
    [filterProgram_ setTextureIndex:0 forTexture:@"sourceImage"];
    [filterProgram_ setTextureIndex:1 forTexture:@"secondSourceImage"];
    [self setProgramUniform];
    [filterProgram_ setCoordinatePointer:[filterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [filterProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [filterProgram_ setCoordinatePointer:secondInputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"secondTextureCoordinate"];
    [filterProgram_ draw];
    
    [outputTexture_ release];
    outputTexture_ = filterFBO_.texture;
    [outputTexture_ retain];
    
    [self produceAtTime:time];
    
    [inputTexture_ release];
    inputTexture_ = nil;
    [secondInputTexture_ release];
    secondInputTexture_ = nil;
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"TwoInputs";
    return vName;
}

@end
