//
//  SodineAppDelegate.h
//  Sodine
//
//  Created by Jérôme Lebel on 29/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SodineViewController;

@interface SodineAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet SodineViewController *viewController;

@end
