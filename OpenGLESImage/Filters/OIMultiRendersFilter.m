//
//  OIMultiRendersFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-4.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIMultiRendersFilter.h"

@implementation OIMultiRendersFilter

@synthesize renderCount = renderCount_;

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.renderCount = 2;
    }
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setRenderCount:(int)renderCount
{
    renderCount_ = renderCount < 0 ? 0 : renderCount;
    
    currentRenderCount_ = renderCount_;
}

#pragma mark - OIConsumer Methods

- (void)renderRect:(CGRect)rect atTime:(CMTime)time
{
    if (!inputTexture_ || !self.isEnabled) {
        return;
    }
    
    if (CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        self.contentSize = inputTexture_.size;
    }
    if (CGRectEqualToRect(self.outputFrame, CGRectZero)) {
        self.outputFrame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    }
    
    if (!CGSizeEqualToSize(filterFBO_.size, contentSize_)) {
        [filterFBO_ setupStorageForOffscreenWithSize:contentSize_];
    }
    
    [filterFBO_ bindToPipeline];
    
    if (currentRenderCount_ == self.renderCount) {
        [filterFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    }
    
    [inputTexture_ bindToTextureIndex:GL_TEXTURE0];
    
    [filterProgram_ use];
    [self setProgramUniform];
    [filterProgram_ setCoordinatePointer:[filterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [filterProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [filterProgram_ draw];
    
    if (currentRenderCount_ > 1) {
        --currentRenderCount_;
        return;
    }
    
    [outputTexture_ release];
    outputTexture_ = filterFBO_.texture;
    [outputTexture_ retain];
    
    [self produceAtTime:time];
    
    currentRenderCount_ = self.renderCount;
}

@end
