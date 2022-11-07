#import "LiquidFun.h"
#import "Box2D.h"
#import "Tube.h"
#import "BoxButton.h"
#import "PolygonObject.h"
#import "Reservoir.h"
#import "TKSpline.h"

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
+ (void)createWorldWithGravity:(Vector2D)gravity {
    world = new b2World(b2Vec2(gravity.x, gravity.y));
    world->SetDebugDraw(&metalDebugDraw);
}

+ (void)destroyBody:(void *)bodyRef {
    world->DestroyBody((b2Body *)bodyRef);
}

+(void *)getVec2:(Vector2D *)vertices vertexCount:(UInt32)size {
    b2Vec2* verticesOut;
    verticesOut = new b2Vec2[size];
    for(uint i = 0; i < size; i++){
        verticesOut[i] = b2Vec2(vertices[i].x, vertices[i].y);
    };
    return verticesOut;
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


+ (void)createParticleBoxForSystem:(void *)particleSystem position:(Vector2D)position size:(Size2D)size color:(void *)color {
    b2PolygonShape shape;
    shape.SetAsBox(size.width * 0.5f, size.height * 0.5f);
    
    b2ParticleGroupDef particleGroupDef;
    particleGroupDef.flags = b2_waterParticle | b2_fixtureContactFilterParticle;
    particleGroupDef.position.Set(position.x, position.y);
    particleGroupDef.shape = &shape;
    b2ParticleColor pColor;
    Color* inColor = (Color*)color;
    pColor.Set(uint8( inColor->r * 255 ), uint8(inColor->g * 255), uint8(inColor->b * 255), uint8( inColor->a * 255 ));
    particleGroupDef.color = pColor;
    ((b2ParticleSystem *)particleSystem)->CreateParticleGroup(particleGroupDef);
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

+(void)updateColors:(void *)particleSystem colors:(void *)color yLevels:(float *)yLevels numLevels:(int)numLevels{
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    
    b2ParticleColor* colorBuffer = ((b2ParticleSystem *)particleSystem)->GetColorBuffer();
    
    for(int pIndex = 0; pIndex<oldPositionsCount; pIndex++) {
        for(int levelIndex = 0; levelIndex< numLevels; levelIndex++) {
            if (levelIndex > 0) {
            if( positionBuffer[pIndex].y > yLevels[levelIndex] ) {
                Color inColor = ((Color*)color)[levelIndex];
                b2ParticleColor overrideColor = b2ParticleColor(uint8( inColor.r * 255 ), uint8(inColor.g * 255), uint8(inColor.b * 255), uint8( inColor.a * 255 ));
                colorBuffer[pIndex] = overrideColor;
            }
            }
            else {
                if( positionBuffer[pIndex].y < yLevels[1] ) {
                Color inColor = ((Color*)color)[0];
                b2ParticleColor overrideColor = b2ParticleColor(uint8( inColor.r * 255 ), uint8(inColor.g * 255), uint8(inColor.b * 255), uint8( inColor.a * 255 ));
                colorBuffer[pIndex] = overrideColor;
                }
            }
        }
    }
    // the for loop above should update the color buffer.
   // ((b2ParticleSystem *)particleSystem)->SetColorBuffer(<#b2ParticleColor *buffer#>, <#int32 capacity#>)
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
b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
int belowPositionsCount = 0;

for(int i = 0; i<oldPositionsCount; i++) {
    if(positionBuffer[i].y < belowYPosition) {
        belowPositionsCount++;
        ((b2ParticleSystem *)particleSystem)->SetParticleLifetime(i, arc4random() % 1000 * (1.0 - 0.3) / 1000 + 0.3);
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
+ (void *)createEdgeBoxWithOrigin:(Vector2D)origin size:(Size2D)size {
  // create the body
  b2BodyDef bodyDef;
  bodyDef.position.Set(origin.x, origin.y);
  b2Body *body = world->CreateBody(&bodyDef);

    b2EdgeShape shape;
  // bottom
  shape.Set(b2Vec2(0, 0), b2Vec2(size.width, 0));
  body->CreateFixture(&shape, 0);
  // top
  shape.Set(b2Vec2(0, size.height), b2Vec2(size.width, size.height));
  body->CreateFixture(&shape, 0);
  
  // left
  shape.Set(b2Vec2(0, size.height), b2Vec2(0, 0));
  body->CreateFixture(&shape, 0);
  
  // right
  shape.Set(b2Vec2(size.width, size.height), b2Vec2(size.width, 0));
  body->CreateFixture(&shape, 0);
  return body;
}

+ (void *)createGroundBoxWithOrigin:(Vector2D)origin size:(Size2D)size {
    // create the body
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(origin.x, origin.y);
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(size.height, size.width);
    body->CreateFixture(&shape, 0.0f);
    return body;
}

+ (void *)b2BoundingBoxFromScreen:(Vector2D)bottomLeftCorner topRightCorner:(Vector2D)topRightCorner {
    b2BodyDef bodyDef;
    b2Body *body = world->CreateBody(&bodyDef);
    b2EdgeShape shape;
    // bottom
    shape.Set(b2Vec2(bottomLeftCorner.x, bottomLeftCorner.y), b2Vec2(topRightCorner.x, bottomLeftCorner.y));
    body->CreateFixture(&shape, 0);
    // top
    shape.Set(b2Vec2(topRightCorner.x, topRightCorner.y), b2Vec2(bottomLeftCorner.x, topRightCorner.y));
    body->CreateFixture(&shape, 0);
    // left
    shape.Set(b2Vec2(bottomLeftCorner.x, topRightCorner.y), b2Vec2(bottomLeftCorner.x, bottomLeftCorner.y));
    body->CreateFixture(&shape, 0);
    // right
    shape.Set(b2Vec2(topRightCorner.x, bottomLeftCorner.y), b2Vec2(topRightCorner.x, topRightCorner.y));
    body->CreateFixture(&shape, 0);
    return body;
}

+ (void)setGravity:(Vector2D)gravity {
  world->SetGravity(b2Vec2(gravity.x, gravity.y));
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

+ (void *)makeLineFixtureOnBody:(void *)bodyRef vertices:(void *)vertices {
    b2FixtureDef fixtureDef;
    b2EdgeShape line;
    line.Set(((b2Vec2 *)vertices)[0], ((b2Vec2 *)vertices)[1]);
    fixtureDef.shape = &line;
    b2Fixture* lineFixture = ((b2Body *)bodyRef)->CreateFixture(&fixtureDef);
    return lineFixture;
}

+ (void)removeFixtureOnBody:(void *)bodyRef fixtureRef:(void *)fixtureRef {
    ((b2Body *) bodyRef)->DestroyFixture( (b2Fixture *)fixtureRef );
}
//positioning bodies
+ (Vector2D)getPositionOfbody:(void *)bodyRef{
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((b2Body*)bodyRef)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

//contacts
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
+ (int)leavingParticleSystem:(void *)particleSystem newSystem:(void *)newSystem a:(Vector2D)a b:(Vector2D)b isLeft:(bool)isLeft {
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
+ (int)deleteParticlesOutside:(void *)particleSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position {
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


//movement and rotation
+ (void)moveKinematic:(void *)kinematicRef pushDirection:(Vector2D)pushDirection {
    ((b2Body *) kinematicRef)->SetLinearVelocity(b2Vec2(pushDirection.x,pushDirection.y));
}
+ (void)pushBody:(void *)bodyRef pushVector:(Vector2D)pushVector atPoint:(Vector2D)atPoint awake:(bool)awake {
    ((b2Body *) bodyRef)->ApplyLinearImpulse(b2Vec2(pushVector.x,pushVector.y), b2Vec2(atPoint.x,atPoint.y), awake);
}
+ (void)dampMovementOfBody:(void *)kinematicRef amount:(float)amount {
    ((b2Body *) kinematicRef)->SetLinearDamping(amount);
}
// rotation
+ (void)rotateBody:(void *)bodyRef amount:(float)amount{
    ((b2Body *)bodyRef)->SetAngularVelocity(amount);
}
+ (void)torqueBody:(void *)bodyRef amount:(float)amount awake:(bool)awake{
    ((b2Body *)bodyRef)->ApplyAngularImpulse(amount, awake);
}

+ (void)dampRotationOfBody:(void *)bodyRef amount:(float)amount {
    ((b2Body *)bodyRef)->SetAngularDamping(amount);
}

+ (float)getRotationOfBody:(void *)bodyRef{
    return ((b2Body *)bodyRef)->GetAngle();
}

// Tube class refactor ( now the tube is constructed in C++ and game scene communication occurs in TestTube.Swift )
+ (void *)makeTube:(void *)particleSysRef
          location:(Vector2D)location
          vertices:(void *) vertices vertexCount:(UInt32)vertexCount
          sensorVertices:(void *)sensorVertices sensorCount:(UInt32)sensorCount
          tubeWidth:(float32)tubeWidth
          tubeHeight:(float32)tubeHeight
          gridId:(long)gridId {
    Tube* newTube = new Tube(world,
                             (b2ParticleSystem*) particleSysRef,
                             b2Vec2(location.x,location.y),
                             (b2Vec2*)vertices, (unsigned int)vertexCount,
                             (b2Vec2*)sensorVertices, (unsigned int)sensorCount,
                             tubeWidth,
                             tubeHeight,
                             gridId);
    tubes.push_back(newTube);
    return newTube;
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
+ (void)setTubeVelocity:(void *)tube velocity:(Vector2D)velocity {
    ((Tube *) tube)->SetVelocity(b2Vec2(velocity.x,velocity.y));
}
// rotation
+ (void)setAngularVelocity:(void *)ofTube angularVelocity:(float)angularVelocity{
    ((Tube *) ofTube)->SetRotation(angularVelocity);
}

+ (Vector2D)getTubePosition:(void *)tube {
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((Tube*)tube)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

+ (void *)getTubeAtPosition:(Vector2D)position {
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

+ (Vector2D)getTubeVelocity:(void *)tube {
    b2Vec2 v = ((Tube *)tube)->GetVelocity();
    Vector2D sharedVelocity;
    sharedVelocity.x = v.x;
    sharedVelocity.y = v.y;
    return sharedVelocity;
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

+ (void *) makeBoxButton:( Vector2D* )withVertices location:(Vector2D)location {
    BoxButton* button = new BoxButton(world, (b2Vec2*)withVertices, b2Vec2(location.x, location.y));
    return button;
}

+ (bool) boxIsAtPosition:( Vector2D )boxPosition boxRef:(void *)boxRef {
    return ((BoxButton *)boxRef)->IsAtPosition(b2Vec2(boxPosition.x, boxPosition.y));
}

+ (Vector2D)getBoxButtonPosition:(void *)boxRef {
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((BoxButton*)boxRef)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
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

// custom polygons
+ (void *)makePolygon:( Vector2D* )withVertices vertexCount:( int32 )vertexCount location:(Vector2D)location {
    PolygonObject* polygonObject = new PolygonObject(world, (b2Vec2*)withVertices, vertexCount, b2Vec2(location.x, location.y));
    return polygonObject;
}
+ (Vector2D)getPolygonPosition:(void *)polygonRef {
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((PolygonObject*)polygonRef)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

+ (float) getPolygonRotation:(void *)polygonRef {
    return ((PolygonObject *)polygonRef)->GetRotation();
}

+ (void) setPolygonVelocity:(void *)polygonRef velocity:(Vector2D)velocity {
    ((PolygonObject *)polygonRef)->SetVelocity(b2Vec2(velocity.x, velocity.y));
}

//move a particle system

+ (void) moveParticleSystem:(void *)particleSys byVelocity:(Vector2D)byVelocity {
    b2ParticleSystem* system = ((b2ParticleSystem *)particleSys);
    int particleCount = system->GetParticleCount();
    b2Vec2* vBuffer = system->GetVelocityBuffer();
    b2Vec2 velocityChange = b2Vec2(byVelocity.x, byVelocity.y);
    
    for( int i = 0; i < particleCount; i++ ) {
        vBuffer[i] += velocityChange;
    }
}

// Reservoir Class

+ (void *) makeReservoir:(void *)particleSysRef
                location:(Vector2D)location
                vertices:(void *) vertices vertexCount:(UInt32)vertexCount {
    Reservoir* newReservoir = new Reservoir(world,
                             (b2ParticleSystem*) particleSysRef,
                             b2Vec2(location.x,location.y),
                             (b2Vec2*)vertices, (unsigned int)vertexCount);
    reservoirs.push_back(newReservoir);
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

+ (Vector2D)getReservoirPosition:(void *)reservoir {
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((Reservoir*)reservoir)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

+ (float)getReservoirRotation:(void *)reservoir{
    return ((Reservoir *)reservoir)->GetRotation();
}

+ (void)createBulbOnReservoir:(void *)reservoir hemisphereSegments:(long)hemisphereSegments radius:(float)radius {
    ((Reservoir *)reservoir)->CreateBulb(hemisphereSegments, radius);
}

+ (Vector2D)getBulbPos:(void *)reservoir {
    Vector2D sharedPos;
    b2Vec2 pos = ((Reservoir *)reservoir)->GetBulbPosition();
    sharedPos.x = pos.x;
    sharedPos.y = pos.y;
    return sharedPos;
}

+ (Vector2D)getSegmentPos:(void *)reservoir atIndex:(long)atIndex {
    b2Vec2 pos = ((Reservoir *)reservoir)->GetBulbSegmentPosition(atIndex);
    Vector2D sharedPos;
    sharedPos.x = pos.x;
    sharedPos.y = pos.y;
    return sharedPos;
}

+ (void) setVelocity:(void *)ofReservoir velocity:(b2Vec2)velocity{
    ((Reservoir *)ofReservoir)->SetVelocity(velocity);
}

+ (Vector2D) getVelocity:(void *)ofReservoir {
    Vector2D sharedVelocity;
    b2Vec2 velocity = ((Reservoir *)ofReservoir)->GetVelocity();
    sharedVelocity.x = velocity.x;
    sharedVelocity.y = velocity.y;
    return sharedVelocity;
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
// pipe fixture creation / destruction
+ (void *)makePipeFixture:(void*)onReservoir lineVertices:(b2Vec2 *)lineVertices vertexCount:(long)vertexCount {
    return ((Reservoir *)onReservoir)->MakeLineFixture(lineVertices, vertexCount);
}
+ (void) destroyPipeFixture:(void*)onReservoir lineRef:(void *)lineRef {
    ((Reservoir *)onReservoir)->DestroyLineFixture( lineRef );
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
    ((b2Fixture*)fixtureRef)->SetFilterData( ((b2ParticleSystem *)particleSystem)->filter );
}

@end


