//
//  PlayScheme.mm
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#include <Foundation/Foundation.h>
#include "PlayScheme.h"

using namespace DragonflyUtils;

PlayScheme::PlayScheme() {
    type = SchemeType::Play;
    
    cur_stage = new Stage1();
    scene_ = cur_stage->GenerateScene();
}

PlayScheme::~PlayScheme() {
    
}

void PlayScheme::SetCamera(Camera *c) {
    Scheme::SetCamera(c);
    cur_stage->SetCamera(camera_);
}


void PlayScheme::HandleKeyPresses(int key, bool keydown) {
    cur_stage->HandleKeyPresses(key, keydown);
}

void PlayScheme::HandleMouseUp(simd_float2 loc, bool left) {
    cur_stage->HandleMouseUp(loc, left);
}

void PlayScheme::HandleMouseDown(simd_float2 loc, bool left) {
    cur_stage->HandleMouseDown(loc, left);
}

void PlayScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    cur_stage->HandleMouseMovement(x, y, dx, dy);
}

void PlayScheme::MainWindow() {
    ImGui::SetNextWindowPos(ImVec2(UI_start_.x, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(window_width_, window_height_));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    // Display FPS
    ImGui::SetCursorPos(ImVec2(5, 10));
    ImGui::Text("%.1f FPS", ImGui::GetIO().Framerate);
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void PlayScheme::BuildUI() {
    MainWindow();
}

void PlayScheme::SwitchStage(Stage *s) {
    if (!s) {
        return;
    }
    
    if (cur_stage) {
        delete cur_stage;
    }
    
    cur_stage = s;
    scene_ = cur_stage->GenerateScene();
    cur_stage->SetCamera(camera_);
}

void PlayScheme::Update() {
    cur_stage->Update(fps);
    UpdateUIVars();
    
    SwitchStage(cur_stage->CheckNextStage());
    
    if (cur_stage->ShouldRecalculateAll()) {
        CalculateCounts();
        should_reset_empty_buffers = true;
        should_reset_static_buffers = true;
    }
    
    for (std::size_t mid = 0; mid < scene_->NumModels(); mid++) {
        scene_->GetModel(mid)->UpdateAnimation(1 / fps);
    }
}
