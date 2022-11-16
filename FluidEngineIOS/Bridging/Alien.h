#ifndef Alien_h
#define Alien_h

#include <stdio.h>
#include "Box2D.h"

class Alien {

public:
    Alien(b2World* worldRef,
          b2Vec2 position,
          b2Vec2* vertices,
          long vertexCount);
    ~Alien();
    
private:
    
private:
    b2Body* m_body;
    b2World* m_world;
};

#endif /* Alien_h */

