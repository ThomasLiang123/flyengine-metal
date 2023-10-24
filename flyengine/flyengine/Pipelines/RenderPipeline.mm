//
//  RenderPipeline.m
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#import <Foundation/Foundation.h>
#include "RenderPipeline.h"

RenderPipeline::~RenderPipeline() {
    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

int RenderPipeline::init () {
    // Setup ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // Setup IO
    io.WantCaptureKeyboard = true;

    // Setup style
    ImGui::StyleColorsDark();

    // Setup SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
    {
        printf("Error: %s\n", SDL_GetError());
        return -1;
    }

    // Inform SDL that we will be using metal for rendering. Without this hint initialization of metal renderer may fail.
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    
    // get screen size
    SDL_DisplayMode DM;
    SDL_GetCurrentDisplayMode(0, &DM);
    auto width = 1080; //DM.w;
    auto height = 700; //DM.h;
    
    std::cout<<width<<" "<<height<<std::endl;
    window = SDL_CreateWindow("fly engine test", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    if (window == NULL)
    {
        printf("Error creating window: %s\n", SDL_GetError());
        return -2;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED/* | SDL_RENDERER_PRESENTVSYNC*/);
    if (renderer == NULL)
    {
        printf("Error creating renderer: %s\n", SDL_GetError());
        return -3;
    }

    // Setup Platform/Renderer backends
    layer = (__bridge CAMetalLayer*)SDL_RenderGetMetalLayer(renderer);
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    device = layer.device;
    
    ImGui_ImplMetal_Init(device);
    ImGui_ImplSDL2_InitForMetal(window);

    command_queue = [layer.device newCommandQueue];
    render_pass_descriptor = [MTLRenderPassDescriptor new];
    library = [device newDefaultLibrary];
    
    SetPipeline();
    
    SDL_SetWindowSize(window, width, height);
    
    SDL_SetRelativeMouseMode(SDL_TRUE);
    
    return SDL_GetWindowID(window);
}

void RenderPipeline::SetScheme(Scheme *sch) {
    scheme = sch;
}

void RenderPipeline::SetSchemeController(SchemeController *sctr) {
    scheme_controller = sctr;
}

void RenderPipeline::SetBuffers(id<MTLBuffer> spv, id<MTLBuffer> sf) {
    scene_projected_vertex_buffer = spv;
    scene_face_buffer = sf;
}

void RenderPipeline::SetPipeline () {
    CGSize drawableSize = layer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:drawableSize.width height:drawableSize.height mipmapped:NO];
    descriptor.storageMode = MTLStorageModePrivate;
    descriptor.usage = MTLTextureUsageRenderTarget;
    depth_texture = [device newTextureWithDescriptor:descriptor];
    depth_texture.label = @"DepthStencil";
    
    MTLRenderPipelineDescriptor *render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"DefaultVertexShader"];
    render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    
    face_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:render_pipeline_descriptor error:nil];
    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    [depth_descriptor setDepthCompareFunction: MTLCompareFunctionLessEqual];
    [depth_descriptor setDepthWriteEnabled: true];
    depth_state = [device newDepthStencilStateWithDescriptor: depth_descriptor];
}

void RenderPipeline::Render() {
    SDL_GetRendererOutputSize(renderer, &window_width, &window_height);
    
    layer.drawableSize = CGSizeMake(window_width, window_height);
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    
    id<MTLCommandBuffer> render_command_buffer = [command_queue commandBuffer];
    render_pass_descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.6, 0.6, 0.6, 1);
    render_pass_descriptor.colorAttachments[0].texture = drawable.texture;
    render_pass_descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    render_pass_descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    render_pass_descriptor.depthAttachment.texture = depth_texture;
    render_pass_descriptor.depthAttachment.clearDepth = 1.0;
    render_pass_descriptor.depthAttachment.loadAction = MTLLoadActionClear;
    render_pass_descriptor.depthAttachment.storeAction = MTLStoreActionStore;
    
    //render_pass_descriptor.renderTargetWidth = window_width;
    //render_pass_descriptor.renderTargetHeight = window_height;
    id <MTLRenderCommandEncoder> render_encoder = [render_command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];
    [render_encoder pushDebugGroup:@"dragonfly"];
    
    [render_encoder setDepthStencilState: depth_state];
    
    unsigned long num_vertices = scheme->NumSceneVertices();
    unsigned long num_faces = scheme->NumSceneFaces();
    unsigned long num_nodes = scheme->NumSceneNodes();
    
    if (num_vertices > 0 && num_faces > 0 && num_nodes > 0) {
        // rendering scene - the faces
        [render_encoder setRenderPipelineState:face_render_pipeline_state];
        [render_encoder setVertexBuffer:scene_projected_vertex_buffer offset:0 atIndex:0];
        [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
        [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_faces*2*3];
    }
    
    // Start the Dear ImGui frame
    ImGui_ImplMetal_NewFrame(render_pass_descriptor);
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    
    scheme_controller->BuildUI();
    
    scheme = scheme_controller->GetScheme();
    scheme->BuildUI();
    
    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), render_command_buffer, render_encoder); // ImGui changes the encoders pipeline here to use its shaders and buffers
     
    // End rendering and display
    [render_encoder popDebugGroup];
    [render_encoder endEncoding];
    
    [render_command_buffer presentDrawable:drawable];
    [render_command_buffer commit];
}
