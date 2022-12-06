#ifndef Infiltrator_h
#define Infiltrator_h

#include <stdio.h>
#include "Box2D.h"
#include <vector>
class Infiltrator {

public:
    Infiltrator( b2World* worldRef,
                //           b2ParticleSystem* particleSystem,
                b2Vec2 location,
                b2Vec2 velocity,
                float startAngle,
                float density,
                float restitution,
                //           long crashParticleCount, // explosive particle effect
                //           float crashParticleDamage, // damage each particle will do
                float gravityScale,
                b2Filter filter);
    ~Infiltrator();
    
    // body methods
    b2Body* MakeBody(b2Vec2 atPos, float angle);
    void DestroyBody(b2Body* bodyRef);
    
    // attach methods
    b2Fixture* AttachPolygon(b2Body* onBody, b2Vec2 pos, b2Vec2* vertices, long vertexCount);
    b2Fixture* AttachCircle(b2Body* onBody, b2Vec2 pos, float radius);
    
    b2Fixture* AttachPolygon(b2Body* onBody, b2Vec2 pos, b2Vec2* vertices, long vertexCount, b2Filter filter);
    b2Fixture* AttachCircle(b2Body* onBody, b2Vec2 pos, float radius, b2Filter);
    // joint methods
    b2Joint* WeldJoint(b2Body* bodyA, b2Body* bodyB, b2Vec2 weldPos, float stiffness, float damping);
    b2Joint* WheelJoint(b2Body* bodyA, b2Body* bodyB, b2Vec2 weldPos, b2Vec2 localAxisA, float stiffness, float damping);
    
private:
    b2World* m_world;
//    b2ParticleSystem* m_particleSystem;

    float m_gravityScale;
    b2Filter m_filter = b2Filter();
    
    b2Vec2 m_origin;
    float m_density;
    float m_restition;
    long m_crashParticleCount;
};

#endif /* Infiltrator_h */

