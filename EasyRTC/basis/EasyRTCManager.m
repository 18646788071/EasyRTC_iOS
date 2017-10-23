
//
//  EasyRTCManager.m
//  EasyRTC
//
//  Created by David on 2017/10/10.
//  Copyright © 2017年 David. All rights reserved.
//

#import "EasyRTCManager.h"

//google提供的免费stun服务器
static NSString *const RTCSTUNServerURL = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL2 = @"stun:23.21.150.121";

typedef enum SendSDPType : NSUInteger{
    SendSDPTypeOffer,
    SendSDPTypeAnswer
}SendSDPType;

@interface EasyRTCManager()<RTCPeerConnectionDelegate,RTCDataChannelDelegate,SRWebSocketDelegate>

@end

@implementation EasyRTCManager{
    //当前用户的userId
    NSNumber *_userId;
    //通信用户的userId
    NSNumber *_connectingUserId;
    
    /** websocket相关 */
    //与信令服务器进行长连接的socket
    SRWebSocket *_socket;
    
    /** webrtc相关 */
    //rtc工厂对象
    RTCPeerConnectionFactory *_rtcFactory;
    //rtc p2p连接对象
    RTCPeerConnection *_rtcP2PConnection;
    //本地媒体流
    RTCMediaStream *_localRTCStream;
    //本地data channel
    RTCDataChannel *_localDataChannel;
    //远端data channel
    RTCDataChannel *_remoteDataChannel;
    //远程媒体流
    RTCMediaStream *_remoteRTCStream;
    //ICE服务器 用于获取sdp
    RTCIceServer *_IceServer;
}

+ (instancetype)sharedManager{
    static EasyRTCManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [EasyRTCManager new];
    });
    return manager;
}

#pragma mark - websocket found

//连接websocket服务器
- (void)connectToServer:(NSString *)address port:(NSString *)port userId:(NSNumber *)userId{
    _userId = userId;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ws://%@:%@/websocket",address,port]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    _socket = [[SRWebSocket alloc] initWithURLRequest:request];
    _socket.delegate = self;
    [_socket open];
}

//向websocket服务器发送自己的userId
- (void)sendUserId{
    if(_socket.readyState == SR_OPEN){
        NSDictionary *param = @{@"eventName" : @"__send_userId", @"data" : @{@"userId" : _userId}};
        NSData *data = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:nil];
        [_socket send:data];
    }
}

//创建本地sdp，通过websocket服务器向指定的userId发送offer
- (void)prepareLocalAndSendOfferWithUserId:(NSNumber *)userId{
    [self prepareLocalAndSendSDPWithType:SendSDPTypeOffer userId:userId];
}

//创建本地sdp，通过websocket服务器向指定的userId发送answer
- (void)prepareLocalAndSendAnswerWithUserId:(NSNumber *)userId{
    [self prepareLocalAndSendSDPWithType:SendSDPTypeAnswer userId:userId];
}

//收到其他用户发来的offer
- (void)didReceiveOfferSDP:(RTCSessionDescription *)offerSDP userId:(NSNumber *)userId{
    //如果已经存在p2p连接 向websocket服务器发送 占线 消息
    if(_rtcP2PConnection){
        NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"eventName":@"__busy",@"data":[NSNull null]} options:NSJSONWritingPrettyPrinted error:nil];
        [_socket send:data];
        return ;
    }
    _connectingUserId = userId;
    //首先初始化webrtc相关设置
    [self initialWebRTCFoundation];
    //收到offer后先设置remoteSDP 再设置localSDP
    __weak typeof(self) weakSelf = self;
    [_rtcP2PConnection setRemoteDescription:offerSDP completionHandler:^(NSError * _Nullable error) {
        if(_rtcP2PConnection.signalingState == RTCSignalingStateHaveRemoteOffer){
            [weakSelf prepareLocalAndSendAnswerWithUserId:userId];
        }
    }];
}

//收到其他用户发来的answer
- (void)didReceiveAnswerSDP:(RTCSessionDescription *)answerSDP userId:(NSNumber *)userId{
    [_rtcP2PConnection setRemoteDescription:answerSDP completionHandler:^(NSError * _Nullable error) {
        
    }];
}

//创建本地sdp，并发送给websocket服务器
- (void)prepareLocalAndSendSDPWithType:(SendSDPType)type userId:(NSNumber *)userId{
    __weak SRWebSocket *weakSocket = _socket;
    __weak RTCPeerConnection *weakConnection = _rtcP2PConnection;
    NSNumber *selfUserId = [_userId copy];
    if(type==SendSDPTypeOffer){
        [weakConnection offerForConstraints:[self SDPConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            [weakConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if(weakConnection.signalingState == RTCSignalingStateHaveLocalOffer){
                    NSDictionary *dic = @{@"eventName": @"__sdp", @"data": @{@"sdp": @{@"type": @"offer", @"sdp": [weakConnection.localDescription.sdp copy]}, @"toUserId": userId ,@"userId":selfUserId}};
                    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
                    [weakSocket send:data];
                }
            }];
        }];
    }else{
        [_rtcP2PConnection answerForConstraints:[self SDPConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            [weakConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if(weakConnection.signalingState == RTCSignalingStateStable){
                    NSDictionary *dic = @{@"eventName": @"__sdp", @"data": @{@"sdp": @{@"type": @"answer", @"sdp": [weakConnection.localDescription.sdp copy]}, @"toUserId": userId ,@"userId":selfUserId}};
                    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
                    [weakSocket send:data];
                }
            }];
        }];
    }
}

//通过websocket服务器向指定的userId发送ICECandidate
- (void)sendICECandidate:(RTCIceCandidate *)candidate withUserId:(NSNumber *)userId{
    NSDictionary *dic = @{@"eventName": @"__ice_candidate", @"data": @{@"id":candidate.sdpMid,@"label": [NSNumber numberWithInt:candidate.sdpMLineIndex], @"candidate": candidate.sdp, @"toUserId": userId ,@"userId":_userId}};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socket send:data];
}

//收到其他用户发来的ICECandidate
- (void)didReceiveICECandidate:(RTCIceCandidate *)candidate{
    [_rtcP2PConnection addIceCandidate:candidate];
}

- (void)closeSocket{
    if(_socket){
        [_socket close];
        _userId = nil;
    }
}

#pragma mark - webrtc found

//初始化webrtc相关设置
- (void)initialWebRTCFoundation{
    _rtcP2PConnection = [self creatRTCP2PConnection];
    [self createLocalStream];
    [_rtcP2PConnection addStream:_localRTCStream];
    [self createDataChannel];
}

- (void)closeP2PConnect{
    [self closeWebRTCFoundation];
}

//关闭webrtc相关设置
- (void)closeWebRTCFoundation{
    _connectingUserId = nil;
    _rtcP2PConnection = nil;
    _localRTCStream = nil;
    _remoteRTCStream = nil;
    _localDataChannel = nil;
    _remoteRTCStream = nil;
}

//与好友建立p2p连接
- (void)connectToFriendWithUserId:(NSNumber *)userId{
    _connectingUserId = userId;
    [self initialWebRTCFoundation];
    [self prepareLocalAndSendOfferWithUserId:userId];
}

//创建rtc p2p连接对象
- (RTCPeerConnection *)creatRTCP2PConnection{
    //如果没有工厂 先初始化工厂
    if(!_rtcFactory){
        _rtcFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    //如果没有ICE服务器 先初始化ICE服务器
    if(!_IceServer){
        _IceServer = [[RTCIceServer alloc] initWithURLStrings:@[RTCSTUNServerURL,RTCSTUNServerURL2]];
    }
    //使用工厂创建rtc p2p连接
    RTCConfiguration *rtcConfig = [[RTCConfiguration alloc] init];
    rtcConfig.iceServers = @[_IceServer];
    RTCPeerConnection *connection = [_rtcFactory peerConnectionWithConfiguration:rtcConfig constraints:[self peerConnectionConstraints] delegate:self];
    return connection;
}

//创建本地流
- (void)createLocalStream
{
    _localRTCStream = [_rtcFactory mediaStreamWithStreamId:@"ARDAMS"];
    
    //音频
    RTCAudioTrack *audioTrack = [_rtcFactory audioTrackWithTrackId:@"ARDAMSa0"];
    [_localRTCStream addAudioTrack:audioTrack];
    
    //视频
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"相机访问受限" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        if (device)
        {
            RTCAVFoundationVideoSource *videoSource = [_rtcFactory avFoundationVideoSourceWithConstraints:[self localVideoConstraints]];
            RTCVideoTrack *videoTrack = [_rtcFactory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
            [_localRTCStream addVideoTrack:videoTrack];
        }
        else
        {
            NSLog(@"该设备不能打开摄像头");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"该设备不能打开摄像头" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
        }
    }
    
}

//给点对点连接，创建dataChannel
- (void)createDataChannel
{
    RTCDataChannelConfiguration *dataChannelConfiguration = [[RTCDataChannelConfiguration alloc] init];
    dataChannelConfiguration.isOrdered = YES;
    _localDataChannel = [_rtcP2PConnection dataChannelForLabel:@"testDataChannel" configuration:dataChannelConfiguration];
    _localDataChannel.delegate = self;
}

//peerConnection约束
- (RTCMediaConstraints *)peerConnectionConstraints
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

//媒体相关约束
- (RTCMediaConstraints *)localVideoConstraints
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsMaxWidth:@"640",kRTCMediaConstraintsMinWidth:@"640",kRTCMediaConstraintsMaxHeight:@"480",kRTCMediaConstraintsMinHeight:@"480",kRTCMediaConstraintsMinFrameRate:@"15"} optionalConstraints:nil];
    return constraints;
}

//sdp约束
- (RTCMediaConstraints *)SDPConstraints{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

#pragma mark - websocket delegate

//连接成功
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    NSLog(@"websocket连接成功");
    [self sendUserId];
}

//连接失败
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@"websocket连接失败 error : %@",error);
}

//连接断开
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    NSLog(@"websocket连接断开 reason:%@",reason);
    NSLog(@"websocket close code : %ld",code);
    [self closeWebRTCFoundation];
}

//收到服务端信息
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    NSLog(@"websocket收到服务端信息");
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:nil];
    NSString *eventName = dic[@"eventName"];
    NSDictionary *data = dic[@"data"];
    
    if([eventName isEqualToString:@"__sdp"]){
        NSDictionary *sdpDic = data[@"sdp"];
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:sdpDic[@"sdp"]];
        //收到offer
        if([sdpDic[@"type"] isEqualToString:@"offer"]){
                        [self didReceiveOfferSDP:sdp userId:data[@"userId"]];
        }
        //收到answer
        else if([sdpDic[@"type"] isEqualToString:@"answer"]){
            [self didReceiveAnswerSDP:sdp userId:data[@"userId"]];
        }
        else{
            //提示收到为定义消息
        }
    }else if([eventName isEqualToString:@"__ice_candidate"]){
        NSString *sdpMid = (NSString *)data[@"id"];
        int sdpMlineIndex = ((NSNumber *)data[@"label"]).intValue;
        NSString *candidateSdp = data[@"candidate"];
        RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:candidateSdp sdpMLineIndex:sdpMlineIndex sdpMid:sdpMid];
        [self didReceiveICECandidate:candidate];
    }else if([eventName isEqualToString:@"__busy"]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"对方正在通话中..." delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - webrtc connection delegate

//从stun服务器获取到iceCandidate
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate{
    
    [self sendICECandidate:candidate withUserId:_connectingUserId];
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    NSLog(@"%s",__func__);
}

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged
{
    NSLog(@"%s",__func__);
    NSLog(@"stateChanged %ld", (long)stateChanged);
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld", (long)newState);
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld", (long)newState);
    //断开peerconection
    if (newState == RTCIceConnectionStateDisconnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
        
            [self closeWebRTCFoundation];
        });
    }
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
    NSLog(@"%s",__func__);
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel

{
    NSLog(@"%s",__func__);
    NSLog(@"channel.state %ld",(long)dataChannel.readyState);
    _remoteDataChannel = dataChannel;
    _remoteDataChannel.delegate = self;
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream
{
    NSLog(@"%s",__func__);
    
    _remoteRTCStream = stream;
    dispatch_async(dispatch_get_main_queue(), ^{
    
    });
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    
}


#pragma mark - webrtc datechannel delegate
/** The data channel state changed. */
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel
{
    NSLog(@"%s",__func__);
    NSLog(@"channel.state %ld",(long)dataChannel.readyState);
}

/** The data channel successfully received a data buffer. */
- (void)dataChannel:(RTCDataChannel *)dataChannel didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer
{
    NSLog(@"%s",__func__);
    NSString *message = [[NSString alloc] initWithData:buffer.data encoding:NSUTF8StringEncoding];
    NSLog(@"message:%@",message);
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
    
}
@end




















