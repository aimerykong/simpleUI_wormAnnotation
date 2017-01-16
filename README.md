# simpleUI_wormAnnotation
This is a simple UI for annotating C. elegans in images. 

An user is expected to click on the worm tips (head and tail, order does not matter), then a chain model is used with dynamic programming to sketch out the worm body by automatically localizing 10 parts/points on the body. 

Please run "extractWormBody_interface_V1.m" to have a clear idea how it works. An input image is like the following -- 

![alt text](https://github.com/aimerykong/simpleUI_wormAnnotation/blob/master/dataset/img005.tif_tif2jpg.jpg "output")

step-1: roughly click the center of a worm, then a zoom-in window pops out;
step-2: click the worm tips (i.e. head and tail, order does not matter), then a line is drawn along the worm body;
step-3: double check by visualization, if the line is a good fit for the target worm, click "Yes"; if not, manually click ten parts which are expected to uniformly distribute on the body, then a line connecting the parts is draw to fit the worm. If the line is not good, or user mis-click somewhere, click "cancel" button to return the main image

All the steps are repeated ten times, meaning 10 worms are expected to annotate for one run.

Shu Kong @ UCI
