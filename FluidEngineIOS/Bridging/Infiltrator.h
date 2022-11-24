#ifndef Friendly_h
#define Friendly_h

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
                        float health,
                        float crashDamage, // damage of crash on friendly
             //           long crashParticleCount, // explosive particle effect
             //           float crashParticleDamage, // damage each particle will do
                        uint16 categoryBits,
                        uint16 maskBits,
                        int16 groupIndex);
    ~Infiltrator();
    
    void SetAsPolygonShape(b2Vec2* vertices,
                           long vertexCount);
    void SetAsCircleShape(float radius);
    void AddCircle( float radius );

    void SetFixedRotation(bool to);
    void Torque(float amt);
    void Impulse(b2Vec2 imp, b2Vec2 atPos);
    float GetHealth();
    void TakeDamage();
    
    b2Vec2 GetPosition();
    float GetRotation();
    float GetAngV();
    b2Vec2 GetVel();
    void SetVelocity(b2Vec2 velocity);
    void SetAngularVelocity(float to);
    void WeldFriendly( Infiltrator* friendly, b2Vec2 weldPos, float stiffness);
    void WheelFriendly( Infiltrator* friendly, b2Vec2 weldPos, float stiffness, float damping);
    b2Body* GetBody();
    
private:
    b2Fixture* m_fixture;
    b2Fixture* m_circleFixture = NULL;
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

#endif /* Friendly_h */

