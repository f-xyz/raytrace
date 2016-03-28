define(function(require, exports, module) {
    'use strict';

    // todo: show fps meter and shader selector if #debug param is true only

    var gl = require('three');
    var Stats = require('stats');
    var routing = require('./routing');
    var shaders = require('./shaders');

    var stats = new Stats();
    document.body.appendChild(stats.domElement);

    var size = new gl.Vector2(innerWidth, innerHeight)
        .divideScalar(routing.hd ? 1 : 2);
    var config = new gl.Vector3(1000, 0, 0);
    var isRunning = false;
    var time = 0;
    var mouse = new gl.Vector2(0, 0);

    var canvas = document.querySelector('canvas');
    var renderer = new gl.WebGLRenderer({ canvas: canvas });
    renderer.setSize(size.x, size.y);

    var camera = new gl.PerspectiveCamera(45, size.x/size.y, 0.1, 100);
    camera.position.set(0, 0, 1);
    camera.lookAt(new gl.Vector3(0, 0, 0));

    var scene = new gl.Scene();
    var shader = new gl.ShaderMaterial({
        vertexShader:   shaders.vertex.projection,
        fragmentShader: shaders.fragment[routing.shader || 'upstream'],
        uniforms: {
            time: { type: 'f', value: 0 },
            resolution: { type: 'v2', value: size },
            mouse: { type: 'v2', value: mouse },
            config: { type: 'v3' }
        }
    });

    var box = new gl.Mesh(new gl.BoxGeometry(1, size.y/size.x, 1), shader);
    scene.add(box);

    console.time('render');
    renderer.render(scene, camera);
    console.timeEnd('render');

    var selectShader = document.getElementById('select-shader');
    selectShader.value = routing.shader || 'upstream';
    selectShader.addEventListener('change', onShaderChanged);

    if (routing.start) {
        start();
    }

    console.log('done');

    ///////////////////////////////////

    // todo
    module.exports = {
        size, config, isRunning,
        start, stop
    };

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
        console.log('keyup', e.keyCode);
    }

    function onMouseMove(e) {
        mouse.x = e.clientX/window.innerWidth;
        mouse.y = e.clientY/window.innerHeight;
        mouse.multiplyScalar(2);
        mouse.addScalar(-1);
        if (!isRunning) {
            render();
        }
        console.log('mousemove', mouse.x, mouse.y);
    }

    function onCLick() {
        console.log('click');
        if (isRunning) {
            stop();
        } else {
            start();
        }
    }

    function onShaderChanged() {
        console.log('onShaderChanged', selectShader.value);
        shader.fragmentShader = shaders.fragment[selectShader.value];
        shader.needsUpdate = true;
        setHash();
        render();
    }

    ///////////////////////////////////

    function setHash() {
        var hash = [];
        hash.push('shader:' + selectShader.value);
        if (routing.start) hash.push('start');
        if (routing.hd) hash.push('hd');
        location.hash = hash.join('/');
    }

    ///////////////////////////////////

    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    window.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('click', onCLick);

});
