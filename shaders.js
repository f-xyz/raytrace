define(function (require, exports, module) {
    'use strict';

    module.exports = {
        vertex: {
            projection: require('text!./shaders/raymarching.vertex.glsl')
        },
        fragment: {
            upstream: require('text!./shaders/raymarching.fragment.glsl'),
            cube: require('text!./shaders/cube.fragment.glsl'),
            spongebob: require('text!./shaders/spongebob.fragment.glsl'),
            mountains: require('text!./shaders/mountains.fragment.glsl'),
            night: require('text!./shaders/night.fragment.glsl'),
            refraction: require('text!./shaders/refraction.fragment.glsl')
        }
    };

});