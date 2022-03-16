//
//  WPInjectionExtension.h
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import <Foundation/Foundation.h>
#import "WPInjectionComponent.h"
#import "WPLazyProxy.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WPInjectionExtension <NSObject>

- (void)willResolveAll;

- (void)didResolveComponent:(WPLazyProxy<WPInjectionComponent> *)component
              andDependency:(WPLazyProxy<WPInjectionComponent> *)dependency;

- (void)didResolveAll;

@end

NS_ASSUME_NONNULL_END
