//
//  WPLazyProxy+WPInjection.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPLazyProxy+WPInjection.h"
#import "WPInjectionComponent.h"
#import <objc/message.h>
#import <objc/runtime.h>

@implementation WPLazyProxy (WPInjection)

- (NSString *)wp_cacheKey {
    NSString *cacheKey;
    if (self.protocol) {
        cacheKey = NSStringFromProtocol(self.protocol);
    } else {
        cacheKey = NSStringFromClass(self.targetClass);
    }
    return cacheKey;
}

- (BOOL)wp_targetHasIvar:(NSString *)ivarName {
    @autoreleasepool {
        unsigned count = 0;
        BOOL flg = NO;
        Ivar *ivarList = class_copyIvarList(self.targetClass, &count);
        for (int i = 0; i < count; i++) {
            @autoreleasepool {
                Ivar ivar = ivarList[i];
                NSString *ivarStr = [NSString stringWithUTF8String:ivar_getName(ivar)];
                if ([ivarStr isEqualToString:ivarName]) {
                    flg = YES;
                    break;
                }
            }
        }
        free(ivarList);
        return flg;
    }
}

- (BOOL)wp_injectShouldIgnoreIvar:(NSString *)aIvarName {
    NSArray<NSString *> *ignoredIvar = @[];
    if ([self.targetClass respondsToSelector:@selector(instanceInjectIgnoredIvars)]) {
        ignoredIvar = [(id<WPInjectionComponent>)self.targetClass instanceInjectIgnoredIvars];
    }
    if (ignoredIvar.count == 0) {
        return NO;
    }
    for (NSString *ivarName in ignoredIvar) {
        @autoreleasepool {
            if ([ivarName isEqualToString:aIvarName]) {
                return YES;
            }
            if ([[NSString stringWithFormat:@"_%@", ivarName] isEqualToString:aIvarName]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSDictionary<NSString *,NSArray<Protocol *> *> *)wp_ivarForProtocols {
    NSMutableDictionary<NSString *,NSArray<Protocol *> *> *ivars = [NSMutableDictionary dictionary];
    unsigned count = 0;
    Ivar *ivarList = class_copyIvarList(self.targetClass, &count);
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
            Ivar ivar = ivarList[i];
            NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
            if ([self wp_injectShouldIgnoreIvar:ivarName]) {
                continue;
            }
            
            NSString *typeName = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];

            NSScanner *scanner = [NSScanner scannerWithString:typeName];
            NSMutableArray<Protocol *> *protocols = [NSMutableArray array];
            [scanner scanUpToString:@"<" intoString:NULL];
            while ([scanner scanString:@"<" intoString:NULL]) {
                NSString *pA = nil;
                [scanner scanUpToString:@">" intoString:&pA];
                @autoreleasepool {
                    Protocol *protocol = NSProtocolFromString(pA);
                    if (protocol) {
                        [protocols addObject:protocol];
                    }
                }
                [scanner scanString:@">" intoString:NULL];
            }

            if (protocols.count > 0) {
                [ivars setObject:protocols forKey:ivarName];
            }
        }
    }
    free(ivarList);
    return [ivars copy];
}

- (void)wp_injectDependency:(WPLazyProxy *)dependency
                forIvarName:(NSString *)ivarName {
    [self.target setValue:dependency forKey:ivarName];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"WPProxy :%p target:%@", self,  self.targetClass];
}

@end
