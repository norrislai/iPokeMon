//
//  PoketchTabBar.m
//  Pokemon
//
//  Created by Kaijie Yu on 2/1/12.
//  Copyright (c) 2012 Kjuly. All rights reserved.
//

#import "CustomTabBar.h"

#import "GlobalConstants.h"

#import <QuartzCore/QuartzCore.h>


@interface CustomTabBar () {
 @private
  UIImageView      * backgroundImageView_;
  UIImageView      * arrow_;
  CGPoint            newPositionForArrow_;
  CGFloat            currArcForArrow_;
}

@property (nonatomic, retain) UIImageView      * backgroundImageView;
@property (nonatomic, retain) UIImageView      * arrow;
@property (nonatomic, assign) CGPoint            newPositionForArrow;
@property (nonatomic, assign) CGFloat            currArcForArrow;

- (CGFloat)horizontalLocationFor:(NSUInteger)tabIndex;
- (void)addTabBarArrowAtIndex:(NSUInteger)itemIndex;
- (UIImage *)tabBarImage:(UIImage *)startImage size:(CGSize)targetSize backgroundImage:(UIImage *)backgroundImage;
- (UIImage *)blackFilledImageWithWhiteBackgroundUsing:(UIImage *)startImage;
- (UIImage *)tabBarBackgroundImageWithSize:(CGSize)targetSize backgroundImage:(UIImage *)backgroundImage;

- (void)setFrameForButtonsBasedOnItemCount;
- (void)setButtonWithTag:(NSInteger)buttonTag origin:(CGPoint)origin;

// Animation Control methods
- (void)pauseLayer:(CALayer *)layer;
- (void)resumeLayer:(CALayer *)layer;
- (void)moveArrowToNewPosition;

@end


@implementation CustomTabBar

@synthesize buttons = buttons_;
@synthesize previousItemIndex = previousItemIndex_;

@synthesize backgroundImageView = backgroundImageView_;
@synthesize arrow               = arrow_;
@synthesize newPositionForArrow = newPositionForArrow_;
@synthesize currArcForArrow     = currArcForArrow_;

- (void)dealloc {
  self.buttons             = nil;
  self.backgroundImageView = nil;
  self.arrow               = nil;
  [super dealloc];
}


- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
  }
  return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
  // Drawing code
}
*/

- (id)initWithItemCount:(NSUInteger)itemCount
                   size:(CGSize)itemSize
                    tag:(NSInteger)objectTag
               delegate:(NSObject <CustomTabBarDelegate> *)tabBarDelegate {
  if (self = [super init]) {
    // The tag allows callers with multiple controls to distinguish between them
    [self setTag:objectTag];
    
    delegate_ = tabBarDelegate;
    
    // Set background
    UIImageView * backgroundImageView = [UIImageView alloc];
    [backgroundImageView initWithImage:
      [UIImage imageNamed:[NSString stringWithFormat:@"TabView%dTabsCircleBarBackground.png", (NSInteger)itemCount]]];
    [self addSubview:backgroundImageView];
    [backgroundImageView release];
    
    /*
    CAKeyframeAnimation *customFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    NSArray *sizeValues = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0f],
                           [NSNumber numberWithFloat:200.0f],
                           [NSNumber numberWithFloat:100.0f], nil];
    NSArray *times = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:0.0f],
                      [NSNumber numberWithFloat:0.6f],
                      [NSNumber numberWithFloat:0.9f], nil]; 
    NSArray *timingFunctions = [NSArray arrayWithObjects:
                                [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], nil];
    
    [customFrameAnimation setValues:sizeValues];
    [customFrameAnimation setKeyTimes:times];
    
    customFrameAnimation.delegate = self;
    customFrameAnimation.duration=2.0f;
    customFrameAnimation.repeatCount = 1;
//    customFrameAnimation.cumulative = YES;
//    customFrameAnimation.additive = YES;
    customFrameAnimation.fillMode = kCAFillModeForwards;
    customFrameAnimation.timingFunctions = timingFunctions;
    customFrameAnimation.removedOnCompletion = NO;
    [arrow_.layer addAnimation:customFrameAnimation forKey:nil];
     */
    
    // Initalize the array to store buttons
    // And iterate through each item
    buttons_ = [[NSMutableArray alloc] initWithCapacity:itemCount];
    for (NSUInteger i = 0; i < itemCount; ++i) {
      UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
      [button setImage:[delegate_ iconFor:i] forState:UIControlStateNormal];
      
      // Register for touch events
      [button addTarget:self action:@selector(touchDownAction:)     forControlEvents:UIControlEventTouchDown];
      [button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
      [button addTarget:self action:@selector(otherTouchesAction:)  forControlEvents:UIControlEventTouchUpOutside];
      [button addTarget:self action:@selector(otherTouchesAction:)  forControlEvents:UIControlEventTouchDragOutside];
      [button addTarget:self action:@selector(otherTouchesAction:)  forControlEvents:UIControlEventTouchDragInside];
      
      // Add the button to |buttons_| array
      [buttons_ addObject:button];
      [self addSubview:button];
    }
    
    // Set frame for button, based on |itemCount|
    [self setFrameForButtonsBasedOnItemCount];
    
    // Top Circle Arrow
    arrow_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TabViewItemArrow.png"]];
    UIButton * button = [buttons_ objectAtIndex:0];
    [arrow_ setFrame:button.frame];
    [self addSubview:arrow_];
    
    self.newPositionForArrow = CGPointMake(button.frame.origin.x + 22.f, button.frame.origin.y + 22.f);
    self.currArcForArrow = M_PI + asinf((kTabBarHeight - self.newPositionForArrow.y) / (kTabBarHeight - 26.f));
    self.previousItemIndex = 0;
    button = nil;
  }
  
  return self;
}

// Only light the selected button area
- (void)dimAllButtonsExcept:(UIButton *)selectedButton {
  for (UIButton * button in buttons_) {
    if (button == selectedButton) {
      [button setSelected:YES];
      [button setHighlighted:button.selected ? NO : YES];
      [button setTag:kSelectedTabItemTag];
      
      // Generate new postion for |arrow_|
      CGPoint newPosition = button.frame.origin;
      newPosition.x += 22.f;
      newPosition.y += 22.f;
      self.newPositionForArrow = newPosition;
    }
    else {
      [button setSelected:NO];
      [button setHighlighted:NO];
      [button setTag:0];
    }
  }
}

- (void)touchDownAction:(UIButton *)button {
  [self dimAllButtonsExcept:button];
  [self moveArrowToNewPosition];
  
  NSInteger newSelectedItemIndex = [buttons_ indexOfObject:button];
  if ([delegate_ respondsToSelector:@selector(touchDownAtItemAtIndex:withPreviousItemIndex:)])
    [delegate_ touchDownAtItemAtIndex:newSelectedItemIndex withPreviousItemIndex:self.previousItemIndex];
  self.previousItemIndex = newSelectedItemIndex;
}

- (void)touchUpInsideAction:(UIButton *)button {
  [self dimAllButtonsExcept:button];
  
  if ([delegate_ respondsToSelector:@selector(touchUpInsideItemAtIndex:)])
    [delegate_ touchUpInsideItemAtIndex:[buttons_ indexOfObject:button]];
}

- (void)otherTouchesAction:(UIButton*)button {
  [self dimAllButtonsExcept:button];
}

- (void)selectItemAtIndex:(NSInteger)index {
  UIButton * button = [buttons_ objectAtIndex:index];
  [self dimAllButtonsExcept:button];
}

// Get position.x of the selected tab
- (CGFloat)horizontalLocationFor:(NSUInteger)tabIndex {
  UIImageView * tabBarArrow = (UIImageView *)[self viewWithTag:kTabArrowImageTag];
  
  // A single tab item's width is the same as the button's width
  UIButton * button = [buttons_ objectAtIndex:tabIndex];
  CGFloat tabItemWidth = button.frame.size.width;
  
  // A half width is tabItemWidth divided by 2 minus half the width of the arrow
  CGFloat halfTabItemWidth = (tabItemWidth / 2) - (tabBarArrow.frame.size.width / 2);
  
  // The horizontal location is the index times the width plus a half width
  //
  //    __^__
  //   |     |
  //    -----
  //
  return button.frame.origin.x + halfTabItemWidth;
}

// Add TabBar Arrow Image
- (void)addTabBarArrowAtIndex:(NSUInteger)itemIndex {
  UIImageView * tabBarArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TabBarSelectedArrow.png"]];
  [tabBarArrow setTag:kTabArrowImageTag];
  [tabBarArrow setFrame:CGRectMake([self horizontalLocationFor:itemIndex] - 22.f,
                                   0.f,
                                   tabBarArrow.frame.size.width,
                                   tabBarArrow.frame.size.height)];
  [self insertSubview:tabBarArrow atIndex:1];
  [tabBarArrow release];
}

// Create a tab bar image
- (UIImage *)tabBarImage:(UIImage *)startImage
                    size:(CGSize)targetSize
         backgroundImage:(UIImage *)backgroundImageSource {
  UIImage * backgroundImage = [self tabBarBackgroundImageWithSize:startImage.size
                                                  backgroundImage:backgroundImageSource];
  UIImage * bwImage = [self blackFilledImageWithWhiteBackgroundUsing:startImage];
  
  // Create an image mask
  CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(bwImage.CGImage),
                                           CGImageGetHeight(bwImage.CGImage),
                                           CGImageGetBitsPerComponent(bwImage.CGImage),
                                           CGImageGetBitsPerPixel(bwImage.CGImage),
                                           CGImageGetBytesPerRow(bwImage.CGImage),
                                           CGImageGetDataProvider(bwImage.CGImage), NULL, YES);
  
  // Using the mask to create a new image
  CGImageRef tabBarImageRef = CGImageCreateWithMask(backgroundImage.CGImage, imageMask);
  
  UIImage * tabBarImage = [UIImage imageWithCGImage:tabBarImageRef
                                              scale:startImage.scale
                                        orientation:startImage.imageOrientation];
  
  // Cleanup
  CGImageRelease(imageMask);
  CGImageRelease(tabBarImageRef);
  
  ///Create a new context with the right size
  UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.f);
  // Draw the new tab bar image at the center
  [tabBarImage drawInRect:CGRectMake((targetSize.width / 2.f) - (startImage.size.width / 2.f),
                                     (targetSize.height / 2.f) - (startImage.size.height / 2.f),
                                     startImage.size.width,
                                     startImage.size.height)];
  // Generate a new image
  UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return resultImage;
}

// Convert the image's fill color to black and background to white
- (UIImage *)blackFilledImageWithWhiteBackgroundUsing:(UIImage *)startImage {
  // Create the proper sized rect
  CGRect imageRect = CGRectMake(0.f, 0.f, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
  
  // Create a new bitmap context
  CGContextRef context = CGBitmapContextCreate(NULL,
                                               imageRect.size.width,
                                               imageRect.size.height,
                                               8,
                                               0,
                                               CGImageGetColorSpace(startImage.CGImage),
                                               kCGImageAlphaPremultipliedLast);
  
  CGContextSetRGBFillColor(context, 1, 1, 1, 1);
  CGContextFillRect(context, imageRect);
  
  // Use the passed in image as a clipping mask
  CGContextClipToMask(context, imageRect, startImage.CGImage);
  // Set the fill color to black: R:0 G:0 B:0 alpha:1
  CGContextSetRGBFillColor(context, 0, 0, 0, 1);
  // Fill with black
  CGContextFillRect(context, imageRect);
  
  // Generate a new image
  CGImageRef newCGImage = CGBitmapContextCreateImage(context);
  UIImage * newImage = [UIImage imageWithCGImage:newCGImage
                                           scale:startImage.scale
                                     orientation:startImage.imageOrientation];
  
  // Cleanup
  CGContextRelease(context);
  CGImageRelease(newCGImage);
  
  return newImage;
}

- (UIImage *)tabBarBackgroundImageWithSize:(CGSize)targetSize
                           backgroundImage:(UIImage*)backgroundImage {
  UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.f);
  
  if (backgroundImage) {
    // Draw the background image centered
    [backgroundImage drawInRect:CGRectMake((targetSize.width - CGImageGetWidth(backgroundImage.CGImage)) / 2.f,
                                           (targetSize.height - CGImageGetHeight(backgroundImage.CGImage)) / 2.f,
                                           CGImageGetWidth(backgroundImage.CGImage),
                                           CGImageGetHeight(backgroundImage.CGImage))];
  } else {
    [[UIColor lightGrayColor] set];
    UIRectFill(CGRectMake(0.f, 0.f, targetSize.width, targetSize.height));
  }
  
  UIImage * finalBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return finalBackgroundImage;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  CGFloat itemWidth = ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)  ? self.window.frame.size.height : self.window.frame.size.width) / buttons_.count;
  // horizontalOffset tracks the x value
  CGFloat horizontalOffset = 0;
  
  // Iterate through each button
  for (UIButton * button in buttons_) {
    // Set the button's x offset
    button.frame = CGRectMake(horizontalOffset, 0.f, button.frame.size.width, button.frame.size.height);
    horizontalOffset += itemWidth;
  }
  
  // Move the arrow to the new button location
  UIButton * selectedButton = (UIButton *)[self viewWithTag:kSelectedTabItemTag];
  [self dimAllButtonsExcept:selectedButton];
}

#pragma mark - Private Methods

- (void)setFrameForButtonsBasedOnItemCount {
  CGFloat tabAreaHalfHeight      = kTabBarHeight;
  CGFloat tabAreaHalfWidth       = kTabBarWdith  / 2;
  CGFloat buttonRadius           = 22.f;
  CGFloat triangleHypotenuse     = tabAreaHalfHeight - 26.f; // Distance to Ball Center
  
  switch ([self.buttons count]) {
    case 2: {
      CGFloat degree    = M_PI / 4.f; // = 45 * M_PI / 180
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self setButtonWithTag:0 origin:CGPointMake(tabAreaHalfWidth - triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleB - buttonRadius)];
      [self setButtonWithTag:1 origin:CGPointMake(tabAreaHalfWidth + triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleB - buttonRadius)];
      break;
    }
      
    case 3: {      
      CGFloat degree    = 65 * M_PI / 180;
      CGFloat triangleA = triangleHypotenuse * cosf(degree);
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self setButtonWithTag:0 origin:CGPointMake(tabAreaHalfWidth - triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      [self setButtonWithTag:1 origin:CGPointMake(tabAreaHalfWidth - buttonRadius,
                                                  tabAreaHalfHeight - triangleHypotenuse - buttonRadius)];
      [self setButtonWithTag:2 origin:CGPointMake(tabAreaHalfWidth + triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      break;
    }
      
    case 4:
    default: {
      CGFloat degree    = 65 * M_PI / 180;
      CGFloat triangleA = triangleHypotenuse * cosf(degree);
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self setButtonWithTag:0 origin:CGPointMake(tabAreaHalfWidth - triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      [self setButtonWithTag:3 origin:CGPointMake(tabAreaHalfWidth + triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      
      degree    = 24 * M_PI / 180;
      triangleA = triangleHypotenuse * cosf(degree);
      triangleB = triangleHypotenuse * sinf(degree);
      [self setButtonWithTag:1 origin:CGPointMake(tabAreaHalfWidth - triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      [self setButtonWithTag:2 origin:CGPointMake(tabAreaHalfWidth + triangleB - buttonRadius,
                                                  tabAreaHalfHeight - triangleA - buttonRadius)];
      break;
    }
  }
}

// Set Frame for button with special tag
- (void)setButtonWithTag:(NSInteger)buttonTag origin:(CGPoint)origin {
  UIButton * button = [self.buttons objectAtIndex:buttonTag];
  [button setFrame:CGRectMake(origin.x, origin.y, 44.f, 44.f)];
  button = nil;
}

#pragma mark - Animation Control Methods

-(void)pauseLayer:(CALayer*)layer {
  CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
  layer.speed = 0.f;
  layer.timeOffset = pausedTime;
}

-(void)resumeLayer:(CALayer*)layer {
  CFTimeInterval pausedTime = [layer timeOffset];
  layer.speed = 1.f;
  layer.timeOffset = 0.f;
  layer.beginTime = 0.f;
  CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
  layer.beginTime = timeSincePause;
}

- (void)moveArrowToNewPosition {
  CGFloat radius            = kTabBarHeight - 26.f; // Distance to Ball Center
  CGFloat centerOriginX     = kTabBarWdith / 2;
  CGFloat centerOriginY     = kTabBarHeight;
  CGFloat itemCenterOriginX = self.newPositionForArrow.x;
  CGFloat itemCenterOriginY = self.newPositionForArrow.y;
  CGFloat arc      = asinf((centerOriginY - itemCenterOriginY) / radius);
  CGFloat newAngle = itemCenterOriginX < centerOriginX ? M_PI + arc : M_PI * 2 - arc;
  
  // Path
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddArc(path, NULL,
               centerOriginX, centerOriginY,   // Center point
               radius,                         // Radius
               self.currArcForArrow, newAngle, // New angle for the new point
               itemCenterOriginX < self.arrow.frame.origin.x ? YES : NO); // Clock wise or not
  CAKeyframeAnimation * customFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  customFrameAnimation.path = path;
  CGPathRelease(path);
  self.currArcForArrow = newAngle;
  
//  NSArray * sizeValues = [NSArray arrayWithObjects:
//                          [self.arrow valueForKey:@"position"], [NSValue valueWithCGPoint:self.newPositionForArrow], nil];
//  NSArray * times = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:0.3f], nil];
//  NSArray * timingFunctions = [NSArray arrayWithObjects:
//                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], nil];
//  [customFrameAnimation setValues:sizeValues];
//  [customFrameAnimation setKeyTimes:times];
  
  customFrameAnimation.delegate = self;
  customFrameAnimation.duration = .3f;
  customFrameAnimation.repeatCount = 1;
  //customFrameAnimation.cumulative = YES;
  //customFrameAnimation.additive = YES;
  customFrameAnimation.calculationMode = kCAAnimationPaced;
  customFrameAnimation.fillMode = kCAFillModeForwards;
//  customFrameAnimation.timingFunctions = timingFunctions;
  customFrameAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  customFrameAnimation.removedOnCompletion = NO;
  [self.arrow.layer addAnimation:customFrameAnimation forKey:@"moveArrow"];
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
  // Update the layer's position so that the layer doesn't snap back when the animation completes
  [self.arrow.layer setPosition:self.newPositionForArrow];
//  [arrow_.layer removeAnimationForKey:@"moveArrow"];
}

@end
