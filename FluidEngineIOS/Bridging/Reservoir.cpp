#include "Reservoir.h"

Reservoir::Reservoir(b2World* worldRef,
           b2ParticleSystem* particleSysRef,
           b2Vec2 location,
           b2Vec2* vertices, unsigned int count) {
    m_world = worldRef;
    m_particleSys = particleSysRef;
    m_filter = b2Filter();
    m_filter.groupIndex = -1;
    m_filter.isFiltering = true;
    m_particleSys->filter = m_filter;
       
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
Reservoir::~Reservoir() {
    m_world->DestroyParticleSystem(m_particleSys);
    m_world->DestroyBody(m_body);
    for( int i = 0; i < m_bulbBodies.size(); i ++ ){
        m_world->DestroyBody( m_bulbBodies[i] );
    }
}
float Reservoir::CreateBulb(long hemisphereSegments, float bulbRadius) {
    m_bulbRadius = bulbRadius;
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
        m_pipeWidth = angleIncrement * bulbRadius * 0.6 * 2;
        float xT =  sin( f ) * m_pipeWidth / 2; // tangent
        float yT =  cos( f ) * m_pipeWidth / 2;
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
    return m_pipeWidth * 3;
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

void* Reservoir::GetWallBody( long atIndex ) {
    return (void*)m_bulbBodies[ atIndex ];
}

void Reservoir::SetWallPieceAngV( long atIndex, float angV ) {
    m_bulbBodies[ atIndex ]->SetAngularVelocity(angV);
}
float Reservoir::GetBulbSegmentRotation( long atIndex ) {
    return m_bulbBodies[ atIndex ]->GetAngle();
}


void* Reservoir::MakeLineFixture( b2Vec2* lineVertices, long vertexCount ) {
   
    b2FixtureDef lineFixtureDef;

    b2ChainShape lineShape;
    lineShape.CreateChain( lineVertices, vertexCount );
    lineFixtureDef.shape = &lineShape;
    lineFixtureDef.filter.isFiltering = true;
    
    b2Fixture* fixtureOut = m_bulbBody->CreateFixture( &lineFixtureDef );
    return (void*)fixtureOut;
}


void Reservoir::DestroyLineFixture( void* fixtureRef ) {
    m_bulbBody->DestroyFixture( ( b2Fixture* )fixtureRef );
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

//particle transfers
long Reservoir::TransferParticles( void* toSystem, b2Vec2 wallPos ) {
    if(m_bulbBody) {
        
    } else { return 0;}
    b2ParticleGroupDef newGroupDef;
    
    b2Vec2* positionBuffer = m_particleSys->GetPositionBuffer();
    int oldPositionsCount = m_particleSys->GetParticleCount();
    b2Vec2* velocityBuffer = m_particleSys->GetVelocityBuffer();
    b2ParticleColor color = m_particleSys->GetColorBuffer()[0];
    int newPositionsCount = 0;
    b2Vec2 bulbCenter = m_bulbBody->GetPosition();
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( b2Distance(c, bulbCenter ) > m_bulbRadius && // outside bulb and inside the pipe entrance
           b2Distance(c, wallPos ) < m_pipeWidth ) {
            newPositionsCount++;
        }
    }
    b2Vec2 newPositions[newPositionsCount];
    b2Vec2 newVelocities[newPositionsCount];
    b2ParticleColor newColorBuffer[newPositionsCount];
    int newPositionIndex = 0;
    float avVelocityX = 0.0;
    float avVelocityY = 0.0;
    
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( b2Distance(c, bulbCenter ) > m_bulbRadius &&  b2Distance(c, wallPos ) < m_pipeWidth ) {
            newPositions[newPositionIndex] = positionBuffer[i];
            newVelocities[newPositionIndex] = velocityBuffer[i];
            avVelocityX += newVelocities[newPositionIndex].x;
            avVelocityY += newVelocities[newPositionIndex].y;
            newPositionIndex++;
            ((b2ParticleSystem *)m_particleSys)->DestroyParticle(i, false);
        }
    }
    avVelocityX = avVelocityX / float(newPositionsCount);
    avVelocityY = avVelocityY / float(newPositionsCount);
    newGroupDef.positionData = newPositions;
    newGroupDef.linearVelocity = b2Vec2(avVelocityX, avVelocityY);
    newGroupDef.particleCount = newPositionsCount;
    newGroupDef.color = color; // MARK: comment out for debug
    newGroupDef.flags = b2_waterParticle | b2_fixtureContactFilterParticle;

    ((b2ParticleSystem *)toSystem)->CreateParticleGroup(newGroupDef);
    return newPositionsCount;
}

void Reservoir::SetValveAngV( void* wallBodyRef, float angV ) {
    ((b2Body*)wallBodyRef)->SetAngularVelocity( angV );
}
float Reservoir::GetWallAngle( void* wallBodyRef ) {
    return ((b2Body*)wallBodyRef)->GetAngle();
}
