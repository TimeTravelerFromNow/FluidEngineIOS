#ifndef Pipe_h
#define Pipe_h

#include "b2ParticleSystem.h"
#include "Box2D.h"
#include "Tube.h"
#import <vector>

class Reservoir {
public:
    b2ParticleSystem* m_particleSys;
public:
    Reservoir(b2World* worldRef,
              b2ParticleSystem* particleSysRef,
              b2Vec2 location,
              b2Vec2* vertices, unsigned int count);
    ~Reservoir();
    // hover candidate testing
    long GetHoverCandidateGridId();
    // pour guides
    void AddGuides(b2Vec2* guideVertices);
    void RemoveGuides();

    // dividers once again
    b2Fixture* addDivider(b2Vec2* dividerVertices);
    void removeDivider(b2Fixture* dividerRef);
    
    void SetVelocity(b2Vec2 velocity);
    
    void SetRotation(float angVelocity);
    
    b2Vec2 GetPosition();
    float GetRotation();

    b2Vec2 GetVelocity();
    
    bool IsAtPosition(b2Vec2 position);
    
    void SetPourBits();
        
    void ClearPourBits();
    
    int EngulfParticles( b2ParticleSystem* originalSystem );
    
    void SetValve0AngularVelocity( float angV );
    float GetValve0Rotation();
    
private:
    b2Fixture* m_topCap;
    b2Fixture* m_guide0;
    b2Fixture* m_guide1;
    b2Fixture* m_PipeFixture;
    
    b2Body* m_body;
    b2Body* m_hboxBody;
    b2Body* m_sensorBody;
    b2Body* m_valve0Body;
    
    float32 width;
    float32 height;
    long id;
    
    b2Filter m_filter;
    b2Fixture* m_valve0Fixture;
};

static std::vector<Reservoir*> reservoirs;

#endif /* Pipe_h */
