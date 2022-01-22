//
//  WPInjection.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPInjection.h"
#import <WPDelegates/WPDelegates.h>
#import <WPInjection/WPLazyProxy+WPInjection.h>

@interface _WPInjectionNode : NSObject

@property (nonatomic, strong) WPLazyProxy<WPInjectionComponent> *proxy;

@property (nonatomic, strong) Class clz;

@property (nonatomic, strong) id<WPInjectionComponent> instance;

@property (nonatomic, strong) Protocol *protocol;

@end

@implementation _WPInjectionNode

- (Protocol *)protocol {
    if (!_protocol) {
        if ([_clz respondsToSelector:@selector(instanceProtocolForInject)]) {
            _protocol = [_clz instanceProtocolForInject];
        }
    }
    return _protocol;
}

- (NSString *)cacheKey {
    NSString *cacheKey;
    if (_protocol) {
        cacheKey = NSStringFromProtocol(_protocol);
    } else {
        cacheKey = NSStringFromClass(_clz);
    }
    return cacheKey;
}

@end

@interface WPInjection () <WPLazyProxyDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, _WPInjectionNode *> *nodes;

@property (nonatomic, strong) WPDelegates *delegates;

@end

@implementation WPInjection

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _delegates;
}

- (instancetype)initWithClazzes:(NSArray<NSString *> *)classes
                initializeClass:(NSString *)initializeClass {
    self = [super init];
    if (self) {
        _nodes = [NSMutableDictionary dictionary];
        _delegates = [[WPDelegates alloc] init];
        
        Class initializeClz = NSClassFromString(initializeClass);
        
        if (initializeClz) {
            _WPInjectionNode *node = [[_WPInjectionNode alloc] init];
            node.clz = NSClassFromString(initializeClass);
            node.instance = [[node.clz alloc] init];
            node.proxy = [WPLazyProxy<WPInjectionComponent> proxyWithTarget:node.instance
                                                                   protocol:node.protocol];
            node.proxy.targetClass = node.clz;
            node.proxy.delegate = self;
            [self.delegates addDelegate:node.instance];
            _nodes[[node cacheKey]] = node;
        }
        
        NSMutableArray *uniqclasses = [NSMutableArray array];
        [classes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj,
                                             NSUInteger idx,
                                             BOOL * _Nonnull stop) {
            if (![uniqclasses containsObject:obj]) {
                [uniqclasses addObject:obj];
            }
        }];
        
        [uniqclasses enumerateObjectsUsingBlock:^(NSString * _Nonnull clzName,
                                                 NSUInteger idx,
                                                 BOOL * _Nonnull stop) {
            _WPInjectionNode *node = [[_WPInjectionNode alloc] init];
            node.clz = NSClassFromString(clzName);
            if (!initializeClz) {
                node.instance = [[node.clz alloc] init];
            } else {
                node.instance = nil; // 实例化的动作会在懒加载触发时在进行
            }
            node.proxy = [WPLazyProxy<WPInjectionComponent> proxyWithTarget:node.instance
                                                                   protocol:node.protocol];
            node.proxy.targetClass = node.clz;
            node.proxy.delegate = self;
            [self.delegates addDelegate:node.instance];
            self.nodes[[node cacheKey]] = node;
        }];
    }
    return self;
}

- (void)installComponent:(nullable id<WPInjectionComponent>)component
             forProtocol:(nullable Protocol *)protocol {
    _WPInjectionNode *node = [[_WPInjectionNode alloc] init];
    node.clz = component.class;
    node.instance = nil; // 手动注入的实例，容器不持有，否则会有cycle
    node.protocol = protocol;
    node.proxy = [WPLazyProxy<WPInjectionComponent> proxyWithTarget:component
                                                           protocol:node.protocol];
    node.proxy.targetClass = component.class;
    node.proxy.delegate = nil; // 手动注入的依赖，不会自动懒加载
    [self.delegates addDelegate:node.instance];
    self.nodes[[node cacheKey]] = node;
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
    
    [self.nodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                    _WPInjectionNode * _Nonnull obj,
                                                    BOOL * _Nonnull stop) {
        WPLazyProxy<WPInjectionComponent> *proxy = obj.proxy;
        if (proxy.target != nil) {
            NSDictionary<NSString *,NSArray<Protocol *> *> *properties = [proxy wp_ivarForProtocols];
            [properties enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName,
                                                            NSArray<Protocol *> *protocols,
                                                            BOOL *ivarStop) {
                [self _resolveProxy:proxy
                  dependentProtocol:protocols.firstObject
                           ivarName:ivarName];
            }];
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
    WPLazyProxy<WPInjectionComponent> *depProxy = [self.nodes objectForKey:protocolName].proxy;
    
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

- (id)lazyInstanceForProtocol:(Protocol *)targetProtocol {
    _WPInjectionNode *node = [self.nodes objectForKey:NSStringFromProtocol(targetProtocol)];
    node.instance = [[node.clz alloc] init];
    [self.delegates addDelegate:node.instance];
    return node.instance;
}

- (void)lazyInstanceDidInject {
    [self resolveDependencies];
}

@end
