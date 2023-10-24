//
//  PlayStage.h
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#ifndef PlayStage_h
#define PlayStage_h

#include <stdio.h>
#include "Stage.h"
#include "KeyPresses.h"

class PlayStage : public Stage {
protected:
    int charactermid = 0;
    simd_float3 cam_origin;
    float cam_dist = 10;
    
    simd_float3 char_velocity_vec;
    simd_float3 bullet_direction_vec;
    float bullet_speed = 0.1;
    
    bool bullet_alive = false;
    
    float G = -10; // m/s
    bool gravity_on = false;
    
    // io
    simd_float2 click_loc_;
    simd_float2 mouse_loc_;
    
    float x_sens_ = 0.1;
    float y_sens_ = 0.1;
    
    bool left_mouse_down_ = false;
    bool right_mouse_down_ = false;
    
    KeyPresses keypresses_;
    
    virtual void CharacterPhysics(float fps);
    
    virtual void Shoot();
    virtual void BulletPhysics(float fps);
public:
    virtual void HandleKeyPresses(int key, bool keydown);
    
    virtual void HandleMouseUp(simd_float2 loc, bool left);
    virtual void HandleMouseDown(simd_float2 loc, bool left);
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    
    virtual void HandleCharacterMovement(float fps);
    virtual void Update(float fps);
};

#endif /* PlayStage_h */
