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
                b2Filter filter);
    ~Infiltrator();
    
    // body methods
    b2Body* MakeBody(b2Vec2 atPos, float angle, b2Filter filter);
    void DestroyBody(b2Body* bodyRef);
    
    // attach methods
    b2Fixture* AttachPolygon(b2Body* onBody, b2Vec2 pos, b2Vec2* vertices, long vertexCount);
    b2Fixture* AttachCircle(b2Body* onBody, b2Vec2 pos, float radius);
    // joint methods
    b2Joint* WheelJoint(b2Body* bodyA, b2Body* bodyB, b2Vec2 weldPos, b2Vec2 localAxisA, float stiffness, float damping);
    
private:
    b2World* m_world;
//    b2ParticleSystem* m_particleSystem;

    b2Filter m_filter = b2Filter();
    
    b2Vec2 m_origin;
    float m_density;
    float m_restition;
    long m_crashParticleCount;
};

#endif /* Infiltrator_h */

