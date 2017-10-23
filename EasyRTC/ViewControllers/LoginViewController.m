//
//  LoginViewController.m
//  EasyRTC
//
//  Created by David on 2017/10/13.
//  Copyright © 2017年 David. All rights reserved.
//

#import "LoginViewController.h"
#import "EasyNetworkManager.h"
#import "UIView+Toast.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)cilckLoginButton:(id)sender {
    if([self.userNameTextField.text isEqualToString:@""]){
        [UIView showToastWithMessage:@"请输入用户名!"];
    }else if([self.passwordTextField.text isEqualToString:@""]){
        [UIView showToastWithMessage:@"请输入密码!"];
    }else{
        [[EasyNetworkManager new] sendLoginMessageWithUserName:self.userNameTextField.text password:self.passwordTextField.text completionHanlder:^(NetworkResultErrorType error, NSData *data) {
            if(!error){
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }else{
                switch (error) {
                    case LoginNoAccountError:
                        [UIView showToastWithMessage:@"账号不存在"];
                        break;
                    case LoginWrongPasswordError:
                        [UIView showToastWithMessage:@"账号或密码不正确"];
                        break;
                    default:
                        break;
                }
            }
        }];
        
    }
    
}



@end
