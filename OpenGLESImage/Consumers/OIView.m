//
//  OIView.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-26.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIView.h>
#import "OIContext.h"
#import "OIFrameBufferObject.h"
#import "OITexture.h"
#import "OIProgram.h"

@implementation OIView

@synthesize enabled = enabled_;
@synthesize contentSize = contentSize_;
@synthesize contentMode = contentMode_;
@synthesize producers = producers_;

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

#pragma mark - Lifecycle

- (void)dealloc
{
    [producers_ release];
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        [displayFBO_ release];
        [displayProgram_ release];
        [inputTexture_ release];
    }];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self performCommonStepsForInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self performCommonStepsForInit];
        
        self.contentSize = displayFBO_.size;
    }
    return self;
}

- (void)performCommonStepsForInit
{
    enabled_ = YES;
    contentSize_ = CGSizeZero;
    contentMode_ = OIConsumerContentModeNormal;
    producers_ = [[NSMutableArray alloc] init];
    displayFBO_ = nil;
    self.opaque = YES;
    
    if ([super respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    else {
        [self setupDisplayFBO];
    }
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        [[OIContext sharedContext] setAsCurrentContext];
        
        inputTexture_ = nil;
        
        displayProgram_ = [[OIProgram alloc] initWithVertexShaderFilename:@"Default" fragmentShaderFilename:@"Default"];
        [displayProgram_ setTextureIndex:0 forTexture:@"sourceImage"];
    }];
}

#pragma mark - Properties' Setters & Getters

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    [self setupDisplayFBO];
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

- (void)setInputTexture:(id)texture
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
    
    [[OIContext sharedContext] setAsCurrentContext];
    [displayFBO_ setContentMode:(OIFrameBufferObjectContentMode)self.contentMode];
    [displayFBO_ bindToPipeline];
    [displayFBO_ clearBufferWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [inputTexture_ bindToTextureIndex:GL_TEXTURE0];
    [displayProgram_ use];
    [displayProgram_ setCoordinatePointer:[displayFBO_ verticesCoordinateForDrawableRect:rect] coordinateSize:2 forAttribute:@"position"];
    [displayProgram_ setCoordinatePointer:inputTexture_.textureCoordinate coordinateSize:2 forAttribute:@"textureCoordinate"];
    [displayProgram_ draw];
    [[OIContext sharedContext] presentRenderBufferToScreen];
}

#pragma mark -

- (void)setupDisplayFBO
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{

        if (displayFBO_) {
            [displayFBO_ release];
        }
        displayFBO_ = [[OIFrameBufferObject alloc] init];
        [displayFBO_ setupStorageForDisplayFromLayer:eaglLayer];
    }];
}

@end
