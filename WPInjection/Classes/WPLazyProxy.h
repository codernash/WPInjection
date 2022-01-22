//
//  WPLazyProxy.h
//  WPInjection
//
//  Created by steve wu on 2022/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WPLazyProxyDelegate <NSObject>

- (id)lazyInstanceForProtocol:(Protocol *)targetProtocol;

- (void)lazyInstanceDidInject;

@end

@interface WPLazyProxy : NSObject

@property (nonatomic, strong) Class targetClass;

@property (nonatomic, weak) id<WPLazyProxyDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

/// 如果没有传入target 对象，代表需要被懒加载实例
/// @param target target description
/// @param protocol protocol description
+ (instancetype)proxyWithTarget:(nullable id)target
                       protocol:(nullable Protocol *)protocol;

- (id)target;

@end

NS_ASSUME_NONNULL_END
