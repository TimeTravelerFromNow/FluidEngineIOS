
#include "Box2D.h"
#include "Infiltrator.h"
#ifndef CustomContactListener_h
#define CustomContactListener_h

class CustomContactListener: public b2ContactListener {
    
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
    
};

inline void CustomContactListener::PreSolve(b2Contact *contact, const b2Manifold *oldManifold) {
    
    while(contact) { // until the pointer is NULL
//        b2Fixture* fixA = contact->GetFixtureA();
//        b2Fixture* fixB = contact->GetFixtureB();
//        for( int i = 0; i < friendlies.size(); i++ ){
//            if( friendlies[i]->GetBody() == fixA->GetBody() || friendlies[i]->GetBody() == fixB->GetBody() ) { // did we have a friendly?
//                for( int j = 0; j < aliens.size(); j++ ) {
//                    if( aliens[j]->GetBody() == fixB->GetBody() ) { // is the other fixture an alien?
//                        aliens[j]->TakeDamage();
//                        friendlies[i]->TakeDamage();
//                        return; // MARK: custom contact code here
//                    }
//                }
//            }
//        }
        contact = contact->GetNext(); // next ptr.
    };
    
    return;
};

static CustomContactListener m_customcontactlistener;


#endif /* CustomContactListener_h */
