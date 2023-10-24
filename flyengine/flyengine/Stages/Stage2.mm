//
//  Stage2.mm
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#include "Stage2.h"

void Stage2::SetCamera(Camera *c) {
    Stage::SetCamera(c);
    
    camera_->pos = {-2, 0, 0};
    camera_->vector = {1, 0, 0};
    camera_->up_vector = {0, 0, 1};
    camera_->FOV = {M_PI_2, M_PI_2};
}

Scene *Stage2::GenerateScene() {
    scene_ = new Scene();
    scene_->MoveModelTo(0, 0, 0, -1);
    should_recalculate_all = true;
    return scene_;
}
