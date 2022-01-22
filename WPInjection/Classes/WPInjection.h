//
//  WPInjection.h
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import <Foundation/Foundation.h>
#import <WPInjection/WPInjectionComponent.h>
#import <WPInjection/WPInjectionExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPInjection : NSObject

/// 开发者可以自定义扩展
@property (nonatomic, strong) NSArray<id<WPInjectionExtension>> *extensions;

- (instancetype)init NS_UNAVAILABLE;

/// 依赖注入初始化方法
/// @param classes 组件的class 列表
/// @param initializeClass 如果要使用懒加载拉起component的能力的话，需要指定initializeClass 作为component集合的拉起入口
- (instancetype)initWithClazzes:(NSArray<NSString *> *)classes
                initializeClass:(nullable NSString *)initializeClass NS_DESIGNATED_INITIALIZER;

/// 手动添加component组件
/// @param component component组件
/// @param protocol component组件提供的服务名称
- (void)installComponent:(nullable id<WPInjectionComponent>)component
             forProtocol:(nullable Protocol *)protocol;

/// 解析依赖，并注入
- (void)resolveDependencies;

@end

NS_ASSUME_NONNULL_END
