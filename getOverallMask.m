function imDisplay = getOverallMask(imDisplay, maskDisplay)



TMP = imDisplay(:,:,1); TMP(maskDisplay==1) = 255; imDisplay(:,:,1) = TMP; 
TMP = imDisplay(:,:,2); TMP(maskDisplay==1) = 0; imDisplay(:,:,2) = TMP;
TMP = imDisplay(:,:,3); TMP(maskDisplay==1) = 0; imDisplay(:,:,3) = TMP;