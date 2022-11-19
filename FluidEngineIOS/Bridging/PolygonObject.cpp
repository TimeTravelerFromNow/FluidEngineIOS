#include "PolygonObject.h"

PolygonObject::PolygonObject(b2World* worldRef,
                     b2Vec2* vertices,
                     int32 verticesCount,
                     b2Vec2 location,
                             bool asStaticChain) {
    m_world = worldRef;
    
    b2BodyDef bodyDef;

    b2ChainShape chainShape;
    b2PolygonShape polygonShape;
    b2FixtureDef fixtureDef;
    
    if (asStaticChain) {
        bodyDef.type = b2_staticBody;
        chainShape.CreateLoop(vertices, verticesCount);
        fixtureDef.shape = &chainShape;
    } else {
        bodyDef.type = b2_dynamicBody;
        polygonShape.Set(vertices, verticesCount);
        fixtureDef.shape = &polygonShape;
        fixtureDef.density = 100.0f;
        fixtureDef.restitution = 0.01f;
        fixtureDef.friction = 0.5;
        bodyDef.gravityScale = 1.0;
    }
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    
   
    fixtureDef.filter = b2Filter();
    fixtureDef.filter.categoryBits = 0x0001;
    fixtureDef.filter.maskBits = 0x0001;
    body->CreateFixture(&fixtureDef);
    m_body = body;
};

void PolygonObject::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}


b2Vec2 PolygonObject::GetPosition() {
    return m_body->GetPosition();
}

float PolygonObject::GetRotation() {
    return m_body->GetAngle();
}
