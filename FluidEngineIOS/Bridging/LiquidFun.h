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
+ (void *)createFlaggedParticleSystem:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density flagBuffer:(UInt32*)flagBuffer flagCount:(int)flagCount;

//particle creation
+ (void)createParticleBoxForSystem:(void *)particleSystem position:(Vector2D)position size:(Size2D)size color:(void *)color;
+ (void)createParticleBallForSystem:(void *)particleSystem position:(Vector2D)position velocity:(Vector2D)velocity angV:(float)angV radius:(float)radius color:(void *)color;
    
+ (int)particleCountForSystem:(void *)particleSystem;
+ (void *)particlePositionsForSystem:(void *)particleSystem;
+ (void)emptyParticleSystem:(void *)particleSystem minTime:(float)minTime maxTime:(float)maxTime;
+ (void) destroyParticleSystem:(void *)particleSystem;
//colors
+ (void *)colorBufferForSystem:(void *)particleSystem;
+(void)updateColors:(void *)particleSystem colors:(void *)color yLevels:(float *)yLevels numLevels:(int)numLevels;

+ (void *)createEdgeBoxWithOrigin:(Vector2D)origin size:(Size2D)size;
+ (void)setGravity:(Vector2D)gravity;
+ (void)setParticleLimitForSystem:(void *)particleSystem maxParticles:(int)maxParticles;
+ (void)destroyWorld;

+ (void *)getVec2:(void *)vertices vertexCount:(UInt32) size;
+ (void *)createGroundBoxWithOrigin:(Vector2D)origin size:(Size2D)size;
+ (void *)b2BoundingBoxFromScreen:(Vector2D)bottomLeftCorner topRightCorner:(Vector2D)topRightCorner;
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
+ (void)destroyParticlesInSystem:(void *)particleSystem; // destroy all particle groups in system
+ (int)deleteParticlesInParticleSystem:(void *)particleSystem aboveYPosition:(float)aboveYPosition;
+ (int)deleteBelowInParticleSystem:(void *)particleSystem belowYPosition:(float)belowYPosition;

// for managing transferring particles leaving to new tubes
+ (int)leavingParticleSystem:(void *)particleSystem newSystem:(void *)newSystem a:(Vector2D)a b:(Vector2D)b isLeft:(bool)isLeft;
+ (int)deleteParticlesOutside:(void *)particleSystem width:(float)width height:(float)height rotation:(float)rotation position:(Vector2D)position;
+ (int)engulfParticles:(void *)inTube originalParticleSystem:(void *)originalParticleSystem;

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
//+ (void *)makeJointTest:(Vector2D)location
//            box1Vertices:(void *)box1Vertices box1Count:(UInt32)box1Count
//         box2Vertices:(void *)box2Vertices box2Count:(UInt32)box2Count;

+ (void *)makeTube:(void *)particleSysRef
          location:(Vector2D)location
          vertices:(void *)vertices
          vertexCount:(UInt32)vertexCount
          tubeWidth:(Float32)tubeWidth
          tubeHeight:(Float32)tubeHeight
          gridId:(long)gridId;

+ (void)destroyTube:(void *)tubeRef;
//hover candidate
+ (long)hoverCandidate:(void *)tube;

//pour guides
+ (void)addGuides:(void *)tube vertices:(void *)vertices;
+ (void)removeGuides:(void *)tube;

// add divider
+ (void *)addDivider:(void *)tube vertices:(void *)vertices;
+ (void)removeDivider:(void *)tube divider:(void *)divider;
//freezing is managed internally in Tube together with the contact listener.
//movement and rotation
+ (void)setTubeVelocity:(void *)tube velocity:(Vector2D)velocity;
// rotation
+ (void)setAngularVelocity:(void *)ofTube angularVelocity:(float)angularVelocity;

+ (Vector2D)getTubePosition:(void *)tube;
+ (void *)getTubeAtPosition:(Vector2D)position;

+ (float)getTubeRotation:(void *)tube;

+ (Vector2D)getTubeVelocity:(void *)tube;

//pour filter bits
+ (void) SetPourBits:(void *)ofTube;
+ (void) ClearPourBits:(void *)ofTube;
+ (void) beginEmpty:(void *)tube;

// box button
+ (void *) makeBoxButton:( Vector2D* )withVertices location:(Vector2D)location;
+ (bool) boxIsAtPosition:( Vector2D )boxPosition boxRef:(void *)boxRef;

//box button states
+ (Vector2D) getBoxButtonPosition:(void *)boxRef;
+ (float) getBoxButtonRotation:(void *)boxRef;
+ (void) updateBoxButton:(void *)boxRef;
+ (void) freezeButton:(void *)boxRef;
+ (void) unFreezeButton:(void *)boxRef;


//custom polygons
+ (void *)makePolygon:( Vector2D* )withVertices vertexCount:( int )vertexCount location:(Vector2D)location;
+ (Vector2D)getPolygonPosition:(void *)polygonRef;
+ (float) getPolygonRotation:(void *)polygonRef;
+ (void) setPolygonVelocity:(void *)polygonRef velocity:(Vector2D)velocity;


+ (void) moveParticleSystem:(void *)particleSys byVelocity:(Vector2D)byVelocity;

//Reservoir Class
+ (void *) makeReservoir:(void *)particleSysRef
                location:(Vector2D)location
                vertices:(void *) vertices vertexCount:(UInt32)vertexCount;
+ (void) destroyReservoir:(void *)reservoir;

+ (Vector2D)getReservoirPosition:(void *)reservoir;
+ (float)getReservoirRotation:(void *)reservoir;
+ (float)createBulbOnReservoir:(void *)reservoir  hemisphereSegments:(long)hemisphereSegments radius:(float)radius;

+ (Vector2D)getBulbPos:(void *)reservoir;
+ (Vector2D)getSegmentPos:(void *)reservoir atIndex:(long)atIndex;

+ (void) setVelocity:(void *)ofReservoir velocity:(Vector2D)velocity;
+ (Vector2D) getVelocity:(void *)ofReservoir;

+ (void) setBulbWallAngV:(void *)ofReservoir atIndex:(long)atIndex angV:(float)angV;
+ (float) getBulbWallAngle:(void *)ofReservoir atIndex:(long)atIndex;

+ (void*) getWallBody:(void *)onReservoir atIndex:(long)atIndex;

// TK Splines 2D
+ (void *)makeSpline:(float *)tControlPoints withControlPoints:(Vector2D *)withControlPoints controlPtsCount:(long)controlPtsCount;
+ (void) setInterpolatedValues:(void *)usingSpline tVals:(float *)tVals onXVals:(float *)onXVals onYVals:(float *)onYVals onTangents:(Vector2D *)onTangents valCount:(long)valCount;
// 1D Spline
+ (void *)make1DSpline:(float *)xControlPoints yControlPoints:(float *)yControlPoints controlPtsCount:(long)controlPtsCount; // returns spline class
+ (void) set1DInterpolatedValues:(void *)using1DSpline xVals:(float *)xVals onYVals:(float *)onYVals onSlopes:(float *)onSlopes valCount:(long)valCount; 

// pipe fixture creation / destruction
+ (void *)makePipeFixture:(void*)onReservoir lineVertices:(Vector2D *)lineVertices vertexCount:(long)vertexCount;
+ (void *)destroyPipeFixture:(void*)onReservoir lineRef:(void *)lineRef;

//reservoir particle transfers
+ (long) transferParticles:(void *)fromReservoir wallSegmentPosition:(Vector2D)wallPos toSystem:(void *)toSystem;

// wall body rotations
+ (void)setWallAngV:(void*)onReservoir wallBodyRef:(void *)wallBodyRef angV:(float)angV;
+ (float)getWallAngle:(void*)onReservoir wallBodyRef:(void *)wallBodyRef;

// just setting fixture filters
+ (void)shareParticleSystemFilterWithFixture:(void*)fixtureRef particleSystem:(void *)particleSystem;
+ (void)setDefaultFilterForFixture:(void *)fixtureRef;

// Alien class
+ (void *)makeAlien:(Vector2D)position vertices:(Vector2D*)vertices vertexCount:(long)vertexCount density:(float)density health:(float)health crashDamage:(float)crashDamage categoryBits:(UInt32)categoryBits maskBits:(UInt16)maskBits groupIndex:(int16_t)groupIndex;
+ (Vector2D)getAlienPosition:(void *)alienRef;
+ (float) getAlienRotation:(void *)alienRef;
+ (void) setAlienVelocity:(void *)alienRef velocity:(Vector2D)velocity;
// Friendly class
+ (void *)makeFriendly:(Vector2D)position vertices:(Vector2D*)vertices vertexCount:(long)vertexCount density:(float)density health:(float)health crashDamage:(float)crashDamage categoryBits:(UInt32)categoryBits maskBits:(UInt16)maskBits groupIndex:(int16_t)groupIndex;
+ (Vector2D)getFriendlyPosition:(void *)friendlyRef;
+ (float) getFriendlyRotation:(void *)friendlyRef;
+ (void) setFriendlyVelocity:(void *)friendlyRef velocity:(Vector2D)velocity;
@end

