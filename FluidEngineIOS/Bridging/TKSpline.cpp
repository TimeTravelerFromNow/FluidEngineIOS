
#include "TKSpline.h"

TKSpline::TKSpline( float* tControlPoints, b2Vec2* controlPoints, long controlPointsCount ) {
    std::vector<double> Y, X;
    std::vector<double> T;
    for( int i = 0; i < controlPointsCount; i++ ) {
        T.push_back( tControlPoints[i] );
        X.push_back( controlPoints[i].x );
        Y.push_back( controlPoints[i].y );
    }
    tk::spline xS(T, X);
    tk::spline yS(T, Y);
    mX_spline = xS;
    mY_spline = yS;
}

void TKSpline::SetInterpolatedPoints( float* fromTVals, float* onXVals, float* onYVals, b2Vec2* onTangentVectors, long valCount ) {
    for( int i = 0; i < valCount; i++ ) {
        onXVals[i] = mX_spline( fromTVals[i] );
        onYVals[i] = mY_spline( fromTVals[i] );
        onTangentVectors[i] = GetTangentUnitVector( fromTVals[i] );
    }
}

b2Vec2 TKSpline::GetTangentUnitVector( float t ) {
    float xSlope = mX_spline.deriv(1, t);
    float ySlope = mY_spline.deriv(1, t);
    float magnitude = sqrt( xSlope * xSlope + ySlope * ySlope );    
    return b2Vec2( xSlope , ySlope ) / magnitude;
}
