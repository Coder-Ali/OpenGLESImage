//
//  OIString.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-9-3.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import <OpenGLESImage/OIString.h>
#import <UIKit/UIKit.h>
#import "OIContext.h"
#import "OITexture.h"

@interface OIString ()
{
    NSString *NSString_;
    UILabel *stringLabel_;
    NSString *fontName_;
    float fontSize_;
    UIColor *color_;
}

@end

@implementation OIString

@synthesize NSString = NSString_;
@synthesize fontName = fontName_;
@synthesize fontSize = fontSize_;
@synthesize color = color_;

#pragma mark - Lifecycle

- (void)dealloc
{
    if (NSString_) {
        [NSString_ release];
    }
    if (stringLabel_) {
        [stringLabel_ release];
    }
    if (fontName_) {
        [fontName_ release];
    }
    if (color_) {
        [color_ release];
    }
    
    [super dealloc];
}

- (instancetype)initWithNSString:(NSString *)string fontSize:(float)fontSize size:(CGSize)size;
{
    self = [self initWithNSString:string fontName:@"Arial" fontSize:fontSize color:[UIColor blackColor] size:size];
    
    return self;
}

- (instancetype)initWithNSString:(NSString *)string fontName:(NSString *)fontName fontSize:(float)fontSize color:(UIColor *)color size:(CGSize)size
{
    self = [super init];
    if (self) {
        NSString_ = nil;
        color_ = nil;
        stringLabel_ = nil;
        
        if (!color) {
            color = [UIColor blackColor];
        }
        
        color_ = [color retain];
        
        if (string) {
            NSString_ = [string copy];
        }
        
        fontSize_ = fontSize;
        
        UIFont *font = nil;
        
        if (fontName && ![fontName isEqualToString:@""]) {
            fontName_ = [fontName copy];
            font = [UIFont fontWithName:fontName_ size:fontSize_];
        }
        else {
            font = [UIFont systemFontOfSize:fontSize_];
            fontName_ = [font.familyName retain];//[[NSString alloc] initWithFormat:@"Arial"];
        }
        
        stringLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        stringLabel_.text = self.NSString;
        stringLabel_.textColor = self.color;
        stringLabel_.backgroundColor = [UIColor clearColor];
        stringLabel_.numberOfLines = 1;
        stringLabel_.font = font;
        stringLabel_.adjustsFontSizeToFitWidth = YES;
        
        outputTexture_ = [[OITexture alloc] init];
        outputTexture_.orientation = OITextureOrientationDown;
        [outputTexture_ setupContentWithCALayer:stringLabel_.layer];
        
        self.outputFrame = CGRectMake(0, 0, outputTexture_.size.width, outputTexture_.size.height);
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

- (void)setNSString:(NSString *)NSString
{
    if (!NSString) {
        return;
    }
    
    if (NSString_) {
        [NSString_ release];
    }
    
    NSString_ = [NSString copy];
    
    [self updateOutputTexture];
}

- (void)setColor:(UIColor *)color
{
    if (!color) {
        return;
    }
    if (color_) {
        [color_ release];
    }
    color_ = [color retain];
    
    [self updateOutputTexture];
}

- (void)setAlpha:(float)alpha
{
    stringLabel_.alpha = alpha;
    
    [self updateOutputTexture];
}

- (float)alpha
{
    return stringLabel_.alpha;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    stringLabel_.textAlignment = textAlignment;
    
    [self updateOutputTexture];
}

- (NSTextAlignment)textAlignment
{
    return stringLabel_.textAlignment;
}

- (void)setFontName:(NSString *)fontName
{
    if (fontName) {
        [fontName_ release];
        fontName_ = [fontName copy];
        
        stringLabel_.font = [UIFont fontWithName:fontName_ size:fontSize_];
        
        [self updateOutputTexture];
    }
}

- (void)setFontSize:(float)fontSize
{
    fontSize_ = fontSize;
    
    stringLabel_.font = [UIFont fontWithName:fontName_ size:fontSize_];
    
    [self updateOutputTexture];
}

#pragma mark -

- (void)updateOutputTexture
{
    stringLabel_.text = self.NSString;
    stringLabel_.textColor = self.color;
    
    [OIContext performSynchronouslyOnImageProcessingQueue:^{

        [outputTexture_ setupContentWithCALayer:stringLabel_.layer];
        
        [self produceAtTime:kCMTimeInvalid];
    }];
}

@end
