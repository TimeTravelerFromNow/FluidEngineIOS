#include "Alien.h"

Alien::Alien( b2World* worldRef,
             //           b2ParticleSystem* particleSystem,
             b2Vec2 location,
             b2Vec2* vertices,
             long vertexCount,
             float density,
             float health,
             float crashDamage, // damage of crash on anything ( even other enemies if possible )
             //           long crashParticleCount, // explosive particle effect
             //           float crashParticleDamage, // damage each particle will do
             uint16 categoryBits,
             uint16 maskBits,
             int16 groupIndex) {
    m_world = worldRef;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
//    bodyDef.gravityScale = 0.0;
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    b2PolygonShape shape;
    b2FixtureDef fixtureDef;
    shape.Set(vertices, vertexCount);

    fixtureDef.shape = &shape;
    fixtureDef.density = density;
    fixtureDef.restitution = 1.0f;
    fixtureDef.filter = b2Filter();
    fixtureDef.filter.categoryBits = categoryBits;
    fixtureDef.filter.maskBits = maskBits;
    fixtureDef.filter.groupIndex = groupIndex;
    m_fixture = body->CreateFixture(&fixtureDef);
    m_body = body;
};

Alien::~Alien() {
    m_body->DestroyFixture(m_fixture);
    m_world->DestroyBody(m_body);
    auto newEnd = std::remove( aliens.begin(), aliens.end(), this);
}

void Alien::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}

void Alien::Impulse(b2Vec2 impulse) {
    m_body->ApplyLinearImpulse(impulse, b2Vec2(0,0), true);
}

b2Vec2 Alien::GetPosition() {
    return m_body->GetPosition();
}

float Alien::GetRotation() {
    return m_body->GetAngle();
}

float Alien::GetHealth() {
    return health;
}

void Alien::TakeDamage() {
    health -= 1;
}


b2Body* Alien::GetBody() {
    return m_body;
}

