//
//  WPInjectionComponent.h
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于描述一个需要懒加载的属性
/// @property (nonatomic, strong) id<WPLazy, WPService> service;
@protocol WPLazy
@end

@protocol WPInjectionComponent <NSObject>

@optional
/// 实例对外提供的能力协议名称, 不实现的话，会用类名(这样就不会对外提供服务)
+ (Protocol *)instanceProtocolForInject;

/// 实例不想被注入的属性名称
+ (NSArray<NSString *> *)instanceInjectIgnoredIvars;

/// 注入依赖失败
- (void)instanceInjectDependencyDidFailed:(NSError *)error;

/// 注入依赖完成
- (void)instanceDidFinishInjectDependencies;

@end

NS_ASSUME_NONNULL_END
