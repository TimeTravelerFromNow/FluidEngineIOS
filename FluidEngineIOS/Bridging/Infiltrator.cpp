#include "Infiltrator.h"

// both Aliens and Human objects are of the class type Infiltrator as well as any other cool swift object that needs to be in Box2D.
// Infiltrator can also serve as the ultimate Box2D C++ to Objective C to Swift class 
Infiltrator::Infiltrator( b2World* worldRef,
                   //           b2ParticleSystem* particleSystem,
                   b2Vec2 location,
                   b2Vec2 velocity,
                   float startAngle,
                   float density,
                   float restitution,
                   //           long crashParticleCount, // explosive particle effect
                   //           float crashParticleDamage, // damage each particle will do
                   b2Filter filter) {
    m_world = worldRef;
    m_origin = location;
    m_density = density;
    m_restition = restitution;
    m_filter = filter;
};

Infiltrator::~Infiltrator() {
//    auto newEnd = std::remove( friendlies.begin(), friendlies.end(), this);
}

// MARK: you may wonder why this is in a class and not outside in LiquidFun,
// there are many physics constants that could be reused inside each infiltrator instance.
// there's no other reason, maybe also neatness, the interface is less crowded with method content.
// body methods
b2Body* Infiltrator::MakeBody(b2Vec2 atPos, float angle, b2Filter filter) {
    b2BodyDef bodyDef;
    bodyDef.gravityScale = 1.0f;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = atPos;
    bodyDef.angle = angle;
    bodyDef.active = true;
    bodyDef.awake = true;
    return m_world->CreateBody(&bodyDef);
}

void Infiltrator::DestroyBody(b2Body* bodyRef) {
    m_world->DestroyBody(bodyRef);
}

// attach methods
b2Fixture* Infiltrator::AttachPolygon(b2Body* onBody, b2Vec2 pos, b2Vec2* vertices, long vertexCount) {
    b2PolygonShape shape;
    b2FixtureDef fixtureDef;
    fixtureDef.density = m_density;
    fixtureDef.restitution = m_restition;
    shape.Set(vertices, vertexCount);
    fixtureDef.filter = m_filter;
    fixtureDef.shape = &shape;
    return onBody->CreateFixture( &fixtureDef );
}
b2Fixture* Infiltrator::AttachCircle(b2Body* onBody, b2Vec2 pos, float radius) {
    b2CircleShape shape;
    shape.m_radius = radius;
    b2FixtureDef fixtureDef;
    fixtureDef.density = m_density;
    fixtureDef.restitution = m_restition;
    fixtureDef.filter = m_filter;
    fixtureDef.friction = 0.7f;
    fixtureDef.shape = &shape;
    return onBody->CreateFixture( &fixtureDef );
}

// joint methods
b2Joint* Infiltrator::WheelJoint(b2Body* bodyA, b2Body* bodyB, b2Vec2 weldPos, b2Vec2 localAxisA, float stiffness, float damping) {
    b2WheelJointDef jointDef;
    jointDef.bodyA = bodyA;
    jointDef.bodyB = bodyB;
    jointDef.localAnchorA = weldPos;
    jointDef.collideConnected = false;
    jointDef.localAxisA = localAxisA;
    jointDef.frequencyHz = stiffness;
    jointDef.dampingRatio = damping;
    return m_world->CreateJoint( &jointDef );
}


//void Infiltrator::WeldInfiltrator( Infiltrator* infiltrator, b2Vec2 weldPos, float stiffness) {
//    b2Body* otherBody = infiltrator->GetBody();
//    b2WeldJointDef jointDef;
//    jointDef.bodyA = m_body;
//    jointDef.bodyB = otherBody;
//    jointDef.collideConnected = false;
//    jointDef.localAnchorA = weldPos;
//    jointDef.frequencyHz = stiffness;
//    b2Joint* joint = m_world->CreateJoint( &jointDef );
//}
