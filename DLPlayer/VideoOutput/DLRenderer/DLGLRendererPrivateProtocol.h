//
//  DLGLRendererPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/22.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLGLRendererPrivateProtocol_h
#define DLGLRendererPrivateProtocol_h

@protocol DLRendererYUVPrivateProtocol <NSObject>
@property (nonatomic, assign) GLint  * _Nullable uniformSamplers;
@property (nonatomic, assign) GLuint * _Nullable textures;
@end

@protocol DLRendererRGBPrivateProtocol <NSObject>
@property (nonatomic, assign) GLint  uniformSampler;
@property (nonatomic, assign) GLuint texture;
@end

#endif /* DLGLRendererPrivateProtocol_h */
