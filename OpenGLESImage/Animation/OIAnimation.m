//
//  OIAnimation.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-11-25.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIAnimation.h>
#import <OpenGLESImage/OIAnimationConfiguration.h>
#import <OpenGLESImage/OIAnimationConfigurationImageDescription.h>
#import <OpenGLESImage/OIAnimationConfigurationTextDescription.h>
#import <OpenGLESImage/OIView.h>
#import <OpenGLESImage/OIImage.h>
#import <OpenGLESImage/OIString.h>
#import <OpenGLESImage/OIAlphaFilter.h>
#import <OpenGLESImage/OIBoxBlurFilter.h>
#import <OpenGLESImage/OIToneFilter.h>
#import <OpenGLESImage/OIRotationFilter.h>
#import <OpenGLESImage/OIBlendFilter.h>
#import <OpenGLESImage/OIOverlayBlendFilter.h>
#import <OpenGLESImage/OIScreenBlendFilter.h>
#import <OpenGLESImage/OIMultiplyBlendFilter.h>
#import <OpenGLESImage/OIAlphaPreMultiplyBlendFilter.h>
#import <OpenGLESImage/OIMultiRendersFilter.h>
#import <OpenGLESImage/OIMultiImagesSplicingFilter.h>
#include <stdlib.h>

/**/
#define BackgroundMusicFileDirectory @"Background Music"

/*Summary Configurations Keys*/
#define kAnimationTotalTimeKey @"time"
#define kAnimationBackgroundMusicKey @"music"
#define kAnimationBackgroundMusicRepeatKey @"music_repeat"

/*General*/
#define kAnimationParticipantIDIndex 0
#define kAnimationParticipantTypeIndex 1
#define kAnimationParticipantStartTimeIndex 2
#define kAnimationParticipantEndTimeIndex 3
#define kAnimationParticipantLayerIndex 4
#define kAnimationParticipantWidthIndex 5
#define kAnimationParticipantHeightIndex 6


/*Text*/
#define kAnimationTextFontNameIndex 7
#define kAnimationTextFontSizeIndex 8
#define kAnimationTextColorIndex 9
#define kAnimationTextIndex 10
#define kAnimationTextAlignmentIndex 11

/*Moving*/
#define kAnimationMovingStartTimeIndex 12
#define kAnimationMovingEndTimeIndex 13
#define kAnimationMovingOriginalXIndex 14
#define kAnimationMovingOriginalYIndex 15
#define kAnimationMovingTargetXIndex 16
#define kAnimationMovingTargetYIndex 17
#define kAnimationMovingEaseModeIndex 18

/*Scale*/
#define kAnimationScaleStartTimeIndex 19
#define kAnimationScaleEndTimeIndex 20
#define kAnimationScaleOriginalValueIndex 13 + 8
#define kAnimationScaleTargetValueIndex 14 + 8
#define kAnimationScaleEaseModeIndex 15 + 8

/*Transparency*/
#define kAnimationTransparencyStartTimeIndex 16 + 8
#define kAnimationTransparencyEndTimeIndex 17 + 8
#define kAnimationTransparencyOriginalValueIndex 18 + 8
#define kAnimationTransparencyTargetValueIndex 19 + 8
#define kAnimationTransparencyEaseModeIndex 20 + 8

/*Blur*/
#define kAnimationBlurStartTimeIndex 21 + 8
#define kAnimationBlurEndTimeIndex 22 + 8
#define kAnimationBlurOriginalBlurSizeIndex 23 + 8
#define kAnimationBlurTargetBlurSizeIndex 24 + 8
#define kAnimationBlurEaseModeIndex 25 + 8

/*Tone*/
#define kAnimationToneStartTimeIndex 26 + 8
#define kAnimationToneEndTimeIndex 27 + 8
#define kAnimationToneRGBIndex 28 + 8
#define kAnimationToneOriginalPercentageIndex 29 + 8
#define kAnimationToneTargetPercentageIndex 30 + 8
#define kAnimationToneEaseModeIndex 31 + 8

/*Rotation*/
#define kAnimationRotationStartTimeIndex 32 + 8
#define kAnimationRotationEndTimeIndex 33 + 8
#define kAnimationRotationOriginalDegreesIndex 34 + 8
#define kAnimationRotationTargetDegreesIndex 35 + 8
#define kAnimationRotationEaseModeIndex 36 + 8

/*Participant Type*/
#define kAnimationParticipantTypeImage 0
#define kAnimationParticipantTypeText 1
#define kAnimationParticipantTypeTextBackground 2

/*Background Music Repeat Type*/
#define kAnimationBackgroundMusicRepeatTypePlayOnce @"0"
#define kAnimationBackgroundMusicRepeatTypeInfinity @"1"

@interface OIAnimation ()
{
    OIAnimationConfiguration *configuration_;
    
    CADisplayLink *animationDisplayLink_;
    
    double totalTime_;
    float standardWidth_;
    float standardHeight_;
    double currentTime_;
    NSMutableDictionary *participants_;
    NSMutableArray *currentImageParticipants_;
    NSMutableArray *currentStringParticipants_;
    NSArray *configurations_;
    
    OIMultiRendersFilter *textLayerEmptyFilter_;
    OIFilter *layer0EmptyFilter_;
    OIFilter *layer1EmptyFilter_;
    
    OIAlphaFilter *layer0AlphaFilter_;
    OIAlphaFilter *layer1AlphaFilter_;
    
    OIBoxBlurFilter *layer0BlurFilter_;
    OIBoxBlurFilter *layer1BlurFilter_;
    
    OIToneFilter *layer0ToneFilter_;
    OIToneFilter *layer1ToneFilter_;
    
    OIRotationFilter *layer0RotationFilter_;
    OIRotationFilter *layer1RotationFilter_;
    
    OIAlphaPreMultiplyBlendFilter *topLayerBlendFilter_;
    OIAlphaPreMultiplyBlendFilter *textLayerImageLayerBlendFilter_;
    OIAlphaPreMultiplyBlendFilter *textLayerBlendFilter_;
    OIBlendFilter *layer01BlendFilter_;
    OIOverlayBlendFilter *overlayBlendFilter_;
    OIScreenBlendFilter *screenBlendFilter_;
    OIMultiplyBlendFilter *multiplyBlendFilter_;
    
    OIMultiImagesSplicingFilter *maskFilter_;
    
    OIAudioVideoWriter *recorder_;
    OIImage *coverImage_;
    OIView *targetView_;
    
    NSURL *backgroundMusicURL_;
    AVAudioPlayer *audioPlayer_;
    AVAssetReader *audioAssetReader_;
    AVAssetReaderTrackOutput *audioAssetReaderOutput_;
}

@end

@implementation OIAnimation

@synthesize configuration = configuration_;
@synthesize recorder = recorder_;
@synthesize coverImage = coverImage_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [self invalidateDisplayLink];
    
    self.configuration = nil;
    
    [participants_ release];
    
    [currentImageParticipants_ release];
    [currentStringParticipants_ release];
    
    [configurations_ release];
    
    self.recorder = nil;
    
    self.coverImage = nil;
    
    [textLayerEmptyFilter_ release];
    [layer0EmptyFilter_ release];
    [layer1EmptyFilter_ release];
    
    [layer0AlphaFilter_ release];;
    [layer0BlurFilter_ release];
    [layer0ToneFilter_ release];
    [layer0RotationFilter_ release];
    
    [layer1AlphaFilter_ release];
    [layer1BlurFilter_ release];
    [layer1ToneFilter_ release];
    [layer1RotationFilter_ release];
    
    [topLayerBlendFilter_ release];
    [textLayerBlendFilter_ release];
    [textLayerImageLayerBlendFilter_ release];
    [layer01BlendFilter_ release];
    [overlayBlendFilter_ release];
    [screenBlendFilter_ release];
    [multiplyBlendFilter_ release];
    
    if (backgroundMusicURL_) {
        [backgroundMusicURL_ release];
    }
    
    [super dealloc];
}

- (id)initWithConfigurations:(NSArray *)configurations
{
    self = [super init];
    
    if (self) {
        self.recorder = nil;
        self.coverImage = nil;
        
        NSDictionary *sumConfs = [configurations objectAtIndex:0];
        NSNumber *totalTime = [sumConfs objectForKey:kAnimationTotalTimeKey];
        NSNumber *standardWidth = [sumConfs objectForKey:@"width"];
        NSNumber *standardHeight = [sumConfs objectForKey:@"heigh"];
        totalTime_ = [totalTime intValue] / 1000.0;
        standardWidth_ = [standardWidth floatValue];
        standardHeight_ = [standardHeight floatValue];
        
        NSString *backgroundMusic = [sumConfs objectForKey:kAnimationBackgroundMusicKey];
        NSString *musicPath = [[self directoryPathWithDirectoryName:BackgroundMusicFileDirectory] stringByAppendingPathComponent:backgroundMusic];
//        NSLog(@"musicPath: %@", musicPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:musicPath]) {
//            NSLog(@"music in document");
            backgroundMusicURL_ = [[NSURL alloc] initFileURLWithPath:musicPath];
        }
        else {
            musicPath = [[NSBundle mainBundle] pathForResource:backgroundMusic ofType:nil];
//            NSLog(@"musicPath: %@", musicPath);
            if ([[NSFileManager defaultManager] fileExistsAtPath:musicPath]) {
                NSLog(@"music in app");
                backgroundMusicURL_ = [[NSURL alloc] initFileURLWithPath:musicPath];
            }
            else {
//                NSLog(@"no music");
                backgroundMusicURL_ = nil;
            }
        }
        
        currentTime_ = 0.0;
        
        participants_ = [[NSMutableDictionary alloc] init];
        
        currentImageParticipants_ = [[NSMutableArray alloc] init];
        currentStringParticipants_ =  [[NSMutableArray alloc] init];
        
        configurations_ = [[NSArray alloc] initWithArray:[configurations objectAtIndex:1]];
        
        for (NSArray *configuration in configurations_) {
            NSString *participantID = [configuration objectAtIndex:kAnimationParticipantIDIndex];
            int participantType = [[configuration objectAtIndex:kAnimationParticipantTypeIndex] intValue];
            
            if (![participants_ objectForKey:participantID]) {
                OIProducer *participant = nil;
                
                if (participantType == kAnimationParticipantTypeImage) {
                    NSLog(@"image name: %@", participantID);
                    participant = [[OIImage alloc] initWithUIImage:[UIImage imageNamed:participantID]];
                }
                else if (participantType == kAnimationParticipantTypeText) {
                    NSString *text = [configuration objectAtIndex:kAnimationTextIndex];
                    NSLog(@"text: %@", text);
                    NSString *fontName = [configuration objectAtIndex:kAnimationTextFontNameIndex];
                    float fontSize = [[configuration objectAtIndex:kAnimationTextFontSizeIndex] floatValue];
                    double x = [[configuration objectAtIndex:kAnimationMovingOriginalXIndex] doubleValue];
                    double y = [[configuration objectAtIndex:kAnimationMovingOriginalYIndex] doubleValue];
                    float width = [[configuration objectAtIndex:kAnimationParticipantWidthIndex] floatValue];
                    float height = [[configuration objectAtIndex:kAnimationParticipantHeightIndex] floatValue];
                    NSString *colorString = [configuration objectAtIndex:kAnimationTextColorIndex];
                    int textAlignment = [[configuration objectAtIndex:kAnimationTextAlignmentIndex] intValue];
                    NSLog(@"text rect:%f, %f, %f, %f", x, y, width, height);
                    NSLog(@"fontSize: %f", fontSize);
                    OIString *stringParticipant = [[OIString alloc] initWithNSString:text fontName:fontName fontSize:fontSize color:[self colorfromString:colorString] size:CGSizeMake(width, height)];
                    
                    stringParticipant.outputFrame = CGRectMake(x, y, width, height);
                    stringParticipant.textAlignment = textAlignment;
                    
                    participant = stringParticipant;
                }
                else if (participantType == kAnimationParticipantTypeTextBackground) {
                    NSString *imagesPath = [self directoryPathWithDirectoryName:participantID];
//                    NSLog(@"imagesPath: %@", imagesPath);
                    OIDebugLog(@"imagesPath: %@", imagesPath);
                    NSError * error = nil;
                    
                    NSArray *imageNameArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imagesPath error:&error];
                    
                    if (imageNameArray && imageNameArray.count > 0) {
                        NSMutableArray *images = [[NSMutableArray alloc] init];
                        
                        UIImage *image = nil;
                        
                        for (int i = 0; i < [imageNameArray count]; i++) {
                            image = [[UIImage alloc] initWithContentsOfFile:[imagesPath stringByAppendingPathComponent:[imageNameArray objectAtIndex:i]]];
                            if (image) {
                                [images addObject:image];
                                [image release];
                            }
                            else {
                                continue;
                            }
                        }
                        
                        UIImage *backgroundImage = [UIImage animatedImageWithImages:images duration:1.5];
                        
                        participant = [[OIImage alloc] initWithUIImage:backgroundImage];
                    }
                }
                
                [participants_ setObject:participant forKey:participantID];
                
                [participant release];
            }
        }
//        NSLog(@"configurations_ : %@", configurations_);
//        NSLog(@"participants_ : %@", participants_);
        
        textLayerEmptyFilter_ = [[OIMultiRendersFilter alloc] init];
        layer0EmptyFilter_ = [[OIFilter alloc] init];
        layer1EmptyFilter_ = [[OIFilter alloc] init];
        
        layer0AlphaFilter_ = [[OIAlphaFilter alloc] init];
        layer0BlurFilter_ = [[OIBoxBlurFilter alloc] init];
        layer0ToneFilter_ = [[OIToneFilter alloc] init];
        layer0RotationFilter_ = [[OIRotationFilter alloc] init];
        
        layer1AlphaFilter_ = [[OIAlphaFilter alloc] init];
        layer1BlurFilter_ = [[OIBoxBlurFilter alloc] init];
        layer1ToneFilter_ = [[OIToneFilter alloc] init];
        layer1RotationFilter_ = [[OIRotationFilter alloc] init];
        
        topLayerBlendFilter_ = [[OIAlphaPreMultiplyBlendFilter alloc] init];
//        topLayerBlendFilter_.outputFrame = CGRectMake(0, 0, 480, 480);
        textLayerImageLayerBlendFilter_ = [[OIAlphaPreMultiplyBlendFilter alloc] init];
        textLayerBlendFilter_ = [[OIAlphaPreMultiplyBlendFilter alloc] init];
        layer01BlendFilter_ = [[OIBlendFilter alloc] init];
        overlayBlendFilter_ = [[OIOverlayBlendFilter alloc] init];
        screenBlendFilter_ = [[OIScreenBlendFilter alloc] init];
        multiplyBlendFilter_ = [[OIMultiplyBlendFilter alloc] init];
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)playAtView:(OIView *)view
{
    if (backgroundMusicURL_) {
        if (self.recorder) {
            self.recorder.shouldWriteWithAudio = YES;
            self.recorder.delegate = self;
        }
        
        audioPlayer_ = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL_ error:nil];
        [audioPlayer_ setVolume:1.0f];
        audioPlayer_.numberOfLoops = 0;
        
        NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:backgroundMusicURL_ options:inputOptions];
        [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            if (!tracksStatus == AVKeyValueStatusLoaded)
            {
                return;
            }
        }];
        NSError *error = nil;
        audioAssetReader_ = [[AVAssetReader alloc] initWithAsset:inputAsset error:&error];
        if (error) {
            NSLog(@"audioAssetReader_ can not be alloc , message: %@", error);
        }
        
        NSArray *audioTracks = [inputAsset tracksWithMediaType:AVMediaTypeAudio];
        if (!audioTracks || audioTracks.count == 0) {
            NSLog(@"Target AVAsset is not a audio asset");
            return;
        }
        
        NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
        audioAssetReaderOutput_ = [[AVAssetReaderTrackOutput alloc] initWithTrack:[audioTracks objectAtIndex:0] outputSettings:decompressionAudioSettings];
        if ([audioAssetReader_ canAddOutput:audioAssetReaderOutput_]) {
            [audioAssetReader_ addOutput:audioAssetReaderOutput_];
        }
        else {
            NSLog(@"Audio can not be read.");
        }
        
        [audioPlayer_ prepareToPlay];
        [audioPlayer_ play];
    }
    
    currentTime_ = 0.0;
    
    targetView_ = view;
    
    textLayerEmptyFilter_.contentSize = targetView_.contentSize;
    layer0EmptyFilter_.contentSize = targetView_.contentSize;
    layer1EmptyFilter_.contentSize = targetView_.contentSize;
    
    layer0AlphaFilter_.contentSize = targetView_.contentSize;
    layer0BlurFilter_.contentSize = targetView_.contentSize;
    layer0ToneFilter_.contentSize = targetView_.contentSize;
    layer0RotationFilter_.contentSize = targetView_.contentSize;
    
    layer1AlphaFilter_.contentSize = targetView_.contentSize;
    layer1BlurFilter_.contentSize = targetView_.contentSize;
    layer1ToneFilter_.contentSize = targetView_.contentSize;
    layer1RotationFilter_.contentSize = targetView_.contentSize;
    
    topLayerBlendFilter_.contentSize = targetView_.contentSize;
    textLayerBlendFilter_.contentSize = targetView_.contentSize;
    textLayerImageLayerBlendFilter_.contentSize = targetView_.contentSize;
    layer01BlendFilter_.contentSize = targetView_.contentSize;
    overlayBlendFilter_.contentSize = targetView_.contentSize;
    screenBlendFilter_.contentSize = targetView_.contentSize;
    multiplyBlendFilter_.contentSize = targetView_.contentSize;
    
    if (self.coverImage) {
        [self.coverImage addConsumer:topLayerBlendFilter_];
        [topLayerBlendFilter_ addConsumer:targetView_];
        [topLayerBlendFilter_ addConsumer:self.recorder];
    }
    
    animationDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderNextFrame:)];
    animationDisplayLink_.frameInterval = 2;
    [animationDisplayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - Private Methods

- (NSString *)directoryPathWithDirectoryName:(NSString *)name
{
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:name];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!(fileExists && isDirectory)) {
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        OIErrorLog(!success, self.class, @"- directoryPathWithDirectoryName:", @"Cannot create target directory", nil);
    }
    
    return path;
}

- (void)renderNextFrameTest:(CADisplayLink *)displayLink
{
//    currentTime_ += displayLink.duration * displayLink.frameInterval;
//    
//    if (currentTime_ < self.configuration.totalTime) {
//        OIImage *stringBackground = nil;
//        
//        OIFilter *imageSubLayer1LastFilter = nil;
//        
//        OIFilter *imageLayerFilter = nil;
//        OIFilter *textLayerFilter = nil;
//        
//        NSArray *currentFrameDescriptions = [self.configuration configurationDescriptionsInOrderAtTime:currentTime_];
//        
//        for (OIAnimationConfigurationDescription *description in currentFrameDescriptions) {
//            if ([description isMemberOfClass:[OIAnimationConfigurationImageDescription class]]) {
//                OIAnimationConfigurationImageDescription *imageDescription = description;
//                
//                OIImage *image = [participants_ objectForKey:imageDescription.itemIdentifier];
//                
//                float currentX = 0.0;
//                float currentY = 0.0;
//                float currentScale = 1.0;
//                
//                if (imageDescription.movingEndTime == 0.0) {
//                    currentX = 0.0;
//                    currentY = 0.0;
//                }
//                else {
//                    float timeScale = (currentTime_ - imageDescription.movingStartTime) / (imageDescription.movingEndTime - imageDescription.movingStartTime);
//                    
//                    float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.movingEaseMode];
//                    
//                    currentX = imageDescription.originalPoint.x + (imageDescription.targetPoint.x - imageDescription.originalPoint.x) * animationFactor;
//                    currentY = imageDescription.originalPoint.y + (imageDescription.targetPoint.y - imageDescription.originalPoint.y) * animationFactor;
//                }
//                
//                if (imageDescription.scaleEndTime == 0.0) {
//                    currentScale = 1.0;
//                }
//                else {
//                    float timeScale = (currentTime_ - imageDescription.scaleStartTime) / (imageDescription.scaleEndTime - imageDescription.scaleStartTime);
//                    
//                    float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.scaleEaseMode];
//                    
//                    currentScale = imageDescription.originalScale + (imageDescription.targetScale - imageDescription.originalScale) * animationFactor;
//                    //                        NSLog(@"currentScale = %f", currentScale);
//                }
//                
//                image.outputFrame = CGRectMake(currentX, currentY, imageDescription.width * currentScale, imageDescription.height * currentScale);
//                //                    NSLog(@"outputFrame: %f, %f, %f, %f", currentX, currentY, participantWidth * currentScale, participantHeight * currentScale);
//                if (currentImageParticipants_.count == 0) {
//                    [image addConsumer:layer0EmptyFilter_];
//                    
//                    imageLayerFilter = layer0EmptyFilter_;
//                    
//                    if (imageDescription.blurEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.blurStartTime) / (imageDescription.blurEndTime - imageDescription.blurStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.blurEaseMode];
//                        
//                        layer0BlurFilter_.blurSize = imageDescription.originalBlurSize + (imageDescription.targetBlurSize - imageDescription.originalBlurSize) * animationFactor;
//                        
//                        [layer0EmptyFilter_ addConsumer:layer0BlurFilter_];
//                        
//                        imageLayerFilter = layer0BlurFilter_;
//                    }
//                    
//                    if (imageDescription.toneEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.toneStartTime) / (imageDescription.toneEndTime - imageDescription.toneStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.toneEaseMode];
//                        
//                        layer0ToneFilter_.red = imageDescription.toneRed;
//                        layer0ToneFilter_.green = imageDescription.toneGreen;
//                        layer0ToneFilter_.blue = imageDescription.toneBlue;
//                        layer0ToneFilter_.percentage = imageDescription.originalTonePercentage + (imageDescription.targetTonePercentage - imageDescription.originalTonePercentage) * animationFactor;
//                        
//                        [imageLayerFilter addConsumer:layer0ToneFilter_];
//                        
//                        imageLayerFilter = layer0ToneFilter_;
//                    }
//                    
//                    if (imageDescription.transparencyEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.transparencyStartTime) / (imageDescription.transparencyEndTime - imageDescription.transparencyStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationTransparencyEaseModeIndex] intValue]];
//                        
//                        layer0AlphaFilter_.alpha = imageDescription.originalAlpha + (imageDescription.targetAlpha - imageDescription.originalAlpha) * animationFactor;
//                        
//                        [imageLayerFilter addConsumer:layer0AlphaFilter_];
//                        
//                        imageLayerFilter = layer0AlphaFilter_;
//                    }
//                    
////                    if (imageDescription.rotationEndTime != 0.0) {
////                        
////                        float timeScale = (currentTime_ - imageDescription.rotationStartTime) / (imageDescription.rotationEndTime - imageDescription.rotationStartTime);
////                        
////                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.rotationEaseMode];
////                        
////                        layer0RotationFilter_.degrees = imageDescription.originalDegrees + (imageDescription.targetDegrees - imageDescription.originalDegrees) * animationFactor;
////                        
////                        [imageLayerFilter addConsumer:layer0RotationFilter_];
////                        
////                        imageLayerFilter = layer0RotationFilter_;
////                    }
//                    
//                    [currentImageParticipants_ addObject:image];
//                }
//                else {
//                    [image addConsumer:layer1EmptyFilter_];
//                    
//                    imageSubLayer1LastFilter = layer1EmptyFilter_;
//                    
//                    if (imageDescription.blurEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.blurStartTime) / (imageDescription.blurEndTime - imageDescription.blurStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.blurEaseMode];
//                        
//                        layer1BlurFilter_.blurSize = imageDescription.originalBlurSize + (imageDescription.targetBlurSize - imageDescription.originalBlurSize) * animationFactor;
//                        
//                        [imageSubLayer1LastFilter addConsumer:layer1BlurFilter_];
//                        
//                        imageSubLayer1LastFilter = layer1BlurFilter_;
//                    }
//                    
//                    if (imageDescription.toneEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.toneStartTime) / (imageDescription.toneEndTime - imageDescription.toneStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.toneEaseMode];
//                        
//                        layer0ToneFilter_.red = imageDescription.toneRed;
//                        layer0ToneFilter_.green = imageDescription.toneGreen;
//                        layer0ToneFilter_.blue = imageDescription.toneBlue;
//                        layer0ToneFilter_.percentage = imageDescription.originalTonePercentage + (imageDescription.targetTonePercentage - imageDescription.originalTonePercentage) * animationFactor;
//                        
//                        [imageLayerFilter addConsumer:layer0ToneFilter_];
//                        
//                        imageLayerFilter = layer0ToneFilter_;
//                    }
//                    
//                    if (imageDescription.transparencyEndTime != 0.0) {
//                        
//                        float timeScale = (currentTime_ - imageDescription.transparencyStartTime) / (imageDescription.transparencyEndTime - imageDescription.transparencyStartTime);
//                        
//                        float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationTransparencyEaseModeIndex] intValue]];
//                        
//                        layer0AlphaFilter_.alpha = imageDescription.originalAlpha + (imageDescription.targetAlpha - imageDescription.originalAlpha) * animationFactor;
//                        
//                        [imageLayerFilter addConsumer:layer0AlphaFilter_];
//                        
//                        imageLayerFilter = layer0AlphaFilter_;
//                    }
//                    
//                    //                    if (imageDescription.rotationEndTime != 0.0) {
//                    //
//                    //                        float timeScale = (currentTime_ - imageDescription.rotationStartTime) / (imageDescription.rotationEndTime - imageDescription.rotationStartTime);
//                    //
//                    //                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:imageDescription.rotationEaseMode];
//                    //
//                    //                        layer0RotationFilter_.degrees = imageDescription.originalDegrees + (imageDescription.targetDegrees - imageDescription.originalDegrees) * animationFactor;
//                    //
//                    //                        [imageLayerFilter addConsumer:layer0RotationFilter_];
//                    //
//                    //                        imageLayerFilter = layer0RotationFilter_;
//                    //                    }
//                }
//                
//                [currentImageParticipants_ addObject:image];
//            }
//        }
//        
//        for (NSArray *configuration in configurations_) {
//            double startTime = [[configuration objectAtIndex:kAnimationParticipantStartTimeIndex] intValue] / 1000.0;
//            double endTime = [[configuration objectAtIndex:kAnimationParticipantEndTimeIndex] intValue] / 1000.0;
//            
//            if (currentTime_ >= startTime && currentTime_ <= endTime) {
//                int participantType = [[configuration objectAtIndex:kAnimationParticipantTypeIndex] intValue];
//                
//                if (participantType == kAnimationParticipantTypeImage) {
//                    OIImage *participant = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
//                    participant.tag = [[configuration objectAtIndex:kAnimationParticipantLayerIndex] intValue];
//                    
//                    
//                    
//                }
//                else if (participantType == kAnimationParticipantTypeText) {
//                    OIString *stringParticipant = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
//                    
//                    if ([[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] != 0) {
//                        double alphaStartTime = [[configuration objectAtIndex:kAnimationTransparencyStartTimeIndex] intValue] / 1000.0;
//                        double alphaEndTime = [[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] / 1000.0;
//                        
//                        double timeScale = (currentTime_ - alphaStartTime) / (alphaEndTime - alphaStartTime);
//                        
//                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationBlurEaseModeIndex] intValue]];
//                        
//                        float originalAlpha = [[configuration objectAtIndex:kAnimationTransparencyOriginalValueIndex] intValue] / 100.0;
//                        float targetAlpha = [[configuration objectAtIndex:kAnimationTransparencyTargetValueIndex] intValue] / 100.0;
//                        
//                        stringParticipant.alpha = originalAlpha + (targetAlpha - originalAlpha) * animationFactor;
//                        
//                    }
//                    //                    NSLog(@"stringParticipant.alpha = %f", stringParticipant.alpha);
//                    [stringParticipant addConsumer:textLayerEmptyFilter_];
//                    [currentStringParticipants_ addObject:stringParticipant];
//                }
//                else if (participantType == kAnimationParticipantTypeTextBackground) {
//                    stringBackground = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
//                    UICollectionView
//                }
//            }
//        }
//        
//        if (currentStringParticipants_.count > 0) {
//            textLayerEmptyFilter_.renderCount = (unsigned int)currentStringParticipants_.count;
//            if (stringBackground) {
//                [textLayerEmptyFilter_ addConsumer:textLayerImageLayerBlendFilter_];
//                [stringBackground addConsumer:textLayerImageLayerBlendFilter_];
//                [textLayerImageLayerBlendFilter_ addConsumer:textLayerBlendFilter_];
//                
//                textLayerFilter = textLayerBlendFilter_;
//            }
//            else {
//                [textLayerEmptyFilter_ addConsumer:textLayerImageLayerBlendFilter_];
//                
//                textLayerFilter = textLayerImageLayerBlendFilter_;
//            }
//        }
//        else if (stringBackground) {
//            [stringBackground addConsumer:textLayerBlendFilter_];
//            
//            textLayerFilter = textLayerBlendFilter_;
//        }
//        
//        if (imageSubLayer1LastFilter) {
//            [imageLayerFilter addConsumer:layer01BlendFilter_];
//            [imageSubLayer1LastFilter addConsumer:layer01BlendFilter_];
//            
//            imageLayerFilter = layer01BlendFilter_;
//        }
//        
//        if (textLayerFilter) {
//            [imageLayerFilter addConsumer:textLayerFilter];
//            if (self.coverImage) {
//                [textLayerFilter addConsumer:topLayerBlendFilter_];
//            }
//            else {
//                [textLayerFilter addConsumer:targetView_];
//                [textLayerFilter addConsumer:self.recorder];
//            }
//        }
//        else if (self.coverImage) {
//            [imageLayerFilter addConsumer:topLayerBlendFilter_];
//        }
//        else {
//            [imageLayerFilter addConsumer:targetView_];
//            [imageLayerFilter addConsumer:self.recorder];
//        }
//        
//        if (currentStringParticipants_.count > 0) {
//            for (OIString *stringParticipant in currentStringParticipants_) {
//                [stringParticipant produceAtTime:kCMTimeInvalid];
//            }
//        }
//        
//        if (stringBackground) {
//            [stringBackground produceAtTime:kCMTimeInvalid];
//        }
//        
//        if (self.coverImage) {
//            [self.coverImage produceAtTime:kCMTimeInvalid];
//        }
//        
//        for (OIProducer *participant in currentImageParticipants_) {
//            //            NSLog(@"render layer:%d", participant.tag);
//            [participant produceAtTime:kCMTimeInvalid];
//        }
//        
//        [OIContext performSynchronouslyOnImageProcessingQueue:^{
//            
//            if (stringBackground) {
//                [stringBackground removeAllConsumers];
//            }
//            
//            [self resetAllParticipant];
//        }];
//    }
//    else {
//        [self invalidateDisplayLink];
//        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidFinish:)]) {
//            [self.delegate animationDidFinish:self];
//        }
//        
//        if (self.recorder) {
//            [self.recorder finishWriting];
//        }
//    }
}


- (void)renderNextFrame:(CADisplayLink *)displayLink
{
    currentTime_ += displayLink.duration * displayLink.frameInterval;
    
    if (currentTime_ < totalTime_) {
        OIImage *stringBackground = nil;
        
        OIFilter *imageSubLayer1LastFilter = nil;
        
        OIFilter *imageLayerFilter = nil;
        OIFilter *textLayerFilter = nil;
        
        for (NSArray *configuration in configurations_) {
            double startTime = [[configuration objectAtIndex:kAnimationParticipantStartTimeIndex] intValue] / 1000.0;
            double endTime = [[configuration objectAtIndex:kAnimationParticipantEndTimeIndex] intValue] / 1000.0;
            
            if (currentTime_ >= startTime && currentTime_ <= endTime) {
                int participantType = [[configuration objectAtIndex:kAnimationParticipantTypeIndex] intValue];
                
                if (participantType == kAnimationParticipantTypeImage) {
                    OIImage *participant = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
                    participant.tag = [[configuration objectAtIndex:kAnimationParticipantLayerIndex] intValue];
                    
                    double currentX = 0.0;
                    double currentY = 0.0;
                    double currentScale = 1.0;
                    
                    if ([[configuration objectAtIndex:kAnimationMovingEndTimeIndex] intValue] == 0) {
                        currentX = 0.0;
                        currentY = 0.0;
                    }
                    else {
                        double startTime = [[configuration objectAtIndex:kAnimationMovingStartTimeIndex] intValue] / 1000.0;
                        double endTime = [[configuration objectAtIndex:kAnimationMovingEndTimeIndex] intValue] / 1000.0;
                        
                        double timeScale = (currentTime_ - startTime) / (endTime - startTime);
                        
                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationMovingEaseModeIndex] intValue]];
                        
                        double originalX = [[configuration objectAtIndex:kAnimationMovingOriginalXIndex] doubleValue];
                        double originalY = [[configuration objectAtIndex:kAnimationMovingOriginalYIndex] doubleValue];
                        
                        double targetX = [[configuration objectAtIndex:kAnimationMovingTargetXIndex] doubleValue];
                        double targetY = [[configuration objectAtIndex:kAnimationMovingTargetYIndex] doubleValue];
                        
                        currentX = originalX + (targetX - originalX) * animationFactor;
                        currentY = originalY + (targetY - originalY) * animationFactor;
                    }
                    
                    if ([[configuration objectAtIndex:kAnimationScaleEndTimeIndex] intValue] == 0) {
                        currentScale = 1.0;
                    }
                    else {
                        double startTime = [[configuration objectAtIndex:kAnimationScaleStartTimeIndex] intValue] / 1000.0;
                        double endTime = [[configuration objectAtIndex:kAnimationScaleEndTimeIndex] intValue] / 1000.0;
                        
                        double timeScale = (currentTime_ - startTime) / (endTime - startTime);
                        
                        double originalScale = [[configuration objectAtIndex:kAnimationScaleOriginalValueIndex] doubleValue] / 100.0;
                        
                        double targetScale = [[configuration objectAtIndex:kAnimationScaleTargetValueIndex] doubleValue] / 100.0;
                        
                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationMovingEaseModeIndex] intValue]];
                        
                        currentScale = originalScale + (targetScale - originalScale) * animationFactor;
//                        NSLog(@"currentScale = %f", currentScale);
                    }
                    
                    int participantWidth = [[configuration objectAtIndex:kAnimationParticipantWidthIndex] intValue];
                    int participantHeight = [[configuration objectAtIndex:kAnimationParticipantHeightIndex] intValue];
                    
                    participant.outputFrame = CGRectMake(currentX, currentY, participantWidth * currentScale, participantHeight * currentScale);
//                    NSLog(@"outputFrame: %f, %f, %f, %f", currentX, currentY, participantWidth * currentScale, participantHeight * currentScale);
                    if (currentImageParticipants_.count == 0) {
                        [participant addConsumer:layer0EmptyFilter_];
                        
                        imageLayerFilter = layer0EmptyFilter_;
                        
                        if ([[configuration objectAtIndex:kAnimationBlurEndTimeIndex] intValue] != 0) {
                            double blurStartTime = [[configuration objectAtIndex:kAnimationBlurStartTimeIndex] intValue] / 1000.0;
                            double blurEndTime = [[configuration objectAtIndex:kAnimationBlurEndTimeIndex] intValue] / 1000.0;
                            
                            double timeScale = (currentTime_ - blurStartTime) / (blurEndTime - blurStartTime);
                            
                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationBlurEaseModeIndex] intValue]];
                            
                            float originalBlurSize = [[configuration objectAtIndex:kAnimationBlurOriginalBlurSizeIndex] intValue] / 10.0;
                            float targetBlurSize = [[configuration objectAtIndex:kAnimationBlurTargetBlurSizeIndex] intValue] / 10.0;
                            
                            layer0BlurFilter_.blurSize = originalBlurSize + (targetBlurSize - originalBlurSize) * animationFactor;
                            
                            [layer0EmptyFilter_ addConsumer:layer0BlurFilter_];
                            
                            imageLayerFilter = layer0BlurFilter_;
                        }
                        
                        if ([[configuration objectAtIndex:kAnimationToneEndTimeIndex] intValue] != 0) {
                            float startTime = [[configuration objectAtIndex:kAnimationToneStartTimeIndex] intValue] / 1000.0;
                            float endTime = [[configuration objectAtIndex:kAnimationToneEndTimeIndex] intValue] / 1000.0;
                            
                            float timeScale = (currentTime_ - startTime) / (endTime - startTime);
                            
                            float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationToneEaseModeIndex] intValue]];
                            
                            NSString *colorString = [configuration objectAtIndex:kAnimationToneRGBIndex];
                            
                            int colorValue = (int)[self intFromString:colorString];
                            
                            int redValue = colorValue & 0xff0000;
                            redValue = redValue >> 16;
                            int greenValue = colorValue & 0x00ff00;
                            greenValue = greenValue >> 8;
                            int blueValue = colorValue & 0x0000ff;
                            
                            float originalPercentage = [[configuration objectAtIndex:kAnimationToneOriginalPercentageIndex] intValue] / 100.0;
                            float targetPercentage = [[configuration objectAtIndex:kAnimationToneTargetPercentageIndex] intValue] / 100.0;
                            
                            layer0ToneFilter_.red = redValue / 255.0;
                            layer0ToneFilter_.green = greenValue / 255.0;
                            layer0ToneFilter_.blue = blueValue / 255.0;
                            layer0ToneFilter_.percentage = originalPercentage + (targetPercentage - originalPercentage) * animationFactor;
                            
                            [imageLayerFilter addConsumer:layer0ToneFilter_];
                            
                            imageLayerFilter = layer0ToneFilter_;
                        }
                        
                        if ([[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] != 0) {
                            double startTime = [[configuration objectAtIndex:kAnimationTransparencyStartTimeIndex] intValue] / 1000.0;
                            double endTime = [[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] / 1000.0;
                            
                            double timeScale = (currentTime_ - startTime) / (endTime - startTime);
                            
                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationTransparencyEaseModeIndex] intValue]];
                            
                            double originalAlpha = [[configuration objectAtIndex:kAnimationTransparencyOriginalValueIndex] intValue] / 100.0;
                            double targetAlpha = [[configuration objectAtIndex:kAnimationTransparencyTargetValueIndex] intValue] / 100.0;
                            
                            layer0AlphaFilter_.alpha = originalAlpha + (targetAlpha - originalAlpha) * animationFactor;
                            
                            [imageLayerFilter addConsumer:layer0AlphaFilter_];
                            
                            imageLayerFilter = layer0AlphaFilter_;
                        }
                        
//                        if ([[configuration objectAtIndex:kAnimationRotationEndTimeIndex] intValue] != 0) {
//                            double startTime = [[configuration objectAtIndex:kAnimationRotationStartTimeIndex] intValue] / 1000.0;
//                            double endTime = [[configuration objectAtIndex:kAnimationRotationEndTimeIndex] intValue] / 1000.0;
//                            
//                            double timeScale = (currentTime_ - startTime) / (endTime - startTime);
//                            
//                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationRotationEaseModeIndex] intValue]];
//                            
//                            float originalDegrees = [[configuration objectAtIndex:kAnimationRotationOriginalDegreesIndex] intValue];
//                            float targetDegrees = [[configuration objectAtIndex:kAnimationRotationTargetDegreesIndex] intValue];
//                            
//                            layer0RotationFilter_.degrees = originalDegrees + (targetDegrees - originalDegrees) * animationFactor;
//                            
//                            [imageLayerFilter addConsumer:layer0RotationFilter_];
//                            
//                            imageLayerFilter = layer0RotationFilter_;
//                        }
                        
                        [currentImageParticipants_ addObject:participant];
                    }
                    else {
                        [participant addConsumer:layer1EmptyFilter_];
                        
                        imageSubLayer1LastFilter = layer1EmptyFilter_;
                        
                        if ([[configuration objectAtIndex:kAnimationBlurEndTimeIndex] intValue] != 0) {
                            double blurStartTime = [[configuration objectAtIndex:kAnimationBlurStartTimeIndex] intValue] / 1000.0;
                            double blurEndTime = [[configuration objectAtIndex:kAnimationBlurEndTimeIndex] intValue] / 1000.0;
                            
                            double timeScale = (currentTime_ - blurStartTime) / (blurEndTime - blurStartTime);
                            
                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationBlurEaseModeIndex] intValue]];
                            
                            float originalBlurSize = [[configuration objectAtIndex:kAnimationBlurOriginalBlurSizeIndex] intValue] / 10.0;
                            float targetBlurSize = [[configuration objectAtIndex:kAnimationBlurTargetBlurSizeIndex] intValue] / 10.0;
                            
                            layer1BlurFilter_.blurSize = originalBlurSize + (targetBlurSize - originalBlurSize) * animationFactor;
                            
                            [layer1EmptyFilter_ addConsumer:layer1BlurFilter_];
                            
                            imageSubLayer1LastFilter = layer1BlurFilter_;
                        }
                        
                        if ([[configuration objectAtIndex:kAnimationToneEndTimeIndex] intValue] != 0) {
                            float startTime = [[configuration objectAtIndex:kAnimationToneStartTimeIndex] intValue] / 1000.0;
                            float endTime = [[configuration objectAtIndex:kAnimationToneEndTimeIndex] intValue] / 1000.0;
                            
                            float timeScale = (currentTime_ - startTime) / (endTime - startTime);
                            
                            float animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationToneEaseModeIndex] intValue]];
                            
                            NSString *colorString = [configuration objectAtIndex:kAnimationToneRGBIndex];
                            
                            int colorValue = (int)[self intFromString:colorString];
                            
                            int redValue = colorValue & 0xff0000;
                            redValue = redValue >> 16;
                            int greenValue = colorValue & 0x00ff00;
                            greenValue = greenValue >> 8;
                            int blueValue = colorValue & 0x0000ff;
                            
                            float originalPercentage = [[configuration objectAtIndex:kAnimationToneOriginalPercentageIndex] intValue] / 100.0;
                            float targetPercentage = [[configuration objectAtIndex:kAnimationToneTargetPercentageIndex] intValue] / 100.0;
                            
                            layer1ToneFilter_.red = redValue / 255.0;
                            layer1ToneFilter_.green = greenValue / 255.0;
                            layer1ToneFilter_.blue = blueValue / 255.0;
                            layer1ToneFilter_.percentage = originalPercentage + (targetPercentage - originalPercentage) * animationFactor;
                            
                            [imageSubLayer1LastFilter addConsumer:layer1ToneFilter_];
                            
                            imageSubLayer1LastFilter = layer1ToneFilter_;
                        }
                        
                        if ([[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] != 0) {
                            double startTime = [[configuration objectAtIndex:kAnimationTransparencyStartTimeIndex] intValue] / 1000.0;
                            double endTime = [[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] / 1000.0;
                            
                            double timeScale = (currentTime_ - startTime) / (endTime - startTime);
                            
                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationTransparencyEaseModeIndex] intValue]];
                            
                            double originalAlpha = [[configuration objectAtIndex:kAnimationTransparencyOriginalValueIndex] intValue] / 100.0;
                            double targetAlpha = [[configuration objectAtIndex:kAnimationTransparencyTargetValueIndex] intValue] / 100.0;
                            
                            layer1AlphaFilter_.alpha = originalAlpha + (targetAlpha - originalAlpha) * animationFactor;
                            
                            [imageSubLayer1LastFilter addConsumer:layer1AlphaFilter_];
                            
                            imageSubLayer1LastFilter = layer1AlphaFilter_;
                        }
                        
//                        if ([[configuration objectAtIndex:kAnimationRotationEndTimeIndex] intValue] != 0) {
//                            double startTime = [[configuration objectAtIndex:kAnimationRotationStartTimeIndex] intValue] / 1000.0;
//                            double endTime = [[configuration objectAtIndex:kAnimationRotationEndTimeIndex] intValue] / 1000.0;
//                            
//                            double timeScale = (currentTime_ - startTime) / (endTime - startTime);
//                            
//                            double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationRotationEaseModeIndex] intValue]];
//                            
//                            float originalDegrees = [[configuration objectAtIndex:kAnimationRotationOriginalDegreesIndex] intValue];
//                            float targetDegrees = [[configuration objectAtIndex:kAnimationRotationTargetDegreesIndex] intValue];
//                            
//                            layer1RotationFilter_.degrees = originalDegrees + (targetDegrees - originalDegrees) * animationFactor;
//                            
//                            [imageSubLayer1LastFilter addConsumer:layer1RotationFilter_];
//                            
//                            imageSubLayer1LastFilter = layer1RotationFilter_;
//                        }
                        
                        OIProducer *lastParticipant = [currentImageParticipants_ objectAtIndex:0];
                        
                        if (lastParticipant.tag > participant.tag) {
                            [currentImageParticipants_ insertObject:participant atIndex:0];
                        }
                        else {
                            [currentImageParticipants_ addObject:participant];
                        }
                    }
                }
                else if (participantType == kAnimationParticipantTypeText) {
                    OIString *stringParticipant = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
                    
                    if ([[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] != 0) {
                        double alphaStartTime = [[configuration objectAtIndex:kAnimationTransparencyStartTimeIndex] intValue] / 1000.0;
                        double alphaEndTime = [[configuration objectAtIndex:kAnimationTransparencyEndTimeIndex] intValue] / 1000.0;
                        
                        double timeScale = (currentTime_ - alphaStartTime) / (alphaEndTime - alphaStartTime);
                        
                        double animationFactor = [self yValueByXValue:timeScale onCurveWithEasingMode:[[configuration objectAtIndex:kAnimationBlurEaseModeIndex] intValue]];
                        
                        float originalAlpha = [[configuration objectAtIndex:kAnimationTransparencyOriginalValueIndex] intValue] / 100.0;
                        float targetAlpha = [[configuration objectAtIndex:kAnimationTransparencyTargetValueIndex] intValue] / 100.0;
                        
                        stringParticipant.alpha = originalAlpha + (targetAlpha - originalAlpha) * animationFactor;
                        
                    }
//                    NSLog(@"stringParticipant.alpha = %f", stringParticipant.alpha);
                    [stringParticipant addConsumer:textLayerEmptyFilter_];
                    [currentStringParticipants_ addObject:stringParticipant];
                }
                else if (participantType == kAnimationParticipantTypeTextBackground) {
                    stringBackground = [participants_ objectForKey:[configuration objectAtIndex:kAnimationParticipantIDIndex]];
                    
                    stringBackground.outputFrame = CGRectMake(0, 0, targetView_.contentSize.width, targetView_.contentSize.height);
                }
            }
        }
        
        if (currentStringParticipants_.count > 0) {
            textLayerEmptyFilter_.renderCount = (unsigned int)currentStringParticipants_.count;
            if (stringBackground) {
                [textLayerEmptyFilter_ addConsumer:textLayerImageLayerBlendFilter_];
                [stringBackground addConsumer:textLayerImageLayerBlendFilter_];
                [textLayerImageLayerBlendFilter_ addConsumer:textLayerBlendFilter_];
                
                textLayerFilter = textLayerBlendFilter_;
            }
            else {
                [textLayerEmptyFilter_ addConsumer:textLayerImageLayerBlendFilter_];
                
                textLayerFilter = textLayerImageLayerBlendFilter_;
            }
        }
        else if (stringBackground) {
            [stringBackground addConsumer:textLayerBlendFilter_];
            
            textLayerFilter = textLayerBlendFilter_;
        }
        
        if (imageSubLayer1LastFilter) {
            [imageLayerFilter addConsumer:layer01BlendFilter_];
            [imageSubLayer1LastFilter addConsumer:layer01BlendFilter_];
            
            imageLayerFilter = layer01BlendFilter_;
        }
        
        if (textLayerFilter) {
            [imageLayerFilter addConsumer:textLayerFilter];
            if (self.coverImage) {
                [textLayerFilter addConsumer:topLayerBlendFilter_];
            }
            else {
                [textLayerFilter addConsumer:targetView_];
                [textLayerFilter addConsumer:self.recorder];
            }
        }
        else if (self.coverImage) {
            [imageLayerFilter addConsumer:topLayerBlendFilter_];
        }
        else {
            [imageLayerFilter addConsumer:targetView_];
            [imageLayerFilter addConsumer:self.recorder];
        }
        
        if (currentStringParticipants_.count > 0) {
            for (OIString *stringParticipant in currentStringParticipants_) {
                [stringParticipant produceAtTime:kCMTimeInvalid];
            }
        }
        
        if (stringBackground) {
            [stringBackground produceAtTime:kCMTimeInvalid];
        }
        
        if (self.coverImage) {
            [self.coverImage produceAtTime:kCMTimeInvalid];
        }
        
        for (OIProducer *participant in currentImageParticipants_) {
//            NSLog(@"render layer:%d", participant.tag);
            [participant produceAtTime:kCMTimeInvalid];
        }
        
        [OIContext performSynchronouslyOnImageProcessingQueue:^{

            if (stringBackground) {
                [stringBackground removeAllConsumers];
            }
            
            [self resetAllParticipant];
        }];
    }
    else {
        [self invalidateDisplayLink];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidFinish:)]) {
            [self.delegate animationDidFinish:self];
        }
        
        if (self.recorder) {
            [self.recorder finishWriting];
        }
    }
}

- (double)yValueByXValue:(double)xValue onCurveWithEasingMode:(int)easingMode
{
    switch (easingMode) {
        case -100:
            return -cos(xValue * OI_PI_2) + 1.0;
            
        case 100:
            return sin(xValue *  OI_PI_2);
            
        case 999:
            return (-0.5 * (cos(xValue * OI_PI) - 1.0));
            
        default:
            return xValue;
    }
}

- (UIColor *)colorfromString:(NSString *)string
{
    long colorValue = [self intFromString:string];
    
    int redValue = colorValue & 0xff0000;
    redValue = redValue >> 16;
    int greenValue = colorValue & 0x00ff00;
    greenValue = greenValue >> 8;
    int blueValue = colorValue & 0x0000ff;
    
    return [UIColor colorWithRed:redValue / 255.0 green:greenValue / 255.0 blue:blueValue / 255.0 alpha:1.0];
}

- (long)intFromString:(NSString *)string
{
    char *p = (char *)string.UTF8String;
    char *str;
    long i = strtol(p, &str, 16);//十六进制
    
    return i;
}

- (void)resetAllParticipant
{
    for (OIProducer *participant in currentImageParticipants_) {
        [participant removeAllConsumers];
    }
    [currentImageParticipants_ removeAllObjects];
    
    for (OIString *stringParticipant in currentStringParticipants_) {
        [stringParticipant removeAllConsumers];
    }
    [currentStringParticipants_ removeAllObjects];
    
    textLayerEmptyFilter_.renderCount = 0;
    [textLayerEmptyFilter_ removeAllConsumers];
    [layer0EmptyFilter_ removeAllConsumers];
    [layer1EmptyFilter_ removeAllConsumers];
    
    [layer0AlphaFilter_ removeAllConsumers];
    [layer0BlurFilter_ removeAllConsumers];
    [layer0ToneFilter_ removeAllConsumers];
    [layer0RotationFilter_ removeAllConsumers];
    
    [layer1AlphaFilter_ removeAllConsumers];
    [layer1BlurFilter_ removeAllConsumers];
    [layer1ToneFilter_ removeAllConsumers];
    [layer1RotationFilter_ removeAllConsumers];
    
    [textLayerBlendFilter_ removeAllConsumers];
    [textLayerImageLayerBlendFilter_ removeAllConsumers];
//    [topLayerBlendFilter_ removeAllConsumers];
    [layer01BlendFilter_ removeAllConsumers];
}

- (void)invalidateDisplayLink
{
    if (animationDisplayLink_) {
        [animationDisplayLink_ invalidate];
        animationDisplayLink_ = nil;
    }
}

#pragma mark - UIAudioVideoWriterDelegate

- (void)audioVideoWriterRequestNextAudioSampleBuffer:(OIAudioVideoWriter *)audioVideoWriter
{
    if (audioAssetReader_.status == AVAssetReaderStatusUnknown) {
        [audioAssetReader_ startReading];
    }
    if (audioAssetReader_.status != AVAssetReaderStatusReading) {
        return;
    }
    CMSampleBufferRef audioSampleBuffer = [audioAssetReaderOutput_ copyNextSampleBuffer];
    [audioVideoWriter writeWithAudioSampleBuffer:audioSampleBuffer];
    if (audioSampleBuffer != NULL) {
        CMSampleBufferInvalidate(audioSampleBuffer);
        CFRelease(audioSampleBuffer);
        return;
    }
}

- (void)audioVideoWriterDidfinishWriting:(OIAudioVideoWriter *)audioVideoWriter
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidRecord:)]) {
        [self.delegate animationDidRecord:self];
    }
}

@end
