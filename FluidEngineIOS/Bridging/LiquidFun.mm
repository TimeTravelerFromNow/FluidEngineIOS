#import "LiquidFun.h"
#import "Box2D.h"
#import "Tube.h"
#import "BoxButton.h"
#import "Reservoir.h"
#import "TKSpline.h"
#import "Infiltrator.h"
#import "CustomContactListener.h"

#ifndef BoxToSimd_Definitions
#define BoxToSimd_Definitions

float2 _float2( const b2Vec2& from) { // I really wanted to avoid this, but it will work for singular b2Vec2/float values
    return { from.x, from.y };
}

b2Vec2 _b2Vec2(float2 from) { // the good news is the pointers seem to be working fine.
    return b2Vec2( from.x, from.y );
}

b2Color _b2Color(float3 from) { // had to do the same (alignments or something made float3 { 0.4, 0.8, 0.3} into b2Color(0.4, 1, 0) )
    return b2Color( from.r, from.g, from.b );
}

#endif

static b2World *world;

@implementation LiquidFun

//getting debug draw data for Metal
+ (int)getPointsDrawCount
{
    return metalDebugDraw.GetPointsCount();
}

+ (void *)getPointsPositions {
    return metalDebugDraw.GetPointsPositionBuffer();
}

+ (void *)getPointsColors {
    return metalDebugDraw.GetPointsColorBuffer();
}

+ (void *)getLinesVertices {
    return metalDebugDraw.GetLinesPositionBuffer();
}
+ (void *)getLinesColors {
    return metalDebugDraw.GetLinesColorBuffer();
}
+ (int)getLinesDrawCount {
    return metalDebugDraw.GetLinesCount();
}

+ (void *)getTrianglesVertices {
    return metalDebugDraw.GetTrianglesPositionBuffer();
}

+ (int)getTrianglesDrawCount {
    return metalDebugDraw.GetTrianglesCount();
}

// world access
+ (void)createWorldWithGravity:(float2)gravity {
    world = new b2World( _b2Vec2(gravity) );
    world->SetDebugDraw(&metalDebugDraw);
    world->SetContactListener( &m_customcontactlistener );
};

+ (void)destroyBody:(void *)bodyRef {
    world->DestroyBody((b2Body *)bodyRef);
}

+ (void *)createParticleSystemWithRadius:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density {
  b2ParticleSystemDef particleSystemDef;
  particleSystemDef.radius = radius;
  particleSystemDef.dampingStrength = dampingStrength;
  particleSystemDef.gravityScale = gravityScale;
  particleSystemDef.density = density;
  
  b2ParticleSystem *particleSystem = world->CreateParticleSystem(&particleSystemDef);
  return particleSystem;
}
+ (void *)createFlaggedParticleSystem:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density flagBuffer:(uint32*)flagBuffer flagCount:(int)flagCount {
    b2ParticleSystemDef particleSystemDef;
    particleSystemDef.radius = radius;
    particleSystemDef.dampingStrength = dampingStrength;
    particleSystemDef.gravityScale = gravityScale;
    particleSystemDef.density = density;
    
    b2ParticleSystem *particleSystem = world->CreateParticleSystem(&particleSystemDef);
    
   // particleSystem->SetFlagsBuffer(flagBuffer, flagCount);
    return particleSystem;
}
// freezing
+ (void)pauseParticleSystem:(void *)particleSystem {
    ((b2ParticleSystem *)particleSystem)->SetPaused(true);
}
+ (void)resumeParticleSystem:(void *)particleSystem {
    ((b2ParticleSystem *) particleSystem)->SetPaused(false);
}
+ (bool)getIsActiveForSystem:(void *)particleSystem {
    return ((b2ParticleSystem *) particleSystem)->GetPaused();
}
+ (void)pauseBody:(void *)bodyReference {
    ((b2Body *)bodyReference)->SetActive(false);
}
+ (void)resumeBody:(void *)bodyReference {
    ((b2Body *)bodyReference)->SetActive(true);
}
+ (bool)getIsActiveForBody:(void *)bodyReference {
    return ((b2Body *)bodyReference)->IsActive();
}

// particle creation
+ (void)createParticleBoxForSystem:(void *)particleSystem position:(float2)position size:(float2)size color:(float3)color {
    b2PolygonShape shape;
    shape.SetAsBox(size.x * 0.5f, size.y * 0.5f);
    
    b2ParticleGroupDef particleGroupDef;
    particleGroupDef.flags = b2_waterParticle | b2_fixtureContactFilterParticle;
    particleGroupDef.position = _b2Vec2(position);
    particleGroupDef.shape = &shape;
    b2ParticleColor pColor;
    pColor.Set( _b2Color(color) );
    particleGroupDef.color = pColor;
    ((b2ParticleSystem *)particleSystem)->CreateParticleGroup(particleGroupDef);
}

+ (void)createParticleBallForSystem:(void *)particleSystem position:(float2)position velocity:(float2)velocity angV:(float)angV radius:(float)radius color:(float3)color {
    b2ParticleGroupDef pGroupDef;
    pGroupDef.flags = b2_powderParticle | b2_fixtureContactFilterParticle;
    pGroupDef.position = _b2Vec2(position);
    pGroupDef.linearVelocity = _b2Vec2(velocity);
    pGroupDef.angularVelocity = angV;
    
    b2CircleShape shape;
    shape.m_radius = radius;
    pGroupDef.shape = &shape;
    pGroupDef.color = b2ParticleColor( _b2Color(color) );
    pGroupDef.lifetime = 4;
    ((b2ParticleSystem*)particleSystem)->CreateParticleGroup(pGroupDef);
}

+ (int)particleCountForSystem:(void *)particleSystem {
  return ((b2ParticleSystem *)particleSystem)->GetParticleCount();
}

+ (void *)particlePositionsForSystem:(void *)particleSystem {
  return ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
}
+ (void)emptyParticleSystem:(void *)particleSystem minTime:(float)minTime maxTime:(float)maxTime {
    int count = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    for(int i = 0; i < count; i++) {
    ((b2ParticleSystem *)particleSystem)->SetParticleLifetime(i, arc4random() % 1000 * (maxTime - minTime) / 1000 + minTime);
    }
}

+ (void)destroyParticleSystem:(void *)particleSystem {
    world->DestroyParticleSystem( (b2ParticleSystem*)particleSystem );
}

+ (void *)colorBufferForSystem:(void *)particleSystem {
    return ((b2ParticleSystem *)particleSystem)->GetColorBuffer();
}

+(void)updateColors:(void *)particleSystem colors:(b2Color *)color yLevels:(float *)yLevels numLevels:(int)numLevels{
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    
    b2ParticleColor* colorBuffer = ((b2ParticleSystem *)particleSystem)->GetColorBuffer();
    
    for(int pIndex = 0; pIndex<oldPositionsCount; pIndex++) {
        for(int levelIndex = 0; levelIndex< numLevels; levelIndex++) {
            if (levelIndex > 0) {
            if( positionBuffer[pIndex].y > yLevels[levelIndex] ) {
                b2ParticleColor overrideColor = b2ParticleColor(color[levelIndex]);
                colorBuffer[pIndex] = overrideColor;
            }
            }
            else {
                if( positionBuffer[pIndex].y < yLevels[1] ) {
                b2ParticleColor overrideColor = b2ParticleColor(color[0]);
                colorBuffer[pIndex] = overrideColor;
                }
            }
        }
    }
}


// for cropping the overflows, and returns how many deleted
+ (int)deleteParticlesInParticleSystem:(void *)particleSystem aboveYPosition:(float)aboveYPosition {
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    int abovePositionsCount = 0;
  
    for(int i = 0; i<oldPositionsCount; i++) {
        if(positionBuffer[i].y > aboveYPosition) {
            abovePositionsCount++;
            ((b2ParticleSystem *)particleSystem)->SetParticleLifetime(i, arc4random() % 1000 * (1.0 - 0.3) / 1000 + 0.3);
        }
    }
    return abovePositionsCount;
}


+ (int)deleteBelowInParticleSystem:(void *)particleSystem belowYPosition:(float)belowYPosition {
    b2ParticleSystem* ref = ((b2ParticleSystem *)particleSystem);
    b2Vec2* positionBuffer = ref->GetPositionBuffer();
    int oldPositionsCount = ref->GetParticleCount();
    int belowPositionsCount = 0;
    
    for(int i = 0; i<oldPositionsCount; i++) {
        if(positionBuffer[i].y < belowYPosition) {
            belowPositionsCount++;
            ref->SetParticleLifetime(i, arc4random() % 1000 * (1.0 - 0.3) / 1000 + 0.3);
        }
    }
    return belowPositionsCount;
}

+ (void)destroyParticlesInSystem:(void *)particleSystem {
    b2ParticleGroup* group = ((b2ParticleSystem *)particleSystem)->GetParticleGroupList();
      while (group)
      {
          group->DestroyParticles(false);
          group = group->GetNext();
      }
}

+ (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations
  positionIterations:(int)positionIterations {
  world->Step(timeStep, velocityIterations, positionIterations);
    world->DrawDebugData();
}

+ (void *)createEdgeBoxWithOrigin:(float2)origin size:(float2)size {
    // create the body
    b2BodyDef bodyDef;
    bodyDef.type = b2_kinematicBody;
    bodyDef.position = _b2Vec2(origin);
    b2Body *body = world->CreateBody(&bodyDef);
    b2EdgeShape shape;
    b2Filter filter;
    filter.maskBits = 0x0001;
    filter.categoryBits = 0x0001;
    
    b2Vec2 halfS = _b2Vec2(size) / 2;
    b2Vec2 bottomL = -halfS;
    b2Vec2 bottomR = b2Vec2(halfS.x,-halfS.y);
    b2Vec2 topL    = b2Vec2(-halfS.x,halfS.y);
    b2Vec2 topR    = halfS;
    // bottom
    shape.Set(bottomL, bottomR);
    b2Fixture* f0 = body->CreateFixture(&shape, 0);
    f0->SetFilterData(filter);
    // top
    shape.Set(topL, topR);
    b2Fixture* f1 = body->CreateFixture(&shape, 0);
    f1->SetFilterData(filter);
    // left
    shape.Set(bottomL, topL);
    b2Fixture* f2 = body->CreateFixture(&shape, 0);
    f2->SetFilterData(filter);
    // right
    shape.Set(bottomR, topR);
    b2Fixture* f3 = body->CreateFixture(&shape, 0);
    f3->SetFilterData(filter);
    
    return body;
}

+ (void)setGravity:(float2)gravity {
  world->SetGravity( _b2Vec2(gravity) );
}

+ (void)setParticleLimitForSystem:(void *)particleSystem maxParticles:(int)maxParticles {
  ((b2ParticleSystem *)particleSystem)->SetDestructionByAge(true);
  ((b2ParticleSystem *)particleSystem)->SetMaxParticleCount(maxParticles);
}
+ (void)destroyWorld {
    world->SetAllowSleeping(true);
    world->SetSubStepping(false);
    delete world;
    world = NULL;
}

+ (void *)makeLineFixtureOnBody:(void *)bodyRef vertices:(b2Vec2 *)vertices {
    b2FixtureDef fixtureDef;
    b2EdgeShape line;
    line.Set(vertices[0], vertices[1]);
    fixtureDef.shape = &line;
    b2Fixture* lineFixture = ((b2Body *)bodyRef)->CreateFixture(&fixtureDef);
    return lineFixture;
}

+ (void)removeFixtureOnBody:(void *)bodyRef fixtureRef:(void *)fixtureRef {
    ((b2Body *) bodyRef)->DestroyFixture( (b2Fixture *)fixtureRef );
}

//positioning bodies
+ (float2)getPositionOfbody:(void *)bodyRef{
    return _float2( ((b2Body*)bodyRef)->GetPosition() );
}

//contacts
// MARK: could be useful but only returns one.
+ (void *)bodyInContactWith:(void *)bodyRef {
    b2Contact* contact = world->GetContactList();
    while(contact) {
        b2Fixture* fixtureA = contact->GetFixtureA();
        b2Fixture* fixtureB = contact->GetFixtureB();
        b2Body* bodyA = fixtureA->GetBody();
        b2Body* bodyB = fixtureB->GetBody();
        if( bodyRef == bodyA){
            return bodyB;
        } else if(bodyRef == bodyB){
            return bodyA;
        }
        contact->GetNext();
    } return nil;
}

// for managing transferring particles leaving to new tubes
+ (int)leavingParticleSystem:(void *)particleSystem newSystem:(void *)newSystem a:(float2)a b:(float2)b isLeft:(bool)isLeft {
    b2ParticleGroupDef newGroupDef;
    
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    b2Vec2* velocityBuffer = ((b2ParticleSystem *)particleSystem)->GetVelocityBuffer();
    int newPositionsCount = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)) > 0 ) {
            newPositionsCount++;
        }
    }
    b2Vec2 newPositions[newPositionsCount];
    b2Vec2 newVelocities[newPositionsCount];
    int newPositionIndex = 0;
    float avVelocityX = 0.0;
    float avVelocityY = 0.0;
    
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if(((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)) > 0 ) {
            newPositions[newPositionIndex] = positionBuffer[i];
            newVelocities[newPositionIndex] = velocityBuffer[i];
            avVelocityX += newVelocities[newPositionIndex].x;
            avVelocityY += newVelocities[newPositionIndex].y;
            newPositionIndex++;
            ((b2ParticleSystem *)particleSystem)->DestroyParticle(i, false);
        }
    }
    avVelocityX = avVelocityX / float(newPositionsCount);
    avVelocityY = avVelocityY / float(newPositionsCount);
    newGroupDef.positionData = newPositions;
    newGroupDef.linearVelocity = b2Vec2(avVelocityX, avVelocityY);
    newGroupDef.particleCount = newPositionsCount;
    newGroupDef.flags = b2_waterParticle | b2_fixtureContactFilterParticle;

    ((b2ParticleSystem *)newSystem)->CreateParticleGroup(newGroupDef);
    return newPositionsCount;
}
+ (int)deleteParticlesOutside:(void *)particleSystem width:(float)width height:(float)height rotation:(float)rotation position:(float2)position {
    b2PolygonShape hitBox;
    hitBox.SetAsBox(width , height);
    b2Transform boxTransform;
    boxTransform.Set( b2Vec2( position.x, position.y), rotation);

    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    int numDestroyed = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if(  !( hitBox.TestPoint(boxTransform, c)  ) ) {
            ((b2ParticleSystem *)particleSystem)->DestroyParticle(i, false);
            numDestroyed++;
        }
    }
    return numDestroyed;
}

+ (int)engulfParticles:(void *)inTube originalParticleSystem:(void *)originalParticleSystem {
    return ( (Tube *) inTube )->EngulfParticles( ( (b2ParticleSystem *)originalParticleSystem ) );
}

// physics setters
+ (void)moveKinematic:(void *)kinematicRef pushDirection:(float2)pushDirection {
    ((b2Body *) kinematicRef)->SetLinearVelocity(b2Vec2(pushDirection.x,pushDirection.y));
}
+ (void)pushBody:(void *)bodyRef pushVector:(float2)pushVector atPoint:(float2)atPoint awake:(bool)awake {
    ((b2Body *) bodyRef)->ApplyLinearImpulse(b2Vec2(pushVector.x,pushVector.y), b2Vec2(atPoint.x,atPoint.y), awake);
}
+ (void)dampMovementOfBody:(void *)kinematicRef amount:(float)amount {
    ((b2Body *) kinematicRef)->SetLinearDamping(amount);
}
+ (void)rotateBody:(void *)bodyRef amount:(float)amount{
    ((b2Body *)bodyRef)->SetAngularVelocity(amount);
}
+ (void)setAngularDamping:(void *)bodyRef amount:(float)amount {
    ((b2Body *)bodyRef)->SetAngularDamping(amount);
}
+ (void)setFixedRotation:(void*)bodyRef to:(bool)to {
    ((b2Body*)bodyRef)->SetFixedRotation(to);
}

// physics appliers
+ (void)torqueBody:(void *)bodyRef amt:(float)amt awake:(bool)awake{
    ((b2Body *)bodyRef)->ApplyAngularImpulse(amt, awake);
}

// physics getters
+ (float)getRotationOfBody:(void *)bodyRef{
    return ((b2Body *)bodyRef)->GetAngle();
}
+ (float2)getVelocityOfBody:(void*)bodyRef{
    return _float2( ((b2Body *)bodyRef)->GetLinearVelocity() );
}

// Tube class refactor ( now the tube is constructed in C++ and game scene communication occurs in TestTube.Swift )
+ (void *)makeTube:(void *)particleSysRef
          location:(float2)location
          vertices:(void *) vertices
          vertexCount:(UInt32)vertexCount
          tubeWidth:(float32)tubeWidth
          tubeHeight:(float32)tubeHeight
          gridId:(long)gridId {
    Tube* newTube = new Tube(world,
                             (b2ParticleSystem*) particleSysRef,
                             _b2Vec2( location ),
                             (b2Vec2*)vertices,
                             (unsigned int)vertexCount,
                             tubeWidth,
                             tubeHeight,
                             gridId);
    tubes.push_back(newTube);
    return newTube;
}

+ (void)destroyTube:(void *)tubeRef {
    ((Tube*)tubeRef)->~Tube();
}

//hover candidate testing
+ (long)hoverCandidate:(void *)tube {
    return ((Tube *)tube)->GetHoverCandidateGridId();
}

//pour Guides
+ (void)addGuides:(void *)tube vertices:(void *)vertices {
    ((Tube *)tube)->AddGuides((b2Vec2 *) vertices);
}
+ (void)removeGuides:(void *)tube {
    ((Tube *)tube)->RemoveGuides();
}
+ (void *)addDivider:(void *)tube vertices:(void *)vertices {
    return ((Tube *)tube)->addDivider((b2Vec2 *) vertices);
}
+ (void)removeDivider:(void *)tube divider:(void *)divider {
    ((Tube *)tube)->removeDivider((b2Fixture*)divider);
}

//movement and rotation
+ (void)setTubeVelocity:(void *)tube velocity:(float2)velocity {
    ((Tube *) tube)->SetVelocity(b2Vec2(velocity.x,velocity.y));
}
// rotation
+ (void)setAngularVelocity:(void *)ofTube angularVelocity:(float)angularVelocity{
    ((Tube *) ofTube)->SetRotation(angularVelocity);
}

+ (float2)getTubePosition:(void *)tube {
    float2 sharedPosition;
    b2Vec2 b2Pos = ((Tube*)tube)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

+ (void *)getTubeAtPosition:(float2)position {
    b2Vec2 pos = b2Vec2(position.x, position.y);
    unsigned long tubeCount = tubes.size();
    for( int i = 0; i < tubeCount; i++ ){
        if ( tubes[i]->IsAtPosition(pos) ) {
            return tubes[i];
        };
    };
    return nil;
}

+ (float)getTubeRotation:(void *)tube{
    return ((Tube *)tube)->GetRotation();
}

+ (float2)getTubeVelocity:(void *)tube {
    return _float2( ((Tube *)tube)->GetVelocity() );
}

//pour filtering

+ (void) SetPourBits:(void *)ofTube {
    ((Tube *)ofTube)->SetPourBits();
}
    
+ (void) ClearPourBits:(void *)ofTube {
    ((Tube *)ofTube)->ClearPourBits();
}

+ (void) beginEmpty:(void *)tube {
    ((Tube *)tube)->BeginEmpty();
}

// making buttons

+ (void *) makeBoxButton:( b2Vec2* )withVertices location:(float2)location {
    BoxButton* button = new BoxButton(world, (b2Vec2*)withVertices, b2Vec2(location.x, location.y));
    return button;
}

+ (bool) boxIsAtPosition:( float2 )boxPosition boxRef:(void *)boxRef {
    return ((BoxButton *)boxRef)->IsAtPosition(_b2Vec2(boxPosition));
}

+ (float2)getBoxButtonPosition:(void *)boxRef {
    return _float2( ((BoxButton*)boxRef)->GetPosition() );
}

+ (float) getBoxButtonRotation:(void *)boxRef {
    return ((BoxButton *)boxRef)->GetRotation();
}

+ (void) updateBoxButton:(void *)boxRef {
    ((BoxButton *)boxRef)->Update();
}

+ (void) freezeButton:(void *)boxRef {
    ((BoxButton *)boxRef)->Freeze();
}

+ (void) unFreezeButton:(void *)boxRef {
    ((BoxButton *)boxRef)->UnFreeze();
}

//move a particle system
+ (void) moveParticleSystem:(void *)particleSys byVelocity:(float2)byVelocity {
    b2ParticleSystem* system = ((b2ParticleSystem *)particleSys);
    int particleCount = system->GetParticleCount();
    b2Vec2* vBuffer = system->GetVelocityBuffer();
    const b2Vec2 b2Velocity = _b2Vec2( byVelocity );
    for( int i = 0; i < particleCount; i++ ) {
        vBuffer[i] += b2Velocity;
    }
}

// Reservoir Class
+ (void *) makeReservoir:(void *)particleSysRef
                location:(float2)location
                vertices:(b2Vec2 *) vertices vertexCount:(UInt32)vertexCount {
    Reservoir* newReservoir = new Reservoir(world,
                                            (b2ParticleSystem*) particleSysRef,
                                            _b2Vec2( location ),
                                            vertices, (unsigned int)vertexCount);
//    reservoirs.push_back(newReservoir);
    return newReservoir;
}

+ (void) destroyReservoir:(void *)reservoir {
    ((Reservoir*)reservoir)->~Reservoir();
}

+ (void) setValve0AngularVelocity:(void*)reservoir angV:(float)angV {
    ((Reservoir *)reservoir)->SetValve0AngularVelocity(angV);
}
+ (float) getValve0Rotation:(void*)reservoir {
    return ((Reservoir*)reservoir)->GetValve0Rotation();
}

+ (float2)getReservoirPosition:(void *)reservoir {
    return _float2( ((Reservoir*)reservoir)->GetPosition() );
}

+ (float)getReservoirRotation:(void *)reservoir{
    return ((Reservoir *)reservoir)->GetRotation();
}

+ (float)createBulbOnReservoir:(void *)reservoir hemisphereSegments:(long)hemisphereSegments radius:(float)radius {
    return ((Reservoir *)reservoir)->CreateBulb(hemisphereSegments, radius);
}

+ (float2)getBulbPos:(void *)reservoir {
    return _float2( ((Reservoir *)reservoir)->GetBulbPosition() );
}

+ (float2)getSegmentPos:(void *)reservoir atIndex:(long)atIndex {
    return _float2( ((Reservoir *)reservoir)->GetBulbSegmentPosition(atIndex) );
}

+ (void) setVelocity:(void *)ofReservoir velocity:(float2)velocity{
    ((Reservoir *)ofReservoir)->SetVelocity( _b2Vec2(velocity) );
}

+ (float2) getVelocity:(void *)ofReservoir {
    return _float2( ((Reservoir *)ofReservoir)->GetVelocity() );
}

+ (void) setBulbWallAngV:(void *)ofReservoir atIndex:(long)atIndex angV:(float)angV {
    ((Reservoir *)ofReservoir)->SetWallPieceAngV(atIndex, angV);
}

+ (float) getBulbWallAngle:(void *)ofReservoir atIndex:(long)atIndex {
    return ((Reservoir *)ofReservoir)->GetBulbSegmentRotation(atIndex);
}

+ (void*) getWallBody:(void *)onReservoir atIndex:(long)atIndex {
    return ((Reservoir *)onReservoir)->GetWallBody(atIndex); //MARK: unsafe
}

//TK Splines
+ (void *)makeSpline:(float *)tControlPoints withControlPoints:(b2Vec2 *)withControlPoints controlPtsCount:(long)controlPtsCount {
    TKSpline* spline = new TKSpline( tControlPoints, withControlPoints, controlPtsCount );
    return spline;
}

+ (void) setInterpolatedValues:(void *)usingSpline tVals:(float *)tVals onXVals:(float *)onXVals onYVals:(float *)onYVals onTangents:(b2Vec2 *)onTangents valCount:(long)valCount {
    ((TKSpline *)usingSpline )->SetInterpolatedPoints(tVals, onXVals, onYVals, onTangents, valCount);
}
+ (void *)make1DSpline:(float *)xControlPoints yControlPoints:(float *)yControlPoints controlPtsCount:(long)controlPtsCount {
    TKSpline1D* spline = new TKSpline1D( xControlPoints, yControlPoints, controlPtsCount );
    return spline;
}
+ (void) set1DInterpolatedValues:(void *)using1DSpline xVals:(float *)xVals onYVals:(float *)onYVals onSlopes:(float *)onSlopes valCount:(long)valCount {
    ((TKSpline1D *)using1DSpline)->SetInterpolatedPoints(xVals, onYVals, onSlopes, valCount);
}
// pipe fixture creation / destruction
+ (void *)makePipeFixture:(void*)onReservoir lineVertices:(b2Vec2 *)lineVertices vertexCount:(long)vertexCount {
    return ((Reservoir *)onReservoir)->MakeLineFixture(lineVertices, vertexCount);
}
+ (void) destroyPipeFixture:(void*)onReservoir lineRef:(void *)lineRef {
    ((Reservoir *)onReservoir)->DestroyLineFixture( lineRef );
}

//reservoir particle transfers
+ (long) transferParticles:(void *)fromReservoir wallSegmentPosition:(float2)wallPos toSystem:(void *)toSystem {
    return long( ((Reservoir *)fromReservoir)->TransferParticles(toSystem, _b2Vec2(wallPos) ) );
}

// wall body rotations
+ (void)setWallAngV:(void*)onReservoir wallBodyRef:(void *)wallBodyRef angV:(float)angV {
    ((Reservoir *)onReservoir)->SetValveAngV(wallBodyRef, angV);
}
+ (float)getWallAngle:(void*)onReservoir wallBodyRef:(void *)wallBodyRef {
    return ((Reservoir *)onReservoir)->GetWallAngle( wallBodyRef );
}

// just setting fixture filters
+ (void)shareParticleSystemFilterWithFixture:(void*)fixtureRef particleSystem:(void *)particleSystem {
    b2Filter pFilter = ((b2ParticleSystem *)particleSystem)->filter;
    if (pFilter.groupIndex > 0 ){
        printf("test");
    }
    ((b2Fixture*)fixtureRef)->SetFilterData( pFilter );
}

+ (void)setDefaultFilterForFixture:(void *)fixtureRef {
    b2Filter defFilter = b2Filter();
    defFilter.isFiltering = true;
    defFilter.groupIndex = -1;
    ((b2Fixture*)fixtureRef)->SetFilterData(defFilter);
}

// Infiltrator class
+ (void *)makeInfiltrator:(float2)position
              velocity:(float2)velocity
            startAngle:(float)startAngle
               density:(float)density
                restitution:(float)restitution
                   filter:(b2Filter)filter {
    Infiltrator* newInfiltrator = new Infiltrator( world,
                                                  //           b2ParticleSystem* particleSystem,
                                                  _b2Vec2( position ),
                                                  _b2Vec2( velocity ),
                                                  startAngle,
                                                  density,
                                                  restitution,
                                                  filter);
    return newInfiltrator;
}

// body methods
+ (void*) newInfiltratorBody:(void*)infiltratorRef pos:(float2)pos angle:(float)angle filter:(b2Filter)filter {
//    printf(" b2Vec2 bytes: %d \n", sizeof(b2Vec2));
//    printf(" float2 bytes: %d \n", sizeof(float2));
//    printf(" packed float2 bytes: %d", sizeof(simd_packed_float2));
    return ((Infiltrator*)infiltratorRef)->MakeBody( _b2Vec2(pos), angle, filter);
}
+ (void) destroyInfiltratorBody:(void*)infiltratorRef bodyRef:(void*)bodyRef {
    ((Infiltrator*)infiltratorRef)->DestroyBody((b2Body*)bodyRef);
}

// fixture methods
+ (void*) makePolygonFixtureOnInfiltrator:(void*)infiltrator body:(void*)body pos:(float2)pos vertices:(b2Vec2*)vertices vertexCount:(long)vertexCount  {
    return ((Infiltrator*)infiltrator)->AttachPolygon((b2Body*)body, _b2Vec2(pos), vertices, vertexCount);
}

+ (void*) makeCircleFixtureOnInfiltrator:(void*)infiltrator body:(void*)body radius:(float)radius pos:(float2)pos {
    return ((Infiltrator*)infiltrator)->AttachCircle((b2Body*)body, _b2Vec2(pos), radius);
}

// joint methods ( has no class specifics )
+ (void*) weldJoint:(b2Body*)bodyA bodyB:(b2Body*)bodyB weldPos:(float2)weldPos stiffness:(float)stiffness damping:(float)damping {
    b2WeldJointDef jointDef;
    jointDef.bodyA = bodyA;
    jointDef.bodyB = bodyB;
    jointDef.localAnchorA = _b2Vec2(weldPos);
    jointDef.collideConnected = false;
    jointDef.frequencyHz = stiffness;
    jointDef.dampingRatio = damping;
    return world->CreateJoint( &jointDef );
}

+ (void*) wheelJoint:(b2Body*)bodyA bodyB:(b2Body*)bodyB weldPos:(float2)weldPos localAxisA:(float2)localAxisA stiffness:(float)stiffness damping:(float)damping {
    b2WheelJointDef jointDef;
    jointDef.bodyA = bodyA;
    jointDef.bodyB = bodyB;
    jointDef.localAnchorA = _b2Vec2(weldPos);
    jointDef.collideConnected = false;
    jointDef.localAxisA = _b2Vec2(localAxisA);
    jointDef.frequencyHz = stiffness;
    jointDef.dampingRatio = damping;
    return world->CreateJoint( &jointDef );
}



@end


