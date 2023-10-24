//
//  Processing.metal
//  flyengine-test
//
//  Created by Thomas Liang on 1/12/23.
//

#include <metal_stdlib>
using namespace metal;

constant float pi = 3.14159265358979;
constant float render_dist = 1000;

typedef simd_float3 Vertex;
typedef simd_float3 Joint;

struct SceneCounts {
    int num_faces;
    int num_vertices;
};

struct Basis {
    simd_float3 pos;
    // angles
    simd_float3 x;
    simd_float3 y;
    simd_float3 z;
};

struct Camera {
    vector_float3 pos;
    vector_float3 vector;
    vector_float3 upVector;
    vector_float2 FOV;
};

struct Face {
    unsigned int vertices[3];
    vector_float4 color;
    
    bool normal_reversed;
    simd_float3 lighting_offset; // if there were a light source directly in front of the face, this is the rotation to get to its brightest orientation
    float shading_multiplier;
};

struct Node {
    int locked_to;
    Basis b;
};

struct NodeVertexLink {
    int nid;
    vector_float3 vector;
    float weight;
};

struct VertexOut {
    vector_float4 pos [[position]];
    vector_float4 color;
};

struct ModelUniforms {
    vector_float3 rotate_origin;
    Basis b;
};

//convert a 3d point to a pixel (vertex) value
vector_float3 PointToPixel (vector_float3 point, constant Camera &camera)  {
    //vector from camera position to object position
    vector_float4 toObject;
    toObject.x = (point.x-camera.pos.x);
    toObject.y = (point.y-camera.pos.y);
    toObject.z = (point.z-camera.pos.z);
    toObject.w = (sqrt(pow(toObject.x, 2)+pow(toObject.y, 2)+pow(toObject.z, 2)));
    
    //project camera vector onto object vector
    float dotProduct = (toObject.x*camera.vector.x)+(toObject.y*camera.vector.y)+(toObject.z*camera.vector.z);
    bool behind = false;
    if (dotProduct < 0) {
        behind = true;
        toObject.x *= -1;
        toObject.y *= -1;
        toObject.z *= -1;
        dotProduct *= -1;
    }
    vector_float4 proj;
    proj.x = dotProduct*camera.vector.x;
    proj.y = dotProduct*camera.vector.y;
    proj.z = dotProduct*camera.vector.z;
    proj.w = sqrt(pow(proj.x, 2)+pow(proj.y, 2)+pow(proj.z, 2));
    
    //subtract projected vector from the object vector to get the "on screen" vector
    vector_float4 distTo;
    distTo.x = toObject.x-proj.x;
    distTo.y = toObject.y-proj.y;
    distTo.z = toObject.z-proj.z;
    distTo.w = sqrt(pow(distTo.x, 2)+pow(distTo.y, 2)+pow(distTo.z, 2));
    
    //angle from vertical on screen - 0 is straight up - counterclockwise
    //use the plane of the camera with normal vector being where the camera is pointing
    //some method to find the angle between 2 vectors in 2pi radians
    //https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors/16544330#16544330
    
    float dotProductDistToAndCamUp = (distTo.x*camera.upVector.x)+(distTo.y*camera.upVector.y)+(distTo.z*camera.upVector.z);
    float det = (camera.upVector.x*distTo.y*camera.vector.z) + (distTo.x*camera.vector.y*camera.upVector.z) + (camera.vector.x*camera.upVector.y*distTo.z) - (camera.upVector.z*distTo.y*camera.vector.x) - (distTo.z*camera.vector.y*camera.upVector.x) - (camera.vector.z*camera.upVector.y*distTo.x);
    float angleBetween = atan2(det, dotProductDistToAndCamUp);
    //TODO: add twist
    angleBetween = angleBetween/*-camera.vector.z*/;
    
    //find dimensions of the "screen rectangle" at the location of the object
    //FOV is the angle of the field of view - the whole screen
    float halfWidth = abs(proj.w*tan(camera.FOV.x/2));
    float halfHeight = abs(proj.w*tan(camera.FOV.y/2));
    
    //screen location of object
    float xLoc = -distTo.w*sin(angleBetween);
    float yLoc = distTo.w*cos(angleBetween);
    
    //get screen coordinates
    float screenX = 0;
    float screenY = 0;
    if (halfWidth != 0 && halfHeight != 0) {
        screenX = (xLoc)/(halfWidth);
        screenY = (yLoc)/(halfHeight);
    }
    
    // if dot product is negative then the vertex is behind
    if (behind) {
        return vector_float3(-screenX, -screenY, proj.w/render_dist);
    }
    
    return vector_float3(screenX, screenY, proj.w/render_dist);
}

vector_float3 RotateAround (vector_float3 point, vector_float3 origin, vector_float3 angle) {
    vector_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    vector_float3 newvec;
    
    // gimbal locked
    
    // around z axis
    newvec.x = vec.x*cos(angle.z)-vec.y*sin(angle.z);
    newvec.y = vec.x*sin(angle.z)+vec.y*cos(angle.z);
    
    vec.x = newvec.x;
    vec.y = newvec.y;
    
    // around y axis
    newvec.x = vec.x*cos(angle.y)+vec.z*sin(angle.y);
    newvec.z = -vec.x*sin(angle.y)+vec.z*cos(angle.y);
    
    vec.x = newvec.x;
    vec.z = newvec.z;
    
    // around x axis
    newvec.y = vec.y*cos(angle.x)-vec.z*sin(angle.x);
    newvec.z = vec.y*sin(angle.x)+vec.z*cos(angle.x);
    
    vec.y = newvec.y;
    vec.z = newvec.z;
    
    point.x = origin.x+vec.x;
    point.y = origin.y+vec.y;
    point.z = origin.z+vec.z;
    
    return point;
}

simd_float3 TranslatePointToStandard(Basis b, simd_float3 point) {
    simd_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    ret.x += b.pos.x;
    ret.y += b.pos.y;
    ret.z += b.pos.z;
    
    return ret;
}

simd_float3 RotatePointToStandard(Basis b, simd_float3 point) {
    simd_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    return ret;
}

simd_float3 AddVectors(simd_float3 v1, simd_float3 v2) {
    simd_float3 ret;
    ret.x = v1.x + v2.x;
    ret.y = v1.y + v2.y;
    ret.z = v1.z + v2.z;
}

vector_float3 cross_product (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float3 u = vector_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vector_float3 v = vector_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vector_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

float dot_product (vector_float3 p1, vector_float3 p2) {
    return p1.x * p2.x + p1.y * p2.y + p1.z * p2.z;
}

vector_float3 cross_vectors(vector_float3 p1, vector_float3 p2) {
    vector_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

vector_float3 TriAvg (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vector_float3(x, y, z);
}

float acos2(vector_float3 v1, vector_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    simd_float3 cross = cross_vectors(v1, v2);
    float det = sqrt(pow(cross.x, 2) + pow(cross.y, 2) + pow(cross.z, 2));
    return atan2(det, dot);
}

float angle_between (vector_float3 v1, vector_float3 v2) {
    float mag1 = sqrt(pow(v1.x, 2) + pow(v1.y, 2) + pow(v1.z, 2));
    float mag2 = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    
    return acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

bool is_behind_camera (vector_float3 v, constant Camera &camera) {
    // check if there is an obtuse angle between cam vec and vec from cam loc to v
    vector_float3 cam_to_v;
    cam_to_v.x = v.x - camera.pos.x;
    cam_to_v.y = v.y - camera.pos.y;
    cam_to_v.z = v.z - camera.pos.z;
    
    return dot_product(cam_to_v, camera.vector) <= 0;
}

float line_plane_intercept (simd_float3 start, simd_float3 vector, simd_float4 plane) {
    float co = plane.x * vector.x + plane.y * vector.y + plane.z * vector.z;
    float k = plane.w - (plane.x * start.x + plane.y * start.y + plane.z * start.z);
    
    float t = k / co;
    return t;
}

vector_float4 camera_plane(constant Camera &c) {
    vector_float4 plane;
    
    plane.x = c.vector.x;
    plane.y = c.vector.y;
    plane.z = c.vector.z;
    plane.w = (c.pos.x * c.vector.x + c.pos.y * c.vector.y + c.pos.z * c.vector.z);
    
    return plane;
}

vector_float3 clip_vertex (vector_float3 v1, vector_float3 v2, constant Camera &c) {
    vector_float3 start = v1;
    vector_float3 vector;
    vector.x = v2.x - start.x;
    vector.y = v2.y - start.y;
    vector.z = v2.z - start.z;
    
    float t = line_plane_intercept(start, vector, camera_plane(c));
    t *= 0.98;
    
    vector_float3 ret;
    ret.x = start.x + t*vector.x;
    ret.y = start.y + t*vector.y;
    ret.z = start.z + t*vector.z;
    return ret;
}

kernel void ResetVertices (device Vertex *vertices [[buffer(0)]], unsigned int vid [[thread_position_in_grid]]) {
    vertices[vid] = vector_float3(0,0,0);
}

kernel void CalculateModelNodeTransforms(device Node *nodes [[buffer(0)]], unsigned int vid [[thread_position_in_grid]], const constant unsigned int *modelIDs [[buffer(1)]], const constant ModelUniforms *uniforms [[buffer(2)]]) {
    ModelUniforms uniform = uniforms[modelIDs[vid]];
//    vector_float3 offset_node = nodes[vid].b.pos;
//    offset_node.x += uniform.b.pos.x;
//    offset_node.y += uniform.b.pos.y;
//    offset_node.z += uniform.b.pos.z;
//    nodes[vid].pos = RotateAround(offset_node, uniform.rotate_origin, uniform.angle);
    nodes[vid].b.pos = TranslatePointToStandard(uniform.b, nodes[vid].b.pos);
    nodes[vid].b.x = RotatePointToStandard(uniform.b, nodes[vid].b.x);
    nodes[vid].b.y = RotatePointToStandard(uniform.b, nodes[vid].b.y);
    nodes[vid].b.z = RotatePointToStandard(uniform.b, nodes[vid].b.z);
    
//    nodes[vid].angle.x += uniform.angle.x;
//    nodes[vid].angle.y += uniform.angle.y;
//    nodes[vid].angle.z += uniform.angle.z;
}

kernel void CalculateVertices(device Vertex *vertices [[buffer(0)]], const constant NodeVertexLink *nvlinks [[buffer(1)]], unsigned int vid [[thread_position_in_grid]], const constant Node *nodes [[buffer(2)]]) {
    Vertex v = vector_float3(0,0,0);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        Node n = nodes[link1.nid];
        
//        Vertex desired1 = vector_float3(n.pos.x + link1.vector.x, n.pos.y + link1.vector.y, n.pos.z + link1.vector.z);
//        desired1 = RotateAround(desired1, n.pos, n.angle);
        Vertex desired1 = TranslatePointToStandard(n.b, link1.vector);
        
        v.x += link1.weight*desired1.x;
        v.y += link1.weight*desired1.y;
        v.z += link1.weight*desired1.z;
    }
    
    if (link2.nid != -1) {
        Node n = nodes[link2.nid];
        
//        Vertex desired2 = vector_float3(n.pos.x + link2.vector.x, n.pos.y + link2.vector.y, n.pos.z + link2.vector.z);
//        desired2 = RotateAround(desired2, n.pos, n.angle);
        Vertex desired2 = TranslatePointToStandard(n.b, link2.vector);
        
        v.x += link2.weight*desired2.x;
        v.y += link2.weight*desired2.y;
        v.z += link2.weight*desired2.z;
    }
    
    vertices[vid] = v;
}

kernel void CalculateClippings(device Face *new_faces [[buffer(0)]], device Vertex *new_vertices [[buffer(1)]], const constant Face *faces [[buffer(2)]], const constant Vertex *vertices [[buffer(3)]], constant Camera &camera [[buffer(4)]], constant SceneCounts *scene_counts [[buffer(5)]], unsigned int fid [[thread_position_in_grid]]) {
    // operate per face
    // if the face has one vertex that goes behind the camera, make 1 new face and 2 new vertices for lines intersections
    // if the face has two vertices that go behind the camera, make two new vertices for lines intersections
    
    // new faces is size of faces * 2
    // new vertices is size of vertices + size of faces * 2
    // index of new vertices = size of vertices + index of face * 2 (+1)
    
    // from onwards use new faces and new vertices
    
    Face f = faces[fid];
    int num_behind = 0;
    bool is_behind[3];
    
    for (int i = 0; i < 3; i++) {
        if (is_behind_camera(vertices[f.vertices[i]], camera)) {
            num_behind++;
            is_behind[i] = true;
        } else {
            is_behind[i] = false;
        }
    }
    
    // add original vertices to new vertices
    new_vertices[f.vertices[0]] = vertices[f.vertices[0]];
    new_vertices[f.vertices[1]] = vertices[f.vertices[1]];
    new_vertices[f.vertices[2]] = vertices[f.vertices[2]];
    
    // default newface
    Face newface;
    newface.vertices[0] = -1;
    newface.vertices[1] = -1;
    newface.vertices[2] = -1;
    
    if (num_behind == 1) {
        int bv = -1;
        int fv1 = -1;
        int fv2 = -1;
        if (is_behind[0]) {
            bv = 0;
            fv1 = 1;
            fv2 = 2;
        } else if (is_behind[1]) {
            bv = 1;
            fv1 = 0;
            fv2 = 2;
        } else {
            bv = 2;
            fv1 = 0;
            fv2 = 1;
        }
        
        // get new vertices and add to new vertices list
        vector_float3 newv1 = clip_vertex(vertices[f.vertices[fv1]], vertices[f.vertices[bv]], camera);
        vector_float3 newv2 = clip_vertex(vertices[f.vertices[fv2]], vertices[f.vertices[bv]], camera);
        
        new_vertices[scene_counts->num_vertices+(fid*2)] = newv1;
        new_vertices[scene_counts->num_vertices+(fid*2)+1] = newv2;
        
        // change first face
        f.vertices[bv] = scene_counts->num_vertices+(fid*2);
        
        // change new face
        newface = f;
        newface.vertices[0] = scene_counts->num_vertices+(fid*2);
        newface.vertices[1] = scene_counts->num_vertices+(fid*2)+1;
        newface.vertices[2] = f.vertices[fv2];
    } else if (num_behind == 2) {
        int fv = -1;
        int bv1 = -1;
        int bv2 = -1;
        if (!is_behind[0]) {
            fv = 0;
            bv1 = 1;
            bv2 = 2;
        } else if (!is_behind[1]) {
            fv = 1;
            bv1 = 0;
            bv2 = 2;
        } else {
            fv = 2;
            bv1 = 0;
            bv2 = 1;
        }
        
        // get new vertices and add to new vertices list
        vector_float3 newv1 = clip_vertex(vertices[f.vertices[fv]], vertices[f.vertices[bv1]], camera);
        vector_float3 newv2 = clip_vertex(vertices[f.vertices[fv]], vertices[f.vertices[bv2]], camera);
        
        new_vertices[scene_counts->num_vertices+(fid*2)] = newv1;
        new_vertices[scene_counts->num_vertices+(fid*2)+1] = newv2;
        
        // change first face
        f.vertices[bv1] = scene_counts->num_vertices+(fid*2);
        f.vertices[bv2] = scene_counts->num_vertices+(fid*2)+1;
    } else {
        vector_float3 blankv;
        blankv.x = 100000000;
        blankv.y = 100000000;
        blankv.z = 100000000;
        
        new_vertices[scene_counts->num_vertices+(fid*2)] = blankv;
        new_vertices[scene_counts->num_vertices+(fid*2)+1] = blankv;
    }
    
    new_faces[fid] = f;
    new_faces[scene_counts->num_faces + fid] = newface;
}

kernel void CalculateProjectedVertices(device vector_float3 *output [[buffer(0)]], const constant Vertex *vertices [[buffer(1)]], unsigned int vid [[thread_position_in_grid]], constant Camera &camera [[buffer(2)]]) {
    output[vid] = PointToPixel(vertices[vid], camera);
}

kernel void CalculateFaceLighting(device Face *output [[buffer(0)]], const constant Face *faces[[buffer(1)]], const constant Vertex *vertices [[buffer(2)]], const constant Vertex *light[[buffer(3)]], unsigned int fid[[thread_position_in_grid]]) {
    Face f = faces[fid];
    vector_float3 f_norm = cross_product(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    if (f.normal_reversed) {
        f_norm.x *= -1;
        f_norm.y *= -1;
        f_norm.z *= -1;
    }
    Vertex center = TriAvg(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    vector_float3 vec_to = vector_float3(light->x - center.x, light->y - center.y, light->z - center.z);
    float ang = abs(acos2(f_norm, vec_to));
    f.color.x /= ang * f.shading_multiplier;
    f.color.y /= ang * f.shading_multiplier;
    f.color.z /= ang * f.shading_multiplier;
    
    output[fid] = f;
}

vertex VertexOut DefaultVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], const constant Face *face_array[[buffer(1)]], unsigned int vid [[vertex_id]]) {
    Face currentFace = face_array[vid/3];
    VertexOut output;
    if (currentFace.vertices[vid%3] == (unsigned int)-1) {
        output.pos = vector_float4(0,0,-1,1);
    } else {
        vector_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
        output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
        output.color = currentFace.color;
    }
    return output;
}

fragment vector_float4 FragmentShader(VertexOut interpolated [[stage_in]]){
    return interpolated.color;
}
