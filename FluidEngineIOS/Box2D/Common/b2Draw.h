/*
* Copyright (c) 2011 Erin Catto http://box2d.org
* Copyright (c) 2014 Google, Inc.
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/

#ifndef B2_DRAW_H
#define B2_DRAW_H

#include <Box2D/Common/b2Math.h>
#include <Box2D/Particle/b2Particle.h>

//copied from the LiquidFun.h implementation (hopefully I will get my position data this way).
template <typename T>
struct UserOverridableBuffer
{
    UserOverridableBuffer()
    {
        data = NULL;
        userSuppliedCapacity = 0;
    }
    T* data;
    int32 userSuppliedCapacity;
};


//
/// Color for debug drawing. Each value has the range [0,1].
struct b2Color
{
	b2Color() {}
	b2Color(float32 r, float32 g, float32 b) : r(r), g(g), b(b) {}
	void Set(float32 ri, float32 gi, float32 bi) { r = ri; g = gi; b = bi; }
	float32 r, g, b;
};

/// Implement and register this class with a b2World to provide debug drawing of physics
/// entities in your game.
class b2Draw
{
public:
	b2Draw();

	virtual ~b2Draw() {}

	enum
	{
		e_shapeBit				= 0x0001,	///< draw shapes
		e_jointBit				= 0x0002,	///< draw joint connections
		e_aabbBit				= 0x0004,	///< draw axis aligned bounding boxes
		e_pairBit				= 0x0008,	///< draw broad-phase pairs
		e_centerOfMassBit			= 0x0010,	///< draw center of mass frame
		e_particleBit				= 0x0020  ///< draw particles
	};

	/// Set the drawing flags.
	void SetFlags(uint32 flags);

	/// Get the drawing flags.
	uint32 GetFlags() const;

	/// Append flags to the current flags.
	void AppendFlags(uint32 flags);

	/// Clear flags from the current flags.
	void ClearFlags(uint32 flags);

	/// Draw a closed polygon provided in CCW order.
	virtual void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color) = 0;

	/// Draw a solid closed polygon provided in CCW order.
	virtual void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color) = 0;

	/// Draw a circle.
	virtual void DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color) = 0;

	/// Draw a solid circle.
	virtual void DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color) = 0;

	/// Draw a particle array
	virtual void DrawParticles(const b2Vec2 *centers, float32 radius, const b2ParticleColor *colors, int32 count) = 0;

	/// Draw a line segment.
	virtual void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) = 0;

	/// Draw a transform. Choose your own length scale.
	/// @param xf a transform.
	virtual void DrawTransform(const b2Transform& xf) = 0;

protected:
	uint32 m_drawFlags;
};
// This class implements debug drawing callbacks that are invoked
// inside b2World::Step.
struct MetalPoints;
struct MetalLines;
struct MetalTriangles;

class DebugDraw : public b2Draw
{
public:
    DebugDraw();
    ~DebugDraw();

    void Create(void *pointsPositions);
        
    void Destroy();

    /// Draw a closed polygon provided in CCW order.
     void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)override;

//    w a solid closed polygon provided in CCW order.
     void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)override;

//    w a circle.
     void DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color) override;

//    w a solid circle.
     void DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color)override;

//    w a particle array
     void DrawParticles(const b2Vec2 *centers, float32 radius, const b2ParticleColor *colors, int32 count) override;

//    w a line segment.
     void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) override;
    /// Draw a transform. Choose your own length scale.
    /// @param xf a transform.
    virtual void DrawTransform(const b2Transform& xf) override;
    // getters for metal
    b2Vec2* GetPointsPositionBuffer();
    b2Color* GetPointsColorBuffer();
    b2Vec2* GetLinesPositionBuffer();
    b2Color* GetLinesColorBuffer();
    b2Vec2* GetTrianglesPositionBuffer();
    int GetPointsCount();
    int GetLinesCount();
    int GetTrianglesCount();

    void Flush();

    bool m_showUI;
    MetalPoints* m_points;
    MetalLines* m_lines;
    MetalTriangles* m_triangles;
};

extern DebugDraw metalDebugDraw;
#endif
