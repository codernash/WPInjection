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

- (void)lazyInstanceShouldInjectForProxy:(WPLazyProxy *)pxy;

@end

typedef NS_ENUM(NSInteger, WPLazyProxyStatus) {
    WPLazyProxyStatusShouldResolve = 0,
    WPLazyProxyStatusDidResolved,
};

@interface WPLazyProxy : NSObject

@property (nonatomic, assign) WPLazyProxyStatus status;

@property (nonatomic, weak) id target;

@property (nonatomic, weak) id<WPLazyProxyDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)proxyWithClz:(Class)clz
                    protocol:(nullable Protocol *)protocol;

- (Class)targetClass;

- (Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
