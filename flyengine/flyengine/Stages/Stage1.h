//
//  Stage1.h
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#ifndef Stage1_h
#define Stage1_h

#include <stdio.h>
#include "PlayStage.h"
#include "Stage2.h"

class Stage1 : public PlayStage {
private:
    void HandleThresholds();
public:
    Scene *GenerateScene();
    void Update(float fps);
};

#endif /* Stage1_h */
