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
    b2Body *dotBody;
    CCLabelTTF *scoreNode;
    CCLabelTTF *timeNode;
    int score;
    int timeCount;
    CGSize screenSize;
    NSTimer *updateTimer;
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
        [updateTimer invalidate];
        // enable events
        self.touchEnabled = YES;
        self.accelerometerEnabled = YES;
        screenSize=[[CCDirector sharedDirector]winSize];
        
        // init physics
        [self initPhysics];
        
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
        
        // Create contact listener
        _contactListener = new MyContactListener();
        world->SetContactListener(_contactListener);
        
        CCSprite *scoreBar = [CCSprite spriteWithFile:@"status.png"];
        scoreBar.position = ccp(0,screenSize.height);
        scoreBar.tag = 3;
        [self addChild:scoreBar];
        timeCount = 0;
        
        scoreNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",score] fontName:@"Arial" fontSize:30.0 ];
        scoreNode.position = ccp(screenSize.width*0.90,screenSize.height*0.93);
        [self addChild:scoreNode z:99];
        
        timeNode = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ",score] fontName:@"Arial" fontSize:30.0 ];
        timeNode.position = ccp(screenSize.width*0.10,screenSize.height*0.93);
        [self addChild:timeNode z:100];
        
        [self createBlockAtLocation:ccp(screenSize.width/2,screenSize.height/2) withSize:CGSizeMake(10, 10)];
        [self createDotAtLocation:ccp(50 , 50) withSize:CGSizeMake(10, 10)];
        [self scheduleUpdate];
        [self schedule:@selector(randomMotion) interval:.1];
    }
    return self;
}

-(void)updateTime{
   for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {
            if (b->GetUserData() != NULL ) {
                 if (timeCount < 5) {
                     b->SetLinearDamping(0.5);
                 }else {
                     b->SetLinearDamping(0);
                 }
            }
    }
    timeNode.string = [NSString stringWithFormat:@" %d ",timeCount];
    timeCount++;
    if (timeCount == 30) {
        [updateTimer invalidate];
        CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:NO];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
}

- (void)randomMotion {
    b2Vec2 velocity = dotBody->GetLinearVelocity();
    float speed = velocity.Length();
    float ratio = 5 / speed;
    velocity*=ratio;
    dotBody->SetLinearVelocity(velocity);
}

-(void) initPhysics
{
    b2Vec2 gravity;
    gravity.Set(-8.0f, -8.0f);
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

- (void)createDotAtLocation:(CGPoint)location withSize:(CGSize)size {
    CCSprite *dot = [CCSprite spriteWithFile:@"images.png"];
    dot.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
    dot.tag = 1;
    [self addChild:dot];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    bodyDef.gravityScale = 0 ;
    bodyDef.allowSleep = false ;
    bodyDef.userData = dot;
    dotBody = world->CreateBody(&bodyDef);
    b2CircleShape shape;
    shape.m_radius = 0.20f;
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 1;
    fixtureDef.friction = 0;
    fixtureDef.restitution = 0.5;
    dotBody->SetLinearVelocity(b2Vec2(50,50));
    _dotFixture = dotBody->CreateFixture(&fixtureDef);
}

- (void)createBlockAtLocation:(CGPoint)location withSize:(CGSize)size {
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
    fixtureDef2.density = 100.0;
    _ballFixture = body2->CreateFixture(&fixtureDef2);
    
}

-(void) update: (ccTime) dt
{
    world->ClearForces();
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    
    for (b2Contact* contact = world->GetContactList(); contact; contact = contact->GetNext()){
        contact->GetFixtureA();contact->GetFixtureB();
        if ((contact->GetFixtureA() == _dotFixture && contact->GetFixtureB() == _ballFixture) ||
            (contact->GetFixtureA() == _ballFixture && contact->GetFixtureB() == _dotFixture)) {
            NSLog(@" Ball Collided ! ");
            score++;
            [updateTimer invalidate];
            [scoreNode setString:[NSString stringWithFormat:@" %d ", score]];
            CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:YES];
            [[CCDirector sharedDirector] replaceScene:gameOverScene];

        } else if((contact->GetFixtureA() == _bottomFixture && contact->GetFixtureB() == _ballFixture) ||
                  (contact->GetFixtureA() == _topFixture && contact->GetFixtureB() == _ballFixture)||
                  (contact->GetFixtureA() == _rightEdgeFixture && contact->GetFixtureB() == _ballFixture) ||
                  (contact->GetFixtureA() == _leftEdgeFixture && contact->GetFixtureB() == _ballFixture))
        {
            [updateTimer invalidate];
            CCScene *gameOverScene = [GameOverSceneLayer sceneWithWon:NO];
            [[CCDirector sharedDirector] replaceScene:gameOverScene];

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

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
    b2Vec2 gravity( acceleration.x  * 15, acceleration.y  * 15);
    world->SetGravity( gravity );
}

#pragma mark GameKit delegate

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
    
    dotBody = NULL;
    
    [super dealloc];
}	

@end
