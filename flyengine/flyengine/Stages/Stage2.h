//
//  Stage2.h
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#ifndef Stage2_h
#define Stage2_h

#include <stdio.h>
#include "Stage.h"

class Stage2 : public Stage {
public:
    void SetCamera(Camera *c);
    
    Scene *GenerateScene();
};

#endif /* Stage2_h */
