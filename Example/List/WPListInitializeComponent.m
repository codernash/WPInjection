//
//  WPListInitializeComponent.m
//  List
//
//  Created by steve wu on 2022/1/25.
//

#import "WPListInitializeComponent.h"
#import <Protocol/WPListPYMK.h>
#import <WPInjection/WPInjectionComponent.h>
#import <Protocol/WPVCLifeCycle.h>

@interface WPListInitializeComponent ()
<
WPVCLifeCycle,
WPInjectionComponent
>

@property (nonatomic, strong) id<WPListPYMK> pymk;

@end

@implementation WPListInitializeComponent

- (void)componentDidLoad {
    __weak typeof(self) weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weak_self.pymk showPYMK];
    });
}

@end
