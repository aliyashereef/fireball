//
//  GameOverSceneLayer.h
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@interface GameOverSceneLayer : CCLayer<GKGameCenterControllerDelegate,UINavigationControllerDelegate>

+(CCScene *) sceneWithWon:(NSString *)message withScore:(int)score;
- (id)initWithWon:(NSString *)message withScore:(int)score;

@end
