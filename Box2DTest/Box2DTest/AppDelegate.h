//
//  AppDelegate.h
//  Box2DTest
//
//  Created by aliya on 25/03/15.
//  Copyright QBurst 2015. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"
#import <GameKit/GameKit.h>

// Added only for iOS 6 support
@interface MyNavigationController : UINavigationController <CCDirectorDelegate>
@end

@interface AppController : NSObject <UIApplicationDelegate>
{
	UIWindow *window_;
	MyNavigationController *navController_;
	CCDirectorIOS	*director_;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) MyNavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@end
