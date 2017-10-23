//
//  EasyRTCManager.h
//  EasyRTC
//
//  Created by David on 2017/10/10.
//  Copyright © 2017年 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketRocket.h"

#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCDataChannelConfiguration.h>
#import <WebRTC/RTCSessionDescription.h>

@interface EasyRTCManager : NSObject

/**
 获取全局单例对象

 @return 全局单例EasyRTCManager对象
 */
+ (instancetype)sharedManager;

/**
 与信令服务器建立长连接（webSocket）
 
 @param address ip或域名地址
 @param port 服务器端口号
 @param userId 提供自己的userId
 */
- (void)connectToServer:(NSString *)address port:(NSString *)port userId:(NSNumber *)userId;

/**
 与指定的用户建立点对点连接

 @param userId 建立点对点连接前需要通过信令服务器传递sdp，userId用来提供给信令服务器确定和哪个用户交换sdp
 */
- (void)connectToFriendWithUserId:(NSNumber *)userId;


/**
 断开点对点连接
 */
- (void)closeP2PConnect;

- (void)closeSocket;


- (RTCPeerConnection *)creatRTCP2PConnection;
@end























