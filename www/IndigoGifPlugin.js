var exec = require('cordova/exec');

exports.saveGifToPhotoAlbum = function (success, error, arg) {
    exec(success, error, 'IndigoGifPlugin', 'saveGifToPhotoAlbum', [arg]);
};

exports.shareGif = function (success, error, arg) {
    exec(success, error, 'IndigoGifPlugin', 'shareGif', [arg]);
};