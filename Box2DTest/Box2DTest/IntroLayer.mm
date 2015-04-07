//
//  IntroLayer.m
//  Box2DTest
//
//  Created by aliya on 25/03/15.
//  Copyright QBurst 2015. All rights reserved.
//


// Import the interfaces
#import "IntroLayer.h"
#import "GameMainSceneLayer.h"
#import "GameOverSceneLayer.h"


#pragma mark - IntroLayer

// HelloWorldLayer implementation
@implementation IntroLayer{
    CCLabelTTF *startUpTimeNode;
    int count;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	IntroLayer *layer = [IntroLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

//
-(id) init
{
	if( (self=[super init])) {
        count = 3;
		// ask director for the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
        
        startUpTimeNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",count] fontName:@"Arial" fontSize:100.0 ];
        startUpTimeNode.position = ccp(size.width*0.5,size.height*0.5);
        [self addChild:startUpTimeNode z:100];
//        CCSprite *introSceneUI =[CCSprite spriteWithFile:@"UI@2x.png" rect:CGRectMake(0, 0,size.width,size.height)];
//        introSceneUI.anchorPoint = ccp(0.5,0.5);
//        introSceneUI.position = ccp(size.width/2,size.height/2);
//        introSceneUI.tag = 0;
//        [self addChild:introSceneUI z:0];
        [self performSelector:@selector(showInitialCounter)  withObject:self afterDelay:1.0];
	}
	
	return self;
}

- (void)showInitialCounter {
    count--;
    [startUpTimeNode setString:[NSString stringWithFormat:@" %d ",count]];
}

-(void) onEnter
{
	[super onEnter];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:3.0 scene:[GameMainSceneLayer scene] ]];
}
@end
