//
//  DLVideoOutputPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/22.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLVideoOutputPrivateProtocol_h
#define DLVideoOutputPrivateProtocol_h
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import "DLGLViewProtocol.h"

@protocol DLGLRendererProtocol;
@class UIView;

@protocol DLVideoOutputPrivateProtocol <DLGLViewDelegateProtocol>

@property (nonatomic, strong) EAGLContext                 *context;

@property (nonatomic, weak  ) id<DLGLRendererProtocol>     renderer;

@property (nonatomic, strong) id<DLGLRendererProtocol>     rgbRenderer;

@property (nonatomic, strong) id<DLGLRendererProtocol>     yuvRenderer;

@property (nonatomic, assign) GLuint                       framebuffer;

@property (nonatomic, assign) GLuint                       renderbuffer;

@property (nonatomic, assign) GLuint                       program;

@property (nonatomic, assign) GLuint                       vertShader;

@property (nonatomic, assign) GLuint                       fragShader;

@property (nonatomic, assign) GLint                        backingWidth;

@property (nonatomic, assign) GLint                        backingHeight;

@property (nonatomic, assign) GLint                        uniformMatrix;

@property (nonatomic, assign) CGSize                       videoSize;

@property (nonatomic, assign) GLfloat                     *vertices;

/* Flag if has a valid videoFrameFormat */
@property (nonatomic, assign) BOOL                         needLoadShaders;
@property (nonatomic, assign) BOOL                         enableGLRender;

- (BOOL)loadShaders;

- (void)updateVertices;

- (void)onGLViewLayoutSubviews;

- (void)onGLViewSetContentMode;

- (void)resetGLRenderBufferStorage;

- (BOOL)supporteVideoFormat:(DLVideoFrameFormat)videoFormat;

- (id<DLGLRendererProtocol>)resolveRendererWithVideoFormat:(DLVideoFrameFormat)videoFormat;

@end

#define VIDEO_PROPERTIES_COMPILEOPTIONS_SETUP \
@synthesize renderRect = _renderRect;\
@synthesize glView = _glView;\
@synthesize backingHeight = _backingHeight;\
@synthesize backingWidth = _backingWidth;\
@synthesize context = _context;\
@synthesize framebuffer = _framebuffer;\
@synthesize program = _program;\
@synthesize renderbuffer = _renderbuffer;\
@synthesize renderer = _renderer;\
@synthesize rgbRenderer = _rgbRenderer;\
@synthesize yuvRenderer =  _yuvRenderer;\
@synthesize uniformMatrix = _uniformMatrix;\
@synthesize vertices = _vertices;\
@synthesize videoSize = _videoSize;\
@synthesize vertShader = _vertShader;\
@synthesize fragShader = _fragShader;\
@synthesize needLoadShaders = _needLoadShaders;\
@synthesize enableGLRender = _enableGLRender;\


#endif /* DLVideoOutputPrivateProtocol_h */
