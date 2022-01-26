#import "LiquidFun.h"
#import "Box2D.h"
#import "Tube.h"
#import "CustomContactListener.h"
#import "JointTest.h"

static b2World *world;
MyContactListener contactListener;

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
    world->SetContactListener(&contactListener);
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
    
    particleSystem->SetFlagsBuffer(flagBuffer, flagCount);
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
    particleGroupDef.flags = b2_waterParticle;
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
    newGroupDef.flags = b2_waterParticle;
    
    ((b2ParticleSystem *)newSystem)->CreateParticleGroup(newGroupDef);
    return newPositionsCount;
}
+ (int)leavingTube:(void *)particleSystem newSystem:(void *)newSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position {
    b2ParticleGroupDef newGroupDef;
   
//    b2BodyDef bodyDef;        // for seeing the box as a debug square
//    bodyDef.position.Set(position.x, position.y);
//    b2Body *body = world->CreateBody(&bodyDef);
    b2PolygonShape hitBox;
    hitBox.SetAsBox(width , height);
    b2Transform boxTransform;
    boxTransform.Set( b2Vec2( position.x, position.y), rotation);
//    b2FixtureDef boxDef;
//    boxDef.shape = &hitBox;
//    body->SetActive(false);
//    body->CreateFixture(&boxDef);
    
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    b2Vec2* velocityBuffer = ((b2ParticleSystem *)particleSystem)->GetVelocityBuffer();
    int newPositionsCount = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( !( hitBox.TestPoint(boxTransform, c  ) ) ) {
            newPositionsCount++;
        }
    }
    b2Vec2 newPositions[newPositionsCount];
    int newPositionIndex = 0;
    float avVelocityX = 0.0;
    float avVelocityY = 0.0;
    
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if( ! ( hitBox.TestPoint(boxTransform, c )) ) {
            newPositions[newPositionIndex] = positionBuffer[i];
            avVelocityX += velocityBuffer[newPositionIndex].x;
            avVelocityY += velocityBuffer[newPositionIndex].y;
            newPositionIndex++;
            ((b2ParticleSystem *)particleSystem)->DestroyParticle(i, false);
        }
    }
    avVelocityX = avVelocityX / float(newPositionsCount);
    avVelocityY = avVelocityY / float(newPositionsCount);
    newGroupDef.positionData = newPositions;
    newGroupDef.linearVelocity = b2Vec2(avVelocityX, avVelocityY);
    newGroupDef.particleCount = newPositionsCount;
    newGroupDef.flags = b2_waterParticle;
    
    ((b2ParticleSystem *)newSystem)->CreateParticleGroup(newGroupDef);
    return newPositionsCount;
}
+ (int)backwashingTube:(void *)particleSystem backSystem:(void *)newSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position color:(void *)color {
    b2ParticleGroupDef newGroupDef;
   
    b2PolygonShape hitBox;
    hitBox.SetAsBox(width , height);
    b2Transform boxTransform;
    boxTransform.Set( b2Vec2( position.x, position.y), rotation);

    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    b2Vec2* velocityBuffer = ((b2ParticleSystem *)particleSystem)->GetVelocityBuffer();
    int newPositionsCount = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        b2Vec2 c = positionBuffer[i];
        if(  hitBox.TestPoint(boxTransform, c  ) ) {   
            newPositionsCount++;
        }
    }
    b2Vec2 newPositions[newPositionsCount];
    int newPositionIndex = 0;
    float avVelocityX = 0.0;
    float avVelocityY = 0.0;
    
    for(int i = 0; i<oldPositionsCount; i++) {  // transfer if inside
        b2Vec2 c = positionBuffer[i];
        if(  hitBox.TestPoint(boxTransform, c ) ) {
            newPositions[newPositionIndex] = positionBuffer[i];
            avVelocityX += velocityBuffer[newPositionIndex].x;
            avVelocityY += velocityBuffer[newPositionIndex].y;
            newPositionIndex++;
            ((b2ParticleSystem *)particleSystem)->DestroyParticle(i, false);
        }
    }
    avVelocityX = avVelocityX / float(newPositionsCount);
    avVelocityY = avVelocityY / float(newPositionsCount);
    newGroupDef.positionData = newPositions;
    newGroupDef.linearVelocity = b2Vec2(avVelocityX, avVelocityY);
    newGroupDef.particleCount = newPositionsCount;
    b2ParticleColor pColor;
    Color* inColor = (Color*)color;
    pColor.Set(uint8( inColor->r * 255 ), uint8(inColor->g * 255), uint8(inColor->b * 255), uint8( inColor->a * 255 ));
    newGroupDef.color = pColor;
    newGroupDef.flags = b2_waterParticle;
    
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
+ (void)transferTopMostGroupInParticleSystem:(void *)particleSystem newSystem:(void *)newSystem color:(void *)color aboveYPosition:(float)aboveYPosition {
    b2ParticleGroupDef newGroupDef;
  
    b2Vec2* positionBuffer = ((b2ParticleSystem *)particleSystem)->GetPositionBuffer();
    int oldPositionsCount = ((b2ParticleSystem *)particleSystem)->GetParticleCount();
    int newPositionsCount = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        if(positionBuffer[i].y > aboveYPosition) {
            newPositionsCount++;
        }
    }
    b2Vec2 newPositions[newPositionsCount];
    int newPositionIndex = 0;
    for(int i = 0; i<oldPositionsCount; i++) {
        if(positionBuffer[i].y > aboveYPosition) {
            newPositions[newPositionIndex] = positionBuffer[i];
            newPositionIndex++;
            ((b2ParticleSystem *)particleSystem)->DestroyParticle(i, false);
        }
    }
    newGroupDef.positionData = newPositions;
    newGroupDef.particleCount = newPositionsCount;
    newGroupDef.flags = b2_waterParticle;

    b2ParticleColor pColor;
    Color* inColor = (Color*)color;
    pColor.Set(uint8( inColor->r * 255 ), uint8(inColor->g * 255), uint8(inColor->b * 255), uint8( inColor->a * 255 ));
    newGroupDef.color = pColor;
    b2ParticleGroup* oldGroup = ((b2ParticleSystem *)newSystem)->GetParticleGroupList();
    ((b2ParticleSystem *)newSystem)->CreateParticleGroup(newGroupDef);
    b2ParticleGroup* newGroup = ((b2ParticleSystem *)newSystem)->GetParticleGroupList();
    if(oldGroup) { //merge if there was a group there before at the top.
        ((b2ParticleSystem *)newSystem)->JoinParticleGroups(oldGroup,newGroup);
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
    for(int i = 0; i < tubes.size(); i++) {
        tubes[i]->PostSolve();
    }
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
//  delete world;
//  world = NULL;
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

//joint tests
+ (void *)makeJointTest:(Vector2D)location
            box1Vertices:(void *)box1Vertices box1Count:(UInt32)box1Count
            box2Vertices:(void *)box2Vertices box2Count:(UInt32)box2Count {
    return new JointTest(world, b2Vec2(location.x,location.y),
                  (b2Vec2*)box1Vertices, (unsigned int)box1Count,
                  (b2Vec2*)box2Vertices, (unsigned int)box2Count);
}
+ (void)moveJointTest:(void *)jointTest velocity:(Vector2D)velocity {
    ((JointTest *)jointTest)->Move(b2Vec2(velocity.x,velocity.y));
}
// Tube class refactor
+ (void *)makeTube:(void *)particleSysRef
          location:(Vector2D)location
          vertices:(void *) vertices vertexCount:(UInt32)vertexCount
          hitBoxVertices:(void *)hitBoxVertices hitBoxCount:(UInt32)hitBoxCount
          sensorVertices:(void *)sensorVertices sensorCount:(UInt32)sensorCount
          gridId:(int)gridId {
    Tube* newTube = new Tube(world,
                             (b2ParticleSystem*) particleSysRef,
                             b2Vec2(location.x,location.y),
                             (b2Vec2*)vertices, (unsigned int)vertexCount,
                             (b2Vec2*)hitBoxVertices, (unsigned int)hitBoxCount,
                             (b2Vec2*)sensorVertices, (unsigned int)sensorCount,
                             gridId);
    tubes.push_back(newTube);
    return newTube;
}
//hover candidate testing
+ (int)hoverCandidate:(void *)tube {
    return ((Tube *)tube)->GetHoverCandidateGridId();
}
//collision
+ (bool)isColliding:(void *)tube {
    return ((Tube *)tube)->isFrozen;
}
//pour Guides
+ (void)addGuides:(void *)tube vertices:(void *)vertices {
    ((Tube *)tube)->AddGuides((b2Vec2 *) vertices);
}
+ (void)removeGuides:(void *)tube {
    ((Tube *)tube)->RemoveGuides();
}
// top cap management
+ (void)capTop:(void *)tube vertices:(void *)vertices {
    ((Tube *)tube)->CapTop((b2Vec2 *) vertices);
}
+ (void)popCap:(void *)tube {
    ((Tube *)tube)->PopCap();
}
//collision heirarchy
+ (void)PickUp:(void *)tube {
    ((Tube *)tube)->StartPickup();
}
+ (void)Drop:(void *)tube {
    ((Tube *)tube)->EndPickup();
}
+ (void)StartReturnTube:(void *)tube {
    ((Tube *)tube)->StartReturn();
}
+ (void)RestTube:(void *)tube {
    ((Tube *)tube)->EndReturn();
}

+(void)PourTube:(void *)tube {
    ((Tube *)tube)->pouring = true;
}
+(void)EndPourTube:(void *)tube {
    ((Tube *)tube)->pouring = false;
}
// freezing
//+ (void)freezeTube:(void *)tube {
//    ((Tube *) tube)->Freeze();
//}
//+ (void)unFreezeTube:(void *)tube {
//   ((Tube *) tube)->UnFreeze();
//}
//movement and rotation
+ (void)moveTube:(void *)tube pushDirection:(Vector2D)pushDirection {
    ((Tube *) tube)->Move(b2Vec2(pushDirection.x,pushDirection.y));
}
// rotation
+ (void)rotateTube:(void *)tube amount:(float)amount{
    ((Tube *) tube)->Rotate(amount);
}

+ (Vector2D)getTubePosition:(void *)tube {
    Vector2D sharedPosition;
    b2Vec2 b2Pos = ((Tube*)tube)->GetPosition();
    sharedPosition.x = b2Pos.x;
    sharedPosition.y = b2Pos.y;
    return sharedPosition;
}

+ (float)getTubeRotation:(void *)tube{
    return ((Tube *)tube)->GetRotation();
}

@end


