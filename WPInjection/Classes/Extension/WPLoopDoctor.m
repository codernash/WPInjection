//
//  WPLoopDoctor.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPLoopDoctor.h"

@interface WPLoopDoctor ()

@property (nonatomic, strong) NSMapTable<id,NSHashTable<id> *> *loopDetective;

@property (nonatomic, strong) dispatch_queue_t analyzeQ;

@end

@implementation WPLoopDoctor

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *name = [NSString stringWithFormat:@"WPLoopDoctor_%p", self];
        _analyzeQ = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
        _loopDetective = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)willResolveAll {
    dispatch_async(_analyzeQ, ^{    
        [self.loopDetective removeAllObjects];
    });
}

- (void)didResolveComponent:(WPLazyProxy<WPInjectionComponent> *)component
              andDependency:(WPLazyProxy<WPInjectionComponent> *)dependency {
    dispatch_async(_analyzeQ, ^{
        NSHashTable *deps = [self.loopDetective objectForKey:component];
        if (deps == nil) {
            deps = [NSHashTable weakObjectsHashTable];
            [self.loopDetective setObject:deps forKey:component];
        }
        [deps addObject:dependency];
        
        {
            NSHashTable *depNodeForDep = [self.loopDetective objectForKey:dependency];
            if (depNodeForDep == nil) {
                depNodeForDep = [NSHashTable weakObjectsHashTable];
                [self.loopDetective setObject:depNodeForDep forKey:dependency];
            }
        }
    });
}

- (void)didResolveAll {
    dispatch_async(_analyzeQ, ^{
        [self _analyse];
    });
}

- (void)_analyse {
    NSHashTable *minDep = [NSHashTable weakObjectsHashTable];
    do {
        [minDep removeAllObjects];
        for (id key in [self.loopDetective keyEnumerator]) {
            NSHashTable *deps = [self.loopDetective objectForKey:key];
            if (deps.count == 0) {
                [minDep addObject:key];
            }
        }
        
        for (id depKey in [minDep objectEnumerator]) {
            for (id aKey in [self.loopDetective keyEnumerator]) {
                NSHashTable *aDeps = [self.loopDetective objectForKey:aKey];
                [aDeps removeObject:depKey];
            }
        }
        
        for (id clearKey in [minDep objectEnumerator]) {
            [self.loopDetective removeObjectForKey:clearKey];
        }
    } while (minDep.count > 0);
    
    if (self.loopDetective.count != 0) {
        NSAssert(NO, @"WPLoopDoctor 实例之间存在环形依赖, 建议拆分组件 %@", self.loopDetective);
    }
}

@end
