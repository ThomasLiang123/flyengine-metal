//
//  PlayScheme.h
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef PlayScheme_h
#define PlayScheme_h

#include <SDL.h>
#include <unistd.h>
#include "Scheme.h"
#include "../Utils/Normals.h"
#include "../Stages/Stage1.h"

class PlayScheme : public Scheme {
private:
    Stage *cur_stage;
    
    void MainWindow();
public:
    PlayScheme();
    ~PlayScheme();
    
    void SetCamera(Camera *c);
    
    void BuildUI();
    void HandleMouseMovement(float x, float y, float dx, float dy);
    void HandleKeyPresses(int key, bool keydown);
    void HandleMouseUp(simd_float2 loc, bool left);
    void HandleMouseDown(simd_float2 loc, bool left);
    
    void SwitchStage(Stage *s);
    
    virtual void Update();
};

#endif /* PlayScheme_h */
