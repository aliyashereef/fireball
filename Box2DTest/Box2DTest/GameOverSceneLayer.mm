//
//  GameOverSceneLayer.m
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "GameOverSceneLayer.h"
#import "GameMainSceneLayer.h"
#import "IntroLayer.h"
#import "AppDelegate.h"

@implementation GameOverSceneLayer{
    CGSize winSize;
    NSString *leaderBoardIdentifier;
    BOOL isGameCenterEnabled;
    NSNumber *savedScore;
}

+(CCScene *) sceneWithWon:(NSString *)message withScore:(int)score{
    CCScene *scene = [CCScene node];
    GameOverSceneLayer *layer = [[[GameOverSceneLayer alloc] initWithWon:message withScore:score] autorelease];
    [scene addChild: layer];
    return scene;
}

- (id)initWithWon:(NSString *)message withScore:(int)score{
    if ((self=[super init])) {
        [self authenticateLocalPlayer];
        winSize = [[CCDirector sharedDirector] winSize];
        savedScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"High Score"];
        
        CCLabelTTF * scoreTextLabel = [CCLabelTTF labelWithString:@"YOUR" fontName:@"HelveticaNeue" fontSize:20];
        CCLabelTTF * scoreLabel = [CCLabelTTF labelWithString:@"SCORE:" fontName:@"HelveticaNeue" fontSize:30];
        CCLabelTTF * scoreValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",score] fontName:@"HelveticaNeue" fontSize:60];
        CCLabelTTF * highScoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"TOP SCORE: %d",[savedScore integerValue]] fontName:@"HelveticaNeue" fontSize:15];
        
        scoreValueLabel.color = ccc3(255,255,255);
        highScoreLabel.color = ccc3(112,112,112);
        scoreTextLabel.color = ccc3(112,112,112);
        scoreLabel.color = ccc3(112,112,112);
        
        scoreTextLabel.position = ccp(winSize.width/2-scoreTextLabel.contentSize.width-25, winSize.height/2 + 40);
        scoreLabel.position = ccp(winSize.width/2-scoreLabel.contentSize.width/2, winSize.height/2 + scoreTextLabel.contentSize.height - 10);
        scoreValueLabel.position = ccp(winSize.width/2+scoreTextLabel.contentSize.width, winSize.height/2 + scoreTextLabel.contentSize.height );
        highScoreLabel.position =ccp(winSize.width/2,winSize.height/2+ scoreValueLabel.contentSize.height - 100);
        
        CCSprite *introSceneUI =[CCSprite spriteWithFile:@"GameOver@2x.png" rect:CGRectMake(0, 0,winSize.width,winSize.height)];
        introSceneUI.anchorPoint = ccp(0.5,0.5);
        introSceneUI.position = ccp(winSize.width/2,winSize.height/2);
        introSceneUI.tag = 0;
        [self addChild:introSceneUI z:0];
        CCSprite *lineSeperator =[CCSprite spriteWithFile:@"Line-Separator@2x.png"];
        lineSeperator.anchorPoint = ccp(0.5,0.5);
        lineSeperator.position = ccp(winSize.width/2,winSize.height/2-15);
        lineSeperator.tag = 1;
        [self addChild:lineSeperator z:10];

        [self addChild:scoreLabel];
        [self addChild:scoreTextLabel];
        [self addChild:highScoreLabel];
        [self addChild:scoreValueLabel];
        
        [self createMenu];
    }
    return self;
}
-(void) createMenu
{
    // Default font size will be 22 points.
    [CCMenuItemFont setFontSize:22];
    [CCMenuItemFont setFontName:@"Helvetica"];
    
    CCMenuItem *playAgainMenuItem = [CCMenuItemImage itemWithNormalImage:@"button-BG-@2x.png" selectedImage:@"button-BG-@2x.png" target:self selector:@selector(playAgainButtonTapped)];
    playAgainMenuItem.position = ccp(winSize.width/2, winSize.height/3);
    
    // Achievement Menu Item using blocks
    CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
        GKGameCenterViewController *acheivementViewController = [[GKGameCenterViewController alloc] init];
        acheivementViewController.gameCenterDelegate = self;
        acheivementViewController.viewState = GKGameCenterViewControllerStateAchievements;
        acheivementViewController.leaderboardIdentifier = @"137_137_7";
        AppController *navController = (AppController*) [[UIApplication sharedApplication] delegate];
        [[navController navController] presentViewController:acheivementViewController animated:YES completion:nil];
         }];
    
    // Leaderboard Menu Item using blocks
    CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
        GKGameCenterViewController *leaderBoardViewController = [[GKGameCenterViewController alloc] init];
        leaderBoardViewController.gameCenterDelegate = self;
        leaderBoardViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
        leaderBoardViewController.leaderboardIdentifier = @"137_137_7";
        AppController *navController = (AppController*) [[UIApplication sharedApplication] delegate];
        [[navController navController] presentViewController:leaderBoardViewController animated:YES completion:nil];
    }];

    CCMenu *playAgain = [CCMenu menuWithItems:itemLeaderboard,itemAchievement ,playAgainMenuItem, nil];
    [playAgain setPosition:ccp( winSize.width/2, winSize.height/3-20)];
    [playAgain alignItemsVertically];
    [self addChild:playAgain z:100];
}

- (void)playAgainButtonTapped {
    [[CCDirector sharedDirector] replaceScene:[IntroLayer scene]];
}

- (void)authenticateLocalPlayer{
    // Instantiate a GKLocalPlayer object to use for authenticating a player.
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            // If it's needed display the login view controller.
            AppController *navController = (AppController*) [[UIApplication sharedApplication] delegate];
            [[navController navController] presentViewController:viewController animated:YES completion:nil];
        }
        else{
            if ([GKLocalPlayer localPlayer].authenticated) {
                // If the player is already authenticated then indicate that the Game Center features can be used.
                isGameCenterEnabled = YES;
                
                // Get the default leaderboard identifier.
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    if (error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    else{
                        leaderboardIdentifier = leaderboardIdentifier;
                        [self reportScore:[savedScore intValue]];

                    }
                }];
            }
            else{
                isGameCenterEnabled = NO;
            }
        }
    };
}

-(void)reportScore:(int)score{
    GKScore *scoreReported = [[GKScore alloc] initWithLeaderboardIdentifier:@"137_137_7"];
    scoreReported.value = score;
    
    [GKScore reportScores:@[scoreReported] withCompletionHandler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

#pragma mark - GKGameCenterControllerDelegate method implementation
-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
