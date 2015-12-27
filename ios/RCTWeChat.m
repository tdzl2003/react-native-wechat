//
//  RCTWeChat.m
//  RCTWeChat
//
//  Created by Yorkie Liu on 10/16/15.
//  Copyright © 2015 WeFlex. All rights reserved.
//


#import "RCTLog.h"
#import "RCTWeChat.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "RCTEventDispatcher.h"
#import "RCTBridge.h"
#import "RCTImageLoader.h"

#define NOT_REGISTERED (@"registerApp required.")
#define INVOKE_FAILED (@"WeChat API invoke returns false.")

@interface RCTWeChat()<WXApiDelegate> {
}

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *appSecret;

@end


@implementation RCTWeChat

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        [self registerAPI];
//    }
//    return self;
//}

RCT_EXPORT_METHOD(registerApp:(NSString *)appid
                  :(RCTResponseSenderBlock)callback)
{
    self.appID = appid;
    callback(@[[WXApi registerApp:appid] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(registerAppWithDescription:(NSString *)appid
                  :(NSString *)appdesc
                  :(RCTResponseSenderBlock)callback)
{
    self.appID = appid;
    callback(@[[WXApi registerApp:appid withDescription:appdesc] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(isWXAppInstalled:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppInstalled])]);
}

RCT_EXPORT_METHOD(isWXAppSupportApi:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppSupportApi])]);
}

RCT_EXPORT_METHOD(getWXAppInstallUrl:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getWXAppInstallUrl]]);
}

RCT_EXPORT_METHOD(getApiVersion:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getApiVersion]]);
}

RCT_EXPORT_METHOD(openWXApp:(RCTResponseSenderBlock)callback)
{
    callback(@[([WXApi openWXApp] ? [NSNull null] : INVOKE_FAILED)]);
}

RCT_EXPORT_METHOD(sendRequest:(NSString *)openid
                  :(RCTResponseSenderBlock)callback)
{
    BaseReq* req = [[BaseReq alloc] init];
    req.openID = openid;
    callback(@[[WXApi sendReq:req] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendAuthRequest:(NSString *)scope
                  :(NSString *)state
                  :(RCTResponseSenderBlock)callback)
{
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = scope;
    req.state = state;
    BOOL success = [WXApi sendReq:req];
    callback(@[success ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendSuccessResponse:(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXSuccess;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendErrorCommonResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeCommon;
    resp.errStr = message;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(sendErrorUserCancelResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeUserCancel;
    resp.errStr = message;
    callback(@[[WXApi sendResp:resp] ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(shareToTimeline:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneTimeline callback:callback];
}

RCT_EXPORT_METHOD(shareToSession:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneSession callback:callback];
}

- (BOOL)handleUrl:(NSURL *)aUrl
{
    if ([WXApi handleOpenURL:aUrl delegate:self])
    {
        return YES;
    }
    return NO;
}

- (void)shareToWeixinWithData:(NSDictionary *)aData thumbImage:(UIImage *)aThumbImage scene:(int)aScene callBack:(RCTResponseSenderBlock)callback
{
    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.scene = aScene;
    
    NSString *type = aData[RCTWXShareType];
    
    if ([type isEqualToString:RCTWXShareTypeText]) {
        req.bText = YES;
        
        NSString *text = aData[RCTWXShareDescription];
        if (text && [text isKindOfClass:[NSString class]]) {
            req.text = text;
        }
    }
    else {
        req.bText = NO;
        
        WXMediaMessage* mediaMessage = [WXMediaMessage new];
        
        mediaMessage.title = aData[RCTWXShareTitle];
        mediaMessage.description = aData[RCTWXShareDescription];
        mediaMessage.mediaTagName = aData[@"mediaTagName"];
        mediaMessage.messageAction = aData[@"messageAction"];
        mediaMessage.messageExt = aData[@"messageExt"];
        
        [mediaMessage setThumbImage:aThumbImage];
        
        if (type.length <= 0 || [type isEqualToString:RCTWXShareTypeNews]) {
            WXWebpageObject* webpageObject = [WXWebpageObject new];
            webpageObject.webpageUrl = aData[RCTWXShareWebpageUrl];
            mediaMessage.mediaObject = webpageObject;
            
            if (webpageObject.webpageUrl.length<=0) {
                callback(@[@"webpageUrl不能为空"]);
                return;
            }
        }
        else if ([type isEqualToString:RCTWXShareTypeAudio]) {
            WXMusicObject *musicObject = [WXMusicObject new];
            musicObject.musicUrl = aData[@"musicUrl"];
            musicObject.musicLowBandUrl = aData[@"musicLowBandUrl"];
            musicObject.musicDataUrl = aData[@"musicDataUrl"];
            musicObject.musicLowBandDataUrl = aData[@"musicLowBandDataUrl"];
            mediaMessage.mediaObject = musicObject;
        }
        else if ([type isEqualToString:RCTWXShareTypeVideo]) {
            WXVideoObject *videoObject = [WXVideoObject new];
            videoObject.videoUrl = aData[@"videoUrl"];
            videoObject.videoLowBandUrl = aData[@"videoLowBandUrl"];
            mediaMessage.mediaObject = videoObject;
        }
        else if ([type isEqualToString:RCTWXShareTypeImage]) {
            WXImageObject *imageObject = [WXImageObject new];
            imageObject.imageUrl = aData[RCTWXShareImageUrl];
            mediaMessage.mediaObject = imageObject;
        }
        req.message = mediaMessage;
    }
    
    BOOL success = [WXApi sendReq:req];
    if (success == NO)
    {
        callback(@[INVOKE_FAILED]);
    }
}


- (void)shareToWeixinWithData:(NSDictionary *)aData scene:(int)aScene callback:(RCTResponseSenderBlock)aCallBack
{
    NSString *imageUrl = aData[@"thumbImage"];
    if (imageUrl.length && _bridge.imageLoader) {
        [_bridge.imageLoader loadImageWithTag:imageUrl size:CGSizeMake(100, 100) scale:1 resizeMode:UIViewContentModeScaleToFill progressBlock:nil completionBlock:^(NSError *error, UIImage *image) {
            [self shareToWeixinWithData:aData thumbImage:image scene:aScene callBack:aCallBack];
        }];
    }
    else {
        [self shareToWeixinWithData:aData thumbImage:nil scene:aScene callBack:aCallBack];
    }
    
}


//- (void)registerAPI
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        NSString *appId = nil;
//        NSArray *list = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
//        for (NSDictionary *item in list) {
//            NSString *name = item[@"CFBundleURLName"];
//            if ([name isEqualToString:@"weixin"]) {
//                NSArray *schemes = item[@"CFBundleURLSchemes"];
//                if (schemes.count > 0)
//                {
//                    appId = schemes[0];
//                    break;
//                }
//            }
//        }
//        [WXApi registerApp:appId];
//    });
//}

#pragma mark - wx callback
-(void) onReq:(BaseReq*)req
{
    
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        SendMessageToWXResp *r = (SendMessageToWXResp *)resp;
        
        NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
        body[@"errStr"] = r.errStr;
        body[@"lang"] = r.lang;
        body[@"country"] =r.country;
        body[@"type"] = @"SendMessageToWX.Resp";
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"WeChat_Resp" body:body];
    }
    else if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *r = (SendAuthResp *)resp;
        NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
        body[@"errStr"] = r.errStr;
        body[@"state"] = r.state;
        body[@"lang"] = r.lang;
        body[@"country"] =r.country;
        body[@"type"] = @"SendAuth.Resp";
        
        if (resp.errCode == WXSuccess)
        {
            [body addEntriesFromDictionary:@{@"appid":self.appID, @"code" :r.code}];
            [self.bridge.eventDispatcher sendDeviceEventWithName:@"WeChat_Resp" body:body];
        }
        else {
            [self.bridge.eventDispatcher sendDeviceEventWithName:@"WeChat_Resp" body:body];
        }
    }
    //    else if([resp isKindOfClass:[PayResp class]]) {
    //
    //    }
}


@end
