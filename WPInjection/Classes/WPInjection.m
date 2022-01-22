//
//  WPInjection.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPInjection.h"
#import <WPDelegates/WPDelegates.h>
#import <WPInjection/WPLazyProxy+WPInjection.h>

@interface WPInjection () <WPLazyProxyDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, WPLazyProxy<WPInjectionComponent> *> *proxies;

@property (nonatomic, strong) NSMutableArray<id> *instances;

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
        _instances = [NSMutableArray array];
        _delegates = [[WPDelegates alloc] init];
        
        NSMutableArray *uniqclasses = [NSMutableArray array];
        [clazzes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj,
                                              NSUInteger idx,
                                              BOOL * _Nonnull stop) {
            if (![uniqclasses containsObject:obj]) {
                [uniqclasses addObject:obj];
            }
        }];
        
        [uniqclasses enumerateObjectsUsingBlock:^(NSString * _Nonnull clzName,
                                                  NSUInteger idx,
                                                  BOOL * _Nonnull stop) {
            
            WPLazyProxy<WPInjectionComponent> *proxy = [self _installComponentForClass:clzName];
            if (idx == 0) {
                id target = [[proxy.targetClass alloc] init];
                proxy.target = target;
                [_instances addObject:target];
            }
        }];
    }
    return self;
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

- (WPLazyProxy<WPInjectionComponent> *)_installComponentForClass:(NSString *)clzName {
    WPLazyProxy<WPInjectionComponent> *proxy = [WPLazyProxy<WPInjectionComponent>
                                                proxyWithClz:NSClassFromString(clzName)
                                                protocol:nil];
    proxy.delegate = self;
    self.proxies[[proxy wp_cacheKey]] = proxy;
    return proxy;
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
    
    [self.proxies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                      WPLazyProxy<WPInjectionComponent> * _Nonnull proxy,
                                                      BOOL * _Nonnull stop) {
        NSDictionary<NSString *,NSArray<Protocol *> *> *ivars = [proxy wp_ivarForProtocols];
        [ivars enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName,
                                                   NSArray<Protocol *> *protocols,
                                                   BOOL *ivarStop) {
            if (proxy.target != nil) {
                [self.delegates addDelegate:proxy.target];
                [self _resolveProxy:proxy
                  dependentProtocol:protocols.firstObject
                           ivarName:ivarName];
            }
        }];
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

#pragma mark - WPLazyProxyDelegate

- (void)lazyInstanceShouldInjectForProxy:(WPLazyProxy *)pxy {
    id target = [[pxy.targetClass alloc] init];
    pxy.target = target;
    [_instances addObject:target];
    [self resolveDependencies];
}

@end
