//
//  DLRendererProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLRenderProtocol_h
#define DLRenderProtocol_h
#import <OpenGLES/ES2/gl.h>

@protocol DLVideoFrameProtocol;

@protocol DLGLRendererProtocol

- (BOOL)isValid;

- (NSString *_Nullable)fragmentShader;

- (void)resolveUniforms: (GLuint) program;

- (void)setFrame:(id<DLVideoFrameProtocol>_Nullable)frame;

- (BOOL)prepareRender;

@end


@protocol DLRendererRGBProtocol <DLGLRendererProtocol>
@property (nonatomic, assign, readonly) GLint  uniformSampler;
@property (nonatomic, assign, readonly) GLuint texture;
@end

@protocol DLRendererYUVProtocol <DLGLRendererProtocol>
@property (nonatomic, assign, readonly) GLint  * _Nullable uniformSamplers;
@property (nonatomic, assign, readonly) GLuint * _Nullable textures;
@end

#endif /* DLRenderProtocol_h */
