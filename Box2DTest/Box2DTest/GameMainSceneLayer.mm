//
//  GameMainSceneLayer.m
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "GameMainSceneLayer.h"
#import "CCPhysicsSprite.h"
#import "AppDelegate.h"
#import "GameContactListener.h"
#include <math.h>
#import <AudioToolbox/AudioServices.h>

#pragma mark - GameMainSceneLayer

@interface GameMainSceneLayer(){
    b2Fixture *_ballFixture;
    b2Fixture *_dotFixture;
    b2Fixture *_bottomFixture;
    b2Fixture *_topFixture;
    b2Fixture *_leftEdgeFixture;
    b2Fixture *_rightEdgeFixture;
    b2Body *blockBody;

    BlockContactListener *_contactListener;
    CCProgressTimer *lifeBar;
    CCProgressTimer *timerBar;
    NSMutableArray *dotsToDestroy;
    CCSprite *basicUI;
    
    CCLabelTTF *scoreNode;
    CCLabelTTF *timeNode;
    
    int score;
    int ballHit;
    int timeCount;
    int dotTag;
    int lifeLeft;
    int bonusBallCatched;
    CGSize screenSize;
    BOOL boxContactBody;
    
    NSTimer *updateTimer;
    NSTimer *dotLifeTimer;
    NSTimer *deleteDotTimer;
    NSTimer *bonusBallTimer;
    NSTimer *startUpTimer;
}

-(void) initPhysics;

@end

@implementation GameMainSceneLayer

+(CCScene *) scene{
    CCScene *scene = [CCScene node];
    GameMainSceneLayer *layer = [GameMainSceneLayer node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}

-(id) init{
    if( (self=[super init])) {
        // enable events
        self.touchEnabled = YES;
        self.accelerometerEnabled = YES;
        screenSize=[[CCDirector sharedDirector]winSize];
        dotsToDestroy = [[NSMutableArray alloc] init];
        // init physics
        [self initPhysics];
        
        timeCount = 60;
        dotTag = 1000;
        lifeLeft = 5;
        bonusBallCatched = 0;

        updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(UpdateBasicTimer) userInfo:nil repeats:YES];
        dotLifeTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(updateDotLifeTime) userInfo:nil repeats:YES];
        deleteDotTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(deleteDot) userInfo:nil repeats:YES];
        bonusBallTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(createBonusBall) userInfo:nil repeats:YES];

        
        // Create contact listener
        _contactListener = new BlockContactListener();
        world->SetContactListener(_contactListener);
        [self createBasicUI];
        [self createLifeBar];
        [self createBlockAtLocation:ccp(screenSize.width/2,screenSize.height/2) withSize:CGSizeMake(10, 10)];
        double randomNumber = (arc4random()%400);
        [self createDotAtLocation:ccp(50,randomNumber) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal@2x.png"]];
        [self scheduleUpdate];
        [self schedule:@selector(randomMotion) interval:.1];
    }
    return self;
}

-(void) initPhysics{
    b2Vec2 gravity;
    gravity.Set(-0.0f, -0.0f);
    world = new b2World(gravity);
    
    // Do we want to let bodies sleep?
    world->SetAllowSleeping(true);
    world->SetContinuousPhysics(true);
    
    m_debugDraw = new GLESDebugDraw( PTM_RATIO );
    world->SetDebugDraw(m_debugDraw);
    uint32 flags = 0;
    //flags += b2Draw::e_shapeBit;
    m_debugDraw->SetFlags(flags);
    
    // Define the ground body.
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0);// bottom-left corner
    //groundBodyDef.userData =  image;
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    // Define the ground box shape.
    b2EdgeShape groundBox;
    
    // bottom
    groundBox.Set(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
    _bottomFixture = groundBody->CreateFixture(&groundBox,0);
    
    // top
    groundBox.Set(b2Vec2(0,(screenSize.height-73)/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,(screenSize.height-73)/PTM_RATIO));
    _topFixture = groundBody->CreateFixture(&groundBox,0);
    
    // left
    groundBox.Set(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
    _leftEdgeFixture = groundBody->CreateFixture(&groundBox,0);
    
    // right
    groundBox.Set(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
    _rightEdgeFixture = groundBody->CreateFixture(&groundBox,0);
}

-(void) draw{
    [super draw];
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    kmGLPushMatrix();
    world->DrawDebugData();
    kmGLPopMatrix();
}

#pragma mark - Private Methods

- (void)createLifeBar {
    lifeBar= [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"active@2x.png"]];
    lifeBar.type = kCCProgressTimerTypeBar;
    lifeBar.midpoint = ccp(0,0);
    lifeBar.barChangeRate = ccp(1,0);
    lifeBar.percentage = 100;
    lifeBar.position = ccp(screenSize.width/2,screenSize.height*.895 - lifeBar.contentSize.height);
    lifeBar.tag = 4;
    [self addChild:lifeBar z:10];
}

- (void)createBasicUI{
    //Create score bar
    basicUI = [CCSprite spriteWithFile:@"UI@2x.png" rect:CGRectMake(0, 0,screenSize.width,screenSize.height)];
    basicUI.anchorPoint = ccp(0.5,0.5);
    basicUI.position = ccp(screenSize.width/2,screenSize.height/2);
    basicUI.tag = 3;
    [self addChild:basicUI z:0];
    
    scoreNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",ballHit] fontName:@"Arial" fontSize:30.0 ];
    scoreNode.position = ccp(screenSize.width*0.90,screenSize.height*0.93);
    [self addChild:scoreNode z:99];
    
    timerBar=[CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"C-BG@2x.png"]];
    timerBar.type=kCCProgressTimerTypeRadial;
    timerBar.position=ccp(screenSize.width*0.10,screenSize.height*0.93);
    timerBar.percentage = 100;
    [self addChild:timerBar z:99];
    CCSprite *timeSprite = [CCSprite spriteWithFile:@"time@2x.png"];
    timeSprite.position = ccp(screenSize.width*0.10,screenSize.height*0.93);
    [self addChild:timeSprite z:100];
}

-(void)UpdateBasicTimer{
    [basicUI setColor:ccc3(200,215,0)];
    if (boxContactBody) {
        lifeLeft--;
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
        [basicUI setColor:ccc3(255,50,0)];
        boxContactBody = NO;
    }
     blockBody->SetLinearDamping(10.0);
    timerBar.percentage=1.6777*timeCount;

    timeNode.string = [NSString stringWithFormat:@" %d ",timeCount];
    timeCount--;
    if (timeCount == 0) {
        [self invalidateAllTimers];
        score = (60 - (timeCount/10))*3 + 10 + ballHit - ((5 - lifeLeft)*10) + (bonusBallCatched*50);
        NSString *message = [self updateHighScoreWithScore:score];
        if (![message isEqualToString:@"High Score !"]) {
            message = @"Time Out";
        }
        CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:message withScore:score];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
}

- (void)deleteDot {
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            if (sprite.tag >= 1000) {
                [sprite setColor:ccc3(255,50,0)];
                double delayInSeconds = 4.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if (  b->GetUserData() != NULL ) {
                        [dotsToDestroy addObject:[NSValue valueWithPointer:b]];
                        lifeLeft--;
                    }
                });
                break;
            }
        }
    }
}
- (void)createBonusBall {
    if ( lifeLeft < 5 ) {
        double randomNumber = (arc4random()% 400) ;
        [self createDotAtLocation:ccp(screenSize.width/2,randomNumber) withSize:CGSizeMake(10, 10) withTag:500 andSprite:[CCSprite spriteWithFile:@"Ball-Bonus@2x.png"]];
    }
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            if (sprite.tag == 500) {
                double delayInSeconds = 3.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if (  b->GetUserData() != NULL ) {
                        [dotsToDestroy addObject:[NSValue valueWithPointer:b]];
                    }
                });
            }
        }
    }
}
    
- (void)updateDotLifeTime{
    dotTag++;
    double randomNumber = (arc4random()%400);
    [self createDotAtLocation:ccp(100,randomNumber) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal@2x.png"]];
}

- (void)endTheGame {
    [self invalidateAllTimers];
    score = (60 - (timeCount/10))*3 + 10 + ballHit - ((5 - lifeLeft)*10) + (bonusBallCatched*50);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSString *message = [self updateHighScoreWithScore:score];
        CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:message withScore:score];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    });
}

- (void)randomMotion {
    b2Vec2 velocity = _dotFixture->GetBody()->GetLinearVelocity();
    float speed = velocity.Length();
    float ratio = 9 / speed;
    velocity*=ratio;
    _dotFixture->GetBody()->SetLinearVelocity(velocity);
    _dotFixture->GetBody()->SetAngularVelocity(5);

}

- (void)updateLevelWithBallHit {
    ballHit++;
    SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/new-mail.caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound);

    [scoreNode setString:[NSString stringWithFormat:@" %d ", ballHit]];
    dotTag++;
    double randomNumber = (arc4random()%400);
    [self createDotAtLocation:ccp(50, randomNumber) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal@2x.png"]];
}

- (void)invalidateAllTimers{
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    if (dotLifeTimer) {
        [dotLifeTimer invalidate];
        dotLifeTimer = nil;
    }
    if (deleteDotTimer) {
        [deleteDotTimer invalidate];
        deleteDotTimer = nil;
    }
    if (bonusBallTimer) {
        [bonusBallTimer invalidate];
        bonusBallTimer = nil;
    }
}

- (void)deleteDotsInQueue {
    NSMutableArray *dotsToDelete = [NSMutableArray new];
    for(NSValue *bodyValue in dotsToDestroy) {
        b2Body *body = (b2Body*)[bodyValue pointerValue];
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            [self removeChild:sprite cleanup:YES];
            body->SetUserData(NULL);
            world->DestroyBody(body);
            [dotsToDelete addObject:bodyValue];
        }
    }
    [dotsToDestroy removeObjectsInArray:dotsToDelete];
}

- (NSString *)updateHighScoreWithScore:(int)highScore{
    NSNumber *savedScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"High Score"];
    if ( highScore > [savedScore intValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:highScore] forKey:@"High Score"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return @"High Score !";
    } else {
        return @"Game Over";
    }
}

#pragma mark - Create Body Methods

- (void)createDotAtLocation:(CGPoint)location withSize:(CGSize)size withTag:(int)tag andSprite :(CCSprite *)image {
    image.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    image.tag = tag;
    [self addChild:image];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    bodyDef.gravityScale = 0 ;
    bodyDef.allowSleep = false ;
    bodyDef.userData = image;
    b2Body *dotb;
    dotb = world->CreateBody(&bodyDef);
    b2CircleShape shape;
    shape.m_radius = 0.20f;
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 5;
    fixtureDef.friction = 0;
    fixtureDef.restitution = .5;
    dotb->SetLinearVelocity(b2Vec2(40,40));
    _dotFixture = dotb->CreateFixture(&fixtureDef);
}

- (void)createBlockAtLocation:(CGPoint)location withSize:(CGSize)size {
    boxContactBody = NO;
    // Create block and add it to the layer
    CCSprite *block = [CCSprite spriteWithFile:@"Eater-Normal@2x.png"];
    block.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    block.tag = 2;
    [self addChild:block];
    b2BodyDef bodyDef2;
    bodyDef2.type = b2_dynamicBody;
    bodyDef2.gravityScale = 1 ;
    bodyDef2.allowSleep = false ;
    bodyDef2.userData = block;
    bodyDef2.position = b2Vec2(location.x/PTM_RATIO,location.y/PTM_RATIO);
    blockBody = world->CreateBody(&bodyDef2);
    b2PolygonShape shape2;
    shape2.SetAsBox(0.5f, 0.5f);
    b2FixtureDef fixtureDef2;
    fixtureDef2.shape = &shape2;
    fixtureDef2.density = 50.0;
    _ballFixture = blockBody->CreateFixture(&fixtureDef2);
}

#pragma mark - Update Methods

-(void) update: (ccTime) dt {
    world->ClearForces();
    
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    blockBody->SetAngularVelocity(8);

    [lifeBar setPercentage:20*lifeLeft];
    std::vector<DotContact>::iterator pos;
    
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos) {
    
        DotContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
            if (spriteA.tag >= 1000 && spriteB.tag == 2) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyA]];
                [self updateLevelWithBallHit];
            } else if (spriteA.tag == 2 && spriteB.tag >= 1000) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyB]];
                [self updateLevelWithBallHit];
            } else if (spriteA.tag == 500 && spriteB.tag == 2) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyA]];
                lifeLeft++;
                bonusBallCatched++;
            }else if (spriteA.tag == 2 && spriteB.tag == 500) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyB]];
                lifeLeft++;
                bonusBallCatched++;
            }
        }

        if((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _topFixture && contact.fixtureB == _ballFixture)||
           (contact.fixtureA == _rightEdgeFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _leftEdgeFixture && contact.fixtureB == _ballFixture)){
            boxContactBody = YES;
        }
    }
    [self deleteDotsInQueue];
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSpriteBatchNode *sprite = (CCSpriteBatchNode *) b->GetUserData();
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO,
                                  b->GetPosition().y * PTM_RATIO);
            sprite.rotation = CC_RADIANS_TO_DEGREES(b->GetAngle() * -1);
        }
    }
    if (lifeLeft == 0) {
        [self endTheGame];
    }
    world->Step(dt, velocityIterations, positionIterations);
}

#pragma mark - Accelerometer Delegate Methods

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration{
    b2Vec2 gravity( acceleration.x  * 450, acceleration.y  * 450);
    world->SetGravity( gravity );
}

-(void) dealloc{
    delete world;
    world = NULL;
    
    delete m_debugDraw;
    m_debugDraw = NULL;
    
    delete _contactListener;
    _contactListener = NULL;
    
    [super dealloc];
}	

@end
