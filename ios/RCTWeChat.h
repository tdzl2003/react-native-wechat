//
//  RCTWeChat.h
//  RCTWeChat
//
//  Created by Yorkie Liu on 10/16/15.
//  Copyright © 2015 WeFlex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base/RCTBridgeModule.h"

#define RCTWXShareTypeNews @"news"
#define RCTWXShareTypeImage @"image"
#define RCTWXShareTypeText @"text"
#define RCTWXShareTypeVideo @"video"
#define RCTWXShareTypeAudio @"audio"

#define RCTWXShareType @"type"
#define RCTWXShareTitle @"title"
#define RCTWXShareDescription @"description"
#define RCTWXShareWebpageUrl @"webpageUrl"
#define RCTWXShareImageUrl @"imageUrl"

@interface RCTWeChat : NSObject <RCTBridgeModule>

- (BOOL)handleUrl:(NSURL *)aUrl;

@end
