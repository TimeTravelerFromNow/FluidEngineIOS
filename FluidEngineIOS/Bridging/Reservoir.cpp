#include "Reservoir.h"

Reservoir::Reservoir(b2World* worldRef,
           b2ParticleSystem* particleSysRef,
           b2Vec2 location,
           b2Vec2* vertices, unsigned int count) {
    
    m_particleSys = particleSysRef;
    m_filter = b2Filter();
    m_filter.isFiltering = true;
    //m_particleSys->filter = m_filter;
       
    b2BodyDef body1Def;
    body1Def.type = b2_kinematicBody;
    body1Def.active = true;
    body1Def.gravityScale = 0.0;
    body1Def.position.Set(location.x, location.y);
    b2Body *body1 = worldRef->CreateBody(&body1Def);
    
    b2ChainShape shape;  // chain
    b2FixtureDef fixtureDef;
    shape.CreateChain(vertices, count);
    fixtureDef.shape = &shape;
    fixtureDef.filter = m_filter;
    
    m_PipeFixture = body1->CreateFixture(&fixtureDef);
    m_body = body1;
    
    b2BodyDef valve0BodyDef;
    valve0BodyDef.type = b2_kinematicBody;
    valve0BodyDef.active = true;
    valve0BodyDef.gravityScale = 0.0;
    valve0BodyDef.position.Set(location.x, location.y);
    b2FixtureDef valve0Def;
    b2EdgeShape valveLine;
    valveLine.Set(((b2Vec2 *)vertices)[0], ((b2Vec2 *)vertices)[count - 1]);
    valve0Def.shape = &valveLine;
    
    b2Body *body2 = worldRef->CreateBody(&valve0BodyDef);
    m_valve0Fixture = body2->CreateFixture(&valve0Def);
    m_valve0Body = body2;

    
    b2WeldJointDef weldJointDef;
    weldJointDef.bodyA = m_body;
    weldJointDef.bodyB = m_valve0Body;
    weldJointDef.collideConnected = false;
    worldRef->CreateJoint(&weldJointDef);
}
Reservoir::~Reservoir() {
    
}
//collision

long Reservoir::GetHoverCandidateGridId() {
    return 0; // MARK: if I want to do the hover logic in C++ I can, but it's up to me
}

b2Fixture* Reservoir::addDivider(b2Vec2* dividerVertices) {
    b2FixtureDef fixtureDef;
    fixtureDef.filter = m_filter;
    b2EdgeShape line;
    line.Set(((b2Vec2 *)dividerVertices)[0], ((b2Vec2 *)dividerVertices)[1]);
    fixtureDef.shape = &line;
    b2Fixture* lineFixture = m_body->CreateFixture(&fixtureDef);
    return lineFixture;
}

void Reservoir::removeDivider(b2Fixture* dividerRef) {
}

//pour guides
void Reservoir::AddGuides(b2Vec2* guidesVertices) {
}
void Reservoir::RemoveGuides() {
}
//movement
void Reservoir::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}
void Reservoir::SetRotation(float angVelocity) {
    m_body->SetAngularVelocity( angVelocity );
}
b2Vec2 Reservoir::GetPosition() {
    return m_body->GetPosition();
}
float Reservoir::GetRotation() {
    return m_body->GetAngle();
}

b2Vec2 Reservoir::GetVelocity() {
    return m_body->GetLinearVelocity();
}

bool Reservoir::IsAtPosition(b2Vec2 position) {
    return false;
}

void Reservoir::SetPourBits() {
}

void Reservoir::ClearPourBits() {
}

int Reservoir::EngulfParticles( b2ParticleSystem* originalSystem ) {
    return 0;
}

void Reservoir::SetValve0AngularVelocity( float angV ) {
    m_valve0Body->SetAngularVelocity(angV);
}

float Reservoir::GetValve0Rotation() {
    return m_valve0Body->GetAngle();
}
