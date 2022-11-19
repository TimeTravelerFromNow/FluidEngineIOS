#ifndef Alien_h
#define Alien_h

#include <stdio.h>
#include "Box2D.h"
#include <vector>

class Alien {

public:
    Alien( b2World* worldRef,
//           b2ParticleSystem* particleSystem,
           b2Vec2 location,
           b2Vec2* vertices,
           long vertexCount,
           float density,
           float health,
           float crashDamage, // damage of crash on friendly
//           long crashParticleCount, // explosive particle effect
//           float crashParticleDamage, // damage each particle will do
           uint16 categoryBits,
           uint16 maskBits,
           int16 groupIndex);
    ~Alien();
    
    b2Vec2 GetPosition();
    float GetRotation();
    void SetVelocity(b2Vec2 velocity);
    void Impulse(b2Vec2 impulse);
    
private:
    b2Body* m_body;
    b2Fixture* m_fixture;
    b2World* m_world;
    b2ParticleSystem* m_particleSystem;
    
    float health;
    float crashDamage;
    long crashParticleCount;
};

static std::vector<Alien*> aliens;

#endif /* Alien_h */

