//
//  Tube.h
//  FluidEngine
//
//  Created by sebi d on 1/23/22.
//

#ifndef Tube_h
#define Tube_h

#include "b2ParticleSystem.h"
#include "Box2D.h"
#import <vector>

class Tube {
public:
    int row;
    int col;
    int gridId; // linear unique identifier
    bool returningToOrigin;
    bool pickedUp;
    bool isFrozen;
    bool pouring;
    bool yieldToFill;
    std::vector<Tube*> tubesColliding;
    b2ParticleSystem* m_particleSys;
    b2World* m_world;
public:
    Tube(b2World* worldRef,
         b2ParticleSystem* particleSysRef,
         b2Vec2 location,
         b2Vec2* vertices, unsigned int count,
         b2Vec2* hitBoxVertices, unsigned int hitBoxCount,
         b2Vec2* sensorVertices, unsigned int sensorCount,
         int row,
         int col,
         int gridId);
    ~Tube();
    //collision
    void YieldToFill();
    void UnYieldToFill();
    void StartPickup();
    void EndPickup();
    void StartReturn();
    void EndReturn();
    void BeganCollide(Tube* tube);
    void EndCollide(Tube* tube);
    void PostSolve(); // only can modify state of objects after collision solves
    // pour guides
    void AddGuides(b2Vec2* guideVertices);
    void RemoveGuides();
    //top cap
    void CapTop(b2Vec2* capVertices);
    void PopCap();
    
    void Move(b2Vec2 velocity);
    
    void Rotate(float angVelocity);
    
    b2Vec2 GetPosition();
    
    float GetRotation();
private:
    void Freeze();
    void UnFreeze();
    b2Fixture* m_topCap;
    b2Fixture* m_guide0;
    b2Fixture* m_guide1;
    
    b2Body* m_body;
    b2Body* m_hboxBody;
    b2Body* m_sensorBody;
};

static std::vector<Tube*> tubes;

#endif /* Tube_h */
