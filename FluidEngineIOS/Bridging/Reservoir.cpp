#include "Reservoir.h"

Reservoir::Reservoir(b2World* worldRef,
           b2ParticleSystem* particleSysRef,
           b2Vec2 location,
           b2Vec2* vertices, unsigned int count) {
    m_world = worldRef;
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
    
    b2Vec2 firstVertex = ((b2Vec2 *)vertices)[0];
    b2Vec2 lastVertex = ((b2Vec2 *)vertices)[count - 1];
    valveLine.Set(firstVertex, lastVertex);
    valve0Def.shape = &valveLine;
    
    m_exitWidth = abs(firstVertex.x - lastVertex.x);
    m_exitPosition = b2Vec2(location.x + (firstVertex.x + lastVertex.x) / 2, location.y + (firstVertex.y + lastVertex.y) / 2);
    
    b2Body *valve0Body = worldRef->CreateBody(&valve0BodyDef);
//    m_valve0Fixture = body2->CreateFixture(&valve0Def);
    m_valve0Body = valve0Body;
    
    b2WeldJointDef weldJointDef;
    weldJointDef.bodyA = m_body;
    weldJointDef.bodyB = m_valve0Body;
    weldJointDef.collideConnected = false;
    worldRef->CreateJoint(&weldJointDef);
}

void Reservoir::CreateBulb(long hemisphereSegments, float bulbRadius) {
    b2BodyDef bulbBodyDef;
    bulbBodyDef.type = b2_kinematicBody;
    bulbBodyDef.active = true;
    bulbBodyDef.gravityScale = 0.0;
    
    b2Vec2 bulbCenter = b2Vec2( m_exitPosition.x, m_exitPosition.y - bulbRadius);
    bulbBodyDef.position.Set( bulbCenter.x, bulbCenter.y );
    
    float currentIterationAngle = 0.0;
    float angleIncrement = b2_pi / hemisphereSegments;

    b2Body *bulbBody = m_world->CreateBody(&bulbBodyDef);
    for( float f; f < 2 * b2_pi; f += angleIncrement ) {
//        if ( ( ((b2_pi / 2) - 0.2) < f && f < ((b2_pi / 2) + 0.2) ) ) {
            
//        } else {
            b2FixtureDef lineFixtureDef;
            b2EdgeShape bulbLine;
            
            float y = sin( f ) * bulbRadius; // center of the line
            float x = cos( f ) * bulbRadius;
            float xT = sin( f ) * angleIncrement * bulbRadius * 0.6; // tangent
            float yT = cos( f ) * angleIncrement * bulbRadius * 0.6;
            b2Vec2 cwVertex = b2Vec2( x + xT, y - yT);
            b2Vec2 ccwVertex = b2Vec2( x - xT, y + yT);
            bulbLine.Set(cwVertex, ccwVertex);
            lineFixtureDef.shape = &bulbLine;
            b2Fixture* lineFixture = bulbBody->CreateFixture(&lineFixtureDef);
            m_lineFixtures.push_back(lineFixture);
            
            numBulbWallPieces++;
//        }
    }
    m_bulbBody = bulbBody;
}

b2Vec2 Reservoir::GetBulbSegmentPosition(long atIndex) {
    b2Vec2 v0 = ((b2EdgeShape*)m_lineFixtures[ atIndex ]->GetShape())->m_vertex0;
    b2Vec2 v1 = ((b2EdgeShape*)m_lineFixtures[ atIndex ]->GetShape())->m_vertex1;
    return (v0 + v1) / 2;
}

b2Vec2 Reservoir::GetBulbPosition() {
    if(m_bulbBody) {
        return m_bulbBody->GetPosition();
    }
    return b2Vec2(0, 0);
}

void Reservoir::RemoveWallPiece( long atIndex ) {
    m_bulbBody->DestroyFixture( m_lineFixtures[atIndex] );
}

void Reservoir::MakePipeFixture( b2Vec2* leftVertices,
                                 b2Vec2* rightVertices,
                                 int leftVertexCount,
                                 int rightVertexCount) {
    b2FixtureDef leftFixtureDef;
    b2FixtureDef rightFixtureDef;

    b2ChainShape leftShape;
    b2ChainShape rightShape;
    leftShape.CreateChain(leftVertices, leftVertexCount);
    rightShape.CreateChain(rightVertices, rightVertexCount);
    leftFixtureDef.shape = &leftShape;
    rightFixtureDef.shape = &rightShape;
    
    leftFixtureDef.filter = m_filter;
    rightFixtureDef.filter = m_filter;
    
    m_lineFixtures.push_back( m_bulbBody->CreateFixture( &leftFixtureDef ) );
    m_lineFixtures.push_back( m_bulbBody->CreateFixture( &rightFixtureDef ) );
}

void Reservoir::DestroyPipeFixtures() {
    int pipeFixtureCount = (m_lineFixtures.size()) / sizeof(b2Fixture*);
    for( int i = 0; i < pipeFixtureCount; i++) {
        m_bulbBody->DestroyFixture(m_lineFixtures[i]);
    }

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

