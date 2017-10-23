//
//  FrendListViewController.m
//  EasyRTC
//
//  Created by David on 2017/10/11.
//  Copyright © 2017年 David. All rights reserved.
//

#import "FriendListViewController.h"
#import "FriendListCell.h"
#import "EasyRTCManager.h"
#import "VideoChatViewController.h"


#define Server_Host @"127.0.0.1"
#define Server_Port @"8080"
#define UserId 1

//#define Server_Host @"192.168.12.109"
//#define Server_Port @"8080"
//#define UserId 2


@interface FriendListViewController ()
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation FriendListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNavigation];
    [self configTableView];
    [self configWebSocket];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

#pragma mark - initial config
- (void)configNavigation{
    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    self.navigationItem.title = @"好友列表";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:self action:@selector(clickBackButton)];
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)configTableView{
    self.tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
}

- (void)configWebSocket{
    [[EasyRTCManager sharedManager] connectToServer:Server_Host port:Server_Port userId:[NSNumber numberWithLong:UserId]];
}

- (void)clickBackButton{
    [self.navigationController popViewControllerAnimated:YES];
    [[EasyRTCManager sharedManager] closeSocket];
}

#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    VideoChatViewController *controller = [storyBoard instantiateViewControllerWithIdentifier:@"videoChat"];
    controller.userId = [NSNumber numberWithInteger:1];
    [self presentViewController:controller animated:YES completion:^{
        
    }];
}

#pragma mark - tableView dataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FriendListCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"blabla"];
    if(!cell){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FriendListCell" owner:self.tableView options:nil] objectAtIndex:0];
    }
    cell.UserName.text = @"奶奶";
    cell.UserIcon.image = [UIImage imageNamed:@"grandma"];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}



@end
