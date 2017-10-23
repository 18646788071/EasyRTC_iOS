//
//  UIView+Toast.m
//  EasyRTC
//
//  Created by David on 2017/10/13.
//  Copyright © 2017年 David. All rights reserved.
//

#import "UIView+Toast.h"
#import "AppDelegate.h"
#import <objc/runtime.h>

@implementation UIView (Toast)

const void *kToastWindowKey = "kToastWindowKey";
+ (void)showToastWithMessage:(NSString *)message{
    __weak AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    UIWindow *lastWindow = objc_getAssociatedObject(delegate, kToastWindowKey);
    if(lastWindow){
        objc_setAssociatedObject(delegate, kToastWindowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIView *alertView = [[UIView alloc] init];
    alertView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    alertView.opaque = NO;
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:15.0],NSForegroundColorAttributeName:[UIColor whiteColor]};
    NSStringDrawingOptions opt = NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine;
    label.attributedText = [[NSAttributedString alloc] initWithString:message attributes:attributes];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = [label.text boundingRectWithSize:CGSizeMake(300, 300) options:opt attributes:attributes context:nil];
    CGRect frame = label.frame;
    frame.size.height += 15;
    frame.size.width += 25;
    alertView.frame = frame;
    label.center = alertView.center;
    alertView.layer.cornerRadius = alertView.frame.size.height*1/4;
    alertView.alpha = 0.8;
    [alertView addSubview:label];
    
    
    CGFloat windowWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat windowHeight = [[UIScreen mainScreen] bounds].size.height;
    frame = CGRectMake(windowWidth/2-frame.size.width/2, windowHeight/2, frame.size.width, frame.size.height);
    

    UIWindow *toastWindow = [[UIWindow alloc] initWithFrame:frame];
    toastWindow.hidden = NO;
    toastWindow.windowLevel = UIWindowLevelAlert;
    
    objc_setAssociatedObject(delegate, kToastWindowKey, toastWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    //显示
    [toastWindow addSubview:alertView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.5 animations:^{
            alertView.alpha = 0;
        } completion:^(BOOL finished) {
            if(finished){
                objc_setAssociatedObject(delegate, kToastWindowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }];
    });
    
}
@end
