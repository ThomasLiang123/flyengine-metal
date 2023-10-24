//
//  SchemeController.m
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#import <Foundation/Foundation.h>
#include "SchemeController.h"

SchemeController::SchemeController(Scheme *scheme) {
    scheme_ = scheme;
}

SchemeController::~SchemeController() {
    
}

void SchemeController::BuildUI() {
}

void SchemeController::SetScheme(Scheme *scheme) {
    scheme_ = scheme;
}

Scheme *SchemeController::GetScheme() {
    return scheme_;
}
