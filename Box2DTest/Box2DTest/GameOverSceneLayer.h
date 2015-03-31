//
//  GameOverSceneLayer.h
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "cocos2d.h"

@interface GameOverSceneLayer : CCLayer

+(CCScene *) sceneWithWon:(BOOL)won withScore:(int)score;
- (id)initWithWon:(BOOL)won withScore:(int)score;

@end
