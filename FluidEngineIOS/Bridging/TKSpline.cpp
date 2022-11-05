
#include "TKSpline.h"

TKSpline::TKSpline( b2Vec2* controlPoints, int controlPointsCount ) {
    std::vector<double> Y, X;
    for( int i = 0; i < controlPointsCount; i++ ) {
        X.push_back( controlPoints[i].x );
        Y.push_back( controlPoints[i].y );
    }
    tk::spline s(Y, X);
    m_spline = s;
}

float TKSpline::GetInterpolatedPosition(tk::spline fromSpline, float yVal) {
    return fromSpline(yVal);
}

b2Vec2 TKSpline::GetTangentUnitVector(tk::spline fromSpline, float yVal) {
    float slope = fromSpline.deriv(1, yVal);
    float angle = atan( slope );
    
    return b2Vec2( cos(angle), sin(angle) );
}
