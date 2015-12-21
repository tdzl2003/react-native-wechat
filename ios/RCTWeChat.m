//
//  RCTWeChat.m
//  RCTWeChat
//
//  Created by Yorkie Liu on 10/16/15.
//  Copyright © 2015 WeFlex. All rights reserved.
//


#import "Base/RCTLog.h"
#import "RCTWeChat.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "Base/RCTEventDispatcher.h"

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

- (BOOL)handleUrl:(NSURL *)aUrl
{
    if ([WXApi handleOpenURL:aUrl delegate:self])
    {
        return YES;
    }
    return NO;
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
        if (resp.errCode == WXSuccess)
        {
//            self.callBackShare(@[[NSNull null]]);
        }
        else if(resp.errCode != WXErrCodeUserCancel)
        {
//            self.callBackShare(@[@{@"err":@(-1001),@"errMsg":@"Canceled."}]);
        }
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
