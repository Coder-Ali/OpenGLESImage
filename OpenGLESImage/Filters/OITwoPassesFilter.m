//
//  OITwoPassesFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-4-16.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OITwoPassesFilter.h"

@implementation OITwoPassesFilter

#pragma mark - Lifecycle

- (void)dealloc
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [secondFilterFBO_ release];
        [secondFilterProgram_ release];
    }];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [[OIContext sharedContext] setAsCurrentContext];
            secondFilterFBO_ = [[OIFrameBufferObject alloc] init];
            secondFilterProgram_ = [[OIProgram alloc] initWithVertexShaderFilename:[[self class] secondVertexShaderFilename] fragmentShaderFilename:[[self class] secondFragmentShaderFilename]];
            [secondFilterProgram_ use];
            [secondFilterProgram_ setTextureIndex:0 forTexture:@"sourceImage"];
        }];
    }
    return self;
}

#pragma mark - OIConsumer Methods

- (void)renderRect:(CGRect)rect atTime:(CMTime)time
{
    if (!inputTexture_ || !enabled_) {
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
    
    [filterProgram_ use];
    [self setProgramUniform];
    [filterProgram_ setCoordinatePointer:[filterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [filterProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [filterProgram_ draw];
    
    if (!CGSizeEqualToSize(secondFilterFBO_.size, contentSize_)) {
        [secondFilterFBO_ setupStorageForOffscreenWithSize:contentSize_];
    }
    [secondFilterFBO_ bindToPipeline];
    [secondFilterFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [filterFBO_.texture bindToTextureIndex:GL_TEXTURE0];
    [secondFilterProgram_ use];
    [self setSecondProgramUniform];
    [secondFilterProgram_ setCoordinatePointer:[secondFilterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [secondFilterProgram_ setCoordinatePointer:filterFBO_.texture.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [secondFilterProgram_ draw];
    
    [outputTexture_ release];
    outputTexture_ = secondFilterFBO_.texture;
    [outputTexture_ retain];
    
    [self produceAtTime:time];
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)secondVertexShaderFilename
{
    return [[self class] vertexShaderFilename];
}

+ (NSString *)secondFragmentShaderFilename
{
    return [[self class] fragmentShaderFilename];
}

- (void)setSecondProgramUniform
{
    
}

@end
