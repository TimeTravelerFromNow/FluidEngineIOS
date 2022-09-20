#ifndef Tube_h
#define Tube_h

#include "b2ParticleSystem.h"
#include "Box2D.h"
#import <vector>

enum PouringCategory {
    
    tube_nullBits = 0,
    
    tube_isNotPouring = 1 << 1,
    
    tube_isPouring = 1 << 2
};

class Tube {
public:
    b2ParticleSystem* m_particleSys;
public:
    Tube(b2World* worldRef,
         b2ParticleSystem* particleSysRef,
         b2Vec2 location,
         b2Vec2* vertices, unsigned int count,
         b2Vec2* hitBoxVertices, unsigned int hitBoxCount,
         b2Vec2* sensorVertices, unsigned int sensorCount,
         float32 tubeWidth,
         float32 tubeHeight,
         long gridId);
    ~Tube();
    //hover candidate testing
    long GetHoverCandidateGridId();
    // pour guides
    void AddGuides(b2Vec2* guideVertices);
    void RemoveGuides();

    // dividers once again
    b2Fixture* addDivider(b2Vec2* dividerVertices);
    void removeDivider(b2Fixture* dividerRef);
    
    void Move(b2Vec2 velocity);
    
    void Rotate(float angVelocity);
    
    b2Vec2 GetPosition();
    float GetRotation();

    bool IsAtPosition(b2Vec2 position);
    
    void SetPourBits();
        
    void ClearPourBits();
    
    int EngulfParticles( b2ParticleSystem* originalSystem );
    
private:
    b2Fixture* m_topCap;
    b2Fixture* m_guide0;
    b2Fixture* m_guide1;
    b2Fixture* m_tubeFixture;
    
    b2Body* m_body;
    b2Body* m_hboxBody;
    b2Body* m_sensorBody;
    float32 width;
    float32 height;
    long id;
    
    b2Filter m_filter;
    
};

static std::vector<Tube*> tubes;

#endif /* Tube_h */
