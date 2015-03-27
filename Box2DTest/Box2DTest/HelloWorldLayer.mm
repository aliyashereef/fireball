//
//  HelloWorldLayer.mm
//  Box2DTest
//
//  Created by aliya on 25/03/15.
//  Copyright QBurst 2015. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "MyContactListener.h"


enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer(){
    b2Fixture *_ballFixture;
    b2Fixture *_dotFixture;
    MyContactListener *_contactListener;


}
-(void) initPhysics;

@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
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
        
		// init physics
		[self initPhysics];
        // Create a world
        b2Vec2 gravity = b2Vec2(-0.0f, -8.0f);
        _world = new b2World(gravity);
        // Create contact listener
        _contactListener = new MyContactListener();
        _world->SetContactListener(_contactListener);
            
            // Create block and add it to the layer
            CCSprite *block = [CCSprite spriteWithFile:@"images.png"];
            block.position = ccp(100, 250);
            block.tag = 1;
            [self addChild:block];
            
            // Create block body
            b2BodyDef blockBodyDef;
            blockBodyDef.type = b2_dynamicBody;
            blockBodyDef.position.Set(arc4random()%568, arc4random()%320);
            blockBodyDef.userData = block;
            b2Body *blockBody = _world->CreateBody(&blockBodyDef);
            
            // Create block shape
            b2PolygonShape blockShape;
            blockShape.SetAsBox(block.contentSize.width/PTM_RATIO/2,
                                block.contentSize.height/PTM_RATIO/2);
            
            // Create shape definition and add to body
            b2FixtureDef blockShapeDef;
            blockShapeDef.shape = &blockShape;
            blockShapeDef.density = 10.0;
            blockShapeDef.friction = 0.0;
            blockShapeDef.restitution = 0.1f;
            blockBody->CreateFixture(&blockShapeDef);
        [self moveRandom:block];
        //a box body
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(500/PTM_RATIO, 500/PTM_RATIO);
        bodyDef.gravityScale = 1.5 ;
        bodyDef.allowSleep = false ;
        b2Body *body = world->CreateBody(&bodyDef);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox( 0.5f, 0.5f);//These are mid points for our 1m box
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.0f;
        _dotFixture = body->CreateFixture(&fixtureDef);
        
        CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithFile:@"Step2.png" rect:CGRectMake(0,0,30,30)];
        [self addChild:sprite];
        
        [sprite setPTMRatio:PTM_RATIO];
        [sprite setB2Body:body];
        [sprite setPosition: ccp( 200, 200)];
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}	

-(void) initPhysics
{
	CGSize s = [[CCDirector sharedDirector] winSize];
	b2Vec2 gravity;
	gravity.Set(0.0f, -0.0f);
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
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

-(void) draw
{
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();
	
	kmGLPopMatrix();
}

-(void)moveRandom:(CCSprite*)s
{
    CGPoint randomPoint = ccp(arc4random()%568, arc4random()%320);
    [s runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:0.9 position: randomPoint],
      [CCCallBlock actionWithBlock:^{
         [self performSelector:@selector(moveRandom:) withObject:s afterDelay:0.0];
     }],
      nil]
     ];
}

-(void) update: (ccTime) dt
{
    int32 velocityIterations = 8;
	int32 positionIterations = 1;

    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        if ((contact.fixtureA == _dotFixture && contact.fixtureB == _ballFixture) ||
            (contact.fixtureA == _ballFixture && contact.fixtureB == _dotFixture)) {
            NSLog(@"Ball hit bottom!");
        }
    }
	world->Step(dt, velocityIterations, positionIterations);	
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
    static float prevX=0, prevY=0;
    #define kFilterFactor .05f
    float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
    float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
    
    prevX = accelX;
    prevY = accelY;
    
    // accelerometer values are in "Portrait" mode. Change them to Landscape left
    // multiply the gravity by 10
    b2Vec2 gravity( acceleration.y  * 50, -acceleration.x  * 50);
    
    world->SetGravity( gravity );
}
#pragma mark GameKit delegate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController{
    
}
@end
