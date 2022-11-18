#ifndef Alien_h
#define Alien_h

#include <stdio.h>
#include "Box2D.h"
class Alien {

public:
    Alien(b2World* worldRef,
          b2Vec2 location,
          b2Vec2* vertices,
          long vertexCount);
    ~Alien();
    
    b2Vec2 GetPosition();
    float GetRotation();
    void SetVelocity(b2Vec2 velocity);
    
private:
    b2Body* m_body;
    b2World* m_world;
};

#endif /* Alien_h */

