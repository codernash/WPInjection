//
//  WPLoopDoctor.m
//  WPInjection
//
//  Created by steve wu on 2022/1/23.
//

#import "WPLoopDoctor.h"

@interface NSMutableArray (WPLoopDoctor)

@end

@implementation NSMutableArray (WPLoopDoctor)

- (void)wpld_offer:(id)object {
    if (object == nil) return;
    [self addObject:object];
}

- (id)wpld_poll {
    id obj = [self objectAtIndex:0];
    [self removeObject:obj];
    return obj;
}

@end

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
        NSEnumerator *loopEnum = [self.loopDetective keyEnumerator];
        id item;
        while (item = [loopEnum nextObject]) {
            @autoreleasepool {
                [self _analyseFrom:item];
            }
        }
    });
}

- (void)_analyseFrom:(id)start {
    NSMutableArray *visited = [NSMutableArray array];
    NSMutableArray *queue = [NSMutableArray array];
    [queue wpld_offer:start];
    while (queue.count != 0) {
        id item = [queue wpld_poll];
        if (![visited containsObject:item]) {
            [visited addObject:item];
            NSEnumerator *neighbours = [[self.loopDetective objectForKey:item] objectEnumerator];
            id neighbour;
            while (neighbour = [neighbours nextObject]) {
                [queue wpld_offer:neighbour];
            }
        } else {
            NSAssert(NO, @"WPLoopDoctor 实例之间存在环形依赖 %@ 循环点为 %@", visited, item);
        }
    }
}

@end
