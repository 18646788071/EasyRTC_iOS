//
//  ViewController.m
//  EasyRTC
//
//  Created by David on 2017/10/10.
//  Copyright © 2017年 David. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"enter"]){
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *token = [userDefaults objectForKey:@"token"];
//        if(!token){
//            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            UIViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
//            [self presentViewController:loginController animated:YES completion:^{
//
//            }];
//        }
    }
}
@end
