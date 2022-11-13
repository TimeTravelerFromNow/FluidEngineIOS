#include "Tube.h"

Tube::Tube(b2World* worldRef,
           b2ParticleSystem* particleSysRef,
           b2Vec2 location,
           b2Vec2* vertices, unsigned int count,
           float32 tubeWidth,
           float32 tubeHeight,
           long gridId) {
    width = tubeWidth;
    height = tubeHeight;
    id = gridId;
    m_particleSys = particleSysRef;
    m_filter = b2Filter();
    m_filter.groupIndex = gridId;
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
    
    m_tubeFixture = body1->CreateFixture(&fixtureDef);
    m_body = body1;
}
Tube::~Tube() {
}
//collision

long Tube::GetHoverCandidateGridId() {
    return 0; // MARK: if I want to do the hover logic in C++ I can, but it's up to me
}

b2Fixture* Tube::addDivider(b2Vec2* dividerVertices) {
    b2FixtureDef fixtureDef;
    fixtureDef.filter = m_filter;
    b2EdgeShape line;
    line.Set(((b2Vec2 *)dividerVertices)[0], ((b2Vec2 *)dividerVertices)[1]);
    fixtureDef.shape = &line;
    b2Fixture* lineFixture = m_body->CreateFixture(&fixtureDef);
    return lineFixture;
}

void Tube::removeDivider(b2Fixture* dividerRef) {
    m_body->DestroyFixture(dividerRef);
}

//pour guides
void Tube::AddGuides(b2Vec2* guidesVertices) {
    if(!( m_guide0 == NULL && m_guide1 == NULL)) { return; }
    b2FixtureDef fixtureDef0;
    b2FixtureDef fixtureDef1;
    fixtureDef0.filter = m_filter;
    fixtureDef1.filter = m_filter;
    b2EdgeShape line0;
    b2EdgeShape line1;
    line0.Set((guidesVertices)[0], (guidesVertices)[1]);
    line1.Set((guidesVertices)[2], (guidesVertices)[3]);
    fixtureDef0.shape = &line0;
    fixtureDef1.shape = &line1;
    b2Fixture* lineFixture0 = m_body->CreateFixture(&fixtureDef0);
    b2Fixture* lineFixture1 = m_body->CreateFixture(&fixtureDef1);
    m_guide0 = lineFixture0;
    m_guide1 = lineFixture1;
}
void Tube::RemoveGuides() {
    if(m_guide0 != NULL && m_guide1 != NULL) {
        m_body->DestroyFixture(m_guide0);
        m_guide0 = NULL;
        m_body->DestroyFixture(m_guide1);
        m_guide1 = NULL;
    }
}
//movement
void Tube::SetVelocity(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}
void Tube::SetRotation(float angVelocity) {
    m_body->SetAngularVelocity( angVelocity );
}
b2Vec2 Tube::GetPosition() {
    return m_body->GetPosition();
}
float Tube::GetRotation() {
    return m_body->GetAngle();
}

b2Vec2 Tube::GetVelocity() {
    return m_body->GetLinearVelocity();
}

bool Tube::IsAtPosition(b2Vec2 position) {
    b2Vec2 currentPosition = m_body->GetPosition();
    float32 left   = currentPosition.x - width / 2;
    float32 right  = currentPosition.x + width / 2;
    float32 top    = currentPosition.y + height / 2 + 0.2;
    float32 bottom = currentPosition.y - height / 2 - 0.2;
    
    return ( ( position.x < right && position.x > left ) && ( position.y < top && position.y > bottom ) );
}

void Tube::SetPourBits() {
    b2Fixture* fixtures = m_body->GetFixtureList();
    
    m_filter.categoryBits = tube_isPouring;
    while( fixtures ) {
        fixtures->SetFilterData( m_filter );
        fixtures = fixtures->GetNext();
    };
    m_tubeFixture->SetFilterData( m_filter );
    m_particleSys->filter = m_filter;
}

void Tube::ClearPourBits() {
    b2Fixture* fixtures = m_body->GetFixtureList();
    
    m_filter.categoryBits = tube_isNotPouring;
    while(fixtures) {
        fixtures->SetFilterData( m_filter );
        fixtures = fixtures->GetNext();
    };
    m_tubeFixture->SetFilterData( m_filter );
    m_particleSys->filter = m_filter;
}

int Tube::EngulfParticles( b2ParticleSystem* originalSystem ) {
    b2ParticleGroupDef newGroupDef;
    
    b2Vec2* positionBuffer = originalSystem->GetPositionBuffer();
    int oldPositionsCount = originalSystem->GetParticleCount();
    b2Vec2* velocityBuffer = originalSystem->GetVelocityBuffer();
    b2ParticleColor* oldColors = originalSystem->GetColorBuffer();
    int newPositionsCount = 0;
    // determine how many particles are inside the new tube's bounds
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( IsAtPosition( c ) ) {
            newPositionsCount++;
        }
    }
    
    b2Vec2 newPositions[newPositionsCount];
    b2Vec2 newVelocities[newPositionsCount];
    int newPositionIndex = 0;
    float avVelocityX = 0.0;
    float avVelocityY = 0.0;
    b2ParticleColor transferredColor;
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if ( IsAtPosition( c ) ) {
            newPositions[newPositionIndex] = positionBuffer[i];
            newVelocities[newPositionIndex] = velocityBuffer[i];
            avVelocityX += newVelocities[newPositionIndex].x;
            avVelocityY += newVelocities[newPositionIndex].y;
            newPositionIndex++;
            originalSystem->DestroyParticle(i, false);
            transferredColor = oldColors[ i ];
        }
    }
    avVelocityX = avVelocityX / float(newPositionsCount);
    avVelocityY = avVelocityY / float(newPositionsCount);
    newGroupDef.positionData = newPositions;
    newGroupDef.linearVelocity = b2Vec2(avVelocityX, avVelocityY);
    newGroupDef.particleCount = newPositionsCount;
    newGroupDef.flags = b2_waterParticle | b2_fixtureContactFilterParticle;
    newGroupDef.color = transferredColor;
    
    m_particleSys->CreateParticleGroup(newGroupDef);
    return newPositionsCount;
}

void Tube::BeginEmpty() {
    m_particleSys->filter = m_filter;
}
