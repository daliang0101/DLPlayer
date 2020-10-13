//
//  DLRendererRGB.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLRendererRGB.h"
#import "DLShaders.h"
#import "DLAVFrameProtocol.h"
#import "DLGLRendererPrivateProtocol.h"
#import <OpenGLES/ES2/gl.h>

@interface DLRendererRGB () <DLRendererRGBPrivateProtocol>

@end

@implementation DLRendererRGB

@synthesize texture = _texture;

@synthesize uniformSampler = _uniformSampler;

- (NSString * _Nullable)fragmentShader {
    return rgbFragmentShaderString;
}

- (BOOL)isValid {
    return (_texture != 0);
}

- (BOOL)prepareRender {
    if (_texture == 0)  {
        return NO;
    }
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_uniformSampler, 0);
    return YES;
}

- (void)resolveUniforms:(GLuint)program {
    self.uniformSampler = glGetUniformLocation(program, "s_texture");
}

- (void)setFrame:(id<DLVideoFrameProtocol> _Nullable)frame {
    id<DLVideoFrameRGBProtocol> rgbFrame = (id<DLVideoFrameRGBProtocol>)frame;
    
    assert(rgbFrame.rgb.length == rgbFrame.width * rgbFrame.height * 3);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _texture)  {
        glGenTextures(1, &_texture);
    }
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGB,
                 (GLsizei)frame.width,
                 (GLsizei)frame.height,
                 0,
                 GL_RGB,
                 GL_UNSIGNED_BYTE,
                 rgbFrame.rgb.bytes);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void) dealloc    {
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

@end
