//
//  GameContactListener.h
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "Box2D.h"
#import <vector>
#import <algorithm>

struct DotContact {
    b2Fixture *fixtureA;
    b2Fixture *fixtureB;
    bool operator==(const DotContact& other) const
    {
        return (fixtureA == other.fixtureA) && (fixtureB == other.fixtureB);
    }
};

class BlockContactListener : public b2ContactListener {
    
public:
    std::vector<DotContact>_contacts;
    
    BlockContactListener();
    ~BlockContactListener();
    
    virtual void BeginContact(b2Contact* contact);
    virtual void EndContact(b2Contact* contact);
    virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
    virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
    
};
