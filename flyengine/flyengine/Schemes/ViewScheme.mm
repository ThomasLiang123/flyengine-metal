//
//  EditModelScheme.m
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#import <Foundation/Foundation.h>
#include "ViewScheme.h"

using namespace DragonflyUtils;

ViewScheme::ViewScheme() {
    type = SchemeType::View;
}

ViewScheme::~ViewScheme() {
    
}

void ViewScheme::HandleMouseUp(simd_float2 loc, bool left) {
    Scheme::HandleMouseUp(loc, left);
}

void ViewScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    Scheme::HandleMouseMovement(x, y, dx, dy);
}

void ViewScheme::MainWindow() {
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

void ViewScheme::BuildUI() {
    MainWindow();
}

void ViewScheme::Update() {
    Scheme::Update();
    
    for (std::size_t mid = 0; mid < scene_->NumModels(); mid++) {
        scene_->GetModel(mid)->UpdateAnimation(1 / fps);
    }
}
