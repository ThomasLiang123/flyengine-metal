//
//  Camera.h
//  flyengine-test
//
//  Created by Thomas Liang on 10/15/23.
//

#ifndef Camera_h
#define Camera_h

struct Camera {
    simd_float3 pos;
    simd_float3 vector;
    simd_float3 up_vector;
    simd_float2 FOV;
};

#endif /* Camera_h */
