//
//  WPLazyProxy.m
//  WPInjection
//
//  Created by steve wu on 2022/1/25.
//

#import "WPLazyProxy.h"
#import <WPInjection/WPInjectionComponent.h>

@interface WPLazyProxy ()

@property (nonatomic, strong) Class targetClass;

@property (nonatomic, strong) Protocol *protocol;

@end

@implementation WPLazyProxy

+ (instancetype)proxyWithClz:(Class)clz
                    protocol:(nullable Protocol *)protocol {
    WPLazyProxy *proxy = [[self alloc] init];
    proxy.targetClass = clz;
    proxy.protocol = protocol;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    if (_target == nil) {
        [_delegate lazyInstanceShouldInjectForProxy:self];
        NSAssert(_target != nil, @"无法获取依赖对象");
        if (_target == nil) {
            return [self.class instanceMethodSignatureForSelector:@selector(_empty)];
        }
    }
    if ([self respondsToSelector:selector]) {
        return [_target methodSignatureForSelector:selector];
    } else {
        return [self.class instanceMethodSignatureForSelector:@selector(_empty)];
    }
}

- (id)_empty { return nil; }

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:_target];
    } else {
        void *null = NULL;
        [invocation setReturnValue:&null];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(WPLazyProxy *)object {
    return [_target isEqual:object.target];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Protocol *)protocol {
    if (!_protocol) {
        if ([_targetClass respondsToSelector:@selector(instanceProtocolForInject)]) {
            _protocol = [_targetClass instanceProtocolForInject];
        }
    }
    return _protocol;
}

@end
