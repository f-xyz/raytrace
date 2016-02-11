#define pi           3.14159265
#define MAX_STEPS    40.0
#define MAX_PATH     100.0
#define MIN_PATH     1e-2
#define REFLECTIONS  3.0

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

struct intersection {
    float path;
    float material;
    float reflectivity;
    float opacity;
    vec3 voxel;
};

float sphere(vec3 v, float r) {
    return length(v) - r;
}

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
        signedBox(q, vec3(1.)),
       -cross(q, 0.2)
    );
}

intersection smoothJoin(intersection a, intersection b, float k) { // k = 0.1 is good
    float aPath = -log(exp(-k*a.path) + exp(-k*b.path)) / k;
    float bPath = -log(exp(-k*a.path) + exp(-k*b.path)) / k;
    intersection res;
    if (max(aPath, -bPath) == aPath) {
        res = a;
        res.path = aPath;
    } else {
        res = b;
        res.path = bPath;
    }
    return res;
}

intersection world(vec3 v) {
    vec3 vRotated = v;
    float s = sin(time/10.);
    float c = cos(time/10.);
    vRotated *= mat3(
        s,  c,  0,
        c, -s,  0,
        0,  0,  1
    ) * mat3(
        s,  0,  c,
        0,  1,  0,
        c,  0, -s
    );

    // sphere(v + vec3(0., 0., 10.), 4.)

    //
    intersection stuff;
    stuff.path = max(
        signedBox(vRotated + vec3(0., 0., 0.), vec3(4.)),
       -cross(vRotated + vec3(0., 0., 10.), 3.0)
    );
    stuff.material = 0.;
    stuff.reflectivity = 1.;
    stuff.opacity = 1.3;

    return stuff;

    // waves
//    vec3 vWave = v;
//    vWave.y += .3*sin(v.x+time);

    float mtime = time/4.;
    vec3 wv = v;
    wv.y +=
        .4*sin(1.*wv.z - 5.*mtime)
//      + .2*sin(wv.x)/* * fnoise(mtime*wv.yx/100.)*/
    ;

    // ground
    intersection plane;
    plane.path = v.y + 20.;
    plane.material = 2.;
    plane.reflectivity = 1.;
    plane.opacity = 1.;

    return join(stuff, plane);
}

intersection trace(vec3 ro, vec3 rd, float offset) {
    intersection w;
    vec3 voxel;
    float path = offset;
    for (float i = 0.; i < MAX_STEPS; ++i) {
        voxel = ro + rd*path;
        w = world(voxel);
        path += w.path;
        if (w.path < path*MIN_PATH) break;
        if (path > MAX_PATH) break;
    }
    w.path = path;
    w.voxel = voxel;
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

vec4 getDirLight(vec3 v, vec3 normal, vec3 pos) {
    vec3 lightDir = pos - v;
    if (trace(v, normalize(lightDir), 0.1).path < length(lightDir)) {
        return vec4(0.);
    }
    return vec4(1.) * abs(dot(normal, normalize(lightDir)))
//      / dot(lightDir, lightDir) // pointLight ~ 1/r^2
    ;
}

vec4 getMaterial(intersection w, vec4 light) {
    vec4 color = vec4(1.);

    if (w.material == 0.) {

        color = light * vec4(.4, .6, .1, 1.);

    } else if (w.material == 1.) {

        if (light == vec4(0.)) {
            light = vec4(.1);
        }

        if (fract(w.voxel.x) < 0.2
        ||  fract(w.voxel.z) < 0.2) {
            color = light * vec4(.4, .6, .8, 1.);
        } else {
            color = light * vec4(.2);
        }

    } else if (w.material == 2.) {

        color = light * vec4(.0, .5, .7, 1.);

    }

    return color;
}

void main() {

    float ratio = resolution.x / resolution.y;
    vec2 uv = 2. * gl_FragCoord.xy / resolution - 1.;

    float eyeDist = 10.0;

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(0.0, 0.0, eyeDist);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

    // camera path
    eye.x = eyeDist*(sin(pi*(mouse.x/2.+.5)));
    eye.z = eyeDist*(cos(pi*(mouse.x/2.+.5)));
    eye.y = 2. + 10.*mouse.y;

    vec3 forward = normalize(lookAt - eye);
    vec3 x = normalize(cross(up, forward));
    vec3 y = cross(forward, x);
    vec3 o = eye + forward; // screen center
    vec3 ro = o + uv.x*x*ratio + uv.y*y; // ray origin
    vec3 rd = normalize(ro - eye); // ray direction

    // clear
    vec4 bg = vec4(.0, .0, -uv.y, 1.);
    gl_FragColor = vec4(0.);

    //
    for (float i = 0.; i < REFLECTIONS; ++i) {
        intersection w = trace(ro, rd, 0.);

        if (w.path < 0.) break;
        if (w.path > MAX_PATH) {
            if (i == 0.) gl_FragColor = bg;
            break;
        };

        vec3 v = ro + rd*w.path;
        vec3 normal = getNormal(v);
        vec3 lightPos = vec3(0., 40., -40.);
        vec3 lightDir = lightPos - v;
        vec4 dirLight = getDirLight(v, normal, lightPos);

//        float ambientOcclusion = getAmbientOcclusion(v, normal);
//        vec4 ambientLight = vec4(0.6 - ambientOcclusion);

        float reflectivity = (REFLECTIONS - i) / REFLECTIONS;
        vec4 color = getMaterial(w, dirLight);
        gl_FragColor += reflectivity * /*w.opacity **/ color;

        // fog
        if (i == 0.) {
            gl_FragColor = mix(gl_FragColor, bg, smoothstep(0., MAX_PATH, w.path));
        }

        break;

        // reflection
        rd = normalize(reflect(rd, normal));
        ro = v + 2.*rd*MIN_PATH;
    }
}