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
    fixtureDef.density = 1.0f;
    
    body1->CreateFixture(&fixtureDef);
    m_body = body1;
    
    b2BodyDef valve0BodyDef;
    valve0BodyDef.type = b2_kinematicBody;
    valve0BodyDef.active = true;
    valve0BodyDef.gravityScale = 0.0;
    valve0BodyDef.position.Set(location.x, location.y);
   
    b2FixtureDef valve0Def;
    valve0Def.filter = m_filter;
    b2EdgeShape valveLine;
    
    b2Vec2 firstVertex = ((b2Vec2 *)vertices)[0];
    b2Vec2 lastVertex = ((b2Vec2 *)vertices)[count - 1];
    valveLine.Set(firstVertex, lastVertex);
    valve0Def.shape = &valveLine;
    valve0Def.density = 1.0f;
    
    m_exitWidth = abs(firstVertex.x - lastVertex.x);
    m_exitPosition = b2Vec2(location.x + (firstVertex.x + lastVertex.x) / 2, location.y + (firstVertex.y + lastVertex.y) / 2);
    
    b2Body *valve0Body = worldRef->CreateBody(&valve0BodyDef);
//    m_valve0Fixture = va	lve0Body->CreateFixture(&valve0Def);
    m_valve0Body = valve0Body;
    
    b2WeldJointDef valve0JointDef;
    valve0JointDef.Initialize(m_body, m_valve0Body, m_exitPosition);

    m_world->CreateJoint(&valve0JointDef);
}

void Reservoir::CreateBulb(long hemisphereSegments, float bulbRadius) {
    b2BodyDef bulbBodyDef;
    bulbBodyDef.type = b2_kinematicBody;
    bulbBodyDef.active = true;
    bulbBodyDef.gravityScale = 0.0;
    
    b2Vec2 bulbCenter = b2Vec2( m_exitPosition.x, m_exitPosition.y - bulbRadius + 0.04);
    bulbBodyDef.position.Set( bulbCenter.x, bulbCenter.y );
    
    float angleIncrement = b2_pi / hemisphereSegments;
    
    for( float f = 0.0; f < 2 * b2_pi; f += angleIncrement ) {
        b2Body *bulbBody = m_world->CreateBody(&bulbBodyDef);
        b2FixtureDef lineFixtureDef;
        b2EdgeShape bulbLine;
        
        float y = sin( f ) * bulbRadius; // center of the line
        float x = cos( f ) * bulbRadius;
        float xT = sin( f ) * angleIncrement * bulbRadius * 0.6; // tangent
        float yT = cos( f ) * angleIncrement * bulbRadius * 0.6;
        b2Vec2 cwVertex = b2Vec2( x + xT, y - yT);
        b2Vec2 ccwVertex = b2Vec2( x - xT, y + yT);
        bulbLine.Set(cwVertex, ccwVertex);
        lineFixtureDef.shape   = &bulbLine;
        lineFixtureDef.density = 1.0;
        b2Fixture* lineFixture = bulbBody->CreateFixture(&lineFixtureDef);
        m_bulbFixtures.push_back(lineFixture);
        m_bulbBodies.push_back(bulbBody);
        m_bulbBody = bulbBody;
        numBulbWallPieces++;
    }
}

b2Vec2 Reservoir::GetBulbSegmentPosition(long atIndex) { //MARK: couldn't get it to work this way
    b2Vec2 v0 = ((b2EdgeShape*)m_bulbFixtures[ atIndex ]->GetShape())->m_vertex0;
    b2Vec2 v1 = ((b2EdgeShape*)m_bulbFixtures[ atIndex ]->GetShape())->m_vertex1;
    b2Vec2 bulbCenter = ((b2Body*)m_bulbBodies[ atIndex ])->GetPosition();
    return bulbCenter;
}

b2Vec2 Reservoir::GetBulbPosition() {
    if(m_bulbBody) {
        return m_bulbBody->GetPosition();
    }
    return b2Vec2(0, 0);
}

void Reservoir::RemoveWallPiece( long atIndex ) {
    m_bulbBody->DestroyFixture( m_bulbFixtures[atIndex] );
}

void Reservoir::SetWallPieceAngV( long atIndex, float angV ) {
    m_bulbBodies[ atIndex ]->SetAngularVelocity(angV);
}
float Reservoir::GetBulbSegmentRotation( long atIndex ) {
    return m_bulbBodies[ atIndex ]->GetAngle();
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
    
    m_pipeFixtures.push_back( m_bulbBody->CreateFixture( &leftFixtureDef ) );
    m_pipeFixtures.push_back( m_bulbBody->CreateFixture( &rightFixtureDef ) );
}

void Reservoir::DestroyPipeFixtures() {
    int pipeFixtureCount = (m_pipeFixtures.size()) / sizeof(b2Fixture*);
    for( int i = 0; i < pipeFixtureCount; i++) {
        m_bulbBody->DestroyFixture(m_pipeFixtures[i]);
    }

}

Reservoir::~Reservoir() {
    
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

