define(function (require, exports, module) {
    'use strict';

    var hash = location.hash.replace(/^#/, '').split('/');
    console.log(hash);

    hash.forEach(function (x) {
        var pair = x.match(/^(.+):(.+)$/);
        if (pair) {
            module.exports[pair[1]] = pair[2];
        } else {
            module.exports[x] = true;
        }

    });

});