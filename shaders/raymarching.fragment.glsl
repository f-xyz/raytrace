#define pi           3.14159265
#define MAX_STEPS    100.0
#define MAX_PATH     100.0
#define MIN_PATH     1e-2
#define REFLECTIONS  1.0
#define NORMAL_DELTA 1e-2

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

float box(vec3 v, vec3 size) {
    return length(max(abs(v)-size, 0.));
}

vec3 warp(vec3 v, float amount) {
    float c = cos(amount*v.y);
    float s = sin(amount*v.y);
    mat2 m = mat2(c, -s, s, c);
    vec3 q = vec3(m*v.xz, v.y);
    return q;
}

float world(vec3 v) {
    vec3 vRotated = warp(v, sin(time) + 1.);
    return min(
//        length(v + vec3(0., sin(time), 0.)) - 1.,
        box(vRotated + vec3(0., 0., 0.), vec3(.5)),
        v.y + 2.
    );
}

float trace(vec3 ro, vec3 rd, float offset) {
    float path = offset;
    for (float i = 0.; i < MAX_STEPS; ++i) {
        float d = world(ro + rd*path);
        path += d;
        if (d < /*path**/MIN_PATH) break;
    }
    return path;
}

vec3 getNormal(vec3 v) {
    vec2 e = vec2(NORMAL_DELTA, 0.);
    float w = world(v);
    return normalize(vec3(
        world(v+e.xyy) - w,
        world(v+e.yxy) - w,
        world(v+e.yyx) - w
    ));
}

vec4 getLight(vec3 v, vec3 normal, vec4 diffuse, vec4 color, vec3 pos) {
    vec3 lightDir = pos - v;
    if (trace(v, normalize(lightDir), 1.) < length(lightDir)) {
        return vec4(0., 0., 0., 1.);
    }
    return diffuse*color*max(0., dot(normal, normalize(lightDir))) / dot(lightDir, lightDir);
}

float getAmbientOcclusion(vec3 v, vec3 normal) {
    float light = 0.;
    for (float i = 0.; i < 4.; ++i) {
        float path = 0.1*i;
        float d = world(v + normal*path);
        light += max(0., path - d);
    }
    return min(light, 1.);
}

void main() {

    float ratio = resolution.x/resolution.y;
    vec2 uv = 2.*gl_FragCoord.xy/resolution - 1.;
//    uv.x *= ratio;

//    vec3 ro = vec3(2., 0., 2.)/**mat3(
//        sin(mouse.x*pi), 0., cos(mouse.x*pi),
//        cos(mouse.x*pi), 0, -sin(mouse.x*pi),
//        0., 0., 0.
//    )*/;
//    ro.x = 2.*sin(time);
//    ro.z = 2.*sin(time);
//    vec3 rd = normalize(vec3(uv, -1.));
//    vec3 rd = normalize(vec3(uv, -1.));

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(0.0, 2.0, 2.0);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

//    gl_FragColor = vec4(mouse.x/2.+.5, mouse.y/2.+.5, 0., 1.);
//    return;

    // mouse
    float dist = 2.0;
    eye.x = dist*sin(mouse.x*pi);
    eye.z = dist*cos(mouse.x*pi) ;
    eye.y = 1.0 + sin(mouse.y);

    // camera path
//    float amp = 4.0;
//    eye.x = amp*cos(time*.3);// + amp*cos(time*speed);
//    eye.z = amp*sin(time*.1);// - amp*sin(time*speed);
//    eye.y = 4.+2.*abs(cos(time/10.0));

    vec3 forward = normalize(lookAt - eye);
    vec3 x = normalize(cross(up, forward));
    vec3 y = cross(forward, x);
    vec3 o = eye + forward; // screen center
    vec3 ro = o + uv.x*x*ratio + uv.y*y; // ray origin
    vec3 rd = normalize(ro - eye); // ray direction

    //
    float path = trace(ro, rd, 0.);
    vec3 v = ro + rd*path;
    vec3 normal = getNormal(v);
    vec3 lightPos = vec3(1, .5, 2);
    vec3 lightDir = lightPos - v;
    vec4 pointLight = getLight(v, normal, vec4(1,0,1,1), vec4(1,0,1,1), lightPos);

//    float ambientOcclusion = getAmbientOcclusion(v, normal);
//    vec4 ambientLight = vec4(0.1-ambientOcclusion);

    gl_FragColor = 10.*(pointLight)*vec4(path/5.+ambientLight*/);

}