//
//  EasyNetworkManager.m
//  EasyRTC
//
//  Created by David on 2017/10/13.
//  Copyright © 2017年 David. All rights reserved.
//

#import "EasyNetworkManager.h"

//请求类型
typedef enum RequestType:NSUInteger{
    RequestTypeLogin
}RequestType;

@interface EasyNetworkManager()<NSURLSessionDataDelegate>
@property (nonatomic,copy)void (^completionCallback)(NetworkResultErrorType, NSData *);
@property (nonatomic,assign) RequestType requestType;
@property (nonatomic,strong) NSMutableData *receiveData;
@end

@implementation EasyNetworkManager

//发送登录请求
- (void)sendLoginMessageWithUserName:(NSString *)userName password:(NSString *)password completionHanlder:(void (^)(NetworkResultErrorType, NSData *))completion{
    self.requestType = RequestTypeLogin;
    self.completionCallback = completion;
    NSDictionary *dataDic = @{@"userName":userName,@"password":password};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *urlStr = [ServuerUrl stringByAppendingString:LoginUrl];
    [self sendHTTPPostRequestWithUrlString:urlStr Data:data];
}

//收到登录请求的结果
- (void)didReceiveLoginResult:(NSError *)error{
    if(!error){
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:self.receiveData options:NSJSONReadingMutableContainers error:nil];
        if([dic[@"isSuccess"] boolValue]){
            self.completionCallback(0, nil);
        }else{
            self.completionCallback(1+((NSNumber *)dic[@"errorType"]).intValue, nil);
        }
    }
}

//从返回数据中提取data字段
- (NSDictionary *)extractDataParam:(NSData *)data{
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    dic = (NSDictionary *)dic[@"data"];
    return dic;
}

//发送HTTP GET请求
- (void)sendHTTPGetRequestWithUrlString:(NSString *)urlStr{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSessionTask *task = [session dataTaskWithURL:url];
    [task resume];
}

//发送HTTP POST请求
- (void)sendHTTPPostRequestWithUrlString:(NSString *)urlStr Data:(NSData *)data{
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    NSURLSessionTask *task = [session dataTaskWithRequest:request];
    [task resume];
}



#pragma mark - urlSessionConnection delegate

//收到服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    //允许处理服务器响应才会继续接受数据
    completionHandler(NSURLSessionResponseAllow);
}

//收到数据 调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.receiveData appendData:data];
}

//请求结果
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    switch (self.requestType) {
        case RequestTypeLogin:
            [self didReceiveLoginResult:error];
            break;
            
        default:
            break;
    }
}

@end
