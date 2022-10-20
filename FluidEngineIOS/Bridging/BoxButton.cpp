#include "BoxButton.h"

BoxButton::BoxButton(b2World* worldRef,
                     b2Vec2* vertices,
                     b2Vec2 location) {
    
    origin = location;
    width = abs(vertices[0].x);
    height = abs(vertices[0].y);
    m_world = worldRef;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody; //can code some fun stuff here later 
    bodyDef.active = true;
    bodyDef.gravityScale = 0.0;
    bodyDef.position.Set(location.x, location.y);
    b2Body *body = m_world->CreateBody(&bodyDef);
    b2PolygonShape shape;
    b2FixtureDef fixtureDef;
    shape.Set(vertices, 4);

    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0f;
    body->CreateFixture(&fixtureDef);
    m_body = body;
};

void BoxButton::Update() {
    DriveBack();
    FightRotation();
}
void BoxButton::DriveBack() {
    b2Vec2 currentPosition = m_body->GetPosition();
    b2Vec2 returnVector = origin - currentPosition;
    b2Vec2 clampedReturn = b2Clamp(returnVector, b2Vec2(-1.0,-1.0), b2Vec2(1.0,1.0));
    b2Vec2 vBefore = m_body->GetLinearVelocity();
    b2Vec2 vAfter = b2Clamp(vBefore, b2Vec2(-0.1,-0.1), b2Vec2(0.1,0.1)) + clampedReturn;
    m_body->SetLinearVelocity(vAfter);
}

void BoxButton::FightRotation() {
    float currentRotation = m_body->GetAngle();
    float fightingStrength = -currentRotation;
    m_body->SetAngularVelocity(fightingStrength * 3);
}

bool BoxButton::IsAtPosition(b2Vec2 position) {
    bool inBox = true;
    b2Vec2 currentPosition = m_body->GetPosition();
    float32 left   = currentPosition.x - width;
    float32 right  = currentPosition.x + width;
    float32 top    = currentPosition.y + height;
    float32 bottom = currentPosition.y - height;
    
    if ( position.x < right && position.x > left ) {
        
    } else { inBox = false; }
    if ( position.y < top && position.y > bottom ) {
        
    } else { inBox = false; }
    return inBox;
}

b2Vec2 BoxButton::GetPosition() {
    return m_body->GetPosition();
}

float BoxButton::GetRotation() {
    return m_body->GetAngle();
}

void BoxButton::Freeze() {
    m_body->SetActive(false);
}

void BoxButton::UnFreeze() {
    m_body->SetActive(true);
}
