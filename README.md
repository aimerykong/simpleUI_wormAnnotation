# simpleUI_wormAnnotation
This is a simple UI for annotating C. elegans in images. 

An user is expected to click on the worm tips (head and tail, order does not matter), then a chain model is used with dynamic programming to sketch out the worm body by automatically localizing 10 parts/points on the body. 


Please run "extractWormBody_interface_V1.m" to have a clear idea how it works. An output is like the following -- 

![alt text](https://github.com/aimerykong/simpleUI_wormAnnotation/blob/master/dataset/img005.tif_tif2jpg.jpg "output")
