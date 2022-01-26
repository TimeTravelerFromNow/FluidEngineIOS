//
//  CustomContactListener.h
//  FluidEngine
//
//  Created by sebi d on 1/15/22.
//

#ifndef CustomContactListener_h
#define CustomContactListener_h

#include "Tube.h"

//helper function to figure out if the collision was between
  //a radar and an aircraft, and sort out which is which

bool getCollision(b2Contact* contact, Tube*& sensorEntity, Tube*& fixtureEntity)
  {
      b2Fixture* fixtureA = contact->GetFixtureA();
      b2Fixture* fixtureB = contact->GetFixtureB();
  
      //make sure only one of the fixtures was a sensor
      bool sensorA = fixtureA->IsSensor();
      bool sensorB = fixtureB->IsSensor();
      if ( ! (sensorA ^ sensorB) )
          return false;
  
      Tube* entityA = static_cast<Tube*>( fixtureA->GetBody()->GetUserData() );
      Tube* entityB = static_cast<Tube*>( fixtureB->GetBody()->GetUserData() );
      
      if ( sensorA ) { //fixtureA is the sensor
          sensorEntity = entityA;
          fixtureEntity = entityB;
      }
      else { //fixtureA must not be a sensor
          sensorEntity = entityB;
          fixtureEntity = entityA;
      }
      return true;
}
//main collision call back function
 class MyContactListener : public b2ContactListener
 {
 private:
   void BeginContact(b2Contact* contact) {
       Tube* Tube0;
       Tube* Tube1;
       if ( getCollision(contact, Tube0, Tube1) )
           Tube0->BeganCollide( Tube1 );
   }
   void EndContact(b2Contact* contact) {
       Tube* Tube0;
       Tube* Tube1;
       if ( getCollision(contact, Tube0, Tube1) )
           Tube0->EndCollide( Tube1 );
   }
//     void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {
//      
//     }
};
#endif /* CustomContactListener_h */
