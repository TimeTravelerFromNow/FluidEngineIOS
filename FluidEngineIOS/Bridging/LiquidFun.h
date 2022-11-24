#import <Foundation/Foundation.h>
#include <simd/simd.h>
#ifndef LiquidFun_Definitions
#define LiquidFun_Definitions

typedef simd_float2 float2;
typedef simd_float3 float3; // float3 is format of b2Color ( which is a struct )
typedef simd_float4 float4;
// simd_uint8_3 is format of b2ParticleColor (Cannot refactor all particle code to use the same format (since it is a class)).

typedef struct BoxFilter
{
    UInt16 categoryBits;
    UInt16 maskBits;
    UInt16 groupIndex;
    
    bool isFiltering; // implemented to allow phasing objects
} BoxFilter;

BoxFilter BoxFilterInit() {
    BoxFilter filter;
    filter.categoryBits = 0x0001;
    filter.maskBits = 0xFFFF;
    filter.groupIndex = 0;
    filter.isFiltering = false;
    return filter;
}

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


+ (void)createWorldWithGravity:(float2)gravity;
//particle system access
+ (void *)createParticleSystemWithRadius:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density;
+ (void *)createFlaggedParticleSystem:(float)radius dampingStrength:(float)dampingStrength gravityScale:(float)gravityScale density:(float)density flagBuffer:(UInt32*)flagBuffer flagCount:(int)flagCount;

//particle creation
+ (void)createParticleBoxForSystem:(void *)particleSystem position:(float2)position size:(float2)size color:(float3)color;
+ (void)createParticleBallForSystem:(void *)particleSystem position:(float2)position velocity:(float2)velocity angV:(float)angV radius:(float)radius color:(float3)color;
    
+ (int)particleCountForSystem:(void *)particleSystem;
+ (void *)particlePositionsForSystem:(void *)particleSystem;
+ (void)emptyParticleSystem:(void *)particleSystem minTime:(float)minTime maxTime:(float)maxTime;
+ (void) destroyParticleSystem:(void *)particleSystem;
//colors
+ (void *)colorBufferForSystem:(void *)particleSystem;
+(void)updateColors:(void *)particleSystem colors:(float3 *)color yLevels:(float *)yLevels numLevels:(int)numLevels;

+ (void *)createEdgeBoxWithOrigin:(float2)origin size:(float2)size;
+ (void)setGravity:(float2)gravity;
+ (void)setParticleLimitForSystem:(void *)particleSystem maxParticles:(int)maxParticles;
+ (void)destroyWorld;

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
+ (int)leavingParticleSystem:(void *)particleSystem newSystem:(void *)newSystem a:(float2)a b:(float2)b isLeft:(bool)isLeft;
+ (int)deleteParticlesOutside:(void *)particleSystem width:(float)width height:(float)height rotation:(float)rotation position:(float2)position;
+ (int)engulfParticles:(void *)inTube originalParticleSystem:(void *)originalParticleSystem;

// movement and rotation
+ (void)pushBody:(void *)bodyRef pushVector:(float2)pushVector atPoint:(float2)atPoint awake:(bool)awake;
+ (void)moveKinematic:(void *)kinematicRef pushDirection:(float2)pushDirection;
+ (void)dampMovementOfBody:(void *)kinematicRef amount:(float)amount;

+ (void)rotateBody:(void *)bodyRef amount:(float)amount;
+ (void)dampRotationOfBody:(void *)bodyRef amount:(float)amount;
+ (void)torqueBody:(void *)bodyRef amount:(float)amount awake:(bool)awake;
+ (float)getRotationOfBody:(void *)bodyRef;
//positioning tubes
+ (float2)getPositionOfbody:(void *)bodyRef;
//contacts
+ (void *)bodyInContactWith:(void *)bodyRef;

// Tube class refactor

// joint test
//+ (void *)makeJointTest:(float2)location
//            box1Vertices:(void *)box1Vertices box1Count:(UInt32)box1Count
//         box2Vertices:(void *)box2Vertices box2Count:(UInt32)box2Count;

+ (void *)makeTube:(void *)particleSysRef
          location:(float2)location
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
+ (void)setTubeVelocity:(void *)tube velocity:(float2)velocity;
// rotation
+ (void)setAngularVelocity:(void *)ofTube angularVelocity:(float)angularVelocity;

+ (float2)getTubePosition:(void *)tube;
+ (void *)getTubeAtPosition:(float2)position;

+ (float)getTubeRotation:(void *)tube;

+ (float2)getTubeVelocity:(void *)tube;

//pour filter bits
+ (void) SetPourBits:(void *)ofTube;
+ (void) ClearPourBits:(void *)ofTube;
+ (void) beginEmpty:(void *)tube;

// box button
+ (void *) makeBoxButton:( float2* )withVertices location:(float2)location;
+ (bool) boxIsAtPosition:( float2 )boxPosition boxRef:(void *)boxRef;

//box button states
+ (float2) getBoxButtonPosition:(void *)boxRef;
+ (float) getBoxButtonRotation:(void *)boxRef;
+ (void) updateBoxButton:(void *)boxRef;
+ (void) freezeButton:(void *)boxRef;
+ (void) unFreezeButton:(void *)boxRef;


//custom polygons
+ (void *)makePolygon:( float2* )withVertices vertexCount:( int )vertexCount location:(float2)location  asStaticChain:(bool)asStaticChain;
+ (float2)getPolygonPosition:(void *)polygonRef;
+ (float) getPolygonRotation:(void *)polygonRef;
+ (void) setPolygonVelocity:(void *)polygonRef velocity:(float2)velocity;


+ (void) moveParticleSystem:(void *)particleSys byVelocity:(float2)byVelocity;

//Reservoir Class
+ (void *) makeReservoir:(void *)particleSysRef
                location:(float2)location
                vertices:(void *) vertices vertexCount:(UInt32)vertexCount;
+ (void) destroyReservoir:(void *)reservoir;

+ (float2)getReservoirPosition:(void *)reservoir;
+ (float)getReservoirRotation:(void *)reservoir;
+ (float)createBulbOnReservoir:(void *)reservoir  hemisphereSegments:(long)hemisphereSegments radius:(float)radius;

+ (float2)getBulbPos:(void *)reservoir;
+ (float2)getSegmentPos:(void *)reservoir atIndex:(long)atIndex;

+ (void) setVelocity:(void *)ofReservoir velocity:(float2)velocity;
+ (float2) getVelocity:(void *)ofReservoir;

+ (void) setBulbWallAngV:(void *)ofReservoir atIndex:(long)atIndex angV:(float)angV;
+ (float) getBulbWallAngle:(void *)ofReservoir atIndex:(long)atIndex;

+ (void*) getWallBody:(void *)onReservoir atIndex:(long)atIndex;

// TK Splines 2D
+ (void *)makeSpline:(float *)tControlPoints withControlPoints:(float2 *)withControlPoints controlPtsCount:(long)controlPtsCount;
+ (void) setInterpolatedValues:(void *)usingSpline tVals:(float *)tVals onXVals:(float *)onXVals onYVals:(float *)onYVals onTangents:(float2 *)onTangents valCount:(long)valCount;
// 1D Spline
+ (void *)make1DSpline:(float *)xControlPoints yControlPoints:(float *)yControlPoints controlPtsCount:(long)controlPtsCount; // returns spline class
+ (void) set1DInterpolatedValues:(void *)using1DSpline xVals:(float *)xVals onYVals:(float *)onYVals onSlopes:(float *)onSlopes valCount:(long)valCount; 

// pipe fixture creation / destruction
+ (void *)makePipeFixture:(void*)onReservoir lineVertices:(float2 *)lineVertices vertexCount:(long)vertexCount;
+ (void *)destroyPipeFixture:(void*)onReservoir lineRef:(void *)lineRef;

//reservoir particle transfers
+ (long) transferParticles:(void *)fromReservoir wallSegmentPosition:(float2)wallPos toSystem:(void *)toSystem;

// wall body rotations
+ (void)setWallAngV:(void*)onReservoir wallBodyRef:(void *)wallBodyRef angV:(float)angV;
+ (float)getWallAngle:(void*)onReservoir wallBodyRef:(void *)wallBodyRef;

// just setting fixture filters
+ (void)shareParticleSystemFilterWithFixture:(void*)fixtureRef particleSystem:(void *)particleSystem;
+ (void)setDefaultFilterForFixture:(void *)fixtureRef;

// Friendly class
+ (void *)makeFriendly:(float2)position velocity:(float2)velocity startAngle:(float)startAngle density:(float)density restitution:(float)restition health:(float)health crashDamage:(float)crashDamage categoryBits:(UInt32)categoryBits maskBits:(UInt16)maskBits groupIndex:(int16_t)groupIndex;
+ (void)destroyFriendly:(void *)friendlyRef;
+ (void)setFriendlyPolygon:(void *)friendlyRef vertices:(float2*)vertices vertexCount:(long)vertexCount;
+ (void)setFriendlyCircle:(void *)friendlyRef radius:(float)radius;
+ (void)addFriendlyCircle:(void *)friendlyRef radius:(float)radius;
    
+ (void)setFriendlyFixedRotation:(void*)friendlyRef to:(bool)to;
+ (void)impulseFriendly:(void*)friendlyRef imp:(float2)imp atPt:(float2)atPt;
+ (void)torqueFriendly:(void*)friendlyRef amt:(float)amt;
+ (float) getFriendlyHealth:(void *)friendlyRef;

+ (float2)getFriendlyPosition:(void *)friendlyRef;
+ (float) getFriendlyRotation:(void *)friendlyRef;
+ (float) getFriendlyAngV:(void *)friendlyRef;
+ (float2) getFriendlyVel:(void *)friendlyRef;

+ (void) setFriendlyVelocity:(void *)friendlyRef velocity:(float2)velocity;
+ (void) setFriendlyAngularVelocity:(void *)friendlyRef angV:(float)angV;
+ (void) weldJointFriendlies:(void *)friendly0 friendly1:(void *)friendly1 weldPos:(float2)weldPos stiffness:(float)stiffness;
+ (void) wheelJointFriendlies:(void *)friendlyA friendlyB:(void *)friendlyB jointPos:(float2)jointPos stiffness:(float)stiffness damping:(float)damping;
@end

