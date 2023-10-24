//
//  ComputePipeline.m
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#import <Foundation/Foundation.h>
#include "ComputePipeline.h"
#include <iostream>

void ComputePipeline::init() {
    device = MTLCreateSystemDefaultDevice();
    command_queue = [device newCommandQueue];
    library = [device newDefaultLibrary];
    
    SetPipeline();
}

void ComputePipeline::SetScheme(Scheme *sch) {
    scheme = sch;
    
    num_scene_vertices = scheme->NumSceneVertices();
    num_scene_faces = scheme->NumSceneFaces();
}

void ComputePipeline::SetPipeline() {
    compute_reset_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"ResetVertices"] error:nil];
    compute_transforms_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateModelNodeTransforms"] error:nil];
    compute_vertex_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateVertices"] error:nil];
    compute_projected_vertices_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedVertices"] error:nil];
    compute_lighting_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateFaceLighting"] error:nil];
    compute_clipping_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateClippings"] error:nil];
}

void ComputePipeline::SetEmptyBuffers() {
    num_scene_vertices = scheme->NumSceneVertices();
    num_scene_faces = scheme->NumSceneFaces();
    
    std::vector<Vertex> empty_scene_vertices;
    for (int i = 0; i < num_scene_vertices; i++) {
        empty_scene_vertices.push_back(simd_make_float3(0, 0, 0));
    }
    
    std::vector<Face> empty_scene_faces;
    for (int i = 0; i < num_scene_faces; i++) {
        empty_scene_faces.push_back(Face());
    }
    
    std::vector<Vertex> empty_clipped_vertices;
    for (int i = 0; i < num_scene_vertices + num_scene_faces*2; i++) {
        empty_clipped_vertices.push_back(simd_make_float3(0, 0, 0));
    }

    std::vector<Face> empty_clipped_faces;
    for (int i = 0; i < num_scene_faces*2; i++) {
        empty_clipped_faces.push_back(Face());
    }
    
    scene_vertex_buffer = [device newBufferWithBytes:empty_scene_vertices.data() length:(num_scene_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    scene_projected_vertex_buffer = [device newBufferWithBytes:empty_clipped_vertices.data() length:((num_scene_vertices + num_scene_faces*2) * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    
    scene_lit_face_buffer = [device newBufferWithBytes:empty_scene_faces.data() length:(num_scene_faces * sizeof(Face)) options:MTLResourceStorageModeShared];
    
    scene_clipped_vertex_buffer = [device newBufferWithBytes:empty_clipped_vertices.data() length:((num_scene_vertices + num_scene_faces*2) * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    scene_clipped_face_buffer = [device newBufferWithBytes:empty_clipped_faces.data() length:(num_scene_faces * 2 * sizeof(Face)) options:MTLResourceStorageModeShared];
}

void ComputePipeline::ResetStaticBuffers() {
    std::vector<Model *> *models = scheme->GetScene()->GetModels();
    
    std::vector<Face> scene_faces;
    std::vector<NodeVertexLink> nvlinks;
    std::vector<uint32_t> node_modelIDs;
    scene_node_array.clear();
    
    num_scene_vertices = 0;
    
    for (std::size_t i = 0; i < models->size(); i++) {
        models->at(i)->AddToBuffers(scene_faces, scene_node_array, nvlinks, node_modelIDs, num_scene_vertices);
    }
    
    num_scene_faces = scene_faces.size();
    
    scene_face_buffer = [device newBufferWithBytes:scene_faces.data() length:(scene_faces.size() * sizeof(Face)) options:MTLResourceStorageModeShared];
    scene_nvlink_buffer = [device newBufferWithBytes:nvlinks.data() length:(nvlinks.size() * sizeof(NodeVertexLink)) options:MTLResourceStorageModeShared];
    scene_node_model_id_buffer = [device newBufferWithBytes:node_modelIDs.data() length:(node_modelIDs.size() * sizeof(uint32)) options:MTLResourceStorageModeShared];
    
    simd_float3 *light = new simd_float3();
    light->x = 0;
    light->y = 0;
    light->z = 8;
    scene_light_buffer = [device newBufferWithBytes:light length:sizeof(simd_float3) options:MTLResourceStorageModeShared];
    delete light;
    
    scene_counts.num_faces = num_scene_faces;
    scene_counts.num_vertices = num_scene_vertices;
    scene_counts_buffer = [device newBufferWithBytes:(void*) &scene_counts length:sizeof(scene_counts) options:MTLResourceStorageModeShared];
}

void ComputePipeline::ResetDynamicBuffers() {
    std::vector<ModelUniforms> *scene_transforms = scheme->GetScene()->GetAllModelUniforms();
    
    std::vector<Model *> *models = scheme->GetScene()->GetModels();
    for (std::size_t i = 0; i < models->size(); i++) {
        models->at(i)->UpdateNodeBuffers(scene_node_array);
    }
    
    camera_buffer = [device newBufferWithBytes:scheme->GetCamera() length:sizeof(Camera) options:{}];
    scene_transform_uniforms_buffer = [device newBufferWithBytes: scene_transforms->data() length:(scene_transforms->size() * sizeof(ModelUniforms)) options:{}];
    scene_node_buffer = [device newBufferWithBytes: scene_node_array.data() length:(scene_node_array.size() * sizeof(Node)) options:MTLResourceStorageModeShared];
}

void ComputePipeline::Compute() {
    id<MTLCommandBuffer> compute_command_buffer = [command_queue commandBuffer];
    id<MTLComputeCommandEncoder> compute_encoder = [compute_command_buffer computeCommandEncoder];
    
    unsigned long num_scene_vertices = scheme->NumSceneVertices();
    unsigned long num_scene_faces = scheme->NumSceneFaces();
    unsigned long num_scene_nodes = scheme->NumSceneNodes();
    
    if (num_scene_vertices > 0 && num_scene_faces > 0 && num_scene_nodes > 0) {
        // reset vertices to 0
        [compute_encoder setComputePipelineState: compute_reset_state];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
        MTLSize gridSize = MTLSizeMake(num_scene_vertices, 1, 1);
        NSUInteger threadGroupSize = compute_reset_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices) threadGroupSize = num_scene_vertices;
        MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate rotated/transformed nodes
        [compute_encoder setComputePipelineState: compute_transforms_pipeline_state];
        [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_node_model_id_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_transform_uniforms_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_nodes, 1, 1);
        threadGroupSize = compute_transforms_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_nodes) threadGroupSize = num_scene_nodes;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate vertices from nodes
        [compute_encoder setComputePipelineState:compute_vertex_pipeline_state];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_nvlink_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_vertices, 1, 1);
        threadGroupSize = compute_vertex_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices) threadGroupSize = num_scene_vertices;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate scene lighting
        [compute_encoder setComputePipelineState: compute_lighting_pipeline_state];
        [compute_encoder setBuffer: scene_lit_face_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_face_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:2];
        [compute_encoder setBuffer: scene_light_buffer offset:0 atIndex:3];
        gridSize = MTLSizeMake(num_scene_faces, 1, 1);
        threadGroupSize = compute_lighting_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_faces) threadGroupSize = num_scene_faces;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate clipping
        [compute_encoder setComputePipelineState: compute_clipping_pipeline_state];
        [compute_encoder setBuffer: scene_clipped_face_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_clipped_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_lit_face_buffer offset:0 atIndex:2];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:3];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:4];
        [compute_encoder setBuffer: scene_counts_buffer offset:0 atIndex:5];
        gridSize = MTLSizeMake(num_scene_faces, 1, 1);
        threadGroupSize = compute_clipping_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_faces) threadGroupSize = num_scene_faces;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate projected vertex in kernel function
        [compute_encoder setComputePipelineState: compute_projected_vertices_pipeline_state];
        [compute_encoder setBuffer: scene_projected_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_clipped_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_vertices+num_scene_faces*2, 1, 1);
        threadGroupSize = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices+num_scene_faces*2) threadGroupSize = num_scene_vertices+num_scene_faces*2;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
    }
    
    [compute_encoder endEncoding];
    [compute_command_buffer commit];
    [compute_command_buffer waitUntilCompleted];
}


void ComputePipeline::SendDataToRenderer(RenderPipeline *renderer) {
    renderer->SetBuffers(scene_projected_vertex_buffer, scene_clipped_face_buffer);
}
