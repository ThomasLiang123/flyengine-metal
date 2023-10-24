//
//  Scheme.hpp
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef Scheme_h
#define Scheme_h

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

#include "../Stages/Stage.h"

#include "../Camera.h"
#include "../KeyPresses.h"

enum SchemeType {
    View,
    Play
};


class Scheme {
protected:
    SchemeType type;
    
    Camera *camera_;
    
    Scene *scene_;
    unsigned long scene_vertex_length_;
    unsigned long scene_face_length_;
    unsigned long scene_node_length_;
    Vertex * scene_models_vertices_;
    Vertex * scene_models_projected_vertices_;
    Face * scene_models_faces_;
    
    Node * scene_models_nodes_;
    Vertex * scene_models_projected_nodes_;
    
    bool should_reset_empty_buffers = false;
    bool should_reset_static_buffers = false;
    
    float fps = 0;
    
    simd_int2 UI_start_;
    
    simd_float2 click_loc_;
    simd_float2 mouse_loc_;
    
    float x_sens_ = 0.1;
    float y_sens_ = 0.1;
    
    bool input_enabled = true;
    
    bool left_mouse_down_ = false;
    bool right_mouse_down_ = false;
    
    KeyPresses keypresses_;
    
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
    
    int window_width_ = 1080;
    int window_height_ = 700;
    float aspect_ratio_ = 1080/700;
    
    bool show_UI = true;
    
    virtual void HandleCameraMovement();
    
    void UpdateUIVars();
    
    virtual void MainWindow();
    
    void CalculateCounts();
    
    void CalculateNumSceneVertices();
    void CalculateNumSceneFaces();
    void CalculateNumSceneNodes();
public:
    Scheme();
    
    SchemeType GetType();
    
    virtual void SetCamera(Camera *camera);
    void SetScene(Scene *scene);
    
    Camera *GetCamera();
    Scene *GetScene();
    
    void EnableInput(bool enabled);
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    virtual void HandleKeyPresses(int key, bool keydown);
    virtual void HandleMouseDown(simd_float2 loc, bool left);
    virtual void HandleMouseUp(simd_float2 loc, bool left);
    
    void CreateNewModel();
    
    virtual void BuildUI() = 0;
    
    void SetResetEmptyBuffers(bool set);
    void SetResetStaticBuffers(bool set);
    
    bool ShouldResetEmptyBuffers();
    bool ShouldResetStaticBuffers();
    
    unsigned long NumSceneVertices();
    unsigned long NumSceneFaces();
    unsigned long NumSceneNodes();
    
    virtual void Update();
    
    virtual ~Scheme();
};

#endif /* Scheme_hpp */
