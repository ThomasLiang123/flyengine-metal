//
//  SchemeController.h
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#ifndef SchemeController_h
#define SchemeController_h

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"

#include "Scheme.h"
#include "ViewScheme.h"

class SchemeController {
private:
    Scheme *scheme_;
public:
    SchemeController(Scheme *scheme);
    ~SchemeController();
    
    void BuildUI();
    
    void SetScheme(Scheme *scheme);
    Scheme *GetScheme();
};

#endif /* SchemeController_h */
