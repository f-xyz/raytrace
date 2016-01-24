#define pi           3.14159265
#define MAX_STEPS    40.0
#define MAX_PATH     20.0
#define MIN_PATH     1e-2
#define REFLECTIONS  2.0

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

struct intersection {
    float path;
    float material;
    float reflectivity;
};

//float box(vec3 v, vec3 size) {
//    return length(max(abs(v)-size, 0.));
//}

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

float repeatedStuff(vec3 v) {
    vec3 s = vec3(4.);
    vec3 q = mod(v, s) - .5*s;
    return max(
        signedBox(q, vec3(1.0)),
       -cross(q, 0.2)
    );
}

intersection world(vec3 v) {
    vec3 vBox = v;
//    float s = sin(time/2.);
//    float c = cos(time/2.);
//    vBox *= mat3(
//        s,  c,  0,
//        c, -s,  0,
//        0,  0,  1
//    );

    intersection box;
    box.path = max(
        signedBox(vBox, vec3(8.)),
       -cross(vBox, 2.)
    );
    box.material = 0.;
    box.reflectivity = 1.;

//    return box;

    intersection plane;
    plane.path = v.y + 10.;
    plane.material = 1.;
    plane.reflectivity = 1.;

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
    vec2 e = vec2(MIN_PATH, 0.);
    float d = world(v).path;
    return normalize(vec3(
        world(v+e.xyy).path - d,
        world(v+e.yxy).path - d,
        world(v+e.yyx).path - d
    ));
}

vec4 getLight(vec3 v, vec3 normal, vec4 diffuse, vec4 color, vec3 pos) {
    vec3 lightDir = pos - v;
//    if (trace(v, normalize(lightDir), 0.1).path < length(lightDir)) {
//        return vec4(0., 0., 0., 1.);
//    }
    return diffuse * color * max(0., dot(normal, normalize(lightDir)))
//      / dot(lightDir, lightDir) // pointLight ~ 1 / r^2
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

vec4 getMaterial(intersection w, vec4 light) {
    vec4 color = vec4(0., 0., 0., 1.);
    if (w.material == 0.) {
        color = w.path * light * vec4(1.4, 1.6, 1.1, 1.);
    } else if (w.material == 1.) {
        color = w.path * light * vec4(.8, .6, .4, 1.);
    }
    return color;
}

void main() {

    float ratio = resolution.x/resolution.y;
    vec2 uv = 2.*gl_FragCoord.xy/resolution - 1.;

    float eyeDist = 5.0;

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(0.0, 0.0, 0.0);
    vec3 lookAt = vec3(eyeDist, eyeDist, eyeDist);

    // camera path
    float amp = 4.0;
    lookAt.x = amp*cos(time*.3);
    lookAt.z = amp*sin(time*.1);
    lookAt.y = amp*cos(time/10.);

    // mouse
//    lookAt.x = eyeDist*sin(mouse.x*pi);
//    lookAt.z = eyeDist*cos(mouse.x*pi);
//    lookAt.y = eyeDist + eyeDist*sin(mouse.y*pi/2.);

    vec3 forward = normalize(lookAt - eye);
    vec3 x = normalize(cross(up, forward));
    vec3 y = cross(forward, x);
    vec3 o = eye + forward; // screen center
    vec3 ro = o + uv.x*x*ratio + uv.y*y; // ray origin
    vec3 rd = normalize(ro - eye); // ray direction

    //
    gl_FragColor = vec4(0., 0., 0., 1.);

    //
    for (float i = 0.; i < REFLECTIONS; ++i) {
        intersection w = trace(ro, rd, 0.);

//        if (w.path < 0.) break;

        vec3 v = ro + rd*w.path;
        vec3 normal = getNormal(v);
        vec3 lightPos = vec3(0., 7., 0.);
        vec3 lightDir = lightPos - v;
        vec4 pointLight = getLight(v, normal, vec4(1,1,1,1), vec4(1,1,1,1), lightPos);

//        float ambientOcclusion = getAmbientOcclusion(v, normal);
//        vec4 ambientLight = vec4(0.0/* - ambientOcclusion*/);

        vec4 color = getMaterial(w, pointLight);
        gl_FragColor += /*(REFLECTIONS-i)/REFLECTIONS**/clamp(color, 0., 5.);
//        gl_FragColor.g = w.path/100.;

        // fog
        vec4 bg = vec4(sin(uv.x), .3, cos(uv.x), 1.);
        gl_FragColor = mix(0.2*gl_FragColor, bg, smoothstep(0., 20., w.path));
        gl_FragColor = mix(gl_FragColor, bg, 0.5);

        if (w.path > 20.) break;

        rd = normalize(reflect(rd, normal));
        ro = v + 2.*rd*MIN_PATH;
    }

//    gl_FragColor *= 0.001;

}
