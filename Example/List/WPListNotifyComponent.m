//
//  WPListNotifyComponent.m
//  Expecta
//
//  Created by steve wu on 2022/1/23.
//

#import "WPListNotifyComponent.h"
#import <Protocol/WPListNotify.h>
#import <WPInjection/WPInjectionComponent.h>
#import <Protocol/WPLiveViewController.h>

@interface WPListNotifyComponent ()
<
WPListNotify,
WPInjectionComponent
>

@property (nonatomic, strong) id<WPLazy, WPLiveViewController> vc;

@end

@implementation WPListNotifyComponent

+ (Protocol *)instanceProtocolForInject {
    return @protocol(WPListNotify);
}

- (void)dealloc {
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)showNotify {
    NSLog(@"WPListNotifyComponent %@ showNotify", self);
    __weak typeof(self) weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weak_self.vc pushVC];
    });
}

@end
