//
//  WPVCLifeCycle.h
//  List
//
//  Created by steve wu on 2022/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WPVCLifeCycle <NSObject>

@optional

- (void)componentDidLoad;

- (void)componentWillAppear:(BOOL)animated;

- (void)componentDidAppear:(BOOL)animated;

- (void)componentWillDisappear:(BOOL)animated;

- (void)componentDidDisappear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
