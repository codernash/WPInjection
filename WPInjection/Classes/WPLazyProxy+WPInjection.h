//
//  WPLazyProxy+WPInjection.h
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPLazyProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface WPLazyProxy (WPInjection)

- (NSString *)wp_cacheKey;

- (BOOL)wp_targetHasIvar:(NSString *)ivarName;

- (NSDictionary<NSString *,NSArray<Protocol *> *> *)wp_ivarForProtocols;

- (void)wp_injectDependency:(WPLazyProxy *)dependency
                forIvarName:(NSString *)ivarName;

@end

NS_ASSUME_NONNULL_END
