//
//  Tube.c
//  FluidEngine
//
//  Created by sebi d on 1/23/22.
//

#include "JointTest.h"


JointTest::JointTest(b2World* worldRef, b2Vec2 location,
           b2Vec2* box1Vertices, unsigned int box1Count,
           b2Vec2* box2Vertices, unsigned int box2Count) {
    b2BodyDef body1Def;
    body1Def.type = b2_kinematicBody;
    body1Def.active = true;
    body1Def.gravityScale = 0.0;
    body1Def.position.Set(location.x, location.y);
    b2Body *body1 = worldRef->CreateBody(&body1Def);
    b2PolygonShape shape1;
    b2FixtureDef fixtureDef1;
    shape1.Set(box1Vertices, box1Count);
    fixtureDef1.shape = &shape1;
    fixtureDef1.density = 1.0f;
    body1->CreateFixture(&fixtureDef1);
    m_body1 = body1;
    
    b2BodyDef body2Def;
    body2Def.type = b2_dynamicBody;
    body2Def.active = true;
    body2Def.gravityScale = 0.0;
    body2Def.position.Set(location.x, location.y);
    b2Body *body2 = worldRef->CreateBody(&body2Def);
    b2PolygonShape shape2;
    b2FixtureDef fixtureDef2;
    shape2.Set(box2Vertices, box2Count);
    fixtureDef2.shape = &shape2;
    fixtureDef2.density = 2.0f;
    body2->CreateFixture(&fixtureDef2);
    
    b2WeldJointDef weldJointDef;
      weldJointDef.bodyA = body1;
      weldJointDef.bodyB = body2;
      weldJointDef.collideConnected = false;
    m_body2 = body2;
    
    worldRef->CreateJoint(&weldJointDef);
    
}

void JointTest::Move(b2Vec2 velocity) {
    m_body1->SetLinearVelocity(velocity);
}
