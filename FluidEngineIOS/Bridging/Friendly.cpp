#include "Friendly.h"

Friendly::Friendly( b2World* worldRef,
                   //           b2ParticleSystem* particleSystem,
                   b2Vec2 location,
                   b2Vec2 velocity,
                   float startAngle,
                   float density,
                   float restitution,
                   float health,
                   float crashDamage, // damage of crash on anything ( even other enemies if possible )
                   //           long crashParticleCount, // explosive particle effect
                   //           float crashParticleDamage, // damage each particle will do
                   uint16 categoryBits,
                   uint16 maskBits,
                   int16 groupIndex) {
    m_world = worldRef;
    m_origin = location;
    m_density = density;
    m_restition = restitution;
    m_health = health;
    m_crashDamage = crashDamage;
    
    m_filter.categoryBits = categoryBits;
    m_filter.maskBits = maskBits;
    m_filter.groupIndex = groupIndex;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
//    bodyDef.gravityScale = 0.0;
//    body
    bodyDef.linearVelocity = velocity;
    bodyDef.angle = startAngle;
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    
    m_body = body;
};

Friendly::~Friendly() {
    m_body->DestroyFixture(m_fixture);
    m_world->DestroyBody(m_body);
    auto newEnd = std::remove( friendlies.begin(), friendlies.end(), this);
}

void Friendly::SetAsPolygonShape(b2Vec2* vertices,
                       long vertexCount) {
    b2PolygonShape shape;
    b2FixtureDef fixtureDef;
    shape.Set(vertices, vertexCount);

    fixtureDef.shape = &shape;
    fixtureDef.density = m_density;
    fixtureDef.restitution = m_restition;
    fixtureDef.filter = m_filter;

    m_fixture = m_body->CreateFixture(&fixtureDef);
}

void Friendly::SetAsCircleShape(float radius) {
    b2CircleShape shape;
    b2FixtureDef fixtureDef;
    
    shape.m_radius = radius;
    
    fixtureDef.shape = &shape;
    fixtureDef.density = m_density;
    fixtureDef.restitution = m_restition;
    fixtureDef.filter = m_filter;
    fixtureDef.friction = 1.0;
    m_body->SetAngularDamping(0.1);
    m_fixture = m_body->CreateFixture(&fixtureDef);
}

void Friendly::AddCircle( float radius ) {
    b2CircleShape shape;
    b2FixtureDef fixtureDef;
    
    shape.m_radius = radius;
    
    fixtureDef.shape = &shape;
    fixtureDef.density = m_density;
    fixtureDef.restitution = m_restition;
    fixtureDef.filter = m_filter;
    fixtureDef.friction = 1.0;
    m_body->SetAngularDamping(0.1);
    m_circleFixture = m_body->CreateFixture(&fixtureDef);
}

void Friendly::SetFixedRotation(bool to) {
    m_body->SetFixedRotation(to);
}

void Friendly::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}

void Friendly::SetAngularVelocity(float to) {
    m_body->SetAngularVelocity(to);
}

void Friendly::Torque(float amt) {
    m_body->ApplyTorque(amt, true);
}

void Friendly::Impulse(b2Vec2 imp, b2Vec2 atPos) {
    m_body->ApplyLinearImpulse(imp, atPos, true);
}

b2Vec2 Friendly::GetPosition() {
    return m_body->GetPosition();
}

float Friendly::GetRotation() {
    return m_body->GetAngle();
}

float Friendly::GetAngV() {
    return m_body->GetAngularVelocity();
}

b2Vec2 Friendly::GetVel() {
    return m_body->GetLinearVelocity();
}

void Friendly::WeldFriendly( Friendly* friendly, b2Vec2 weldPos, float stiffness) {
    b2Body* otherBody = friendly->GetBody();
    b2WeldJointDef jointDef;
    jointDef.bodyA = m_body;
    jointDef.bodyB = otherBody;
    jointDef.collideConnected = false;
    jointDef.localAnchorA = weldPos;
    jointDef.frequencyHz = stiffness;
    b2Joint* joint = m_world->CreateJoint( &jointDef );
}

void Friendly::WheelFriendly( Friendly* friendly, b2Vec2 weldPos, float stiffness, float damping) {
    b2Body* otherBody = friendly->GetBody();
    b2WheelJointDef jointDef;
    jointDef.bodyA = m_body;
    jointDef.bodyB = otherBody;
    jointDef.localAnchorA = weldPos;
    jointDef.collideConnected = false;
    jointDef.localAxisA = b2Vec2(0, 1);
    jointDef.frequencyHz = stiffness;
    jointDef.dampingRatio = damping;
    b2Joint* joint = m_world->CreateJoint( &jointDef );
}


float Friendly::GetHealth() {
    return m_health;
}

void Friendly::TakeDamage() {
    m_health -= 1;
}


b2Body* Friendly::GetBody() {
    return m_body;
}
