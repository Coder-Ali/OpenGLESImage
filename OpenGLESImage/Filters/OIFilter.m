//
//  OIFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-15.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIFilter.h"
#import "OIContext.h"
#import "OIFrameBufferObject.h"
#import "OIProgram.h"
#import "OITexture.h"

@interface OIFilter ()

@end

@implementation OIFilter

@synthesize producers = producers_;
@synthesize contentSize = contentSize_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [producers_ release];
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [filterFBO_ release];
        [filterProgram_ release];
        [inputTexture_ release];
    }];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        producers_ = [[NSMutableArray alloc] init];
        contentSize_ = CGSizeZero;
        [OIContext performSynchronouslyOnImageProcessingQueue:^{
            [[OIContext sharedContext] setAsCurrentContext];
            filterFBO_ = [[OIFrameBufferObject alloc] init];
            filterProgram_ = [[OIProgram alloc] initWithVertexShaderFilename:[[self class] vertexShaderFilename] fragmentShaderFilename:[[self class] fragmentShaderFilename]];
            [filterProgram_ use];
            [filterProgram_ setTextureIndex:0 forTexture:@"sourceImage"];
            inputTexture_ = nil;
        }];
    }
    return self;
}

- (id)initWithContentSize:(CGSize)contentSize
{
    self = [self init];
    if (self) {
        self.contentSize = contentSize;
    }
    return self;
}

#pragma mark - OIConsumer Methods

- (void)setProducer:(OIProducer *)producer
{
    if (![self.producers containsObject:producer]) {
        [producers_ addObject:producer];
    }
}

- (void)removeProducer:(OIProducer *)producer
{
    if ([self.producers containsObject:producer]) {
        [producers_ removeObject:producer];
    }
}

- (void)setInputTexture:(OITexture *)texture
{
    if (inputTexture_ != texture) {
        [inputTexture_ release];
        inputTexture_ = texture;
        [inputTexture_ retain];
    }
}

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
    [filterFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [inputTexture_ bindToTextureIndex:GL_TEXTURE0];
    
    [filterProgram_ use];
    [self setProgramUniform];
    [filterProgram_ setCoordinatePointer:[filterFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [filterProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [filterProgram_ draw];
    
    [outputTexture_ release];
    outputTexture_ = filterFBO_.texture;
    [outputTexture_ retain];

    [self produceAtTime:time];
}

- (UIImage *)imageFromCurrentFrame
{
    if ([consumers_ count]) {
        id <OIConsumer> consumer = [consumers_ lastObject];
        if ([consumer respondsToSelector:@selector(imageFromCurrentFrame)]) {
            return [consumer imageFromCurrentFrame];
        }
    }
    return [outputTexture_ imageFromContentBuffer];
}

#pragma mark - Common Motheds In This Class & Its Subclasses



#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"Default";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"Default";
    return fName;
}

- (void)setProgramUniform
{
    
}

@end
