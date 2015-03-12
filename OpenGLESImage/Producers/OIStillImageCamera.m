//
//  OIStillImageCamera.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-3-31.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIStillImageCamera.h"
#import <UIKit/UIKit.h>
#import "OIContext.h"
#import "OIConsumer.h"
#import "OITexture.h"

@interface OIStillImageCamera ()
{
    AVCaptureStillImageOutput *stillImageOutput_;
    OIStillImageCameraFlashMode flashMode_;
}

@end

@implementation OIStillImageCamera

@synthesize flashMode = flashMode_;

#pragma mark - Lifecycle

- (void)dealloc
{
    if (cameraSession_) {
        if (stillImageOutput_) {
            [cameraSession_ removeOutput:stillImageOutput_];
            [stillImageOutput_ release];
        }
    }
    
    [super dealloc];
}

- (id)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition sessionPreset:(NSString *)sessionPreset
{
    self = [super initWithCameraPosition:cameraPosition sessionPreset:sessionPreset];
    if (self) {
        [cameraSession_ beginConfiguration];
        
        stillImageOutput_ = [[AVCaptureStillImageOutput alloc] init];
        [stillImageOutput_ setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        if ([cameraSession_ canAddOutput:stillImageOutput_]) {
            [cameraSession_ addOutput:stillImageOutput_];
        }
        else
        {
            NSLog(@"Couldn't add still image output");
            [cameraSession_ commitConfiguration];
            [self release];
            return nil;
        }
        
        [cameraSession_ commitConfiguration];
        
        flashMode_ = OIStillImageCameraFlashModeOff;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setFlashMode:(OIStillImageCameraFlashMode)flashMode
{
    if (flashMode_ == flashMode) {
        return;
    }
    NSArray *inputs = cameraSession_.inputs;
	for (AVCaptureDeviceInput *input in inputs) {
		AVCaptureDevice *device = input.device;
		if ( [device hasMediaType:AVMediaTypeVideo] ) {
			AVCaptureDevicePosition position = device.position;
			if (position == AVCaptureDevicePositionBack) {
                if (flashMode == OIStillImageCameraFlashModeTorch) {
                    if ([device hasTorch]) {
                        if (device.torchMode != AVCaptureTorchModeOn) {
                            if ([device lockForConfiguration:nil]) {
                                if ([device isTorchModeSupported:AVCaptureTorchModeOn]) {
                                    [cameraSession_ beginConfiguration];
                                    [device setFlashMode:AVCaptureFlashModeOff];
                                    [device setTorchMode:AVCaptureTorchModeOn];
                                    [cameraSession_ commitConfiguration];
                                }
                                [device unlockForConfiguration];
                                break;
                            }
                        }
                    }
                }
				else {
                    if ([device hasFlash]) {
                        if (device.flashMode != (AVCaptureFlashMode)flashMode || flashMode_ == OIStillImageCameraFlashModeTorch) {
                            if ([device lockForConfiguration:nil]) {
                                if ([device isFlashModeSupported:(AVCaptureFlashMode)flashMode]) {
                                    [cameraSession_ beginConfiguration];
                                    [device setTorchMode:AVCaptureTorchModeOff];
                                    [device setFlashMode:(AVCaptureFlashMode)flashMode];
                                    [cameraSession_ commitConfiguration];
                                }
                                [device unlockForConfiguration];
                                break;
                            }
                        }
                    }
                }
			}
		}
	}
    flashMode_ = flashMode;
}

#pragma mark - Capturing Photo Methods

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

- (void)captureImageSampleBufferAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef, NSError *))handler
{
    if(stillImageOutput_.isCapturingStillImage){
        handler(NULL, [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorMaximumStillImageCaptureRequestsExceeded userInfo:nil]);
        return;
    }
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[stillImageOutput_ connections]];
    
//    if ([videoConnection isVideoOrientationSupported]){
//        [videoConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation]];
//	}
    
    [stillImageOutput_ captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        handler(imageSampleBuffer, error);
    }];
}

- (void)captureOriginalImageAsynchronouslyWithCompletionHandler:(void (^)(UIImage *, NSError *))handler
{
    [self captureImageSampleBufferAsynchronouslyWithCompletionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        if (imageSampleBuffer == NULL) {
            handler(nil, error);
            return;
        }
        
        UIImage *originalImage = [self imageFromSampleBuffer:imageSampleBuffer];
        handler(originalImage, error);
    }];
}

- (void)captureProcessedImageAsynchronouslyWithCompletionHandler:(void (^)(UIImage *, NSError *))handler
{
    dispatch_semaphore_wait(imageProcessingSemaphore_, DISPATCH_TIME_FOREVER);
    
    [self captureImageSampleBufferAsynchronouslyWithCompletionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        if (imageSampleBuffer == NULL) {
            dispatch_semaphore_signal(imageProcessingSemaphore_);
            handler(nil, error);
            return;
        }
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(imageSampleBuffer);
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        [OIContext performAsynchronouslyOnImageProcessingQueue:^{
            OITextureOrientation textureOrientation;
            switch (self.orientaion)
            {
                case OIVideoCaptorOrientationPortrait:
                    textureOrientation = OITextureOrientationUp;
                    break;
                case OIVideoCaptorOrientationPortraitUpsideDown:
                    textureOrientation = OITextureOrientationDown;
                    break;
                case OIVideoCaptorOrientationLandscapeLeft:
                    textureOrientation = OITextureOrientationLeft;
                    break;
                case OIVideoCaptorOrientationLandscapeRight:
                    textureOrientation = OITextureOrientationRight;
                    break;
                default:
                    textureOrientation = OITextureOrientationUp;
                    break;
            }
            
            OITexture *imageTexture = [[OITexture alloc] initWithCVBuffer:imageBuffer orientation:textureOrientation];
            if ([consumers_ count]) {
                for (id <OIConsumer> consumer in consumers_) {
                    [consumer setInputTexture:imageTexture];
                    [consumer renderRect:CGRectMake(0, 0, imageTexture.size.width, imageTexture.size.height) atTime:kCMTimeInvalid];
                }
            }
            
            UIImage *processedImage = nil;
            id <OIConsumer> consumer = [consumers_ objectAtIndex:0];
            if ([consumer respondsToSelector:@selector(imageFromCurrentFrame)]) {
                processedImage = [consumer imageFromCurrentFrame];
            }
            dispatch_semaphore_signal(imageProcessingSemaphore_);
            handler(processedImage, error);
        }];
    }];
}

- (void)captureOriginalImageAndProcessedImageAsynchronouslyWithCompletionHandler:(void (^)(UIImage *, UIImage *, NSError *))handler
{
    dispatch_semaphore_wait(imageProcessingSemaphore_, DISPATCH_TIME_FOREVER);
    
    [self captureOriginalImageAsynchronouslyWithCompletionHandler:^(UIImage *originalImage, NSError *error){
        if (!originalImage) {
            dispatch_semaphore_signal(imageProcessingSemaphore_);
            handler(originalImage, nil, error);
            return;
        }
        
        [OIContext performAsynchronouslyOnImageProcessingQueue:^{
            OITexture *imageTexture = [[OITexture alloc] initWithCGImage:originalImage.CGImage orientation:(OITextureOrientation)originalImage.imageOrientation];
            if ([consumers_ count]) {
                for (id <OIConsumer> consumer in consumers_) {
                    [consumer setInputTexture:imageTexture];
                    [consumer renderRect:CGRectMake(0, 0, imageTexture.size.width, imageTexture.size.height) atTime:kCMTimeInvalid];
                }
            }
            
            UIImage *processedImage = nil;
            id <OIConsumer> consumer = [consumers_ objectAtIndex:0];
            if ([consumer respondsToSelector:@selector(imageFromCurrentFrame)]) {
                processedImage = [consumer imageFromCurrentFrame];
            }
            
            dispatch_semaphore_signal(imageProcessingSemaphore_);
            
            handler(originalImage, processedImage, error);
        }];
    }];
}

#pragma mark -

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer

{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
    // Lock the base address of the pixel buffer
	
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
    // Get the number of bytes per row for the pixel buffer
	
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
	
    // Get the number of bytes per row for the pixel buffer
	
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	
    // Get the pixel buffer width and height
	
    size_t width = CVPixelBufferGetWidth(imageBuffer);
	
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    //    NSLog(@"width:%zu    height:%zu",width,height);
	
	
    // Create a device-dependent RGB color space
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // Create a bitmap graphics context with the sample buffer data
	
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
	//	CGContextRotateCTM(context, radians(45));
	
    // Create a Quartz image from the pixel data in the bitmap graphics context
	
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
	
    // Create an image object from the Quartz image
    
    UIImageOrientation imageOrientation;
	switch (self.orientaion)
    {
		case OIVideoCaptorOrientationPortrait:
			imageOrientation = UIImageOrientationRight;
			break;
		case OIVideoCaptorOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationLeft;
			break;
		case OIVideoCaptorOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationUp;
			break;
		case OIVideoCaptorOrientationLandscapeRight:
			imageOrientation = UIImageOrientationDown;
			break;
		default:
			imageOrientation = UIImageOrientationUp;
			break;
	}
    
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:imageOrientation];
	
    // Release the Quartz image
	
    CGImageRelease(quartzImage);
    
    // Free up the context and color space
    
    CGColorSpaceRelease(colorSpace);
	
    CGContextRelease(context);
    
    // Unlock the pixel buffer
	
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    return image;
}

@end
