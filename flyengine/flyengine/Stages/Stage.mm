//
//  Stage.mm
//  flyengine-test
//
//  Created by Thomas Liang on 10/3/23.
//

#include "Stage.h"

Stage::Stage() {
}

Stage::~Stage() {
    delete scene_;
}

void Stage::SetCamera(Camera *c) {
    camera_ = c;
}

Scene *Stage::GenerateScene() {
    scene_ = new Scene();
    should_recalculate_all = true;
    return scene_;
}

void Stage::HandleKeyPresses(int key, bool keydown) {
    
}

void Stage::HandleMouseUp(simd_float2 loc, bool left) {
    
}

void Stage::HandleMouseDown(simd_float2 loc, bool left) {
    
}

void Stage::HandleMouseMovement(float x, float y, float dx, float dy) {
    
}

Stage *Stage::CheckNextStage() {
    if (next_stage) {
        Stage *temp = next_stage;
        next_stage = nullptr;
        return temp;
    }
    return nullptr;
}

bool Stage::ShouldRecalculateAll() {
    if (should_recalculate_all) {
        should_recalculate_all = false;
        return true;
    }
    return false;
}

void Stage::Update(float fps) {
}
