//
//  DotSprite.m
//  Box2DTest
//
//  Created by aliya on 31/03/15.
//  Copyright (c) 2015 QBurst. All rights reserved.
//

#import "DotSprite.h"
#import "AppDelegate.h"
#define PTM_RATIO 32

@implementation DotSprite

- (id)initAtLocation:(CGPoint)location withSize:(CGSize)size{

    self = [super initWithFile:@"images.png"];
    if (self) {
        self.position = ccp(location.x/PTM_RATIO, location.y/PTM_RATIO);
        self.tag = 1;
    }
    return self;
}

@end
