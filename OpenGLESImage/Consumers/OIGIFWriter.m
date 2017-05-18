//
//  OIGIFWriter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 2017/2/20.
//  Copyright © 2017年 Kwan Yiuleung. All rights reserved.
//

#import "OIGIFWriter.h"
#import "OIContext.h"
#import "OITexture.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@implementation OIGIFWriter

@synthesize enabled = enabled_;

- (void)dealloc
{
    [OIContext performSynchronouslyOnImageProcessingQueue:^{
        if (inputTexture_) {
            [inputTexture_ release];
        }
    }];
}

- (instancetype)initWithContentSize:(CGSize)contentSize outputURL:(NSURL *)outputURL
{
    self = [super init];
    
    if (self) {
        CFURLRef url = CFURLCreateWithFileSystemPath (
                                                      kCFAllocatorDefault,
                                                      (CFStringRef)outputURL.absoluteString,
                                                      kCFURLPOSIXPathStyle,
                                                      false);
        
        //通过一个url返回图像目标
        destination_ = CGImageDestinationCreateWithURL(url, kUTTypeGIF, 60, NULL);
        
        //设置gif的信息,播放间隔时间,基本数据,和delay时间
        frameProperties_ = [NSDictionary
                                         dictionaryWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0/30.0], (NSString *)kCGImagePropertyGIFDelayTime, nil]
                                         forKey:(NSString *)kCGImagePropertyGIFDictionary];
        
        frameTime_ = kCMTimeZero;
        recordedFrameCount_ = 0;
    }
    
    return self;
}

#pragma mark - OIConsumer Methods

- (void)setProducer:(OIProducer *)producer
{
    
}

- (void)removeProducer:(OIProducer *)producer
{
    
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
    if (!inputTexture_ || !self.isEnabled || recordedFrameCount_ >=60) {
        return;
    }
    
    if (CMTimeCompare(frameTime_, kCMTimeZero) == 0) { //0代表相等
        frameTime_ = time;
    }
    else {
        CMTime delta = CMTimeSubtract(time, frameTime_);
        if (CMTimeGetSeconds(delta) < 1.0/30.0) {
            return;
        }
    }
    
    frameTime_ = time;
    
    UIImage *frame = [inputTexture_ imageFromContentBuffer];
    
    if (frame) {
        CGImageDestinationAddImage(destination_, frame.CGImage, (__bridge CFDictionaryRef)frameProperties_);
        recordedFrameCount_++;
    }
    
    if (recordedFrameCount_ >= 60) {
        //设置gif信息
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:60];
        
        [dict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCGImagePropertyGIFHasGlobalColorMap];
        
        [dict setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
        
        [dict setObject:[NSNumber numberWithInt:8] forKey:(NSString*)kCGImagePropertyDepth];
        
        [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
        
        NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:dict
                                                                  forKey:(NSString *)kCGImagePropertyGIFDictionary];

        CGImageDestinationSetProperties(destination_, (__bridge CFDictionaryRef)gifProperties);
        CGImageDestinationFinalize(destination_);
        CFRelease(destination_);
    }
}

@end
