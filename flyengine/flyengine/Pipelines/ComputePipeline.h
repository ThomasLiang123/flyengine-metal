//
//  ComputePipeline.h
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef ComputePipeline_h
#define ComputePipeline_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#import "../Schemes/Scheme.h"
#import "RenderPipeline.h"

class ComputePipeline {
private:
    struct SceneCounts {
        int num_faces;
        int num_vertices;
    };
    
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id <MTLLibrary> library;
    
    id <MTLComputePipelineState> compute_reset_state;
    id <MTLComputePipelineState> compute_transforms_pipeline_state;
    id <MTLComputePipelineState> compute_vertex_pipeline_state;
    id <MTLComputePipelineState> compute_projected_vertices_pipeline_state;
    id <MTLComputePipelineState> compute_lighting_pipeline_state;
    id <MTLComputePipelineState> compute_clipping_pipeline_state;
    
    // buffers for scene compute
    id <MTLBuffer> camera_buffer;
    
    id <MTLBuffer> scene_light_buffer;
    
    id <MTLBuffer> scene_vertex_buffer;
    id <MTLBuffer> scene_projected_vertex_buffer;
    id <MTLBuffer> scene_face_buffer;
    id <MTLBuffer> scene_lit_face_buffer;
    
    id <MTLBuffer> scene_clipped_vertex_buffer;
    id <MTLBuffer> scene_clipped_face_buffer;

    id <MTLBuffer> scene_node_model_id_buffer;

    std::vector<Node> scene_node_array;
    id <MTLBuffer> scene_node_buffer;
    id <MTLBuffer> scene_nvlink_buffer;

    id <MTLBuffer> scene_transform_uniforms_buffer;
    
    SceneCounts scene_counts;
    id<MTLBuffer> scene_counts_buffer;
    
    // scheme and scheme variables
    Scheme *scheme;
    unsigned int num_scene_vertices = 0;
    unsigned int num_scene_faces = 0;
public:
    void init();
    void SetScheme(Scheme *sch);
    
    void SetPipeline();
    
    void SetEmptyBuffers();
    void ResetStaticBuffers();
    void ResetDynamicBuffers();
    
    void Compute();
    void SendDataToRenderer(RenderPipeline *renderer);
};

#endif /* ComputePipeline_h */
