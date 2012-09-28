//
//  UIImage+DeviceBoundAddon.m
//
//  Created by Thierry Passeron on 28/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#define DEBUG_UIImage_DeviceBoundAddon

#import "UIImage+DeviceBoundAddon.h"

@implementation UIImage (DeviceBoundAddon)

NS_INLINE NSString *NSStringFromUIDeviceOrientation(UIDeviceOrientation orientation) {
  switch (orientation) {
    case UIDeviceOrientationFaceDown:
      return @"FaceDown";
      break;
      
    case UIDeviceOrientationFaceUp:
      return @"FaceUp";
      break;
      
    case UIDeviceOrientationPortraitUpsideDown:
      return @"PortraitUpsideDown";
      break;
      
    case UIDeviceOrientationPortrait:
      return @"Portrait";
      break;
      
    case UIDeviceOrientationLandscapeLeft:
      return @"LandscapeLeft";
      break;
      
    case UIDeviceOrientationLandscapeRight:
      return @"LandscapeRight";
      break;
      
    case UIDeviceOrientationUnknown:
#ifdef DEBUG_UIImage_DeviceBoundAddon
      NSLog(@"Unknown orientation");
#endif
      return nil;
      
    default:
      break;
  }
  return nil;
}

NS_INLINE NSString* degradedOrientationString(NSString *orientation) {
  if ([orientation hasPrefix:@"Portrait"]) {
    return orientation.length > 8 /* @"Portrait".length */ ? @"Portrait" : @"";
  }
  
  if ([orientation hasPrefix:@"Landscape"]) {
    return orientation.length > 9 /* @"Landscape".length */ ? @"Landscape" : @"";
  }
  
  if ([orientation hasPrefix:@"Face"]) {
    return orientation.length > 4 /* @"Face".length */ ? @"Face" : @"Portrait";
  }
  return @"";
}

NS_INLINE NSString *NSStringFromUIUserInterfaceIdiom(UIUserInterfaceIdiom idiom) {
  if (idiom == UIUserInterfaceIdiomPad) {
    return @"ipad";
  }
  if (idiom == UIUserInterfaceIdiomPhone) {
    return @"iphone";
  }
  return @"";
}

typedef void (^ModifierBlock)(NSString *, NSArray *nexts);

+ (id)deviceBoundImageNamed:(NSString *)path {
  NSString *basename = [path stringByDeletingPathExtension];
  NSString *extention = [path pathExtension];
  BOOL hasExtention = extention.length > 0;
  
  CGRect bounds = [UIScreen mainScreen].bounds;
  BOOL isJony5 = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && bounds.size.height >= 548.0;
  
  NSMutableArray *names = [NSMutableArray array];
  
  // To find out which image name to load there are many possibilities:
  
  // With jony5 modifier
  // Without jony5 modifier
  
  // With device orientation modifier
  // With degraded device orientation modifier
  // Without device orientation modifier
  
  // With scale modifier
  // Without scale modifier
  
  // With device modifier
  // Without device modifier
  
  // => Max possibilities: 2 * 3 * 2 * 2 = 24!
  
#define SET_NEXT( X ) ModifierBlock _next = (ModifierBlock)[X objectAtIndex:0]; \
                      NSArray *_nexts = [X subarrayWithRange:NSMakeRange(1, X.count - 1)];
  
  ModifierBlock m_j5 = ^(NSString *input, NSArray *nexts) {
    SET_NEXT(nexts)
    if (isJony5) _next([input stringByAppendingString:@"-568h"], _nexts);
    _next(input, _nexts);
  };
  
  ModifierBlock m_orientation = ^(NSString *input, NSArray *nexts) {
    NSString *orientation = NSStringFromUIDeviceOrientation([UIDevice currentDevice].orientation);
    SET_NEXT(nexts)
    while (orientation.length) {
      _next([input stringByAppendingFormat:@"-%@", orientation], _nexts);
      orientation = degradedOrientationString(orientation);
    }
    _next(input, _nexts);
  };
  
  ModifierBlock m_scale = ^(NSString *input, NSArray *nexts) {
    CGFloat scale = [UIScreen mainScreen].scale;
    SET_NEXT(nexts)
    if (scale > 1.0) _next([input stringByAppendingFormat:@"@%dx", (int)floor(scale)], _nexts);
    if (!isJony5) _next(input, _nexts);
  };
  
  ModifierBlock m_device = ^(NSString *input, NSArray *nexts) {
    SET_NEXT(nexts)
    _next([input stringByAppendingFormat:@"~%@", NSStringFromUIUserInterfaceIdiom(UI_USER_INTERFACE_IDIOM())], _nexts);
    _next(input, _nexts);
  };
  
  ModifierBlock terminator = ^(NSString *input, NSArray *nexts) {
    [names addObject:hasExtention ? [input stringByAppendingPathExtension:extention] : input];
  };
  
  m_j5(basename, @[
   [[m_orientation copy]autorelease],
   [[m_scale copy]autorelease],
   [[m_device copy]autorelease],
   [[terminator copy]autorelease],
  ]);
  
#ifdef DEBUG_UIImage_DeviceBoundAddon
  NSLog(@"Possible image names: %@", names);
#endif
  
  for (NSString *name in names) {
    UIImage *image = [UIImage imageNamed:name];
    if (image) {
#ifdef DEBUG_UIImage_DeviceBoundAddon
      // It's a hint, it may not be the real filename that was loaded for imageNamed may have done it's own effort
      NSLog(@"Loaded image from filename: %@", name);
#endif
      return image;
    }
  }
  
  return nil;
}
@end

