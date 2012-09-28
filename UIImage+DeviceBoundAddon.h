//
//  UIImage+DeviceBoundAddon.h
//
//  Created by Thierry Passeron on 28/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

/*
 
 (iOS4+)
 
 This UIImage addition follows Apple's guideline concerning image naming scheme
 except it doesn't handle custom URL schemes
 
 Reference: http://developer.apple.com/library/ios/DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/iPhoneAppProgrammingGuide.pdf
 
 */

#import <UIKit/UIKit.h>

@interface UIImage (DeviceBoundAddon)

/* 
 Get an image based on user interface Idiom / orientation / scale constraints
 
 This is the best effort to get a named image just like in -[UIImage imageNamed:] based on the current device constraints
 
 Example:
   
 [UIImage deviceBoundImageNamed:@"Default"];
 
 On the iPhone 6.0 simulator with a Retina 4-inch hardware selected
 This will try possible image names: (
  "Default-568h@2x~iphone",
  "Default-568h@2x",
  "Default@2x~iphone",
  "Default@2x"
 )
 2012-09-28 12:50:41.793 XXX[94685:c07] Loaded image: Default-568h@2x~iphone

 */
+ (id)deviceBoundImageNamed:(NSString *)name;

@end
