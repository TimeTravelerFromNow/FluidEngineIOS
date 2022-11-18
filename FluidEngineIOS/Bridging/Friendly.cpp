#include "Friendly.h"

Friendly::Friendly(b2World* worldRef,
                    b2Vec2 location,
                    b2Vec2* vertices,
                    long vertexCount) {
    m_world = worldRef;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.gravityScale = 0.0;
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    b2PolygonShape shape;
    b2FixtureDef fixtureDef;
    shape.Set(vertices, vertexCount);

    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0f;
    fixtureDef.restitution = 1.0f;
    fixtureDef.filter = b2Filter();
    fixtureDef.filter.categoryBits = 0x0001;
    fixtureDef.filter.maskBits = 0x0001;
    body->CreateFixture(&fixtureDef);
    m_body = body;
};

void Friendly::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}


b2Vec2 Friendly::GetPosition() {
    return m_body->GetPosition();
}

float Friendly::GetRotation() {
    return m_body->GetAngle();
}
