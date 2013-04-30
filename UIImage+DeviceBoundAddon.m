//
//  UIImage+DeviceBoundAddon.m
//
//  Created by Thierry Passeron on 28/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

//#define DEBUG_UIImage_DeviceBoundAddon

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
    default:
      break;
  }
#ifdef DEBUG_UIImage_DeviceBoundAddon
  NSLog(@"Unknown orientation");
#endif
  return nil;
}

NS_INLINE UIDeviceOrientation UIDeviceOrientationFromNSString(NSString *orientation) {
  if ([orientation isEqualToString:@"Portrait"]) {
    return UIDeviceOrientationPortrait;
  } else
  if ([orientation isEqualToString:@"Landscape"]) {
    return UIDeviceOrientationLandscapeLeft;
  } else
  if ([orientation isEqualToString:@"LandscapeLeft"]) {
    return UIDeviceOrientationLandscapeLeft;
  } else
  if ([orientation isEqualToString:@"LandscapeRight"]) {
    return UIDeviceOrientationLandscapeRight;
  } else
  if ([orientation isEqualToString:@"FaceUp"]) {
    return UIDeviceOrientationFaceUp;
  } else
  if ([orientation isEqualToString:@"FaceDown"]) {
    return UIDeviceOrientationFaceDown;
  } else
  if ([orientation isEqualToString:@"PortraitUpsideDown"]) {
    return UIDeviceOrientationPortraitUpsideDown;
  }
  return UIDeviceOrientationUnknown;
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

static NSCharacterSet *modifiersCharacterSet = nil;
+ (NSDictionary *)constraintsForName:(NSString *)name {
  NSMutableDictionary *contraints = [NSMutableDictionary dictionary];
  NSString *baseName = nil;
  NSString *orientation = nil;
  NSString *scale = nil;
  NSString *device = nil;
  NSString *extention = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    modifiersCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"-~@."]retain];
  });
  
  NSScanner *scanner = [NSScanner scannerWithString:name];
  [scanner scanUpToCharactersFromSet:modifiersCharacterSet intoString:&baseName];

  NSString *temp = nil;
  while (scanner.scanLocation < name.length - 1) {
    [scanner scanCharactersFromSet:modifiersCharacterSet intoString:&temp];
    if ([temp isEqualToString:@"-"]) {
      [scanner scanUpToCharactersFromSet:modifiersCharacterSet intoString:&orientation];
    } else
    if ([temp isEqualToString:@"~"]) {
      [scanner scanUpToCharactersFromSet:modifiersCharacterSet intoString:&device];
    } else
    if ([temp isEqualToString:@"@"]) {
      [scanner scanUpToCharactersFromSet:modifiersCharacterSet intoString:&scale];
    } else
    if ([temp isEqualToString:@"."]) {
      [scanner scanUpToCharactersFromSet:modifiersCharacterSet intoString:&extention];
    }
  }
  
  if (baseName) contraints[@"basename"] = baseName;
  if (orientation) contraints[@"orientation"] = orientation;
  if (scale) contraints[@"scale"] = scale;
  if (device) contraints[@"device"] = device;
  if (extention) contraints[@"extention"] = extention;

#ifdef DEBUG_UIImage_DeviceBoundAddon
  NSLog(@"Constraints for name %@: %@", name, contraints);
#endif

  return contraints;
}

typedef void (^ModifierBlock)(NSString *, NSArray *nexts);

+ (id)deviceBoundImageNamed:(NSString *)path {
  NSDictionary *constraints = [self constraintsForName:path];

  NSString *basename = constraints[@"basename"];
  NSString *extention = constraints[@"extention"];
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
    SET_NEXT(nexts)
    if (constraints[@"orientation"]) _next([input stringByAppendingFormat:@"-%@", constraints[@"orientation"]], _nexts);
    
    NSString *orientation = NSStringFromUIDeviceOrientation((UIDeviceOrientation)([UIApplication sharedApplication].statusBarOrientation));
    while (orientation.length) {
      _next([input stringByAppendingFormat:@"-%@", orientation], _nexts);
      orientation = degradedOrientationString(orientation);
    }
    _next(input, _nexts);
  };
  
  ModifierBlock m_scale = ^(NSString *input, NSArray *nexts) {
    SET_NEXT(nexts)
    if (constraints[@"scale"]) _next([input stringByAppendingFormat:@"@%@", constraints[@"scale"]], _nexts);
    
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale > 1.0) _next([input stringByAppendingFormat:@"@%dx", (int)floor(scale)], _nexts);
    if (!isJony5) _next(input, _nexts);
  };
  
  ModifierBlock m_device = ^(NSString *input, NSArray *nexts) {
    SET_NEXT(nexts)
    if (constraints[@"device"]) _next([input stringByAppendingFormat:@"~%@", constraints[@"device"]], _nexts);
    _next([input stringByAppendingFormat:@"~%@", NSStringFromUIUserInterfaceIdiom(UI_USER_INTERFACE_IDIOM())], _nexts);
    _next(input, _nexts);
  };
  
  ModifierBlock terminator = ^(NSString *input, NSArray *nexts) {
    // Unique names filter
    if ([names indexOfObject:input] == NSNotFound) [names addObject:input];
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
  
  NSString *imagePath = nil;
  for (NSString *name in names) {
    imagePath = [[NSBundle mainBundle]pathForResource:name ofType:hasExtention ? extention : @"png"];
    if (!imagePath) continue;

    UIImage *_image = [UIImage imageWithContentsOfFile:imagePath];
    NSDictionary *imageContraints = [self constraintsForName:name];
    CGFloat scale = imageContraints[@"scale"] ? [imageContraints[@"scale"]floatValue] : 1.;
    UIImageOrientation orientation = UIImageOrientationUp;
    
    if (imageContraints[@"orientation"]) {
      switch (UIDeviceOrientationFromNSString(imageContraints[@"orientation"])) {
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationPortrait:
          orientation = UIImageOrientationUp;
          break;

        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortraitUpsideDown:
          orientation = UIImageOrientationDown;
          break;
        
        case UIDeviceOrientationLandscapeLeft:
          orientation = UIImageOrientationRight;
          break;

        case UIDeviceOrientationLandscapeRight:
          orientation = UIImageOrientationLeft;
          break;
          
        default:
          break;
      }
    }
    
    UIImage *image = [UIImage imageWithCGImage:_image.CGImage scale:scale orientation:orientation];

#ifdef DEBUG_UIImage_DeviceBoundAddon
      NSLog(@"Loaded image from filename: %@ with constraints: %@", name, imageContraints);
#endif
      return image;
  }
  
  return nil;
}

@end

