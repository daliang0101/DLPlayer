//
//  DLVideoOutputBase.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLVideoOutputBase.h"
#import "DLAVFrameProtocol.h"
#import "DLVideoOutputPrivateProtocol.h"
#import "DLRenderer.h"
#import <UIKit/UIView.h>
#import "DLShaders.h"
#import "DLGLView.h"

@interface DLVideoOutputBase () <DLVideoOutputPrivateProtocol>

@end

@implementation DLVideoOutputBase

VIDEO_PROPERTIES_COMPILEOPTIONS_SETUP

- (instancetype)init
{
    self = [super init];
    if (self) {
        _needLoadShaders = YES;
        _enableGLRender = YES;
        [self prepare];
    }
    return self;
}

- (void)dealloc {
    self.renderer = nil;
    self.rgbRenderer = nil;
    self.yuvRenderer =  nil;
    
    if (_vertices) {
        free(_vertices);
    }
    if (_vertShader) {
        glDeleteShader(_vertShader);
        self.vertShader = 0;
    }
    if (_fragShader) {
        glDeleteShader(_fragShader);
        self.fragShader = 0;
    }
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        self.framebuffer = 0;
    }
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        self.renderbuffer = 0;
    }
    if (_program) {
        glDeleteProgram(_program);
        self.program = 0;
    }
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

#pragma mark - DLVideoOutputProtocol' private

- (GLfloat *)vertices {
    if (!_vertices) {
        _vertices = (GLfloat *)calloc(8, sizeof(GLfloat));
    }
    return _vertices;
}

- (id<DLGLRendererProtocol>)rgbRenderer {
    if (!_rgbRenderer) {
        _rgbRenderer = [DLRenderer rendererWithType:DLRendererTypeRGB];
    }
    return _rgbRenderer;
}

- (id<DLGLRendererProtocol>)yuvRenderer {
    if (!_yuvRenderer) {
        _yuvRenderer = [DLRenderer rendererWithType:DLRendererTypeYUV];
    }
    return _yuvRenderer;
}

- (GLuint)program {
    if (!_program) {
        _program = glCreateProgram();
    }
    return _program;
}

- (BOOL)loadShaders {
    if (!_renderer || !_needLoadShaders) {
        return NO;
    }
    BOOL result = NO;
    
    self.vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    
    if (!_vertShader) {
        goto exit;
    }
    
    self.fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.fragmentShader);
    
    if (!_fragShader) {
         goto exit;
    }
    
    glAttachShader(self.program, _vertShader);
    glAttachShader(self.program, _fragShader);
    glBindAttribLocation(self.program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(self.program, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(self.program);
    
    GLint status;
    glGetProgramiv(self.program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to link program %d", self.program);
        goto exit;
    }
    result = validateProgram(self.program);
    self.uniformMatrix = glGetUniformLocation(self.program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:self.program];
    
    self.needLoadShaders = NO;
    
    glUseProgram(self.program);
    
exit:
    if (YES) {
        if (_vertShader) {
            glDeleteShader(_vertShader);
            self.vertShader = 0;
        }
        if (_fragShader) {
            glDeleteShader(_fragShader);
            self.fragShader = 0;
        }
        if (result) {
            NSLog(@"Setup GL programm succeed");
        } else {
            glDeleteProgram(self.program);
            self.program = 0;
        }
    }
    return result;
}

- (void)updateVertices {
    const BOOL fit      = (_glView.contentMode == UIViewContentModeScaleAspectFit);
    
    const float width   = _videoSize.width;
    const float height  = _videoSize.height;
    
    const float dH      = (float)_backingHeight / height;
    const float dW      = (float)_backingWidth      / width;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = (height * dd / (float)_backingHeight);
    const float w       = (width  * dd / (float)_backingWidth );
    
    self.vertices[0] = - w;
    self.vertices[1] = - h;
    self.vertices[2] =   w;
    self.vertices[3] = - h;
    self.vertices[4] = - w;
    self.vertices[5] =   h;
    self.vertices[6] =   w;
    self.vertices[7] =   h;
}

- (void)resetGLRenderBufferStorage {
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.glView.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", status);
    } else {
        NSLog(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
        glViewport(0, 0, _backingWidth, _backingHeight);
    }
}

- (void)onGLViewLayoutSubviews {
    [self resetGLRenderBufferStorage];
    [self updateVertices];
    [self render: nil];
}

- (void)onGLViewSetContentMode {
    [self updateVertices];
    if (_renderer.isValid) {
        [self render:nil];
    }
}

- (BOOL)supporteVideoFormat:(DLVideoFrameFormat)videoFormat {
    return videoFormat == DLVideoFrameFormatYUV ||
    videoFormat == DLVideoFrameFormatRGB;
}

- (id<DLGLRendererProtocol>)resolveRendererWithVideoFormat:(DLVideoFrameFormat)videoFormat {
    switch (videoFormat) {
        case DLVideoFrameFormatYUV:
            return self.yuvRenderer;
            break;
        case DLVideoFrameFormatRGB:
            return self.rgbRenderer;
            break;
        default:
            break;
    }
    return nil;
}

#pragma mark - DLVideoOutputProtocol's public

- (UIView *)glView {
    if (!_glView) {
        _glView = [DLGLView glViewWithType:DLGLViewTypeBase];
        _glView.contentMode = UIViewContentModeScaleAspectFit;
        _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        ((UIView<DLGLViewProtocol> *)(_glView)).delegate = self;
    }
    return _glView;
}
- (void)setRenderRect:(CGRect)renderRect {
    _renderRect = renderRect;
    self.glView.frame = renderRect;
}

- (void)setupVideoFormat:(DLVideoFrameFormat)videoFormat
               videoSize:(CGSize)videoSize
{
    if ([self supporteVideoFormat:videoFormat]) {
        self.videoSize = videoSize;
        self.renderer = [self resolveRendererWithVideoFormat:videoFormat];
        [self loadShaders];
        [self onGLViewLayoutSubviews];
    }
}

- (void)prepare {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*)self.glView.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        NSLog(@"EAGLContext init failed");
        return;
    }
    
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.glView.layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Handle GL_FRAMEBUFFER failed: %d", status);
        return;
    }
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"Handle GL_FRAMEBUFFER failed: %d", glError);
        return;
    }

    [self loadShaders];
    
    self.vertices[0] = -1.0f;
    self.vertices[1] = -1.0f;
    self.vertices[2] =  1.0f;
    self.vertices[3] = -1.0f;
    self.vertices[4] = -1.0f;
    self.vertices[5] =  1.0f;
    self.vertices[6] =  1.0f;
    self.vertices[7] =  1.0f;
}

- (void)render:(nullable id<DLVideoFrameProtocol>)frame {
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!frame) {
        // No frame, present the GL clear Color
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        return;
    }
    
    if (!_enableGLRender) {
        return;
    }
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    [_renderer setFrame:frame];
    
    if ([_renderer prepareRender]) {
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);

        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, self.vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
#if 0
        if (!validateProgram(self.program))
        {
            NSLog(@"Failed to validate program");
            return;
        }
#endif
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }

    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)play {
    self.enableGLRender = YES;
}
- (void)stop {
    self.enableGLRender = NO;
}
- (void)pause {
    self.enableGLRender = NO;
}

@end
