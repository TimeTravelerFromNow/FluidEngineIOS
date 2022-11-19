#ifndef Friendly_h
#define Friendly_h

#include <stdio.h>
#include "Box2D.h"
#include <vector>
class Friendly {

public:
    Friendly( b2World* worldRef,
             //           b2ParticleSystem* particleSystem,
                        b2Vec2 location,
                        float density,
                        float restitution,
                        float health,
                        float crashDamage, // damage of crash on friendly
             //           long crashParticleCount, // explosive particle effect
             //           float crashParticleDamage, // damage each particle will do
                        uint16 categoryBits,
                        uint16 maskBits,
                        int16 groupIndex);
    ~Friendly();
    
    void SetAsPolygonShape(b2Vec2* vertices,
                           long vertexCount);
    void SetAsCircleShape(float radius);
    void SetFixedRotation(bool to);
    void Torque(float amt);
    void Impulse(b2Vec2 imp, b2Vec2 atPos);
    
    b2Vec2 GetPosition();
    float GetRotation();
    float GetAngV();
    void SetVelocity(b2Vec2 velocity);
    void SetAngularVelocity(float to);
    void WeldFriendly( Friendly* friendly, b2Vec2 weldPos, float stiffness);

    b2Body* GetBody();
    
private:
    b2Fixture* m_fixture;
    b2World* m_world;
    b2ParticleSystem* m_particleSystem;
    b2Body* m_body;

    b2Filter m_filter = b2Filter();
    
    b2Vec2 m_origin;
    float m_density;
    float m_restition;
    float m_health;
    float m_crashDamage;
    long m_crashParticleCount;
};

static std::vector<Friendly*> friendlies;

#endif /* Friendly_h */

