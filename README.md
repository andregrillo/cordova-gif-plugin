cordova-gif-plugin


Saving a gif:
````
cordova.plugins.IndigoGifPlugin.saveGifToPhotoAlbum(function(s){alert("sucesso: " + s)},function(e){alert("error: " + e)},"http://www.personal.psu.edu/crd5112/photos/GIF%20Example.gif");
````

Sharing a gif:
`````
cordova.plugins.IndigoGifPlugin.shareGif(function(s){alert("sucesso: " + s)},function(e){alert("error: " + e)},"data:image/gif;base64,<BASE64-STRING>");
`````


