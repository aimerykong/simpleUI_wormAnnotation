function [wormStruct] = dpWormEstimation( im, target, partDist, scoreMultiplier, partSize, subSize, nPart )
% This function is used for estimating worm body with a simple part-based
% model, which is a chain model. Dynamic programming is used to find a
% global optimal placement of the worm parts. This function returns the
% worm parts locations and estimate score stored in a structure.
%
%
% Input
%   im              --  the image or image area;
%   target          --  the (predicted) target map highlighting the TWO 
%                       detected keypoints of the worms. It is a binary
%                       map.
%   partDist        --  partwise distance as a defined parameter, e.g. 3 as
%                       default;
%   scoreMultiplier --  calibrating the mismatching score into the same
%                       scale of partwise distance, e.g. 10 as default;
%   partSize        --  define the part size, e.g. 5x5 as default; 
%   subSize         --  define the subsampling straddle, e.g. 3 as default;
%
%
% Output
%   wormStruct      --  a structure with part locations, total mismatch
%                       score (the smaller the better).
%
% Shu Kong @ UCI
% skong2@uci.edu
% 03/21/2015

%% setting default values
if (nargin < 3) 
    partDist = 3; end
if (nargin < 4) 
    scoreMultiplier = 10; end
if (nargin < 5) 
    partSize = 5; end
if (nargin < 6) 
    subSize = 5; end
if (nargin < 7) 
    nPart = 14; end % number of parts

%% build fast intermediate maps for dynamic programming
keypointIdx = find(target==1); % find the two detected keypoints
[keypointsubI, keypointsubJ] = ind2sub(size(im), keypointIdx); % subscripts

% define average filter for fast mismatching calculation
h = fspecial('average', partSize); 
imMeanF = filter2(h, im, 'same');
imMeanF(1:ceil(partSize/2),:) = 1; % boundary does not contribute at all
imMeanF(:, 1:ceil(partSize/2)) = 1;
imMeanF(end-ceil(partSize/2):end,:) = 1;
imMeanF(:, end-ceil(partSize/2):end) = 1;

% subsample the image into a smaller one, for fast calculation and saving memory
subsampleRow = 1:subSize:size(im,1); 
subsampleColumn = 1:subSize:size(im,2);
imMeanF = imMeanF(subsampleRow, subsampleColumn);

% get the subscript and linear index in the subsampled image
keypointsubI = ceil(keypointsubI/subSize);
keypointsubJ = ceil(keypointsubJ/subSize);
keypointIdxNew = sub2ind(size(imMeanF), keypointsubI, keypointsubJ);

C = imMeanF*scoreMultiplier; % store the mismatch score for fast calculation
V = zeros(size(C,1), size(C,2), numel(C)); % storing the pairwise distances
for i = 1:size(V,3) % fast index along the third mode for partwise distance
    D = reshape(1:numel(C), [], 1);
    [I, J] = ind2sub(size(C), D);
    [anchorI, anchorJ] = ind2sub(size(C), i);
    I = I-anchorI;
    J = J-anchorJ;
    D = (I.^2+J.^2);
    
    %D = max(0, (D-partDist).^2-4).^3;
    %D = (sqrt(I.^2+J.^2)-partDist).^2;
    %D = abs(sqrt(I.^2+J.^2)-partDist).^2; % distance can be chosen to be other forms, say Manhattan distance
                                          % 'partDist' is the desired
                                          % distance.
    V(:,:,i) = reshape(D, size(C));
end

%% dynamic programming
L0 = keypointIdxNew(1); % worm head
Ln1 = keypointIdxNew(2); % worm tail

B = zeros(nPart, size(V,3)); % the table used for dynamic programming
V = reshape(V, numel(V(:,:,1)), size(V,3));
for i = 1:nPart
    if i == 1
        TMP = V( L0, : );
        B(i,:) = (C(:) + TMP(:))';
    else
        %B(i,li) = C(li) + min(TMP) + (i==nPart)*V(li, Ln1); % the recurrent calculation
        TMP = bsxfun(@plus, V, B(i-1,:) );
        B(i,:) = C(:) + min(TMP, [], 2) + (i==nPart)*V(:, Ln1);
    end
end

%% trace back to find the part sequence
parts = zeros(1, nPart+2); parts(1) = Ln1;
mask = zeros(size(C));
mask(Ln1) = 1;

imDemons = imMeanF; % for demonstration reason
imDemons(keypointIdxNew) = 1.2;
[score, ind] = min(B(nPart, :));
imDemons(ind) = 1.2;
mask(ind) = 1;
parts(2) = ind; % the last part excluding the worm tail

for i = nPart:-1:1+1 
    li = ind;
    [val, ind] = min( V(li,:) + B(i-1,:) );
    imDemons(ind) = 1.2;
    mask(ind) = 1;
    parts(nPart-i+3) = ind;
%     fprintf('\t%d\n', ind);
end
mask(L0) = 1; % worm head
parts(end) = L0;

%% get the parts location with the original image size
[xParts,yParts] = ind2sub(size(mask), parts);
xParts = (xParts-1)*subSize+1;
yParts = (yParts-1)*subSize+1;

mask = zeros(size(im,1), size(im,2)); %imresize(0*mask, size(mask)*subSize);
idx = sub2ind(size(mask), xParts, yParts);
mask(idx) = 1;

%% assemble the output
wormStruct.showMap = imDemons;
wormStruct.mask = mask;
wormStruct.parts = [xParts(:), yParts(:), parts(:)];
wormStruct.score = score + ...
    1-target(L0) + ...
    1-target(Ln1);



