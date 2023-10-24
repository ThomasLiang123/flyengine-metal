//
//  Stage1.mm
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#include "Stage1.h"

Scene *Stage1::GenerateScene() {
    scene_ = new Scene();
    Model *m = new Model(1);
    m->MakeRect(10, 10, 1, simd_make_float4(0, 0, 1, 1));
    scene_->AddModel(m);
    scene_->MoveModelBy(1, 0, 0, -1);
    
    Model *m2 = new Model(2);
    m2->MakeRect(0.5, 0.5, 0.5, simd_make_float4(1, 0, 0, 1));
    scene_->AddModel(m2);
    scene_->MoveModelBy(2, 0.25, 0.25, 0.25);
    
    should_recalculate_all = true;
    return scene_;
}

void Stage1::HandleThresholds() {
    simd_float3 char_pos = scene_->GetModelPosition(charactermid);
    if (char_pos.x >= 10 && char_pos.y >= 10) {
        next_stage = new Stage2();
    }
}

void Stage1::Update(float fps) {
    PlayStage::Update(fps);
    HandleThresholds();
}
