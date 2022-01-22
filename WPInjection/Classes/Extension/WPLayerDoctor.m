//
//  WPLayerDoctor.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPLayerDoctor.h"

@implementation WPLayerDoctor

- (void)willResolveAll {}

- (void)didResolveComponent:(WPLazyProxy<WPInjectionComponent> *)component
              andDependency:(WPLazyProxy<WPInjectionComponent> *)dependency {
    WPInjectionLayerIdentifier hostLayer = [_layerMapping objectForKey:NSStringFromClass(component.targetClass)];
    WPInjectionLayerIdentifier depLayer = [_layerMapping objectForKey:NSStringFromClass(dependency.targetClass)];
    if (_layerConfig == nil) {
        // 如果没设置层级管理配置项，则不强制判断
        return;
    }
    if ([hostLayer isEqual:depLayer]) {
        // 同层依赖是允许的
        return;
    }
    
    NSArray<WPInjectionLayerIdentifier> *deps = [_layerConfig objectForKey:hostLayer];
    if (![deps containsObject:depLayer]) {
        NSAssert(NO, @"WPLayerDoctor 发现存在不合理的层级依赖 %@ 依赖了 %@，层级为 %@ 依赖 %@", component.target, dependency.target, hostLayer, depLayer);
    }
}

- (void)didResolveAll {}

@end
