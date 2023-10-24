//
//  PlayStage.mm
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#include "PlayStage.h"

void PlayStage::HandleKeyPresses(int key, bool keydown) {
    switch (key) {
        case 119:
            keypresses_.w = keydown;
            break;
        case 97:
            keypresses_.a = keydown;
            break;
        case 115:
            keypresses_.s = keydown;
            break;
        case 100:
            keypresses_.d = keydown;
            break;
        case 32:
            keypresses_.space = keydown;
            break;
        case 1073742049:
            keypresses_.shift = keydown;
            break;
        case 1073742048:
            keypresses_.control = keydown;
            break;
        case 1073742054:
            keypresses_.option = keydown;
            break;
        case 1073742055:
            keypresses_.command = keydown;
            break;
        default:
            break;
    }
}

void PlayStage::HandleMouseUp(simd_float2 loc, bool left) {
    if (left) {
        if (!left_mouse_down_) Shoot();
        left_mouse_down_ = true;
    } else {
        right_mouse_down_ = true;
    }
}

void PlayStage::HandleMouseDown(simd_float2 loc, bool left) {
    if (left) {
        left_mouse_down_ = false;
    } else {
        right_mouse_down_ = false;
    }
}

void PlayStage::HandleMouseMovement(float x, float y, float dx, float dy) {
    if (camera_ == nullptr) return;
    
    //get current camera angles (phi is horizontal and theta is vertical)
    //get the new change based on the amount the mouse moved
    float curr_phi = atan2(camera_->vector.y, camera_->vector.x);
    float phi_change = x_sens_*dx*(M_PI/180);
    
    float curr_theta = acos(camera_->vector.z);
    float theta_change = y_sens_*dy*(M_PI/180);
    
    //get new phi and theta angles
    float new_phi = curr_phi + phi_change;
    float new_theta = curr_theta + theta_change;
    //set the camera "pointing" vector to spherical -> cartesian
    camera_->vector.x = sin(new_theta)*cos(new_phi);
    camera_->vector.y = sin(new_theta)*sin(new_phi);
    camera_->vector.z = cos(new_theta);
    //set the camera perpendicular "up" vector the same way but adding pi/2 to theta
    camera_->up_vector.x = sin(new_theta-M_PI_2)*cos(new_phi);
    camera_->up_vector.y = sin(new_theta-M_PI_2)*sin(new_phi);
    camera_->up_vector.z = cos(new_theta-M_PI_2);
    
    simd_float3 charpos = scene_->GetModelPosition(charactermid);
    cam_origin = simd_make_float3(charpos.x, charpos.y, charpos.z + 1.5);
    camera_->pos.x = cam_origin.x - camera_->vector.x * cam_dist;
    camera_->pos.y = cam_origin.y - camera_->vector.y * cam_dist;
    camera_->pos.z = cam_origin.z - camera_->vector.z * cam_dist;
}

void PlayStage::CharacterPhysics(float fps) {
    if (camera_ == nullptr) return;
    
    if (fps > 0) {
        float charz = scene_->GetModelPosition(charactermid).z;
        gravity_on = charz > 0;
    
        if (gravity_on) {
            char_velocity_vec.z += G / fps;
        } else {
            scene_->MoveModelBy(charactermid, 0, 0, 0 - charz);
            if (char_velocity_vec.z < 0) {
                char_velocity_vec.z = 0;
            }
        }
        scene_->MoveModelBy(charactermid, char_velocity_vec.x / fps, char_velocity_vec.y / fps, char_velocity_vec.z / fps);
        
        simd_float3 charpos = scene_->GetModelPosition(charactermid);
        cam_origin = simd_make_float3(charpos.x, charpos.y, charpos.z + 1.5);
        camera_->pos.x = cam_origin.x - camera_->vector.x * cam_dist;
        camera_->pos.y = cam_origin.y - camera_->vector.y * cam_dist;
        camera_->pos.z = cam_origin.z - camera_->vector.z * cam_dist;
    }
}

void PlayStage::Shoot() {
    if (camera_ == nullptr) return;
    
    simd_float3 charpos = scene_->GetModelPosition(charactermid);
    scene_->MoveModelTo(2, charpos.x, charpos.y, charpos.z+1.5);
    bullet_direction_vec = camera_->vector;
    bullet_alive = true;
}

void PlayStage::BulletPhysics(float fps) {
    if (bullet_alive) {
        scene_->MoveModelBy(2, bullet_speed*bullet_direction_vec.x, bullet_speed*bullet_direction_vec.y, bullet_speed*bullet_direction_vec.z);
        
        if (dist3to3(scene_->GetModelPosition(0), scene_->GetModelPosition(2)) > 20 || scene_->GetModelPosition(2).z < 0) {
            bullet_alive = false;
            scene_->MoveModelTo(2, 0, 0, -100);
        }
    }
}

void PlayStage::HandleCharacterMovement(float fps) {
    if (camera_ == nullptr) return;
    
    float magnitude = sqrt(pow(camera_->vector.x, 2)+pow(camera_->vector.y, 2));
    float unit_x = camera_->vector.x/magnitude;
    float unit_y = camera_->vector.y/magnitude;
    
    if (charactermid < scene_->NumModels()) {
        char_velocity_vec.x = 0;
        char_velocity_vec.y = 0;
        
        bool moving = false;
        
        if (keypresses_.w) {
            char_velocity_vec.x += 3 * unit_x;
            char_velocity_vec.y += 3 * unit_y;
            moving = true;
        }
        if (keypresses_.a) {
            char_velocity_vec.x += 3 * unit_y;
            char_velocity_vec.y -= 3 * unit_x;
            moving = true;
        }
        if (keypresses_.s) {
            char_velocity_vec.x -= 3 * unit_x;
            char_velocity_vec.y -= 3 * unit_y;
            moving = true;
        }
        if (keypresses_.d) {
            char_velocity_vec.x -= 3 * unit_y;
            char_velocity_vec.y += 3 * unit_x;
            moving = true;
        }
        if (keypresses_.space && !gravity_on) {
            char_velocity_vec.z += 3;
        }
    }
}

void PlayStage::Update(float fps) {
    CharacterPhysics(fps);
    HandleCharacterMovement(fps);
    BulletPhysics(fps);
}
