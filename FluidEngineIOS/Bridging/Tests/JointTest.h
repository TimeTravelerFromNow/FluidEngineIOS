//
//  JointTest.hpp
//  FluidEngine
//
//  Created by sebi d on 1/24/22.
//

#ifndef JointTest_h
#define JointTest_h

#include "Box2d.h"

class JointTest {
public:
    b2Body* m_body1;
    b2Body* m_body2;
public:
    JointTest(b2World* worldRef, b2Vec2 location,
               b2Vec2* box1Vertices, unsigned int box1Count,
               b2Vec2* box2Vertices, unsigned int box2Count);
    ~JointTest();
    
    void Move(b2Vec2 velocity);
};

#endif /* JointTest_h */
