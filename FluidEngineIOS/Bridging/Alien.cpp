#include "Alien.h"

Alien::Alien(b2World* worldRef,
             b2Vec2 position,
             b2Vec2* vertices,
             long vertexCount) {
    m_world = worldRef;

    b2PolygonShape shape;
    shape.Set(vertices, vertexCount);
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.active = true;
    bodyDef.position = position;

    m_body = m_world->CreateBody(&bodyDef);
};
