//
//  DLRendererYUV.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLRendererYUV.h"
#import "DLShaders.h"
#import "DLAVFrameProtocol.h"
#import <OpenGLES/ES2/gl.h>



@implementation DLRendererYUV

@synthesize textures = _textures;

@synthesize uniformSamplers = _uniformSamplers;

- (GLuint *)textures {
    if (!_textures) {
        _textures = (GLuint *)calloc(3, sizeof(GLuint));
    }
    return _textures;
}

- (GLint *)uniformSamplers {
    if (!_uniformSamplers) {
        _uniformSamplers  = (GLint *)calloc(3, sizeof(GLint));
    }
    return _uniformSamplers;
}

- (BOOL) isValid    {
    return (self.textures[0] != 0);
}

- (NSString *) fragmentShader   {
    return yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program  {
    self.uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    self.uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    self.uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}

- (void)setFrame:(id<DLVideoFrameProtocol> _Nullable) frame   {
    id<DLVideoFrameYUVProtocol> yuvFrame = (id<DLVideoFrameYUVProtocol>)frame;
    
    assert(yuvFrame.luma.length == yuvFrame.width * yuvFrame.height);
    assert(yuvFrame.chromaB.length == (yuvFrame.width * yuvFrame.height) / 4);
    assert(yuvFrame.chromaR.length == (yuvFrame.width * yuvFrame.height) / 4);
    
    const NSUInteger frameWidth = frame.width;
    const NSUInteger frameHeight = frame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == self.textures[0])  {
        glGenTextures(3, self.textures);
    }
    
    const UInt8 *pixels[3] = { yuvFrame.luma.bytes, yuvFrame.chromaB.bytes, yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        glBindTexture(GL_TEXTURE_2D, self.textures[i]);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     (GLsizei)widths[i],
                     (GLsizei)heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL) prepareRender  {
    if (self.textures[0] == 0) {
        return NO;
    }
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, self.textures[i]);
        glUniform1i(self.uniformSamplers[i], i);
    }
    return YES;
}

- (void) dealloc {
    if (self.textures[0])   {
        glDeleteTextures(3, self.textures);
        free(self.textures);
    }
    if (self.uniformSamplers[0]) {
        free(self.uniformSamplers);
    }
}

@end
