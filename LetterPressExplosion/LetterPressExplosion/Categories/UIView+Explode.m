//
//  UIView+CoreAnimation.m
//  CoreAnimationPlayGround
//
//  Created by Daniel Tavares on 27/03/2013.
//  Copyright (c) 2013 Daniel Tavares. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "UIView+Explode.h"

@interface LPParticleLayer : CALayer
@property (nonatomic, strong) UIBezierPath *particlePath;
@end

@implementation LPParticleLayer

- (void)dealloc {
    self.particlePath = nil;
}

@end

@interface UIView (ExplodePrivate)
@property (nonatomic, assign) NSUInteger totalPieces;
@property (nonatomic, assign) NSUInteger pieceCount;
@property (nonatomic, strong) void(^completionHandler)(void);
@end

@implementation UIView (Explode)

float randomFloat()
{
    return (float)rand()/(float)RAND_MAX;
}

- (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (void)lp_explode
{
    [self lp_explode:nil];
}

- (void)lp_explode:(void (^)(void))completion
{
    [self lp_explodeWithRows:5 columns:5 speed:2.35f completion:completion];
}

- (void)lp_explodeWithRows:(NSUInteger)rows columns:(NSUInteger)columns speed:(CGFloat)speed completion:(void (^)(void))completion
{
    self.totalPieces = columns * rows;
    self.pieceCount = 0;
    self.completionHandler = completion;
    
    float width = self.frame.size.width / columns;
    float height = self.frame.size.height / rows;
    CGSize imageSize = CGSizeMake(width, height);
    
    CGFloat columnsCount = self.frame.size.width / imageSize.width;
    CGFloat rowsCount = self.frame.size.height / imageSize.height;
    
    int fullColumns = floorf(columnsCount);
    int fullRows = floorf(rowsCount);
    
    CGFloat remainderWidth = self.frame.size.width  - (fullColumns * imageSize.width);
    CGFloat remainderHeight = self.frame.size.height - (fullRows * imageSize.height );
    
    
    if (columnsCount > fullColumns) fullColumns++;
    if (rowsCount > fullRows) fullRows++;
    
    CGRect originalFrame = self.layer.frame;
    CGRect originalBounds = self.layer.bounds;
    
   
    CGImageRef fullImage = [self imageFromLayer:self.layer].CGImage;
    
    //if its an image, set it to nil
    if ([self isKindOfClass:[UIImageView class]])
    {
        [(UIImageView*)self setImage:nil];
    }
    
    [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    for (int y = 0; y < fullRows; ++y)
    {
        for (int x = 0; x < fullColumns; ++x)
        {
            CGSize tileSize = imageSize;
            
            if (x + 1 == fullColumns && remainderWidth > 0)
            {
                // Last column
                tileSize.width = remainderWidth;
            }
            if (y + 1 == fullRows && remainderHeight > 0)
            {
                // Last row
                tileSize.height = remainderHeight;
            }
            
            CGRect layerRect = (CGRect){{x*imageSize.width, y*imageSize.height},
                tileSize};
            
            CGImageRef tileImage = CGImageCreateWithImageInRect(fullImage,layerRect);
            
            LPParticleLayer *layer = [LPParticleLayer layer];
            layer.frame = layerRect;
            layer.contents = (__bridge id)(tileImage);
            layer.borderWidth = 0.0f;
            layer.borderColor = [UIColor blackColor].CGColor;
            layer.particlePath = [self pathForLayer:layer parentRect:originalFrame];
            [self.layer addSublayer:layer];
            
            CGImageRelease(tileImage);
        }
    }
    
    [self.layer setFrame:originalFrame];
    [self.layer setBounds:originalBounds];

    
    self.layer.backgroundColor = [UIColor clearColor].CGColor;
    
    NSArray *sublayersArray = [self.layer sublayers];
    [sublayersArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        LPParticleLayer *layer = (LPParticleLayer *)obj;
        
        //Path
        CAKeyframeAnimation *moveAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        moveAnim.path = layer.particlePath.CGPath;
        moveAnim.removedOnCompletion = YES;
        moveAnim.fillMode=kCAFillModeForwards;
        NSArray *timingFunctions = [NSArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],nil];
        [moveAnim setTimingFunctions:timingFunctions];
        
        float r = randomFloat();

        NSTimeInterval duration = speed * r;
        
        CAKeyframeAnimation *transformAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        
        CATransform3D startingScale = layer.transform;
        CATransform3D endingScale = CATransform3DConcat(CATransform3DMakeScale(randomFloat(), randomFloat(), randomFloat()), CATransform3DMakeRotation(M_PI*(1+randomFloat()), randomFloat(), randomFloat(), randomFloat()));
        
        NSArray *boundsValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:startingScale],
                                 
                                 [NSValue valueWithCATransform3D:endingScale], nil];
        [transformAnim setValues:boundsValues];
        
        NSArray *times = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                          [NSNumber numberWithFloat:duration*.25], nil];
        [transformAnim setKeyTimes:times];
        
        
        timingFunctions = [NSArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                    nil];
        [transformAnim setTimingFunctions:timingFunctions];
        transformAnim.fillMode = kCAFillModeForwards;
        transformAnim.removedOnCompletion = NO;
        
        //alpha
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnim.fromValue = [NSNumber numberWithFloat:1.0f];
        opacityAnim.toValue = [NSNumber numberWithFloat:0.f];
        opacityAnim.removedOnCompletion = NO;
        opacityAnim.fillMode =kCAFillModeForwards;
        
        CAAnimationGroup *animGroup = [CAAnimationGroup animation];
        animGroup.animations = [NSArray arrayWithObjects:moveAnim,transformAnim,opacityAnim, nil];
        animGroup.duration = duration;
        animGroup.fillMode =kCAFillModeForwards;
        animGroup.delegate = self;
        [animGroup setValue:layer forKey:@"animationLayer"];
        [animGroup setValue:@"explosion" forKey:@"identifier"];
        [layer addAnimation:animGroup forKey:nil];
        
        //take it off screen
        [layer setPosition:CGPointMake(0, -600)];
    }];
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if ([[theAnimation valueForKey:@"identifier"] isEqualToString:@"explosion"])
    {
        LPParticleLayer *layer = [theAnimation valueForKey:@"animationLayer"];
        if (layer)
        {
            [layer removeFromSuperlayer];
        }

        self.pieceCount++;
        
        if (self.pieceCount == self.totalPieces)
        {
            [self cleanTotalPieces];
            [self cleanPieceCount];
            
            if (self.completionHandler)
            {
                self.completionHandler();
                self.completionHandler = nil;
            }
        }
    }
}

-(UIBezierPath *)pathForLayer:(CALayer *)layer parentRect:(CGRect)rect
{
    UIBezierPath *particlePath = [UIBezierPath bezierPath];
    [particlePath moveToPoint:layer.position];
    
    float r = ((float)rand()/(float)RAND_MAX) + 0.3f;
    float r2 = ((float)rand()/(float)RAND_MAX)+ 0.4f;
    float r3 = r*r2;
    
    int upOrDown = (r <= 0.5) ? 1 : -1;
    
    CGPoint curvePoint = CGPointZero;
    CGPoint endPoint = CGPointZero;
    
    float maxLeftRightShift = 1.f * randomFloat();
    
    CGFloat layerYPosAndHeight = (self.superview.frame.size.height-((layer.position.y+layer.frame.size.height)))*randomFloat();
    CGFloat layerXPosAndHeight = (self.superview.frame.size.width-((layer.position.x+layer.frame.size.width)))*r3;
    
    float endY = self.superview.frame.size.height-self.frame.origin.y;
    
    if (layer.position.x <= rect.size.width*0.5)
    {
        //going left
        endPoint = CGPointMake(-layerXPosAndHeight, endY);
        curvePoint= CGPointMake((((layer.position.x*0.5)*r3)*upOrDown)*maxLeftRightShift,-layerYPosAndHeight);
    }
    else
    {
        endPoint = CGPointMake(layerXPosAndHeight, endY);
        curvePoint= CGPointMake((((layer.position.x*0.5)*r3)*upOrDown+rect.size.width)*maxLeftRightShift, -layerYPosAndHeight);
    }
    
    [particlePath addQuadCurveToPoint:endPoint
                     controlPoint:curvePoint];
    
    return particlePath;
}

- (void)setTotalPieces:(NSUInteger)totalPieces {
    objc_setAssociatedObject(self, @selector(totalPieces), @(totalPieces), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)totalPieces {
    return [objc_getAssociatedObject(self, @selector(totalPieces)) unsignedIntegerValue];
}

- (void)setPieceCount:(NSUInteger)pieceCount {
    objc_setAssociatedObject(self, @selector(pieceCount), @(pieceCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)pieceCount {
    return [objc_getAssociatedObject(self, @selector(pieceCount)) unsignedIntegerValue];
}

- (void)setCompletionHandler:(void (^)(void))completionHandler {
    objc_setAssociatedObject(self, @selector(completionHandler), completionHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void(^)(void))completionHandler {
    return objc_getAssociatedObject(self, @selector(completionHandler));
}

- (void)cleanTotalPieces {
    objc_setAssociatedObject(self, @selector(totalPieces), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cleanPieceCount {
    objc_setAssociatedObject(self, @selector(pieceCount), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
