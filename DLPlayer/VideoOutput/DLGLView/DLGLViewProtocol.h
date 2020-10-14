//
//  DLGLViewProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLGLViewProtocol_h
#define DLGLViewProtocol_h

@protocol DLGLViewDelegateProtocol <NSObject>
- (void)onGLViewLayoutSubviews;
- (void)onGLViewSetContentMode;
@end

@protocol DLGLViewProtocol <NSObject>
@property (nonatomic, weak) id<DLGLViewDelegateProtocol> delegate;
@end

#endif /* DLGLViewProtocol_h */
