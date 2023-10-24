//
//  Stage.h
//  flyengine-test
//
//  Created by Thomas Liang on 10/3/23.
//

#ifndef Stage_h
#define Stage_h

#include <stdio.h>
#include <vector>
#include <string>
#include <sstream>

#include <simd/SIMD.h>

#include <iostream>

#include "imgui.h"

#include "../Utils/Utils.h"

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"

#include "../Camera.h"

class Stage {
protected:
    Camera *camera_ = nullptr;
    Scene *scene_ = nullptr;
    
    // flags
    Stage *next_stage = nullptr;
    bool should_recalculate_all = false;
public:
    Stage();
    ~Stage();
    
    virtual void SetCamera(Camera *c);
    virtual Scene *GenerateScene();
    
    virtual void HandleKeyPresses(int key, bool keydown);
    
    virtual void HandleMouseUp(simd_float2 loc, bool left);
    virtual void HandleMouseDown(simd_float2 loc, bool left);
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    
    virtual Stage *CheckNextStage();
    virtual bool ShouldRecalculateAll();
    virtual void Update(float fps);
};

#endif /* Stage_h */
