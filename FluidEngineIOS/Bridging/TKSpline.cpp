
#include "TKSpline.h"

TKSpline::TKSpline( b2Vec2* controlPoints, long controlPointsCount ) {
    std::vector<double> Y, X;
    for( int i = 0; i < controlPointsCount; i++ ) {
        X.push_back( controlPoints[i].x );
        Y.push_back( controlPoints[i].y );
    }
    tk::spline s(Y, X);
    m_spline = s;
}

float TKSpline::GetInterpolatedPosition( float yVal ) {
    return m_spline(yVal);
}

void TKSpline::SetInterpolatedPoints( float* fromYVals, float* onXVals, long yValCount ) {
    for( int i = 0; i < yValCount; i++ ) {
        onXVals[i] = m_spline( fromYVals[i] );
    }
}

b2Vec2 TKSpline::GetTangentUnitVector( float yVal ) {
    float slope = m_spline.deriv(1, yVal);
    float angle = atan( slope );
    
    return b2Vec2( cos(angle), sin(angle) );
}

//b2Vec2* TKSpline::GetTangentVectors( double* yVals, long yValCount ) {
//    
//    return void;
//}
