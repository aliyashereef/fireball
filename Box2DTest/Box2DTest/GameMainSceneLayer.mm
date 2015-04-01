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

#pragma mark - GameMainSceneLayer

@interface GameMainSceneLayer(){
    b2Fixture *_ballFixture;
    b2Fixture *_dotFixture;
    b2Fixture *_bottomFixture;
    b2Fixture *_topFixture;
    b2Fixture *_leftEdgeFixture;
    b2Fixture *_rightEdgeFixture;

    MyContactListener *_contactListener;
    CCProgressTimer *lifeBar;
    
    CCLabelTTF *scoreNode;
    CCLabelTTF *timeNode;
    
    int score;
    int timeCount;
    int dotTag;
    int lifeLeft;
    int destroyedSpriteTag;
    CGSize screenSize;
    BOOL boxContactBody;
    
    NSTimer *updateTimer;
    NSTimer *dotLifeTimer;
    NSTimer *deleteDotTimer;

}

-(void) initPhysics;

@end

@implementation GameMainSceneLayer

+(CCScene *) scene
{
    CCScene *scene = [CCScene node];
    GameMainSceneLayer *layer = [GameMainSceneLayer node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}

-(id) init
{
    if( (self=[super init])) {
        // enable events
        self.touchEnabled = YES;
        self.accelerometerEnabled = YES;
        screenSize=[[CCDirector sharedDirector]winSize];
        
        // init physics
        [self initPhysics];
        
        timeCount = 0;
        dotTag = 1000;
        lifeLeft = 5;
        
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
        dotLifeTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateDotLifeTime) userInfo:nil repeats:YES];
        deleteDotTimer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(deleteDot) userInfo:nil repeats:YES];
        
        // Create contact listener
        _contactListener = new MyContactListener();
        world->SetContactListener(_contactListener);
        [self createScoreBar];
        [self createLifeBar];
        [self createBlockAtLocation:ccp(screenSize.width/2,screenSize.height/2) withSize:CGSizeMake(10, 10)];
        [self createDotAtLocation:ccp(50 , 50) withSize:CGSizeMake(10, 10) withTag:dotTag];
        [self scheduleUpdate];
        [self schedule:@selector(randomMotion) interval:.1];
    }
    return self;
}

-(void) initPhysics
{
    b2Vec2 gravity;
    gravity.Set(-0.0f, -0.0f);
    world = new b2World(gravity);
    
    // Do we want to let bodies sleep?
    world->SetAllowSleeping(true);
    world->SetContinuousPhysics(true);
    
    m_debugDraw = new GLESDebugDraw( PTM_RATIO );
    world->SetDebugDraw(m_debugDraw);
    uint32 flags = 0;
    flags += b2Draw::e_shapeBit;
    m_debugDraw->SetFlags(flags);
    
    // Define the ground body.
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0); // bottom-left corner
    
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    
    // Define the ground box shape.
    b2EdgeShape groundBox;
    
    // bottom
    groundBox.Set(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
    _bottomFixture = groundBody->CreateFixture(&groundBox,0);
    
    // top
    groundBox.Set(b2Vec2(0,(screenSize.height-58)/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,(screenSize.height-58)/PTM_RATIO));
    _topFixture = groundBody->CreateFixture(&groundBox,0);
    
    // left
    groundBox.Set(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
    _leftEdgeFixture = groundBody->CreateFixture(&groundBox,0);
    
    // right
    groundBox.Set(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
    _rightEdgeFixture = groundBody->CreateFixture(&groundBox,0);
}

-(void) draw
{
    [super draw];
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    kmGLPushMatrix();
    world->DrawDebugData();
    kmGLPopMatrix();
}

#pragma mark - Private Methods

- (void)createLifeBar {
    lifeBar= [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"life.png"]];
    lifeBar.type = kCCProgressTimerTypeBar;
    lifeBar.midpoint = ccp(0,0);
    lifeBar.barChangeRate = ccp(1,0);
    lifeBar.percentage = 100;
    lifeBar.position = ccp(screenSize.width/2-(lifeBar.contentSize.width/4),screenSize.height-lifeBar.contentSize.height-20);
    lifeBar.tag = 4;
    [self addChild:lifeBar];
}
- (void)createScoreBar{
    //Create score bar
    CCSprite *scoreBar = [CCSprite spriteWithFile:@"status.png"];
    scoreBar.position = ccp(0,screenSize.height);
    scoreBar.tag = 3;
    [self addChild:scoreBar];
    
    scoreNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",score] fontName:@"Arial" fontSize:30.0 ];
    scoreNode.position = ccp(screenSize.width*0.90,screenSize.height*0.93);
    [self addChild:scoreNode z:99];
    
    timeNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",score] fontName:@"Arial" fontSize:30.0 ];
    timeNode.position = ccp(screenSize.width*0.10,screenSize.height*0.93);
    [self addChild:timeNode z:100];
}

-(void)updateTime{
    if (boxContactBody) {
        lifeLeft--;
        boxContactBody = NO;
        [lifeBar setPercentage:20*lifeLeft];
    }
   for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
            if (b->GetUserData() != NULL ) {
                CCSprite *sprite = (CCSprite *) b->GetUserData();
                if (sprite.tag == 2) {
                    b->SetLinearDamping(10.0);
                }
            }
    }
    timeNode.string = [NSString stringWithFormat:@" %d ",timeCount];
    timeCount++;
    if (timeCount == 120) {
        [self invalidateAllTimers];
        CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:@"Time Out" withScore:score];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
}
- (void)deleteDot {
    for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
        if (b->GetUserData() != NULL ) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            if (sprite.tag >= 1000) {
                NSLog(@"%d",sprite.tag);
                [sprite setColor:ccc3(255,50,0)];
                double delayInSeconds = 4.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if (sprite.tag != destroyedSpriteTag && b->GetUserData() != NULL) {
                        world->DestroyBody( b );
                        CCSprite *sprite = (CCSprite *) b->GetUserData();
                        [self removeChild:sprite cleanup:YES];
                        lifeLeft--;
                        [lifeBar setPercentage:20*lifeLeft];
                    }
                });
                break;
            }
        }
    }
}
- (void)updateDotLifeTime{
    dotTag++;
    [self createDotAtLocation:ccp(50 , 50) withSize:CGSizeMake(10, 10) withTag:dotTag];
}

- (void)endTheGame {
    [self invalidateAllTimers];
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
    float ratio = 10 / speed;
    velocity*=ratio;
    _dotFixture->GetBody()->SetLinearVelocity(velocity);
}

- (void)updateLevel {
    score++;
    AppController *controller = [[UIApplication sharedApplication] delegate];
    controller.gameLevel = [NSNumber numberWithInt:score+1];
    [scoreNode setString:[NSString stringWithFormat:@" %d ", score]];
    dotTag++;
    [self createDotAtLocation:ccp(50 , 50) withSize:CGSizeMake(10, 10) withTag:dotTag];
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
}

- (NSString *)updateHighScoreWithScore:(int)highScore{
    NSNumber *savedScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"High Score"];
    if ( highScore > [savedScore intValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:highScore] forKey:@"High Score"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return @"High Score !";
    }else{
        return @"Game Over";
    }
}

#pragma mark - Create Body Methods

- (void)createDotAtLocation:(CGPoint)location withSize:(CGSize)size withTag:(int)tag {
    CCSprite *dot = [CCSprite spriteWithFile:@"images.png"];
    dot.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    dot.tag = tag;
    [self addChild:dot];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    bodyDef.gravityScale = 0 ;
    bodyDef.allowSleep = false ;
    bodyDef.userData = dot;
    b2Body *dotb;
    dotb = world->CreateBody(&bodyDef);
    b2CircleShape shape;
    shape.m_radius = 0.20f;
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 1;
    fixtureDef.friction = 0;
    fixtureDef.restitution = 0.5;
    double angle =  arc4random()%80+5 ;
    dotb->SetLinearVelocity(b2Vec2(50*sin(angle),50*cos(angle)));
    _dotFixture = dotb->CreateFixture(&fixtureDef);
}

- (void)createBlockAtLocation:(CGPoint)location withSize:(CGSize)size {
    boxContactBody = NO;
    // Create block and add it to the layer
    CCSprite *block = [CCSprite spriteWithFile:@"Step2.png"];
    block.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    block.tag = 2;
    [self addChild:block];
    b2BodyDef bodyDef2;
    bodyDef2.type = b2_dynamicBody;
    bodyDef2.gravityScale = 1 ;
    bodyDef2.allowSleep = false ;
    bodyDef2.userData = block;
    bodyDef2.position = b2Vec2(location.x/PTM_RATIO,location.y/PTM_RATIO);
    b2Body *body2 = world->CreateBody(&bodyDef2);
    b2PolygonShape shape2;
    shape2.SetAsBox(0.5f, 0.5f);
    b2FixtureDef fixtureDef2;
    fixtureDef2.shape = &shape2;
    fixtureDef2.density = 50.0;
    _ballFixture = body2->CreateFixture(&fixtureDef2);
}

#pragma mark - Update Methods

-(void) update: (ccTime) dt
{
    world->ClearForces();
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos) {
    
        MyContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
            if (spriteA.tag >= 1000 && spriteB.tag == 2) {
                toDestroy.push_back(bodyA);
                destroyedSpriteTag = spriteA.tag;
                [self updateLevel];
            } else if (spriteA.tag == 2 && spriteB.tag >= 1000) {
                toDestroy.push_back(bodyB);
                destroyedSpriteTag = spriteB.tag;
                [self updateLevel];
            }
        }

        if((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _topFixture && contact.fixtureB == _ballFixture)||
           (contact.fixtureA == _rightEdgeFixture && contact.fixtureB == _ballFixture) ||
           (contact.fixtureA == _leftEdgeFixture && contact.fixtureB == _ballFixture))
        {
            boxContactBody = YES;
        }
    }
    
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            [self removeChild:sprite cleanup:YES];
        }
        world->DestroyBody(body);
    }
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

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
    b2Vec2 gravity( acceleration.x  * 450, acceleration.y  * 450);
    world->SetGravity( gravity );
}

#pragma mark GameKit Delegate Methods

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController{
    
}

-(void) dealloc
{
    delete world;
    world = NULL;
    
    delete m_debugDraw;
    m_debugDraw = NULL;
    
    delete _contactListener;
    _contactListener = NULL;
    
    [super dealloc];
}	

@end
