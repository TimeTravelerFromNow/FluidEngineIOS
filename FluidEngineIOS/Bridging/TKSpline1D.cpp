
#include "TKSpline.h"

TKSpline1D::TKSpline1D( float* xControlPoints, float* yControlPoints, long controlPointsCount ) {
    std::vector<double> X, Y;
    for( int i = 0; i < controlPointsCount; i++ ) {
        X.push_back( xControlPoints[i] );
        Y.push_back( yControlPoints[i] );
    }
    tk::spline S(X, Y);
    m_spline = S;
}

void TKSpline1D::SetInterpolatedPoints( float* fromXVals, float* onYVals, float* onSlopes, long valCount ) {
    for( int i = 0; i < valCount; i++ ) {
        onYVals[i] = m_spline( fromXVals[i] );
        onSlopes[i] = GetSlope( fromXVals[i] );
    }
}

float TKSpline1D::GetSlope(float x) {
    float slope = m_spline.deriv(1, x);
    return slope;
}
