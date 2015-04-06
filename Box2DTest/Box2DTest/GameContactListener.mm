//
//  GameContactListener.m
//  Box2DTest
//
//  Created by aliya on 30/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "GameContactListener.h"

BlockContactListener::BlockContactListener() : _contacts() {
}

BlockContactListener::~BlockContactListener() {
}

void BlockContactListener::BeginContact(b2Contact* contact) {
    // We need to copy out the data because the b2Contact passed in
    // is reused.
    DotContact myContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    _contacts.push_back(myContact);
}

void BlockContactListener::EndContact(b2Contact* contact) {
    DotContact dotContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    std::vector<DotContact>::iterator pos;
    pos = std::find(_contacts.begin(), _contacts.end(), dotContact);
    if (pos != _contacts.end()) {
        _contacts.erase(pos);
    }
}

void BlockContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold) {
}

void BlockContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {
}
