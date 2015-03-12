/* 
  BeautyCamera.fsh
  OpenGLESImage

  Created by Kwan Yiuleung on 14-5-29.
  Copyright (c) 2014年 Kwan Yiuleung. All rights reserved.
*/

varying highp vec2 textureCoordinatePort;
varying highp vec2 secondTextureCoordinatePort;

uniform lowp sampler2D sourceImage;
uniform lowp sampler2D secondSourceImage;
uniform lowp sampler2D redTable;
uniform lowp sampler2D greenTable;
uniform lowp sampler2D blueTable;
uniform lowp sampler2D redTable2;
uniform lowp sampler2D greenAndBlueTable;
//uniform float proportion;

void main()
{
	lowp vec4 sourceColor = texture2D(sourceImage, textureCoordinatePort);
    lowp vec4 surfaceBlurColor = texture2D(secondSourceImage, secondTextureCoordinatePort);
    
    sourceColor.rgb = mix(surfaceBlurColor.rgb, sourceColor.rgb, 0.5882);
    
	sourceColor.r = texture2D(redTable,   vec2(sourceColor.r, 0.3)).p;
	sourceColor.g = texture2D(greenTable, vec2(sourceColor.g, 0.3)).p;
	sourceColor.b = texture2D(blueTable,  vec2(sourceColor.b, 0.3)).p;
    
    sourceColor.rgb = sourceColor.rgb * 1.04 + vec3(-0.01);
    
    sourceColor.r = clamp(sourceColor.r, 0.0, 1.0);
    sourceColor.g = clamp(sourceColor.g, 0.0, 1.0);
    sourceColor.b = clamp(sourceColor.b, 0.0, 1.0);
    
    sourceColor.r = pow(sourceColor.r, 1.0526);
    sourceColor.g = pow(sourceColor.g, 1.0526);
    sourceColor.b = pow(sourceColor.b, 1.0526);
    
    if ((sourceColor.r != 0.0 || sourceColor.g != 0.0 || sourceColor.b != 0.0) && (sourceColor.r != 1.0 || sourceColor.g != 1.0 || sourceColor.b != 1.0)) {
        lowp float max = max(sourceColor.r, max(sourceColor.g, sourceColor.b));
        lowp float min = min(sourceColor.r, min(sourceColor.g, sourceColor.b));
        lowp float lim = 1.0 - abs(max - 0.5) + abs(min - 0.5);
        lowp float dec = lim * sourceColor.g;
        lowp float inc = lim - dec;
        if (dec != 0.0) {
            if (sourceColor.g > 0.5) {
                sourceColor.g -= 0.03 * inc;
            }
            else
                sourceColor.g -= 0.03 * dec;
        }
        dec = lim * sourceColor.b;
        inc = lim - dec;
        if (inc != 0.0) {
            sourceColor.b -= 0.01 * inc;
        }
    }
    
    if (sourceColor.r > sourceColor.b && sourceColor.g > sourceColor.b) {
        lowp float max, mid, min = sourceColor.b;
        if (sourceColor.r > sourceColor.g) {
            max = sourceColor.r;
            mid = sourceColor.g;
        }
        else {
            max = sourceColor.g;
            mid = sourceColor.r;
        }
        lowp float lim = mid - min;
        lowp float dec = lim * sourceColor.r;
        lowp float inc = lim - dec;
        if (inc != 0.0) {
            sourceColor.r -= -0.1 * inc;
        }
        dec = lim * sourceColor.g;
        inc = lim - dec;
        if (dec != 0.0) {
            if (sourceColor.g > 0.5) {
                sourceColor.g -= 0.1 * inc;
            }
            else
                sourceColor.g -= 0.1 * dec;
        }
        dec = lim * sourceColor.b;
        inc = lim - dec;
        if (inc != 0.0) {
            sourceColor.b -= -0.13 * inc;
        }
    }
    
    sourceColor.r = texture2D(redTable2, vec2(sourceColor.r, 0.3)).p;
    sourceColor.g = texture2D(greenAndBlueTable, vec2(sourceColor.g, 0.3)).p;
    sourceColor.b = texture2D(greenAndBlueTable, vec2(sourceColor.b, 0.3)).p;
    
    gl_FragColor = sourceColor;
}