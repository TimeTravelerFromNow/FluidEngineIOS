
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

void TKSpline::SetInterpolatedPoints( float* fromTVals, float* onXVals, float* onYVals, long valCount ) {
    for( int i = 0; i < valCount; i++ ) {
        onXVals[i] = mX_spline( fromTVals[i] );
        onYVals[i] = mY_spline( fromTVals[i] );
    }
}

b2Vec2 TKSpline::GetTangentUnitVector( float yVal ) {
    float slope = mX_spline.deriv(1, yVal);
    float angle = atan( slope );
    
    return b2Vec2( cos(angle), sin(angle) );
}

//b2Vec2* TKSpline::GetTangentVectors( double* yVals, long yValCount ) {
//    
//    return void;
//}
