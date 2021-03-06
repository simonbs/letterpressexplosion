//
//  UIView+CoreAnimation.h
//  CoreAnimationPlayGround
//
//  Created by Daniel Tavares on 27/03/2013.
//  Copyright (c) 2013 Daniel Tavares. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Explode)

- (void)lp_explode;
- (void)lp_explode:(void(^)(void))completion;
- (void)lp_explodeWithRows:(NSUInteger)rows columns:(NSUInteger)columns speed:(CGFloat)speed completion:(void(^)(void))completion;

@end
