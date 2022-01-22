//
//  WPLiveViewController.m
//  WPInjection_Example
//
//  Created by steve wu on 2022/1/25.
//  Copyright © 2022 stevepeng13. All rights reserved.
//

#import "WPLiveViewController.h"
#import <WPInjection/WPInjection.h>
#import <WPInjection/WPLayerDoctor.h>
#import <WPInjection/WPLoopDoctor.h>
#import <Protocol/WPListPYMK.h>
#import <Protocol/WPLiveViewController.h>
#import <Protocol/WPVCLifeCycle.h>

@interface WPLiveViewController ()
<
WPLiveViewController,
WPInjectionComponent
>

@property (nonatomic, strong) WPInjection<WPVCLifeCycle> *injection;

//@property (nonatomic, strong) id<WPListPYMK> pymk;

@end

@implementation WPLiveViewController

- (void)dealloc {
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.injection = [[WPInjection<WPVCLifeCycle> alloc] initWithClazzes:@[
            @"WPListInitializeComponent",
            @"WPListNotifyComponent",
            @"WPListPYMKComponent",
        ]];
        
        [self.injection installComponent:self
                             forProtocol:@protocol(WPLiveViewController)];
        
        WPLayerDoctor *layer = [[WPLayerDoctor alloc] init];
        
        // layer 层级配置就是字符串的映射，这里RD可以自定义实现方式
        layer.layerConfig = @{
            @"bizLayer" : @[@"layoutLayer", @"baseLayer"],
            @"layoutLayer" : @[@"baseLayer"]
        };
        // 这里表示每个组件所对应的layer层级
        layer.layerMapping = @{
            @"WPLiveViewController" : @"bizLayer",
            @"WPListInitializeComponent" : @"bizLayer",
            @"WPListNotifyComponent" : @"bizLayer",
            @"WPListPYMKComponent" : @"bizLayer",
        };
        
        self.injection.extensions = @[
            layer,
            [[WPLoopDoctor alloc] init],
        ];
        
        [self.injection resolveDependencies];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.pymk showPYMK];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.injection componentDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.injection componentWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.injection componentDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.injection componentWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.injection componentDidDisappear:animated];
}

- (void)pushVC {
    NSLog(@"WPLiveViewController Did Push VC");
}

@end
