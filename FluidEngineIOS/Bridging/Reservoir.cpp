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
//    m_valve0Fixture = valve0Body->CreateFixture(&valve0Def);
    m_valve0Body = valve0Body;
    
    b2WeldJointDef weldJointDef;
    weldJointDef.bodyA = m_body;
    weldJointDef.bodyB = m_valve0Body;
    weldJointDef.collideConnected = false;
    worldRef->CreateJoint(&weldJointDef);
    m_pipeLengthsEqual = true;
}

b2Vec2* Reservoir::CreateBulb() {
    b2BodyDef bulbBodyDef;
    bulbBodyDef.type = b2_kinematicBody;
    bulbBodyDef.active = true;
    bulbBodyDef.gravityScale = 0.0;
    
    const float bulbRadius = 0.4;
    b2Vec2 bulbCenter = b2Vec2( m_exitPosition.x, m_exitPosition.y - bulbRadius);
    bulbBodyDef.position.Set( bulbCenter.x, bulbCenter.y );
    
    float angleIncrement = b2_pi / 6;

    b2Body *bulbBody = m_world->CreateBody(&bulbBodyDef);
    numBulbWallPieces = long( 2 * b2_pi / angleIncrement );
    
    b2Vec2 verticesOut[numBulbWallPieces * 2];
    long linOff = 0;
    
    b2Vec2 pipeTestPos;
    b2Vec2 startRightVertex;
    b2Vec2 startLeftVertex;
    for( float f = 0.0; f < 2 * b2_pi; f += angleIncrement ) {
        if ( ( ((b2_pi / 2) - 0.3) < f && f < ((b2_pi / 2) + 0.3) ) ) {
            
        } else {
            b2FixtureDef lineFixtureDef;
            b2EdgeShape bulbLine;
            
            float y = sin( f ) * bulbRadius; // center of the line
            float x = cos( f ) * bulbRadius;
            float xT = sin( f ) * angleIncrement * bulbRadius * 0.5; // tangent
            float yT = cos( f ) * angleIncrement * bulbRadius * 0.5;
            b2Vec2 cwVertex = b2Vec2( x + xT, y - yT);
            b2Vec2 ccwVertex = b2Vec2( x - xT, y + yT);
            
            verticesOut[linOff * 2] = cwVertex;
            verticesOut[linOff * 2 + 1] = ccwVertex;
            if(linOff == 10) {
                pipeTestPos = b2Vec2((cwVertex.x + ccwVertex.x) / 2, (cwVertex.y + ccwVertex.y) / 2);
                startLeftVertex = cwVertex;
                startRightVertex = ccwVertex;
            }
            bulbLine.Set(cwVertex, ccwVertex);
            lineFixtureDef.shape = &bulbLine;
            b2Fixture* lineFixture = bulbBody->CreateFixture(&lineFixtureDef);
            m_lineFixtures.push_back(lineFixture);
            
            linOff++;
        }
    }
    b2Vec2 pipeDirection =  pipeTestPos;
    float pipeDirNorm = pipeDirection.Length();
    pipeDirection = 0.3 * pipeDirection / pipeDirNorm;
    m_pipeDirection = pipeDirection;
    m_pipePosition = pipeTestPos;
    
    b2Vec2 rightVertex1 = startRightVertex + pipeDirection;
    b2Vec2 leftVertex1 = startLeftVertex + pipeDirection;
    
    
    b2Vec2 firstRightLine[2];
    firstRightLine[0] = startRightVertex;
    firstRightLine[1] = rightVertex1;
    
    b2FixtureDef rightLineDef;
    b2ChainShape rightLine;
    
    rightLine.CreateChain(firstRightLine, 2);
    rightLineDef.shape = &rightLine;
    
    b2Vec2 firstLeftLine[2];
    firstLeftLine[0] = startLeftVertex;
    firstLeftLine[1] = leftVertex1;
    
    b2FixtureDef leftLineDef;
    b2ChainShape leftLine;
    leftLine.CreateChain(firstLeftLine, 2);
    leftLineDef.shape = &leftLine;
    
    m_bulbBody = bulbBody;

    m_rightPipeFixture = m_bulbBody->CreateFixture(&rightLineDef);
    m_leftPipeFixture  = m_bulbBody->CreateFixture(&leftLineDef);
    
    return verticesOut;
}

void Reservoir::BuildPipe(b2Vec2 towardsPoint) {
    b2Fixture* rightFixture = m_rightPipeFixture;
    b2Fixture* leftFixture = m_leftPipeFixture;
    b2ChainShape* rightShape = ((b2ChainShape *)  rightFixture->GetShape() );
    b2ChainShape* leftShape = ((b2ChainShape *) leftFixture->GetShape() );

    b2Vec2* rightVertices =  rightShape->m_vertices;
    int32 rightVertexCount =  rightShape->m_count;

    b2Vec2* leftVertices = leftShape->m_vertices;
    int32 leftVertexCount =  leftShape->m_count;
    
    b2Vec2 newRVertices[ rightVertexCount + 1 ]; // L and R should be the same size, but keeping sanity
    b2Vec2 newLVertices[ leftVertexCount + 1 ];

    b2FixtureDef newRFixDef;
    b2FixtureDef newLFixDef;
    b2ChainShape newRChainShape;
    b2ChainShape newLChainShape;
    
    for( int i = 0; i < rightVertexCount; i++) { // rewrite the old vertices
        newRVertices[i] = rightVertices[i];
        newLVertices[i] = leftVertices[i];
    }
    //decide on a new pipeDirection
    m_pipeDirection += towardsPoint * 0.01;
    //normalize
    m_pipeDirection = 0.5 * b2Vec2(m_pipeDirection.x, m_pipeDirection.y) / m_pipeDirection.Normalize();
    b2Vec2 nextDir = m_pipeDirection + towardsPoint * 0.01;
    b2Vec2 nextPipeDirection = 0.5 * b2Vec2(nextDir.x, nextDir.y) / nextDir.Normalize();
    float32 adjustmentAngle;
    
    // set the last vertices a vector away from the previous last vertices
    newRVertices[rightVertexCount]  = newRVertices[rightVertexCount - 1] + m_pipeDirection;
    newLVertices[leftVertexCount]  = newLVertices[leftVertexCount - 1] + m_pipeDirection;
    
    newRChainShape.CreateChain(newRVertices, rightVertexCount + 1);
    newLChainShape.CreateChain(newLVertices, leftVertexCount + 1);

    newRFixDef.shape = &newRChainShape;
    newLFixDef.shape = &newLChainShape;
    
    m_bulbBody->DestroyFixture(m_leftPipeFixture);
    m_bulbBody->DestroyFixture(m_rightPipeFixture);
    m_rightPipeFixture = m_bulbBody->CreateFixture(&newRFixDef);
    m_leftPipeFixture = m_bulbBody->CreateFixture(&newLFixDef);

}

b2Vec2** Reservoir::GetAllPipeVertices() { // get an array of all pipe vertices.
    b2Vec2** pipeVerticesArray = static_cast<b2Vec2 **>(malloc(2 * sizeof(b2Vec2 *)));
    pipeVerticesArray[0] = ((b2ChainShape*)m_rightPipeFixture->GetShape())->m_vertices;
    int32 count1 = ((b2ChainShape*)m_rightPipeFixture->GetShape())->m_count;
    b2Vec2 center1 = m_body->GetPosition();
    for( int32 i = 0; i < count1; i++) {
        pipeVerticesArray[0][i] += center1;
    }
    pipeVerticesArray[1] = ((b2ChainShape*)m_leftPipeFixture->GetShape())->m_vertices;
    return pipeVerticesArray;
}

int32* Reservoir::GetPipeLineVertexCounts() {
    int32* vertexCountArray = static_cast<int32 *>(malloc(2 * sizeof(int32 *)));
    vertexCountArray[0] = ((b2ChainShape*)m_rightPipeFixture->GetShape())->m_count;
    vertexCountArray[1] = ((b2ChainShape*)m_leftPipeFixture->GetShape())->m_count;
    return vertexCountArray;
}

int Reservoir::GetPipeLineCounts() {  // returns total number of pipe lines
    return 2;
}

void Reservoir::RemoveWallPiece( long atIndex ) {
    if( m_lineFixtures[atIndex] && atIndex < numBulbWallPieces ) {
    m_bulbBody->DestroyFixture( m_lineFixtures[atIndex] );
    }
}

//void Reservoir::AttachWallPiece( long atIndex ) {
//    if( m_lineFixtures[atIndex] && atIndex < numBulbWallPieces ) {
//    m_bulbBody->Fixture( m_lineFixtures[atIndex] );
//    }
//}

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

