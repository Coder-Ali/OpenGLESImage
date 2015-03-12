//
//  OIFastSurfaceBlurFilter.m
//  OpenGLESImage
//
//  Created by Kwan Yiuleung on 14-5-28.
//  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
//

#import "OIFastSurfaceBlurFilter.h"

@interface OIFastSurfaceBlurFilter ()
{
    int radius_;
    int stepDistance_;
}

@end

@implementation OIFastSurfaceBlurFilter

@synthesize radius = radius_;
@synthesize stepDistance = stepDistance_;

#pragma mark - Liftcycle

- (id)init
{
    self = [super init];
    if (self) {
        self.radius = 8;
        self.stepDistance = 4;
    }
    return self;
}

#pragma mark - Properties' Setters & Getters

//- (void)setRadius:(int)radius
//{
//    radius_ = radius;
//    
//    [OIContext performSynchronouslyOnImageProcessingQueue:^{
//        [[OIContext sharedContext] setAsCurrentContext];
//        [filterProgram_ use];
//        [filterProgram_ setInt:radius_ forUniform:@"radius"];
//        
//        [secondFilterProgram_ use];
//        [secondFilterProgram_ setInt:radius_ forUniform:@"radius"];
//    }];
//}
//
//- (void)setStepDistance:(int)stepDistance
//{
//    stepDistance_ = stepDistance;
//    
//    [OIContext performSynchronouslyOnImageProcessingQueue:^{
//        [[OIContext sharedContext] setAsCurrentContext];
//        [filterProgram_ use];
//        [filterProgram_ setInt:stepDistance_ forUniform:@"stepDistance"];
//        
//        [secondFilterProgram_ use];
//        [secondFilterProgram_ setInt:stepDistance_ forUniform:@"stepDistance"];
//    }];
//}

#pragma mark - The Methods Be Overrided In Subclass If Need

+ (NSString *)vertexShaderFilename
{
    static NSString *vName = @"FastSurfaceBlur";
    return vName;
}

+ (NSString *)fragmentShaderFilename
{
    static NSString *fName = @"FastSurfaceBlur";
    return fName;
}

- (void)setProgramUniform
{
    OI2DFloatVector vector = {1.0 / contentSize_.width, 0.0};
    [filterProgram_ set2DFloatVector:vector forUniform:@"offset"];
}

- (void)setSecondProgramUniform
{
    OI2DFloatVector vector = {0.0, 1.0 / contentSize_.height};
    [secondFilterProgram_ set2DFloatVector:vector forUniform:@"offset"];
}

@end
