//
//  WPLayerDoctor.h
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import <Foundation/Foundation.h>
#import "WPInjectionExtension.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString const * WPInjectionLayerIdentifier;

typedef NSDictionary<WPInjectionLayerIdentifier, NSArray<WPInjectionLayerIdentifier> *>* WPInjectionLayerConfig;

@interface WPLayerDoctor : NSObject
<
WPInjectionExtension
>

@property (nonatomic, strong) WPInjectionLayerConfig layerConfig;

@property (nonatomic, strong) NSDictionary<NSString *, WPInjectionLayerIdentifier> *layerMapping;

@end

NS_ASSUME_NONNULL_END
