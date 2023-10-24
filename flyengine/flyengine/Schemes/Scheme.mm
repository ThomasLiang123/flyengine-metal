//
//  Scheme.mm
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#include "Scheme.h"

using namespace DragonflyUtils;

Scheme::Scheme() {
    UI_start_.x = 0;
    UI_start_.y = 0;
}

Scheme::~Scheme() {
}

SchemeType Scheme::GetType() {
    return type;
}

void Scheme::SetCamera(Camera *camera) {
    camera_ = camera;
}

void Scheme::SetScene(Scene *scene) {
    scene_ = scene;
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

Camera * Scheme::GetCamera() {
    return camera_;
}

Scene * Scheme::GetScene() {
    return scene_;
}

void Scheme::EnableInput(bool enabled) {
    input_enabled = enabled;
}

void Scheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    if (input_enabled && keypresses_.control) {
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
    }
}
 
void Scheme::HandleKeyPresses(int key, bool keydown) {
    if (input_enabled) {
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
}

void Scheme::HandleCameraMovement() {
    // find unit vector of xy camera vector
    float magnitude = sqrt(pow(camera_->vector.x, 2)+pow(camera_->vector.y, 2));
    float unit_x = camera_->vector.x/magnitude;
    float unit_y = camera_->vector.y/magnitude;
    
    if (keypresses_.w) {
        camera_->pos.x += (3.0/fps)*unit_x;
        camera_->pos.y += (3.0/fps)*unit_y;
    }
    if (keypresses_.a) {
        camera_->pos.y -= (3.0/fps)*unit_x;
        camera_->pos.x += (3.0/fps)*unit_y;
    }
    if (keypresses_.s) {
        camera_->pos.x -= (3.0/fps)*unit_x;
        camera_->pos.y -= (3.0/fps)*unit_y;
    }
    if (keypresses_.d) {
        camera_->pos.y += (3.0/fps)*unit_x;
        camera_->pos.x -= (3.0/fps)*unit_y;
    }
    if (keypresses_.space) {
        camera_->pos.z += (3.0/fps);
    }
    if (keypresses_.option) {
        camera_->pos.z -= (3.0/fps);
    }
}

void Scheme::HandleMouseDown(simd_float2 loc, bool left) {
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    if (input_enabled) {
        click_loc_ = loc;
        
        if (left) {
            left_mouse_down_ = true;
        } else {
            right_mouse_down_ = true;
        }
    }
}

void Scheme::HandleMouseUp(simd_float2 loc, bool left) {
    if (left) {
        left_mouse_down_ = false;
    } else {
        right_mouse_down_ = false;
    }
}

void Scheme::CreateNewModel() {
    scene_->CreateNewModel();
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::UpdateUIVars() {
    window_width_ = ImGui::GetIO().DisplaySize.x;
    window_height_ = ImGui::GetIO().DisplaySize.y;
    aspect_ratio_ = (float) window_width_/ (float) window_height_;
    fps = ImGui::GetIO().Framerate;
    
    camera_->FOV = {M_PI_2, 2*(atanf((float) window_height_/(float) window_width_))};
}

void Scheme::MainWindow() {
    ImGui::SetNextWindowPos(ImVec2(UI_start_.x, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(window_width_, window_height_));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    // Display FPS
    fps = ImGui::GetIO().Framerate;
    
    ImGui::SetCursorPos(ImVec2(5, 10));
    ImGui::Text("%.1f FPS", fps);
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void Scheme::SetResetEmptyBuffers(bool set) {
    should_reset_empty_buffers = set;
}

void Scheme::SetResetStaticBuffers(bool set) {
    should_reset_static_buffers = set;
}

bool Scheme::ShouldResetEmptyBuffers() {
    return should_reset_empty_buffers;
}

bool Scheme::ShouldResetStaticBuffers() {
    return should_reset_static_buffers;
}

void Scheme::CalculateCounts() {
    CalculateNumSceneVertices();
    CalculateNumSceneFaces();
    CalculateNumSceneNodes();
}

void Scheme::CalculateNumSceneVertices() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumVertices();
    }
    scene_vertex_length_ = sum;
}

void Scheme::CalculateNumSceneFaces() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumFaces();
    }
    scene_face_length_ = sum;
}

void Scheme::CalculateNumSceneNodes() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumNodes();
    }
    scene_node_length_ = sum;
}

unsigned long Scheme::NumSceneVertices() {
    return scene_vertex_length_;
}

unsigned long Scheme::NumSceneFaces() {
    return scene_face_length_;
}

unsigned long Scheme::NumSceneNodes() {
    return scene_node_length_;
}

void Scheme::Update() {
    HandleCameraMovement();
    
    UpdateUIVars();
}
