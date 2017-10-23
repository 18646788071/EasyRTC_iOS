//
//  FriendListCell.m
//  EasyRTC
//
//  Created by David on 2017/10/11.
//  Copyright © 2017年 David. All rights reserved.
//

#import "FriendListCell.h"

@implementation FriendListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if(selected){
        self.selected = NO;
    }
}

@end
