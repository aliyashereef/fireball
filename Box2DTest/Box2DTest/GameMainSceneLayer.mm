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
#import "GameConstants.h"

#pragma mark - GameMainSceneLayer

typedef enum
{
    kGameOverWithHighScore = 0,
    kGameOverWithOutHighScore = 1,
    kGameOverWithTimeOut = 2,
    kGameOverWithHighScoreAndTimeOut= 3,
}GameOverState;

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
    
    CCSprite *block;
    CCSprite *timeSprite;
    
    CCLabelTTF *scoreNode;
    CCLabelTTF *timeNode;CCLabelTTF *startUpTimeNode;
    
    int score;
    int ballHit;
    int timeCount;
    int dotTag;
    int lifeLeft;int startUpCount;
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
        startUpCount = 3;
        
        startUpTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(showInitialCounter) userInfo:nil repeats:YES];

        startUpTimeNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",startUpCount] fontName:@"Arial" fontSize:100.0 ];
        startUpTimeNode.position = ccp(screenSize.width*0.5,screenSize.height*0.5);
        startUpTimeNode.tag = 999;
        [self addChild:startUpTimeNode z:999];

        // Create contact listener
        _contactListener = new BlockContactListener();
        world->SetContactListener(_contactListener);
        
        [self createBasicUI];
        [self createLifeBar];
    }
    return self;
}

- (void)showInitialCounter {
    startUpCount--;
    [startUpTimeNode setString:[NSString stringWithFormat:@" %d ",startUpCount]];
    if (startUpCount==0) {
        [startUpTimer invalidate];
        startUpTimer = nil;
        [self removeChildByTag:999 cleanup:YES];
        
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:.7 target:self selector:@selector(UpdateBasicTimer) userInfo:nil repeats:YES];
        dotLifeTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(updateDotLifeTime) userInfo:nil repeats:YES];
        deleteDotTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(deleteDot) userInfo:nil repeats:YES];
        bonusBallTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(createBonusBall) userInfo:nil repeats:YES];
        
        [self createBlockAtLocation:ccp(screenSize.width/2,screenSize.height/2) withSize:CGSizeMake(10, 10)];
        double randomNumber = (arc4random()%400);
        [self createDotAtLocation:ccp(50,randomNumber) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal.png"]];
        [self schedule:@selector(randomMotion) interval:.1];
        [self scheduleUpdate];
    }
}

-(void) initPhysics{
    b2Vec2 gravity;
    gravity.Set(-1.0, -1.0f);
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
    lifeBar= [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"active.png"]];
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
    CCSprite *basicUI = [CCSprite spriteWithFile:@"UI.png" rect:CGRectMake(0, 0,screenSize.width,screenSize.height)];
    basicUI.anchorPoint = ccp(0.5,0.5);
    basicUI.position = ccp(screenSize.width/2,screenSize.height/2);
    basicUI.tag = 38;
    [self addChild:basicUI z:0];
    
    scoreNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",ballHit] fontName:@"Arial" fontSize:30.0 ];
    scoreNode.position = ccp(screenSize.width*0.90,screenSize.height*0.93);
    [self addChild:scoreNode z:99];
    
    timerBar=[CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"C-BG.png"]];
    timerBar.type=kCCProgressTimerTypeRadial;
    timerBar.position=ccp(screenSize.width*0.10,screenSize.height*0.93);
    timerBar.percentage = 100;
    [self addChild:timerBar z:99];
    timeSprite = [CCSprite spriteWithFile:@"time.png"];
    timeSprite.position = ccp(screenSize.width*0.10,screenSize.height*0.93);
    [self addChild:timeSprite z:100];
    
}

-(void)UpdateBasicTimer{

    [block setColor:ccc3(200,215,0)];
    if ([self getChildByTag:0]) {
        [self removeChildByTag:0 cleanup:YES];
    }
    if (timeCount < 10) {
        CCBlink * blinker = [CCBlink actionWithDuration: 0.1 blinks: 1];
        [timeSprite runAction: blinker];
    }
    if (boxContactBody) {
        lifeLeft--;
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
        [block setColor:ccc3(255,50,0)];
        CCSprite *detectWallCollisionUI =[CCSprite spriteWithFile:@"UI_2.png" rect:CGRectMake(0, 0,screenSize.width,screenSize.height)];
        detectWallCollisionUI.anchorPoint = ccp(0.5,0.5);
        detectWallCollisionUI.position = ccp(screenSize.width/2,screenSize.height/2);
        detectWallCollisionUI.tag = 0;
        [self addChild:detectWallCollisionUI z:0];
        boxContactBody = NO;
    }
    timerBar.percentage=1.6777*timeCount;

    timeNode.string = [NSString stringWithFormat:@" %d ",timeCount];
    timeCount--;
}

- (void)deleteDot {
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();

            if (sprite.tag >= 1000) {
                [sprite setColor:ccc3(255,50,0)];sprite.tag = 700;
                double delayInSeconds = 5.0;
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
        [self createDotAtLocation:ccp(screenSize.width/2,randomNumber) withSize:CGSizeMake(10, 10) withTag:500 andSprite:[CCSprite spriteWithFile:@"Ball-Bonus.png"]];
    }
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            if (sprite.tag == 500) {
                double delayInSeconds = 4.0;
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
    [self createDotAtLocation:ccp(100,randomNumber) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal.png"]];
}

- (void)endTheGame {
    [self invalidateAllTimers];
    score = (60 - (timeCount/10))*3 + 10 + ballHit - ((5 - lifeLeft)*10) + (bonusBallCatched*50);
    NSNumber *gameOverState = [self updateHighScoreWithScore:score];
    CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:gameOverState withScore:score];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
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
    [scoreNode setString:[NSString stringWithFormat:@" %d ", ballHit]];
    dotTag++;
    double randomNumberToFireBall = (arc4random()%400);
    [self createDotAtLocation:ccp(50, randomNumberToFireBall) withSize:CGSizeMake(10, 10) withTag:dotTag andSprite:[CCSprite spriteWithFile:@"Ball-Normal.png"]];
}

- (void)playCatchAlert {
    SystemSoundID myAlertSound;
    NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/new-mail.caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
    AudioServicesPlaySystemSound(myAlertSound);
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
            [self addChild:[self createParticleEffectAtPosition:ccp(sprite.position.x, sprite.position.y) forTag:sprite.tag] z:70];
            [self removeChild:sprite cleanup:YES];
            body->SetUserData(NULL);
            world->DestroyBody(body);
            [dotsToDelete addObject:bodyValue];
        }
    }
    [dotsToDestroy removeObjectsInArray:dotsToDelete];
}

- (NSNumber *)updateHighScoreWithScore:(int)highScore{
    NSNumber *savedScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"High Score"];
    if ( highScore > [savedScore intValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:highScore] forKey:@"High Score"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (timeCount == 0) {
            return [NSNumber numberWithInt:kGameOverWithHighScoreAndTimeOut];
        } else {
            return [NSNumber numberWithInt:kGameOverWithHighScore];
        }
        
    } else if(timeCount == 0){
        return [NSNumber numberWithInt:kGameOverWithTimeOut];
    } else {
        return [NSNumber numberWithInt:kGameOverWithOutHighScore];
    }
}

- (CCParticleSystemQuad *)createParticleEffectAtPosition:(CGPoint)point forTag:(int)tag{
    //
    CCParticleSystemQuad *emitter = [[CCParticleSystemQuad alloc] initWithTotalParticles:506];
    emitter.duration = 0.15;
    switch (tag) {
        case 500:
            emitter.texture=[[CCTextureCache sharedTextureCache] addImage:@"GreenParticle.png"];break;
        case 700:
            emitter.texture=[[CCTextureCache sharedTextureCache] addImage:@"RedParticle.png"];break;
        default:
            emitter.texture=[[CCTextureCache sharedTextureCache] addImage:@"DefaultParticle.png"];break;
    }
    
    emitter.sourcePosition  = point;
    [emitter setEmitterMode: kCCParticleModeGravity];
    
    // angle
    emitter.angle = 0;
    emitter.angleVar = 360;
    
    //  Gravity Mode: speed of particles
    emitter.speed = 55.33;
    emitter.speedVar = 288.21;
    
    // gravity
    emitter.gravity = ccp(333.68, 333.68);
    
    // Gravity Mode:  radial
    emitter.radialAccel = 0;
    emitter.radialAccelVar = 0;
    
    emitter.tangentialAccel = 0;
    emitter.tangentialAccelVar = 0.0;
    
    //life
    emitter.life = 0.20;
    emitter.lifeVar = 0.15;
    
    emitter.startSize = 5.0;
    emitter.startSizeVar = 15.00;
    emitter.endSize = 0.0;
    emitter.endSizeVar = 0.0;
    emitter.startSpin = 0.0;
    emitter.startSpinVar = 0.0;
    emitter.endSpin = 0.0;
    emitter.endSpinVar = 0.0;
    
    // blend function
    emitter.blendFunc = (ccBlendFunc) { 1,1 };
    
    // color
    emitter.startColor = (ccColor4F) {255,56,255,1};
    emitter.startColorVar = (ccColor4F) {0,0,0,1};
    emitter.endColor = (ccColor4F) {240,54,255,1};
    emitter.endColorVar = (ccColor4F) {0,0,0,0};
    
    // position
    emitter.position = ccp(0,0);
    
    emitter.emissionRate = emitter.totalParticles/emitter.life;
    emitter.blendAdditive = YES;
    return emitter;
}

#pragma mark - Create Body Methods

- (void)createDotAtLocation:(CGPoint)location withSize:(CGSize)size withTag:(int)tag andSprite :(CCSprite *)image {
    image.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    image.tag = tag;
    [self addChild:image z:1001];
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
    block = [CCSprite spriteWithFile:@"Eater-Normal.png"];
    block.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    block.tag = 2;
    [self addChild:block z:1000];
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
    blockBody->SetLinearDamping(10.0);

    if (lifeLeft <= 0 || timeCount == 0) {
        [self endTheGame];
    }
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    blockBody->SetAngularVelocity(8);

    [self deleteDotsInQueue];
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
            if ((spriteA.tag >= 1000 || spriteA.tag == 700) && spriteB.tag == 2) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyA]];
                [self updateLevelWithBallHit];
                [self playCatchAlert];
            } else if (spriteA.tag == 2 && (spriteB.tag >= 1000 || spriteB.tag == 700)) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyB]];
                [self updateLevelWithBallHit];
                [self playCatchAlert];
            } else if (spriteA.tag == 500 && spriteB.tag == 2) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyA]];
                lifeLeft++;
                bonusBallCatched++;
                [self playCatchAlert];
            }else if (spriteA.tag == 2 && spriteB.tag == 500) {
                [dotsToDestroy addObject:[NSValue valueWithPointer:bodyB]];
                lifeLeft++;
                bonusBallCatched++;
                [self playCatchAlert];
            }
        }

        if((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _topFixture && contact.fixtureB == _ballFixture)||
           (contact.fixtureA == _rightEdgeFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _leftEdgeFixture && contact.fixtureB == _ballFixture)){
            boxContactBody = YES;
        }
        }
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSpriteBatchNode *sprite = (CCSpriteBatchNode *) b->GetUserData();
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO,
                                  b->GetPosition().y * PTM_RATIO);
            sprite.rotation = CC_RADIANS_TO_DEGREES(b->GetAngle() * -1);
        }
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
