//
//  EasyNetworkManager.h
//  EasyRTC
//
//  Created by David on 2017/10/13.
//  Copyright © 2017年 David. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ServerHost @"http://127.0.0.1"
#define ServerPort @"8080"
#define ServuerUrl ServerHost@":"ServerPort
#define LoginUrl @"/login"

//请求结果错误类型
typedef enum NetworkResultErrorType:NSUInteger{
    ResultNoError = 0,
    NetworkNotWorkError,
    LoginNoAccountError,
    LoginWrongPasswordError
}NetworkResultErrorType;

@interface EasyNetworkManager : NSObject

- (void)sendLoginMessageWithUserName:(NSString *)userName password:(NSString *)password completionHanlder:(void (^)(NetworkResultErrorType error, NSData *data))completion;
@end
