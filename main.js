define(function(require/*, exports, module*/) {
    'use strict';

    var gl = require('three');
    var Stats = require('stats');

    var stats = new Stats();
    document.body.appendChild(stats.domElement);

    var size = new gl.Vector2(innerWidth, innerHeight)
        .divideScalar(isHD() ? 1 : 2);
    var config = new gl.Vector3(1000, 0, 0); // iterations / not used / not used
    var isRunning = false;
    var time = 0;

    var canvas = document.querySelector('canvas');
    var renderer = new gl.WebGLRenderer({ canvas: canvas });
    renderer.setSize(size.x, size.y);

    var camera = new gl.PerspectiveCamera(45, size.x/size.y, 0.1, 100);
    camera.position.set(0, 0, 1);
    camera.lookAt(new gl.Vector3(0, 0, 0));

    var scene = new gl.Scene();
    var shader = new gl.ShaderMaterial({
        vertexShader:   require('text!./shaders/raymarching.vertex.glsl'),
        fragmentShader: require('text!./shaders/raymarching.fragment.glsl'),
        uniforms: {
            time: { type: 'f', value: 0 },
            resolution: { type: 'v2', value: size },
            config: { type: 'v3' }
        }
    });

    var box = new gl.Mesh(new gl.BoxGeometry(1, size.y/size.x, 1), shader);
    scene.add(box);
    renderer.render(scene, camera);

    if (shouldAutoStart()) {
        start();
    }

    ///////////////////////////////////

    function start() {
        console.log('start');
        config.x = 100;
        isRunning = true;
        time = Date.now();
        loop();
    }

    function stop() {
        console.log('stop');
        config.x = 1000;
        isRunning = false;
        render();
    }

    function loop() {
        stats.begin();
        if (isRunning) {
            requestAnimationFrame(loop);
            step();
            render();
        }
        stats.end();
    }

    function step() {
        var now = Date.now();
        shader.uniforms.time.value += (now - time) / 1000;
        time = now;
    }

    function render() {
        renderer.render(scene, camera);
    }

    ///////////////////////////////////

    function onKeyDown(e) {
        switch (e.keyCode) {
            case 87: // w
                break;
            case 83: // s
                break;
            case 65: // a
                break;
            case 68: // d
                break;
            case 38: // up
                break;
            case 40: // down
                break;
        }
    }

    function onKeyUp(e) {
        switch (e.keyCode) {
            case 32: // space
                if (isRunning) {
                    stop();
                } else {
                    start();
                }
                break;
        }
        console.log(e.keyCode);
    }

    ///////////////////////////////////

    addEventListener('keydown', onKeyDown);
    addEventListener('keyup', onKeyUp);

    ////////////////////////////////////

    function isHD() {
        return location.hash.match(/hd/);
    }

    function shouldAutoStart() {
        return location.hash.match(/start/);
    }

});
