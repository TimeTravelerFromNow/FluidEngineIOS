//
//  Tube.c
//  FluidEngine
//
//  Created by sebi d on 1/23/22.
//

#include "Tube.h"

Tube::Tube(b2World* worldRef,
           b2ParticleSystem* particleSysRef,
           b2Vec2 location,
           b2Vec2* vertices, unsigned int count,
           b2Vec2* hitBoxVertices, unsigned int hitBoxCount,
           b2Vec2* sensorVertices, unsigned int sensorCount,
           int row,
           int col,
           int gridId) {
    m_world = worldRef;
    gridId = gridId;
    row = row;
    col = col;
    m_particleSys = particleSysRef;
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
    body1->CreateFixture(&fixtureDef);
    m_body = body1;
    //sensor Body (must stay active to continue registering collision when the hitboxes and frame freeze.)
    b2BodyDef sensorBodyDef;
    sensorBodyDef.type = b2_dynamicBody;
    sensorBodyDef.active = true;
    sensorBodyDef.bullet = true;
    sensorBodyDef.position.Set(location.x, location.y);
    sensorBodyDef.gravityScale = 0.0;
    b2Body *sensorBody = worldRef->CreateBody(&sensorBodyDef);
    b2PolygonShape shape1; // sensor
    b2FixtureDef sensorFixture;
    sensorFixture.isSensor = true;
    shape1.Set(sensorVertices, sensorCount);
    sensorFixture.shape = &shape1;
    sensorFixture.density = 1.0f;
    sensorBody->CreateFixture(&sensorFixture);
    b2WeldJointDef sensorWeldDef;
    sensorWeldDef.bodyA = body1;
    sensorWeldDef.bodyB = sensorBody;
    sensorWeldDef.collideConnected = false;
    worldRef->CreateJoint(&sensorWeldDef); // weld the sensor
    m_sensorBody = sensorBody;
   //hitboxes
    b2BodyDef hboxBodyDef;
    hboxBodyDef.type = b2_dynamicBody;
    hboxBodyDef.active = true;
    hboxBodyDef.gravityScale = 0.0;
    hboxBodyDef.position.Set(location.x, location.y);
    b2Body *body2 = worldRef->CreateBody(&hboxBodyDef);
    
    int currIndex = 0;
    b2Vec2 boxVertices[4];
    for( int i = 0; i < hitBoxCount; i++) {
        boxVertices[currIndex] = hitBoxVertices[i];
        if ( currIndex == 3) {
            b2PolygonShape shape2;
            b2FixtureDef fixtureDef2;
            shape2.Set(boxVertices, 4);
            fixtureDef2.shape = &shape2;
            fixtureDef2.density = 2.0f;
            body2->CreateFixture(&fixtureDef2);
            currIndex = 0;
        } else {
        currIndex++;
        }
    }

    m_hboxBody = body2;

    b2WeldJointDef weldJointDef;
      weldJointDef.bodyA = sensorBody;
      weldJointDef.bodyB = body2;
      weldJointDef.collideConnected = false;
    
    worldRef->CreateJoint(&weldJointDef);
    
    m_body->SetUserData(this);
    m_hboxBody->SetUserData(this);
    m_sensorBody->SetUserData(this);
    returningToOrigin = false;
    pickedUp = false;
    pouring = false;
    yieldToFill = true;
    isFrozen = false;
    Freeze();
}
Tube::~Tube() {
    m_world->DestroyBody(m_body);
    m_world->DestroyBody(m_hboxBody);
    m_world->DestroyBody(m_sensorBody);
}
//collision
void Tube::YieldToFill() {
    yieldToFill = true;
}
void Tube::UnYieldToFill() {
    yieldToFill = false;
}
void Tube::StartReturn() {
    returningToOrigin = true;
}
void Tube::EndReturn() {
    returningToOrigin = false;
}
void Tube::StartPickup() {
    pickedUp = true;
}
void Tube::EndPickup() {
    pickedUp = false;
}
void Tube::BeganCollide(Tube* tube) {
    tubesColliding.push_back( tube ); // do not do modifications to Tube activity during began Collide.
}
void Tube::EndCollide(Tube* tube) {
     tubesColliding.erase( std::find(tubesColliding.begin(), tubesColliding.end(), tube ) );
}
void Tube::PostSolve() {
    if( yieldToFill ) {
        Freeze();
    } else {
    unsigned long collidingNum = tubesColliding.size();
    if (collidingNum > 0) {
    bool freeze = false;
        if(returningToOrigin) {
            for(int i = 0; i<collidingNum; i++) {
                if (tubesColliding[i]->pickedUp)  {
                    freeze = true;
                } else if ( tubesColliding[i]->returningToOrigin ) {
                    if( tubesColliding[i]->gridId > gridId) { // choose arbitrary to unfreeze if both returning
                        freeze = true;
                    }
                }
            }
        } else if (pouring) {//pouring not as important as returning
            for(int i = 0; i<collidingNum; i++) {
                if (tubesColliding[i]->returningToOrigin)  {
                    freeze = true;
                } else if ( tubesColliding[i]->pouring ) {
                    // dont freeze
                }
            }
        } else if (!pickedUp) { // at rest, yield to collision
            freeze = true;
        }
        if( freeze ){
            Freeze();
        } else {
            UnFreeze();
        }
    } else {
        UnFreeze();
    }
    }
}
//top cap
void Tube::CapTop(b2Vec2* capVertices) {
    b2FixtureDef fixtureDef;
    b2EdgeShape line;
    line.Set(((b2Vec2 *)capVertices)[0], ((b2Vec2 *)capVertices)[1]);
    fixtureDef.shape = &line;
    b2Fixture* lineFixture = m_body->CreateFixture(&fixtureDef);
    m_topCap = lineFixture;
}
void Tube::PopCap() {
    m_body->DestroyFixture(m_topCap);
}
//pour guides
void Tube::AddGuides(b2Vec2* guidesVertices) {
    b2FixtureDef fixtureDef0;
    b2FixtureDef fixtureDef1;
    b2EdgeShape line0;
    b2EdgeShape line1;
    line0.Set(((b2Vec2 *)guidesVertices)[0], ((b2Vec2 *)guidesVertices)[1]);
    line1.Set(((b2Vec2 *)guidesVertices)[2], ((b2Vec2 *)guidesVertices)[3]);
    fixtureDef0.shape = &line0;
    fixtureDef1.shape = &line1;
    b2Fixture* lineFixture0 = m_body->CreateFixture(&fixtureDef0);
    b2Fixture* lineFixture1 = m_body->CreateFixture(&fixtureDef1);
    m_guide0 = lineFixture0;
    m_guide1 = lineFixture1;
}
void Tube::RemoveGuides() {
    m_body->DestroyFixture(m_guide0);
    m_body->DestroyFixture(m_guide1);
}
//movement
void Tube::Move(b2Vec2 velocity) {
    m_body->SetLinearVelocity(velocity);
}
void Tube::Rotate(float angVelocity) {
    m_body->SetAngularVelocity( angVelocity );
}
b2Vec2 Tube::GetPosition() {
    return m_body->GetPosition();
}
float Tube::GetRotation() {
    return m_body->GetAngle();
}
// activeness
void Tube::Freeze() {
    if( !isFrozen  ) {
        m_body->SetActive(false);
        m_sensorBody->SetLinearVelocity(b2Vec2()); // stop it from leaving current freeze location.
        m_hboxBody->SetActive(false);
        m_particleSys->SetPaused(true);
        isFrozen = true;
    }
}
void Tube::UnFreeze() {
    if( isFrozen ){
        m_body->SetActive(true);
        m_hboxBody->SetActive(true);
        m_particleSys->SetPaused(false);
        isFrozen = false;
    }
}
