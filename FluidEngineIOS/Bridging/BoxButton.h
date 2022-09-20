#ifndef BoxButton_h
#define BoxButton_h

#include <stdio.h>
#include "Box2D.h"

class BoxButton {

public:
    BoxButton(b2World* worldRef,
              b2Vec2* vertices,
              b2Vec2 location);
    ~BoxButton();
    
    bool IsAtPosition(b2Vec2 position);
    
    b2Vec2 GetPosition();
    float GetRotation();
    
    void Update();
    
    void Freeze();
    void UnFreeze();
    
private:
    void DriveBack();
    void FightRotation();
    
private:
    b2Body* m_body;
    b2World* m_world;
    
    float32 width;
    float32 height;
    
    b2Vec2 origin;
};

#endif /* BoxButton_h */

