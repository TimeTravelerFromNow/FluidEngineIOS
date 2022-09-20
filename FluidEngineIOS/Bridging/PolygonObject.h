#ifndef PolygonObject_h
#define PolygonObject_h

#include <stdio.h>
#include "Box2D.h"
class PolygonObject {

public:
    PolygonObject(b2World* worldRef,
                  b2Vec2* vertices,
                  int32 verticesCount,
                  b2Vec2 location);
    ~PolygonObject();
    
    b2Vec2 GetPosition();
    float GetRotation();
    void SetVelocity(b2Vec2 velocity);
    
private:
    b2Body* m_body;
    b2World* m_world;
};

#endif /* PolygonObject_h */

