//
//  RenderPipeline.h
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef RenderPipeline_h
#define RenderPipeline_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include <SDL.h>

#include "../Schemes/Scheme.h"
#include "../Schemes/SchemeController.h"

class RenderPipeline {
private:
    MTLRenderPassDescriptor* render_pass_descriptor;
    CAMetalLayer *layer;
    
    SDL_Window* window;
    SDL_Renderer* renderer;
    
    int window_width;
    int window_height;
    
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id<MTLLibrary> library;
    
    id <MTLRenderPipelineState> face_render_pipeline_state;

    id <MTLDepthStencilState> depth_state;
    id <MTLTexture> depth_texture;
    
    // buffers for scene render
    id <MTLBuffer> scene_projected_vertex_buffer;
    id <MTLBuffer> scene_face_buffer;
    
    Scheme *scheme;
    SchemeController *scheme_controller;
public:
    ~RenderPipeline();
    
    int init();
    void SetScheme(Scheme *sch);
    void SetSchemeController(SchemeController *sctr);
    void SetBuffers(id<MTLBuffer> spv, id<MTLBuffer> sf);
    
    void SetPipeline();
    
    void Render();
};

#endif /* RenderPipeline_h */
