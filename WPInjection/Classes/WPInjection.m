//
//  WPInjection.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPInjection.h"
#import "WPDelegates.h"
#import "WPLazyProxy+WPInjection.h"

@interface WPInjection ()
<
WPLazyProxyDelegate
>

@property (nonatomic, strong) NSMutableDictionary<NSString *, WPLazyProxy<WPInjectionComponent> *> *proxies;

@property (nonatomic, strong) NSMutableDictionary<NSString *,id> *instances;

@property (nonatomic, strong) WPDelegates *delegates;

@end

@implementation WPInjection

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _delegates;
}

- (instancetype)initWithClazzes:(NSArray<NSString *> *)clazzes {
    self = [super init];
    if (self) {
        _proxies = [NSMutableDictionary dictionary];
        _instances = [NSMutableDictionary dictionary];
        _delegates = [[WPDelegates alloc] init];

        [self _layoutClazzes:clazzes];
    }
    return self;
}

- (void)_layoutClazzes:(NSArray<NSString *> *)clazzes {
    NSMutableArray *uniqClasses = [NSMutableArray array];
    [clazzes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj,
                                          NSUInteger idx,
                                          BOOL * _Nonnull stop) {
        if (![uniqClasses containsObject:obj]) {
            [uniqClasses addObject:obj];
        }
    }];
    
    [uniqClasses enumerateObjectsUsingBlock:^(NSString * _Nonnull clzName,
                                              NSUInteger idx,
                                              BOOL * _Nonnull stop) {
        WPLazyProxy<WPInjectionComponent> *proxy = [WPLazyProxy<WPInjectionComponent>
                                                    proxyWithClz:NSClassFromString(clzName)
                                                    protocol:nil];
        proxy.delegate = self;
        self.proxies[[proxy wp_cacheKey]] = proxy;
    }];
    
    NSMutableArray<NSString *> *lazies = [NSMutableArray array];
    // 找出所有没有被lazy 描述的protocol 然后实例化他们的target
    [self.proxies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                      WPLazyProxy<WPInjectionComponent> * _Nonnull proxy,
                                                      BOOL * _Nonnull stop) {
        NSDictionary<NSString *,NSArray<Protocol *> *> *ivars = [proxy wp_ivarForProtocols];
        [ivars enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName,
                                                   NSArray<Protocol *> *protocols,
                                                   BOOL *ivarStop) {
            if ([protocols containsObject:@protocol(WPLazy)]) {
                __block WPLazyProxy<WPInjectionComponent> *targetProxy = nil;
                [protocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull ptl,
                                                        NSUInteger idx,
                                                        BOOL * _Nonnull stop) {
                    if (ptl != @protocol(WPLazy)) {
                        WPLazyProxy<WPInjectionComponent> *tp = [self.proxies objectForKey:NSStringFromProtocol(ptl)];
                        if (tp != nil) {
                            targetProxy = tp;
                            *stop = YES;
                        }
                    }
                }];
                if (targetProxy && ![lazies containsObject:targetProxy.wp_cacheKey]) {
                    [lazies addObject:targetProxy.wp_cacheKey];
                }
            }
        }];
    }];
    
    [self.proxies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                      WPLazyProxy<WPInjectionComponent> * _Nonnull proxy,
                                                      BOOL * _Nonnull stop) {
        NSDictionary<NSString *,NSArray<Protocol *> *> *ivars = [proxy wp_ivarForProtocols];
        [ivars enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName,
                                                   NSArray<Protocol *> *protocols,
                                                   BOOL *ivarStop) {
            if (![protocols containsObject:@protocol(WPLazy)]) {
                __block WPLazyProxy<WPInjectionComponent> *targetProxy = nil;
                [protocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull ptl,
                                                        NSUInteger idx,
                                                        BOOL * _Nonnull stop) {
                    if (ptl != @protocol(WPLazy)) {
                        WPLazyProxy<WPInjectionComponent> *tp = [self.proxies objectForKey:NSStringFromProtocol(ptl)];
                        if (targetProxy != nil) {
                            targetProxy = tp;
                            *stop = YES;
                        }
                    }
                }];
                if (targetProxy && [lazies containsObject:targetProxy.wp_cacheKey]) {
                    [lazies removeObject:targetProxy.wp_cacheKey];
                }
            }
        }];
    }];
    
    NSMutableArray<NSString *> *allProiesKey = [[self.proxies allKeys] mutableCopy];
    [lazies enumerateObjectsUsingBlock:^(NSString * _Nonnull obj,
                                         NSUInteger idx,
                                         BOOL * _Nonnull stop) {
        [allProiesKey removeObject:obj];
    }];
    
    [allProiesKey enumerateObjectsUsingBlock:^(NSString * _Nonnull cacheKey,
                                               NSUInteger idx,
                                               BOOL * _Nonnull stop) {
        WPLazyProxy<WPInjectionComponent> *targetProxy = [self.proxies objectForKey:cacheKey];
        if (!targetProxy.target) {
            id target = [[targetProxy.targetClass alloc] init];
            targetProxy.target = target;
            [_instances setObject:target
                           forKey:NSStringFromClass(targetProxy.targetClass)];
            [self.delegates addDelegate:targetProxy.target];
        }
    }];
}

- (void)installComponent:(nullable id<WPInjectionComponent>)component
             forProtocol:(nullable Protocol *)protocol {
    WPLazyProxy<WPInjectionComponent> *proxy = [WPLazyProxy<WPInjectionComponent>
                                                proxyWithClz:component.class
                                                protocol:protocol];
    proxy.target = component;
    [self.delegates addDelegate:component];
    self.proxies[[proxy wp_cacheKey]] = proxy;
}

/// 解析依赖
- (void)resolveDependencies {
    if (_extensions != nil && [_extensions isKindOfClass:NSArray.class]) {
        [_extensions enumerateObjectsUsingBlock:^(id<WPInjectionExtension>  _Nonnull obj,
                                                  NSUInteger idx,
                                                  BOOL * _Nonnull stop) {
            [obj willResolveAll];
        }];
    }
    
    // 注入
    [self.proxies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                      WPLazyProxy<WPInjectionComponent> * _Nonnull proxy,
                                                      BOOL * _Nonnull stop) {
        NSDictionary<NSString *,NSArray<Protocol *> *> *ivars = [proxy wp_ivarForProtocols];
        [ivars enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName,
                                                   NSArray<Protocol *> *protocols,
                                                   BOOL *ivarStop) {
            __block Protocol *targetProtocol = nil;
            [protocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull ptl,
                                                    NSUInteger idx,
                                                    BOOL * _Nonnull stop) {
                WPLazyProxy<WPInjectionComponent> *targetProxy = [self.proxies objectForKey:NSStringFromProtocol(ptl)];
                if (targetProxy != nil && ptl != @protocol(WPLazy)) {
                    targetProtocol = ptl;
                }
            }];
            [self _resolveProxy:proxy
              dependentProtocol:targetProtocol
                       ivarName:ivarName];
        }];
    }];
    
    [self.proxies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                      WPLazyProxy<WPInjectionComponent> * _Nonnull proxy,
                                                      BOOL * _Nonnull stop) {
        if (proxy.target) {
            [proxy instanceDidFinishInjectDependencies];
        }
    }];
    
    if (_extensions != nil && [_extensions isKindOfClass:NSArray.class]) {
        [_extensions enumerateObjectsUsingBlock:^(id<WPInjectionExtension>  _Nonnull obj,
                                                  NSUInteger idx,
                                                  BOOL * _Nonnull stop) {
            [obj didResolveAll];
        }];
    }
}

/// 查找属性中声明的协议依赖的Component实现
/// @param proxy 依赖方的代理对象
/// @param depProtocol 依赖方依赖的协议
/// @param ivarName 依赖方声明的属性名称
- (void)_resolveProxy:(WPLazyProxy<WPInjectionComponent> *)proxy
    dependentProtocol:(Protocol *)depProtocol
             ivarName:(NSString *)ivarName {
    NSString *protocolName = NSStringFromProtocol(depProtocol);
    WPLazyProxy<WPInjectionComponent> *depProxy = [self.proxies objectForKey:protocolName];
    
    if (depProxy == nil) {
        NSString *errorString = [NSString stringWithFormat:@"依赖的proxy没找到, \
                                 但是协议是可用的 可能没有注册进来 \
                                 component:%@  \
                                 ivarName:%@ \
                                 协议:%@",
                                 proxy,
                                 ivarName,
                                 NSStringFromProtocol(depProtocol)];
        NSError *error = [NSError errorWithDomain:@"WPLazyProxyManager"
                                             code:1098988
                                         userInfo:@{@"msg":errorString}];
        [proxy instanceInjectDependencyDidFailed:error];
        return;
    }
    
    if (![proxy wp_targetHasIvar:ivarName]) {
        NSString *errorString = [NSString stringWithFormat:@"属性没找到 \
                                 component:%@ \
                                 ivarName:%@ \
                                 协议:%@",
                                 proxy,
                                 ivarName,
                                 NSStringFromProtocol(depProtocol)];
        NSError *error = [NSError errorWithDomain:@"WPLazyProxyManager"
                                             code:1098988
                                         userInfo:@{@"msg":errorString}];
        [proxy instanceInjectDependencyDidFailed:error];
        return;
    }
    
    if (_extensions != nil && [_extensions isKindOfClass:NSArray.class]) {
        [_extensions enumerateObjectsUsingBlock:^(id<WPInjectionExtension>  _Nonnull obj,
                                                  NSUInteger idx,
                                                  BOOL * _Nonnull stop) {
            [obj didResolveComponent:proxy
                       andDependency:depProxy];
        }];
    }
    [proxy wp_injectDependency:depProxy forIvarName:ivarName];
}

- (void)shouldLazyLoadForProxy:(WPLazyProxy *)proxy {
    id target = [self.instances objectForKey:NSStringFromClass(proxy.targetClass)];
    if (target) {
        proxy.target = target;
        return;
    }
    target = [[proxy.targetClass alloc] init];
    proxy.target = target;
    [_instances setObject:target
                   forKey:NSStringFromClass(proxy.targetClass)];
    [self.delegates addDelegate:proxy.target];
    [self resolveDependencies];
}

@end
