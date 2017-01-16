% ---- worm dataset collection (version 1.0) ----
% click the worm head and tail or body parts to estimate worm body.
% With only the worm head and tail, the body can be estimated by a chain
% model with dynamic programming. While when this method fails, the user
% can choose to click ten parts of the worm, and segments between two
% consecutive parts jointly determine the worm body.
%
% The only thing for a user to contribute is to replace the image name in
% line 33, then run the code again and again, annotating more worms for all
% the images at hand.
%
% To annotate the worm, first click a body, preferrably at the middle of
% worm body, then a zoom-in image will be displayed for clicking the worm
% head and tail. After that, the estimated worm will be displayed to
% indicate how well the method estimates the worm. 
% If the result is good enough, the user can submit the result. If the
% result is not good enough, the user can choose either to return to the
% original image and start to click somewhere else, or click worm body ten
% times in order to manuallly estimate the worm. 
%
%
% Shu Kong
% skong2@uci.edu
% 04/13/2015



clear
close all
clc;

%% parameters and path
filename = 'img005.tif_tif2jpg.jpg';% 2 4 5


numWorm = 2;  % the number of worms required to find by users
radius = 80; % the patch size is of (2*radius+1)x(2*radius+1) pixel resolution

scoreMultiplier = 20; % calibrating the mismatching score
nPart = 14; % the number of parts for chain model to estimate worm body
numParts = nPart+2; % click 10 parts for one worm
partSize = 5; % define the part size
subSize = 3; % define the subsampling straddle
partDist = 4; % partwise distance
numPartMulipleClicking = 10; % the number of clicks required to estimate the worm manually (clicks at worm parts in order)

%% imread and display for clicking
destPath = '.\dataSet_wormBody'; % save the result under this folder
dataPath = '.\dataset'; % the images to estimate worms are under this folder
im = imread( fullfile(dataPath, filename) ); % read image

im = im(1:round(size(im,1)*0.7), round(size(im,1)*0.1):round(size(im,1)*0.8)); % crop the image to a reasonable area
imOrg = im; % backup the original image

mask = zeros(size(imOrg)); % the mask as labels for later use, will be saved along with the estimated worms

imDisplay = repmat(im, [1,1,3]); % to display the estimated worms in the whole original image
maskDisplay = mask; % to display the estimated worms in binary scale with original size

[junk,nameFile,extFile] = fileparts(filename); % get the file name
dirMat = dir( fullfile(destPath, strcat(nameFile, '*.mat')) ); % retrieval all the existing images

wormListAll = {};
for i = 1:numel(dirMat); % merge all the existing masks to visualize how many worms are still needed to estimate
    matTMP = load( fullfile(destPath, dirMat(i).name) ); % load the mask stored in the directory
    maskDisplay = maskDisplay | matTMP.mask; % 'or' operation
    for j = 1:numel(matTMP.wormSetMore{1}.wormFound)
        wormListAll{end+1} = matTMP.wormSetMore{1}.wormFound{j};
    end
end

% display the image in rgb format for better visualization
imDisplay = getOverallMask(imDisplay, maskDisplay);

imOrg = imDisplay;

%% procedure of estimating the worms
wormFound = cell(numWorm,1); % store all the found worms by the user
posWorm = zeros(numWorm, 7); % one row per worm, [center_x, center_y, upperleft_x, upperleft_y, bottomright_x, bottomright_x, num]

countWorm = 0;
retakeFlag = 0; % flag to re-estimate the worm
tenPartClickFlag = 0; % flag to indicate whether the user wants to click ten times manually to estimate the worms

while countWorm < numWorm % get all valid worms    
    if ~retakeFlag % if user does not want to re-estimate the previous worm, then click the worm to zoom in for estimation
        %figure(1); showFoundWorm(imOrg, wormFound, countWorm); 
        figure(1); showFoundWorm(imOrg, wormListAll, numel(wormListAll));
        title(strcat(num2str(numWorm-countWorm), ' worms are needed to be found by clicking the head and tail, ',...
            ' click to zoom in for data collection'))
        wormPartPosition = zeros(2, numParts);
        
        [xPatchCenter,yPatchCenter] = ginput(1); % zoom in the area centered at (x, y)
    end
    
    %make some arbitrary rectangle (in this case, located at (0,0) with [width, height] of [10, 20])
    UL = [yPatchCenter, xPatchCenter]-radius;
    BR = [yPatchCenter, xPatchCenter]+radius;
    UL(UL<=0) = 1;
    
    if BR(1) > size(imOrg, 1) % please make sure all the images are square patch, do not click those which are too close to the image boundary
        BR(1) = size(imOrg, 1);     end
    if BR(2) > size(imOrg, 2)
        BR(2) = size(imOrg, 2);    end
    ULorg = int16(UL); % convert to int for index reason
    BRorg = int16(BR);
    
    patchTMP = imOrg(ULorg(1):BRorg(1), ULorg(2):BRorg(2)); % get the zoom-in area
    
    patchTMP = repmat(patchTMP, [1,1,3]); % make it a rgb format for annotation reason
    figureWorm = figure(1);
    imshow(patchTMP); title('click worm head and tail');
    patchTMP_BACKUP = patchTMP;
    
    
    if tenPartClickFlag % if the user chooses to click ten times to estimate the worm manually
        countParts = 1;
        wormPartPosition = zeros(2,numPartMulipleClicking);
        while countParts <= numPartMulipleClicking % click the worm parts and estimate the worm body based on the parts
            [x,y] = ginput(1);
            wormPartPosition(:, countParts) = [y;x];
            
            patchTMP(uint8(y), uint8(x), 1:3) = [255, 0, 0]; % set the clicked part points as red
            figure(1); imshow(patchTMP); title( strcat(num2str(countParts), '/', num2str(numPartMulipleClicking), ' click worm body in order') );
            line( wormPartPosition(2,1:countParts), wormPartPosition(1,1:countParts), 'linewidth', 1, 'color', 'r');
            
            countParts = countParts + 1;
        end
    else % the user click only the head and tail of the worm for automatically estimating the worm
        countParts = 1;
        while countParts <= 2 % click the worm parts and estimate the worm body based on the parts
            [x,y] = ginput(1);
            wormPartPosition(:, countParts) = [y;x];
            patchTMP(uint16(y), uint16(x), 1:3) = [255, 0, 0]; % set the clicked part points as red
            countParts = countParts + 1;
        end
        
        % dynamic programming to estimate the worm body
        wormPartPositionBACKUP = wormPartPosition;
        
        target = zeros(size(patchTMP,1), size(patchTMP,2) );
        target( sub2ind(size(target), uint16(wormPartPositionBACKUP(1,1)),uint16(wormPartPositionBACKUP(2,1))) ) = 1;
        target( sub2ind(size(target), uint16(wormPartPositionBACKUP(1,2)),uint16(wormPartPositionBACKUP(2,2))) ) = 1;
        
        % threshold the patch to faciliate automatic estimation
        p = 20; % p-th percentile of the intensities in the patch as the threshold
        thresh = patchTMP(:);
        thresh = prctile(thresh, p); % get the threshold intensity value
        patchTMP_BACKUP(patchTMP_BACKUP >= thresh) = Inf;
        
        % chain model via dynamic programming to estimate the worm body
        wormStruct = dpWormEstimation(  mat2gray(patchTMP_BACKUP(:,:,1)), target, partDist, scoreMultiplier, partSize, subSize, nPart );
        
        figure(1);
        imshow(patchTMP); title('estimated worm body');
        line( wormStruct.parts(:,2), wormStruct.parts(:,1), 'linewidth', 1);
        
        wormPartPosition = wormStruct.parts(:,1:2)';
    end
    wormPartPosition(1,:) = double(ULorg(1)) + wormPartPosition(1,:); % y -- vertical (1)
    wormPartPosition(2,:) = double(ULorg(2)) + wormPartPosition(2,:); % x -- horizontal (2)
    
    % get the mask as labels
    mask = connPart4Body(mask, wormPartPosition);
    
   % maskDisplay = maskDisplay | mask; % store into the overall mask
    imDisplay = getOverallMask(imDisplay, maskDisplay);

    ButtonName = questdlg('Are you sure to submit? Please make sure you estimate the worm body correctly! \nYes: submit, No: do not submit and turn to another patch, ... Re-take: re-click the worm on this patch', ...
        'double check before submission', ...
        'Yes', 'No (return)', 'Re-clicking 10 parts',  'No');
    switch ButtonName,
        case 'Yes', % if yes, store all the patches
            retakeFlag =0;
            tenPartClickFlag = 0;
            countWorm = countWorm + 1;
            wormFound{countWorm} = wormPartPosition;
            wormListAll{end+1} = wormPartPosition;
            
            maskDisplay = maskDisplay | mask; % store into the overall mask
            imDisplay = getOverallMask(imDisplay, maskDisplay);
            
            %showFoundWorm(imOrg, wormFound, countWorm);
            disp('Thank you for your contribution, please do more!');
        case 'Re-clicking 10 parts',
            retakeFlag = 1;
            tenPartClickFlag = 1;
        case 'No (return)',
            retakeFlag = 0;
            tenPartClickFlag = 0;
            disp('Thank you for your carefulness, please redo it!');
    end
end

%% flip and rotate to get more annotated data
[wormSetMore] = rotflip2getMore(imOrg, wormFound);

if ~isdir(destPath)
    mkdir(destPath);
end

%% save the result
[junk,nameFile,extFile] = fileparts(filename);
save( fullfile(destPath, strcat(nameFile, '_', datestr(now,'mm-dd-yyyy-HH-MM-SS'), '__', num2str(numWorm), '.mat')),...
    'wormSetMore', 'mask');

%% final showcase the annotated worms
wormSetMore = compact2full(wormSetMore);
%k = 1; showFoundWorm(wormSetMore{k}.im, wormSetMore{k}.wormFound);

f = figure(1); 
showFoundWorm(im, wormListAll, numel(wormListAll));
H = getframe(f);
title('visualization of estimated worms');

print(f, '-r100', '-dbitmap', 'image.bmp');
