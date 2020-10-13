//
//  DLAVFrameSubtitleaASSParser.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLAVFrameSubtitleaASSParser : NSObject

+ (NSArray *) parseEvents: (NSString *) events;
+ (NSArray *) parseDialogue: (NSString *) dialogue
                  numFields: (NSUInteger) numFields;
+ (NSString *) removeCommandsFromEventText: (NSString *) text;

@end

NS_ASSUME_NONNULL_END
