//
//  WPViewController.m
//  WPInjection
//
//  Created by stevepeng13 on 01/23/2022.
//  Copyright (c) 2022 stevepeng13. All rights reserved.
//

#import "WPViewController.h"
#import "WPLiveViewController.h"

@interface WPViewController ()

@end

@implementation WPViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    WPLiveViewController *vc = [[WPLiveViewController alloc] init];
    vc.title = @"Live";
    [self.navigationController pushViewController:vc animated:YES];
}

@end
