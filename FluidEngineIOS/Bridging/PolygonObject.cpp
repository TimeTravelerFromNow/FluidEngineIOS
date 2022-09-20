#include "PolygonObject.h"

PolygonObject::PolygonObject(b2World* worldRef,
                     b2Vec2* vertices,
                     int32 verticesCount,
                     b2Vec2 location) {
    m_world = worldRef;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_kinematicBody;
    bodyDef.active = true;
    bodyDef.gravityScale = 0.0;
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    b2ChainShape shape;
    b2FixtureDef fixtureDef;
    shape.CreateLoop(vertices, verticesCount);

    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0f;
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
