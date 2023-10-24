//
//  Engine.h
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef Engine_h
#define Engine_h

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <sys/stat.h>
#include <sys/types.h>
#include <math.h>

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include <SDL.h>
#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "Camera.h"

#include "Schemes/SchemeController.h"

#include "Schemes/Scheme.h"
#include "Schemes/PlayScheme.h"
#include "Schemes/ViewScheme.h"

#include "Pipelines/ComputePipeline.h"
#include "Pipelines/RenderPipeline.h"

class Engine {
private:
    std::string project_path = "/";
    
    int window_id;

    int scene_window_start_x = 0;
    int scene_window_start_y = 0;
    int window_width = 1080;
    int window_height = 700;

    bool show_main_window = true;

    // metal
    CAMetalLayer *layer;
    id <MTLCommandQueue> command_queue;

    ComputePipeline *compute_pipeline;
    RenderPipeline *render_pipeline;

    float fps = 0;

    // scheme and scene
    Camera *camera;
    SchemeController *scheme_controller;
    Scheme *scheme;

    void HandleKeyboardEvents(SDL_Event event);

    void HandleMouseEvents(SDL_Event event);
public:
    Engine();
    ~Engine();
    int init();
    void run();
};

#endif /* Engine_h */
