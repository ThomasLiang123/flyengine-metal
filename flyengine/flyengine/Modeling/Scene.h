//
//  Scene.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef Scene_h
#define Scene_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>
#include <filesystem>
#include <sys/stat.h>
#include <sys/types.h>

#include "Model.h"
#include "../Utils/Basis.h"

using namespace DragonflyUtils;

struct ModelUniforms {
    simd_float3 rotate_origin;
    Basis b;
};

class Scene {
private:
    std::vector<Model *> models;
    std::vector<ModelUniforms> model_uniforms;
    
    std::string name_;
public:
    Scene();
    ~Scene();
    
    void GetFromFolder(std::string path);
    
    Model *GetModel(unsigned long mid);
    ModelUniforms *GetModelUniforms(unsigned long mid);
    
    simd_float3 GetModelPosition(unsigned long mid);
    Basis *GetModelBasis(unsigned long mid);
    
    void MoveModelBy(unsigned int mid, float dx, float dy, float dz);
    void RotateModelBy(unsigned int mid, float dx, float dy, float dz);
    
    void MoveModelTo(unsigned int mid, float x, float y, float z);
    //void RotateModelTo(unsigned int mid, float x, float y, float z);
    
    void CreateNewModel();
    void NewModelFromFile(std::string path);
    void AddModel(Model *m);
    void AddModel(Model *m, ModelUniforms mu);
    
    void RemoveModel(unsigned long mid);
    
    unsigned long NumModels();
    
    std::vector<Model *> *GetModels();
    std::vector<ModelUniforms> *GetAllModelUniforms();
    
    std::string GetName();
    void SetName(std::string name);
    void SaveToFolder(std::string path);
};



#endif /* Scene_h */
