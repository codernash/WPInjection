//
//  WPListPYMKComponent.m
//  Expecta
//
//  Created by steve wu on 2022/1/23.
//

#import "WPListPYMKComponent.h"
#import <Protocol/WPListNotify.h>
#import <Protocol/WPListPYMK.h>
#import <WPInjection/WPInjectionComponent.h>

@interface WPListPYMKComponent ()
<
WPListPYMK,
WPInjectionComponent
>

@property (nonatomic, strong) id<WPListNotify> notify;

@end

@implementation WPListPYMKComponent

+ (Protocol *)instanceProtocolForInject {
    return @protocol(WPListPYMK);
}

- (void)instanceDidFinishInjectDependencies {
    
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

- (void)showPYMK {
    NSLog(@"WPListPYMKComponent %@ showPYMK", self);
    __weak typeof(self) weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weak_self.notify showNotify];
    });
}

@end
