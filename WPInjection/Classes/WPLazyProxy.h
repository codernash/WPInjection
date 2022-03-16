//
//  WPLazyProxy.h
//  WPInjection
//
//  Created by steve wu on 2022/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WPLazyProxy;

@protocol WPLazyProxyDelegate <NSObject>

- (void)shouldLazyLoadForProxy:(WPLazyProxy *)proxy;

@end

@interface WPLazyProxy : NSObject

@property (nonatomic, weak) id<WPLazyProxyDelegate> delegate;

@property (nonatomic, weak) id target;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)proxyWithClz:(Class)clz
                    protocol:(nullable Protocol *)protocol;

- (Class)targetClass;

- (Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
