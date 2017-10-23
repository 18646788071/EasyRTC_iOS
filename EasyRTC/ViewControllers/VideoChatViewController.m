//
//  VideoChatViewController.m
//  EasyRTC
//
//  Created by David on 2017/10/12.
//  Copyright © 2017年 David. All rights reserved.
//

#import "VideoChatViewController.h"
#import "EasyRTCManager.h"

@interface VideoChatViewController ()

@end

@implementation VideoChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[EasyRTCManager sharedManager] creatRTCP2PConnection];
    [[EasyRTCManager sharedManager] connectToFriendWithUserId:self.userId];
}

- (IBAction)clickBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    [[EasyRTCManager sharedManager] closeP2PConnect];
}


@end
