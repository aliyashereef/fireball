//
//  GameOverSceneLayer.m
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "GameOverSceneLayer.h"
#import "GameMainSceneLayer.h"

@implementation GameOverSceneLayer

+(CCScene *) sceneWithWon:(BOOL)won withScore:(int)score{
    CCScene *scene = [CCScene node];
    GameOverSceneLayer *layer = [[[GameOverSceneLayer alloc] initWithWon:won withScore:score] autorelease];
    [scene addChild: layer];
    
    return scene;
}

- (id)initWithWon:(BOOL)won withScore:(int)score{
    if ((self=[super init])) {
        
        NSString * message;
        if (won) {
            message = @"You Won!";
        } else {
            message = @"Game Over";
        }
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CCLabelTTF * label = [CCLabelTTF labelWithString:message fontName:@"Arial" fontSize:32];
        CCLabelTTF * scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Score : %d ",score] fontName:@"Arial" fontSize:32];
        label.color = ccc3(255,255,255);
        scoreLabel.color = ccc3(255,255,255);
        scoreLabel.position = ccp(winSize.width/2, 500);
        label.position = ccp(winSize.width/2, 450);
        [self addChild:scoreLabel];
        [self addChild:label];
        [self createMenu];
    }
    return self;
}
-(void) createMenu
{
    // Default font size will be 22 points.
    [CCMenuItemFont setFontSize:22];
    [CCMenuItemFont setFontName:@"Arial"];
    
    // Reset Button
    CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Play Again" block:^(id sender){
        [[CCDirector sharedDirector] replaceScene: [GameMainSceneLayer scene]];
    }];
    CCMenuItemLabel *leaderBoard = [CCMenuItemFont itemWithString:@"Leader Board" block:^(id sender){
    }];

    
    
    CCMenu *menu = [CCMenu menuWithItems:leaderBoard, reset, nil];
    
    [menu alignItemsVertically];
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    [menu setPosition:ccp( size.width/2, size.height/2)];
    [self addChild: menu z:-1];
}

@end
