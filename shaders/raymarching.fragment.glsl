#define pi           3.14159265
#define MAX_STEPS    32.0
#define MAX_PATH     10.0
#define MIN_PATH     1e-2
#define REFLECTIONS  1.0
#define NORMAL_DELTA 1e-1

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

float box(vec3 v, vec3 size) {
    return length(max(abs(v)-size, 0.));
}

float signedBox(vec3 v, vec3 size) {
    vec3 d = abs(v) - size;
    return min(max(d.x, max(d.y, d.z)), 0.) +
        length(max(d, 0.));
}

float cross(vec3 v, float size) {
    float inf = 5.; // almost infinity lol
    float da = signedBox(v.xyz, vec3(inf,  size, size));
    float db = signedBox(v.yzx, vec3(size, inf,  size));
    float dc = signedBox(v.zxy, vec3(size, size, inf));
    return min(da, min(db, dc));
}

vec3 warp(vec3 v, float amount) {
    float c = cos(amount*v.y);
    float s = sin(amount*v.y);
    mat2 m = mat2(c, -s, s, c);
    vec3 q = vec3(m*v.xz, v.y);
    return q;
}

float world(vec3 v) {
    vec3 vRotated = v;//warp(v, sin(time)/2.);
    float s = sin(time);
    float c = cos(time);
    vRotated *= mat3(
        s,  c,  0,
        c, -s,  0,
        0,  0,  1
    );
    return min(
        max(
            signedBox(vRotated, vec3(2.)),
            -cross(vRotated, 1.5)
        ),
        v.y + 10.
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
    if (trace(v, normalize(lightDir), 0.1) < length(lightDir)) {
        return vec4(0., 0., 0., 1.);
    }
    return diffuse * color * max(0., dot(normal, normalize(lightDir)))
//         / dot(lightDir, lightDir) // pointLight
    ;
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

    float eyeDistance = 5.0;

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(eyeDistance, eyeDistance, eyeDistance);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

    // mouse
//    eye.x = eyeDistance*sin(mouse.x*pi);
//    eye.z = eyeDistance*cos(mouse.x*pi);
//    eye.y = eyeDistance + eyeDistance*sin(mouse.y*pi/2.);

    // camera path
    float amp = 4.0;
    eye.x = amp*cos(time*.3);// + amp*cos(time*speed);
    eye.z = amp*sin(time*.1);// - amp*sin(time*speed);
    eye.y = amp+abs(cos(time/10.0));

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
    vec3 lightPos = vec3(0., 7., 0.);
    vec3 lightDir = lightPos - v;
    vec4 pointLight = getLight(v, normal, vec4(1,1,1,1), vec4(1,1,1,1), lightPos);

//    float ambientOcclusion = getAmbientOcclusion(v, normal);
//    vec4 ambientLight = vec4(1.0 - ambientOcclusion);

    gl_FragColor = 0.2*(pointLight)*vec4(path/*+ambientLight*/);

    // fog
    gl_FragColor = mix(gl_FragColor, vec4(0.), smoothstep(0., 30., path));

}
