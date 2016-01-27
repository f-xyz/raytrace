#define PI              3.14159265
#define MAX_STEPS       128.0
#define MAX_PATH        100.0
#define MIN_PATH_DELTA  1e-2
#define REFLECTIONS     2.0
#define NORMAL_DELTA    1e-2

uniform float time;
uniform float seed;
uniform vec2 resolution;
uniform vec2 mouse;
uniform sampler2D tex;
uniform sampler2D backbuffer;

float plane(vec3 v, float y) { return v.y + y; }
float sphere(vec3 v, float r) { return length(v) - r; }

vec3 join(vec3 a, vec3 b) {
    float d = a.x - b.x;
    return d < 0.0 ? a : b;
}

float hash(float seed) {
    return fract(sin(seed)*94565.6547);
}

float hash(vec2 seed) {
    return hash(dot(seed, vec2(456.133, 231.654)));
}

float noise(vec2 seed) {
    vec2 F = floor(seed);
    vec2 f = fract(seed);
    vec2 e = vec2(1.0, 0.0);

    f *= f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(F + e.yy), hash(F + e.xy), f.x),
        mix(hash(F + e.yx), hash(F + e.xx), f.x), f.y);
}

float fnoise(vec2 seed) {
    seed += vec2(12.0);
    return 0.5 * noise(seed)
         + 0.25 * noise(seed * 1.97)
         + 0.125 * noise(seed * 4.04)
         + 0.0625 * noise(seed * 8.17)
    ;
}

vec3 world(vec3 v) {
    float mtime = time / 4.0;
    vec3 wv = v;
    wv.y +=
        0.1 * sin(2.0*wv.z - 5.0*mtime)
      + 0.1 * sin(wv.x) * fnoise(mtime*wv.yx/100.)
    ;
    return join(
        vec3(sphere(v + vec3(-5.0, -8.0, 10.0 + MAX_PATH), 20.0), 1.0, 0.0),
        vec3(plane(wv, 10.0), 2.0, 1.0));
}

void main() {

    vec2 pos01 = gl_FragCoord.xy / resolution;
    vec2 pos = 2.*pos01 - 1.; // [-1; 1]
    float ratio = resolution.x / resolution.y;

    vec3 up     = vec3(0.0, 1.0, 0.0);
    vec3 eye    = vec3(0.0, 4.0, 4.0);
    vec3 lookAt = vec3(0.0, 3.0, 0.0);

    vec3 forward = normalize(lookAt - eye);
    vec3 x = normalize(cross(up, forward));
    vec3 y = cross(forward, x);
    vec3 o = eye + forward; // screen center
    vec3 ro = o + pos.x*x*ratio + pos.y*y; // ray origin
    vec3 rd = normalize(ro - eye); // ray direction

    //

    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

    // stars

    float starProbability = hash(pos);
    if (starProbability < 0.001) {
        gl_FragColor = vec4(0.2);
    }

    //

    float depth = 0.0; // eq. ray path length
    vec2 gradientDelta = vec2(NORMAL_DELTA, 0.0);
    vec3 normal;
    vec3 voxel;
    float materialId;
    vec4 diffuseColor;
    float rayPower = 1.0;

    for (float iReflection = 0.0; iReflection < REFLECTIONS; iReflection++)
        for (float iStep = 0.0; iStep < MAX_STEPS; ++iStep) {
            voxel = ro + depth * rd; // calc current voxel
            vec3 intersection = world(voxel);
            float d = intersection.x; // distance to the closest surface
            depth += d;
            materialId = intersection.y; // material ID

            if (d < MIN_PATH_DELTA) { // the ray hits

                normal = normalize(vec3(
                    world(voxel + gradientDelta.xyy).x - world(voxel - gradientDelta.xyy).x,
                    world(voxel + gradientDelta.yxy).x - world(voxel - gradientDelta.yxy).x,
                    world(voxel + gradientDelta.yyx).x - world(voxel - gradientDelta.yyx).x));

                rd = normalize(reflect(rd, normal));
                ro = voxel + 2.0 * MIN_PATH_DELTA * rd;

                vec3 light = eye;
                float phong = max(0.0, dot(normal, normalize(light.xyz - voxel)));

                if (materialId == 1.0) {
                    diffuseColor = 4.0 * fnoise(4.0*pos) * vec4(0.6, 0.5, 0.4, 1.0);
                } else if (materialId == 2.0) {
                    diffuseColor = 0.2 * vec4(0.2, 0.6, 0.8, 1.0);
                }

                vec4 c = rayPower * diffuseColor * phong;
                if (iReflection == 0.0) {
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                }

                if (materialId == 2.0) {
                    float q = depth / MAX_PATH;
                    gl_FragColor += mix(c, vec4(0, 0, 0, 1), q);
                } else {
                    gl_FragColor += c;
                }

                rayPower = intersection.z;
                break;

            } else if (depth > MAX_PATH) {
               break;
            }
        }

    // fog

    gl_FragColor += 0.4*fnoise(pos+sin(0.1*time));
}