#ifndef Pipe_h
#define Pipe_h

#include "b2ParticleSystem.h"
#include "Box2D.h"
#include "Tube.h"
#include <vector>

class Reservoir {
public:
    b2ParticleSystem* m_particleSys;
    long numBulbWallPieces;
public:
    Reservoir(b2World* worldRef,
              b2ParticleSystem* particleSysRef,
              b2Vec2 location,
              b2Vec2* vertices, unsigned int count);
    ~Reservoir();
    
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
    void CreateBulb(long hemisphereSegments, float bulbRadius);
    b2Vec2 GetBulbPosition();
    b2Vec2 GetBulbSegmentPosition(long atIndex);

    void* MakeLineFixture( b2Vec2* lineVertices, long vertexCount );
//    void SetFixtureFilter( void* fixtureRef, ...) // MARK: TODO some pipe filter implementation here
    void DestroyLineFixture( void* fixtureRef );
    
    void RemoveWallPiece( long atIndex );
    
    void SetWallPieceAngV( long atIndex, float angV );
    float GetBulbSegmentRotation( long atIndex );
    
private:
    b2Fixture* m_topCap;
    b2Fixture* m_guide0;
    b2Fixture* m_guide1;
    
    b2Body* m_body;
    b2Body* m_hboxBody;
    b2Body* m_sensorBody;
    b2Body* m_valve0Body;
    
    float32 width;
    float32 height;
    long id;
    
    b2Filter m_filter;
    b2Fixture* m_valve0Fixture;
    
    float m_exitWidth;
    b2Vec2 m_exitPosition;
    
    std::vector<b2Fixture*> m_bulbFixtures;
    std::vector<b2Body*> m_bulbBodies;
    std::vector<b2Fixture*> m_pipeFixtures;
    
    b2Body* m_bulbBody;
    
    b2World* m_world;
};

static std::vector<Reservoir*> reservoirs;

#endif /* Pipe_h */
