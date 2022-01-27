#import <Foundation/Foundation.h>
#ifndef LiquidFun_Definitions
#define LiquidFun_Definitions

typedef struct Vector2D {
  float x;
  float y;
} Vector2D;

typedef struct Size2D {
  float width;
  float height;
} Size2D;

typedef struct Color {
    float r;
    float g;
    float b;
    float a;
} Color;

typedef struct VertexIn {
    Vector2D position;
    Color    color;
} VertexIn;

#endif

@interface LiquidFun : NSObject

//draw access
+ (int)getPointsDrawCount;
+ (void *)getPointsPositions;
+ (void *)getPointsColors;

+ (void *)getLinesVertices;
+ (int)getLinesDrawCount;

+ (void *)getTrianglesVertices;
+ (int)getTrianglesDrawCount;

// world access
+ (void)worldStep:(CFTimeInterval)timeStep velocityIterations:(int)velocityIterations positionIterations:(int)positionIterations;
+ (void)destroyBody:(void *)bodyRef;


+ (void)createWorldWithGravity:(Vector2D)gravity;
//particle system access
+ (void *)createParticleSystemWithRadius:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density;
+ (void)createParticleBoxForSystem:(void *)particleSystem position:(Vector2D)position size:(Size2D)size color:(void *)color;
+ (int)particleCountForSystem:(void *)particleSystem;
+ (void *)particlePositionsForSystem:(void *)particleSystem;
+ (void)emptyParticleSystem:(void *)particleSystem minTime:(float)minTime maxTime:(float)maxTime;

//colors
+ (void *)colorBufferForSystem:(void *)particleSystem;
+(void)updateColors:(void *)particleSystem colors:(void *)color yLevels:(float *)yLevels numLevels:(int)numLevels;


+ (void *)createEdgeBoxWithOrigin:(Vector2D)origin size:(Size2D)size;
+ (void)setGravity:(Vector2D)gravity;
+ (void)setParticleLimitForSystem:(void *)particleSystem maxParticles:(int)maxParticles;
+ (void)destroyWorld;

+ (void *)getVec2:(void *)vertices vertexCount:(UInt32) size;
+ (void *)createGroundBoxWithOrigin:(Vector2D)origin size:(Size2D)size;
//freezing
+ (void)pauseParticleSystem:(void *)particleSystem;
+ (void)resumeParticleSystem:(void *)particleSystem;
+ (bool)getIsActiveForSystem:(void *)particleSystem;
+ (void)pauseBody:(void *)bodyReference;
+ (void)resumeBody:(void *)bodyReference;
+ (bool)getIsActiveForBody:(void *)bodyReference;

// segmenting
+ (void *)makeLineFixtureOnBody:(void *)bodyRef vertices:(void *)vertices; //2 only
+ (void)removeFixtureOnBody:(void *)bodyRef fixtureRef:(void *)fixtureRef;
+ (void)transferTopMostGroupInParticleSystem:(void *)particleSystem newSystem:(void *)newSystem color:(void *)color aboveYPosition:(float)aboveYPosition;
+ (void)destroyParticlesInSystem:(void *)particleSystem; // destroy all particle groups in system
+ (int)deleteParticlesInParticleSystem:(void *)particleSystem aboveYPosition:(float)aboveYPosition;
+ (int)deleteBelowInParticleSystem:(void *)particleSystem belowYPosition:(float)belowYPosition;

// for managing transferring particles leaving to new tubes
+ (int)leavingParticleSystem:(void *)particleSystem newSystem:(void *)newSystem a:(Vector2D)a b:(Vector2D)b isLeft:(bool)isLeft;
+ (int)leavingTube:(void *)particleSystem newSystem:(void *)newSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position;
+ (int)backwashingTube:(void *)particleSystem backSystem:(void *)backSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position color:(void *)color;
+ (int)deleteParticlesOutside:(void *)particleSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position;
// movement and rotation
+ (void)pushBody:(void *)bodyRef pushVector:(Vector2D)pushVector atPoint:(Vector2D)atPoint awake:(bool)awake;
+ (void)moveKinematic:(void *)kinematicRef pushDirection:(Vector2D)pushDirection;
+ (void)dampMovementOfBody:(void *)kinematicRef amount:(float)amount;

+ (void)rotateBody:(void *)bodyRef amount:(float)amount;
+ (void)dampRotationOfBody:(void *)bodyRef amount:(float)amount;
+ (void)torqueBody:(void *)bodyRef amount:(float)amount awake:(bool)awake;
+ (float)getRotationOfBody:(void *)bodyRef;
//positioning tubes
+ (Vector2D)getPositionOfbody:(void *)bodyRef;
//contacts
+ (void *)bodyInContactWith:(void *)bodyRef;



// Tube class refactor

// joint test
+ (void *)makeJointTest:(Vector2D)location
            box1Vertices:(void *)box1Vertices box1Count:(UInt32)box1Count
         box2Vertices:(void *)box2Vertices box2Count:(UInt32)box2Count;
+ (void)moveJointTest:(void *)jointTest velocity:(Vector2D)velocity;

+ (void *)makeTube:(void *)particleSysRef
          location:(Vector2D)location
          vertices:(void *)vertices vertexCount:(UInt32)vertexCount
          hitBoxVertices:(void *)hitBoxVertices hitBoxCount:(UInt32)hitBoxCount
          sensorVertices:(void *)sensorVertices sensorCount:(UInt32)sensorCount
          row:(int)row
          col:(int)col
          gridId:(int)gridId;
+ (void)destroyTube:(void *)tube;
//hover candidate
+ (int)hoverCandidate:(void *)tube;
//collision
+ (bool)isColliding:(void *)tube; // dont need anymore
//collision heirarchy
+ (void)YieldToFill:(void *)tube;
+ (void)UnYieldToFill:(void *)tube;
+ (void)PickUp:(void *)tube;
+ (void)Drop:(void *)tube;
+ (void)StartReturnTube:(void *)tube;
+ (void)RestTube:(void *)tube;
+(void)PourTube:(void *)tube;
+(void)EndPourTube:(void *)tube;
//pour guides
+ (void)addGuides:(void *)tube vertices:(void *)vertices;
+ (void)removeGuides:(void *)tube;
// cap management
+ (void)capTop:(void *)tube vertices:(Vector2D *)vertices;
+ (void)popCap:(void *)tube;
    //freezing is managed internally in Tube together with the contact listener.
//movement and rotation
+ (void)moveTube:(void *)tube pushDirection:(Vector2D)pushDirection;
// rotation
+ (void)rotateTube:(void *)tube amount:(float)amount;

+ (Vector2D)getTubePosition:(void *)tube;

+ (float)getTubeRotation:(void *)tube;

@end
