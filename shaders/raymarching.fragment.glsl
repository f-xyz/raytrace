#define pi           3.14159265
#define MAX_STEPS    200.0
#define MAX_PATH     40.0
#define MIN_PATH     1e-2
#define REFLECTIONS  1.0
#define NORMAL_DELTA 1e-1

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

struct intersection {
    float path;
    float material;
    float power;
};

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

intersection join(intersection a, intersection b) {
    float d = a.path - b.path;
    if (d < 0.) return a;
    else return b;
}

intersection world(vec3 v) {
    vec3 vBox = v;//warp(v.yzx, sin(time)/4.);
    float s = sin(time/2.);
    float c = cos(time/2.);
    vBox *= mat3(
        s,  c,  0,
        c, -s,  0,
        0,  0,  1
    );

    intersection box;
    box.path = max(
        signedBox(vBox, vec3(2.5)),
        -cross(vBox, 2.4)
    );
    box.material = 0.;
    box.power = 1.;

    intersection plane;
    plane.path = v.y + 10.;
    plane.material = 1.;
    plane.power = 1.;

    return join(box, plane);
}

intersection trace(vec3 ro, vec3 rd, float offset) {
    intersection w;
    float path = offset;
    for (float i = 0.; i < MAX_STEPS; ++i) {
        w = world(ro + rd*path);
        path += w.path;
        if (w.path < path*MIN_PATH) break;
        if (path > MAX_PATH) break;
    }
    w.path = path;
    return w;
}

vec3 getNormal(vec3 v) {
    vec2 e = vec2(NORMAL_DELTA, 0.);
    float d = world(v).path;
    return normalize(vec3(
        world(v+e.xyy).path - d,
        world(v+e.yxy).path - d,
        world(v+e.yyx).path - d
    ));
}

vec4 getLight(vec3 v, vec3 normal, vec4 diffuse, vec4 color, vec3 pos) {
    vec3 lightDir = pos - v;
    if (trace(v, normalize(lightDir), 0.1).path < length(lightDir)) {
        return vec4(0., 0., 0., 1.);
    }
    return diffuse * color * max(0., dot(normal, normalize(lightDir)))
//      / dot(lightDir, lightDir) // pointLight
    ;
}

float getAmbientOcclusion(vec3 v, vec3 normal) {
    float light = 0.;
    for (float i = 0.; i < 4.; ++i) {
        float path = 0.1*i;
        float d = world(v + normal*path).path;
        light += max(0., path - d);
    }
    return min(light, 1.);
}

void main() {

    float ratio = resolution.x/resolution.y;
    vec2 uv = 2.*gl_FragCoord.xy/resolution - 1.;

    float eyeDist = 5.0;

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(eyeDist, eyeDist, eyeDist);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

    // camera path
    float amp = 4.0;
    eye.x = amp*cos(time*.3);// + amp*cos(time*speed);
    eye.z = amp*sin(time*.1);// - amp*sin(time*speed);
    eye.y = amp+abs(cos(time/10.0));

    // mouse
//    eye.x = eyeDist*sin(mouse.x*pi);
//    eye.z = eyeDist*cos(mouse.x*pi);
//    eye.y = eyeDist + eyeDist*sin(mouse.y*pi/2.);

    vec3 forward = normalize(lookAt - eye);
    vec3 x = normalize(cross(up, forward));
    vec3 y = cross(forward, x);
    vec3 o = eye + forward; // screen center
    vec3 ro = o + uv.x*x*ratio + uv.y*y; // ray origin
    vec3 rd = normalize(ro - eye); // ray direction

    //
    intersection w = trace(ro, rd, 0.);
    vec3 v = ro + rd*w.path;
    vec3 normal = getNormal(v);
    vec3 lightPos = vec3(0., 7., 0.);
    vec3 lightDir = lightPos - v;
    vec4 pointLight = getLight(v, normal, vec4(1,1,1,1), vec4(1,1,1,1), lightPos);

//    float ambientOcclusion = getAmbientOcclusion(v, normal);
//    vec4 ambientLight = vec4(0.0/* - ambientOcclusion*/);

    if (w.material == 0.) {
        gl_FragColor = w.path*pointLight*vec4(1.4, 1.6, 1.1, 1.);
    } else if (w.material == 1.) {
        gl_FragColor = w.path*pointLight*vec4(.8, .6, .4, 1.);
    }

    // fade
    vec4 bg = vec4(sin(uv.x), .3, cos(uv.x), 1.);
    gl_FragColor = mix(0.2*gl_FragColor, bg, smoothstep(0., 20., w.path));
    gl_FragColor = mix(gl_FragColor, bg, 0.6);

}
