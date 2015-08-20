//
//  OIMultiInputsFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-4.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIMultiInputsFilter.h"

@interface OIMultiInputsFilter ()
{
    unsigned int inputCount_;
    NSMutableArray *inputTextures_;
}

@end

@implementation OIMultiInputsFilter

@synthesize inputCount = inputCount_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [inputTextures_ release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    
    if (self) {
        self.inputCount = 2;
        
        inputTextures_ = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithContentSize:(CGSize)contentSize inputCount:(unsigned int)inputCount
{
    self = [super initWithContentSize:contentSize];
    
    if (self) {
        self.inputCount = inputCount;
    }
    
    return self;
}

#pragma mark - Properties' Setter & Getter

- (void)setInputCount:(unsigned int)inputCount
{
    if (inputCount < 1 || inputCount > 8) {
        return;
    }
    
    inputCount_ = inputCount;
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [filterProgram_ use];
        [filterProgram_ setInt:inputCount_ forUniform:@"inputCount"];
        int sourceImages[8] = {0, 1, 2, 3, 4, 5, 6, 7};
        [filterProgram_ setIntArray:sourceImages withArrayCount:8 forUniform:@"sourceImages"];
    }];
    
//    for (int i = 0; i < inputCount_; ++i) {
//        [OIContext performSynchronouslyOnImageProcessingQueue:^{
//            [[OIContext sharedContext] setAsCurrentContext];
//            [filterProgram_ use];
//            [filterProgram_ setInt:inputCount_ forUniform:@"inputCount"];
//            [filterProgram_ setTextureIndex:i forTexture:[NSString stringWithFormat:@"sourceImage%d", i]];
//        }];
//    }
}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"MultiInputs";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"MultiInputs";
    return fName;
}

#pragma mark - OIConsumer Methods

- (void)setInputTexture:(OITexture *)texture
{
    [inputTextures_ addObject:texture];
}

- (void)renderRect:(CGRect)rect atTime:(CMTime)time
{
    if (!self.isEnabled || inputTextures_.count < self.inputCount) {
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
    [filterFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    for (int i = 0; i < self.inputCount; ++i) {
        OITexture *inputTexture = [inputTextures_ objectAtIndex:i];
        [inputTexture bindToTextureIndex:GL_TEXTURE0 + i];
    }
    
    [filterProgram_ use];
    [self setProgramUniform];
    [filterProgram_ setCoordinatePointer:[filterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    
    for (int i = 0; i < self.inputCount; ++i) {
        OITexture *inputTexture = [inputTextures_ objectAtIndex:i];
        [filterProgram_ setCoordinatePointer:inputTexture.textureCoordinate coordinateSize:2 forAttribute:[NSString stringWithFormat:@"texture%dCoordinate", i]];
    }
    
    [filterProgram_ draw];
    
    [inputTextures_ removeAllObjects];
    
    [outputTexture_ release];
    outputTexture_ = filterFBO_.texture;
    [outputTexture_ retain];
    
    [self produceAtTime:time];
}

@end
