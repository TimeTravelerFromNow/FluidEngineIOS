/*
* Copyright (c) 2011 Erin Catto http://box2d.org
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

#include <Box2D/Common/b2Draw.h>
DebugDraw metalDebugDraw;

b2Draw::b2Draw()
{
	m_drawFlags = 0;
}

void b2Draw::SetFlags(uint32 flags)
{
	m_drawFlags = flags;
}

uint32 b2Draw::GetFlags() const
{
	return m_drawFlags;
}

void b2Draw::AppendFlags(uint32 flags)
{
	m_drawFlags |= flags;
}

void b2Draw::ClearFlags(uint32 flags)
{
	m_drawFlags &= ~flags;
}

struct MetalPoints
{

    void Destroy()
    {
    }

    void Create()
    {
        m_count = 0;
    }
    
    void Vertex(const b2Vec2& v, const b2Color& c, float size)
    {
        if (m_count >= e_maxVertices)
          Flush();
        m_vertices[m_count] = v;
        m_colors[m_count] = c;
        m_sizes[m_count] = size;
        ++m_count;
    }

    void Flush()
    {
        if (m_count == 0)
            return;
        m_count = 0;
    }

    enum { e_maxVertices = 512 };
    b2Vec2 m_vertices[e_maxVertices];
    b2Color m_colors[e_maxVertices];
    float m_sizes[e_maxVertices];

    int32 m_count;
};

//
struct MetalLines
{

    void Destroy()
    {
        
    }
    
    void Create()
    {
        m_count = 0;
    }

    void Vertex(const b2Vec2& v, const b2Color& c)
    {
        if (m_count >= e_maxVertices)
            Flush();

        m_vertices[m_count] = v;
        m_colors[m_count] = c;
        ++m_count;
    }

    void Flush()
    {
        if (m_count == 0)
            return;
        m_count = 0;
    }

    enum { e_maxVertices = 2 * 2048 }; // default : 2 * 512
    b2Vec2 m_vertices[e_maxVertices];
    b2Color m_colors[e_maxVertices];
    
    
    int32 m_count;
};

//
struct MetalTriangles
{
    void Create()
    {
        m_count = 0;
    }

    void Destroy()
    {
        
    }

    void Vertex(const b2Vec2& v, const b2Color& c)
    {
        if (m_count >= e_maxVertices)
            Flush();

        m_vertices[m_count] = v;
        m_colors[m_count] = c;
        ++m_count;
    }

    void Flush()
    {
        if (m_count == 0)
            return;
// draw

        m_count = 0;
    }

    enum { e_maxVertices = 3 * 512 };
    b2Vec2 m_vertices[e_maxVertices];
    b2Color m_colors[e_maxVertices];

    int32 m_count;

};

//
DebugDraw::DebugDraw()
{
    m_drawFlags = 0x0001;

    m_points = new MetalPoints;
    m_points->Create();
    m_lines = new MetalLines;
    m_lines->Create();
    m_triangles = new MetalTriangles;
    m_triangles->Create();
}

//
DebugDraw::~DebugDraw()
{
    Destroy();
    b2Assert(m_points == NULL);
    b2Assert(m_lines == NULL);
    b2Assert(m_triangles == NULL);
}
//
void DebugDraw::Create(void *pointsPositions  )
{

}
void DebugDraw::Destroy()
{
    m_points->Destroy();
    delete m_points;
    m_points = NULL;

    m_lines->Destroy();
    delete m_lines;
    m_lines = NULL;

    m_triangles->Destroy();
    delete m_triangles;
    m_triangles = NULL;
}

b2Vec2* DebugDraw::GetPointsPositionBuffer() {
    return m_points->m_vertices;
}
b2Color* DebugDraw::GetPointsColorBuffer() {
    return m_points->m_colors;
}
int DebugDraw::GetPointsCount(){
    return m_points->m_count;
}
b2Vec2* DebugDraw::GetLinesPositionBuffer() {
    return m_lines->m_vertices;
}
b2Color* DebugDraw::GetLinesColorBuffer() {
    return m_lines->m_colors;
}
int DebugDraw::GetLinesCount() {
    return m_lines->m_count;
}
b2Vec2* DebugDraw::GetTrianglesPositionBuffer() {
    return m_triangles->m_vertices;
}
int DebugDraw::GetTrianglesCount() {
    return m_triangles->m_count;
}


//
void DebugDraw::DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
{
    b2Vec2 p1 = vertices[vertexCount - 1];
    for (int32 i = 0; i < vertexCount; ++i)
    {
        b2Vec2 p2 = vertices[i];
        m_lines->Vertex(p1, color);
        m_lines->Vertex(p2, color);
        p1 = p2;
    }
}

//
void DebugDraw::DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
{
    b2Color fillColor = b2Color(0.5f * color.r, 0.5f * color.g, 0.5f * color.b);

    for (int32 i = 1; i < vertexCount - 1; ++i)
    {
        m_triangles->Vertex(vertices[0], fillColor);
        m_triangles->Vertex(vertices[i], fillColor);
        m_triangles->Vertex(vertices[i + 1], fillColor);
    }

    b2Vec2 p1 = vertices[vertexCount - 1];
    for (int32 i = 0; i < vertexCount; ++i)
    {
        b2Vec2 p2 = vertices[i];
        m_lines->Vertex(p1, color);
        m_lines->Vertex(p2, color);
        p1 = p2;
    }
}

//
void DebugDraw::DrawCircle(const b2Vec2& center, float radius, const b2Color& color)
{
    const float k_segments = 16.0f;
    const float k_increment = 2.0f * b2_pi / k_segments;
    float sinInc = sinf(k_increment);
    float cosInc = cosf(k_increment);
    b2Vec2 r1(1.0f, 0.0f);
    b2Vec2 v1 = center + radius * r1;
    for (int32 i = 0; i < k_segments; ++i)
    {
        // Perform rotation to avoid additional trigonometry.
        b2Vec2 r2;
        r2.x = cosInc * r1.x - sinInc * r1.y;
        r2.y = sinInc * r1.x + cosInc * r1.y;
        b2Vec2 v2 = center + radius * r2;
        m_lines->Vertex(v1, color);
        m_lines->Vertex(v2, color);
        r1 = r2;
        v1 = v2;
    }
}
//
void DebugDraw::DrawSolidCircle(const b2Vec2& center, float radius, const b2Vec2& axis, const b2Color& color)
{
    const float k_segments = 16.0f;
    const float k_increment = 2.0f * b2_pi / k_segments;
    float sinInc = sinf(k_increment);
    float cosInc = cosf(k_increment);
    b2Vec2 v0 = center;
    b2Vec2 r1(cosInc, sinInc);
    b2Vec2 v1 = center + radius * r1;
    b2Color fillColor = b2Color(0.5f * color.r, 0.5f * color.g, 0.5f * color.b);
    for (int32 i = 0; i < k_segments; ++i)
    {
        // Perform rotation to avoid additional trigonometry.
        b2Vec2 r2;
        r2.x = cosInc * r1.x - sinInc * r1.y;
        r2.y = sinInc * r1.x + cosInc * r1.y;
        b2Vec2 v2 = center + radius * r2;
        m_triangles->Vertex(v0, fillColor);
        m_triangles->Vertex(v1, fillColor);
        m_triangles->Vertex(v2, fillColor);
        r1 = r2;
        v1 = v2;
    }

    r1.Set(1.0f, 0.0f);
    v1 = center + radius * r1;
    for (int32 i = 0; i < k_segments; ++i)
    {
        b2Vec2 r2;
        r2.x = cosInc * r1.x - sinInc * r1.y;
        r2.y = sinInc * r1.x + cosInc * r1.y;
        b2Vec2 v2 = center + radius * r2;
        m_lines->Vertex(v1, color);
        m_lines->Vertex(v2, color);
        r1 = r2;
        v1 = v2;
    }

    // Draw a line fixed in the circle to animate rotation.
    b2Vec2 p = center + radius * axis;
    m_lines->Vertex(center, color);
    m_lines->Vertex(p, color);
}

//
void DebugDraw::DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color)
{
    m_lines->Vertex(p1, color);
    m_lines->Vertex(p2, color);
}
//
void DebugDraw::DrawTransform(const b2Transform& xf)
{
    const float k_axisScale = 0.4f;
    b2Color red(1.0f, 0.0f, 0.0f);
    b2Color green(0.0f, 1.0f, 0.0f);
    b2Vec2 p1 = xf.p, p2;

    m_lines->Vertex(p1, red);
    p2 = p1 + k_axisScale * xf.q.GetXAxis();
    m_lines->Vertex(p2, red);

    m_lines->Vertex(p1, green);
    p2 = p1 + k_axisScale * xf.q.GetYAxis();
    m_lines->Vertex(p2, green);
}

void DebugDraw::DrawParticles(const b2Vec2 *centers, float32 radius, const b2ParticleColor *colors, int32 count)
{
    m_points->m_count = count;
    if( colors ) {
    for(int i = 0; i<count; i++){
        m_points->Vertex(centers[i], b2Color(0.3,0.3,1.0) , radius);
    }
    }
    else {
        for(int i = 0; i<count; i++){

        m_points->Vertex(centers[i], b2Color(0.9, 0.1, 1.0) , radius);
        }
    }
}
