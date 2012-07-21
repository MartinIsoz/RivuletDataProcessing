%% Algorithm of finding cuvettes modified for publication


%enhance contrasts of the input image and save it to temporary variable
tmpIM = imadjust(ImInput,stretchlim(ImInput),[1e-2 0.99]);
tmpIM  = im2bw(tmpIM, 0.16); %convert image to black and white
%find boundaries of each element, clear tmpIM
[B,L]  = bwboundaries(tmpIM,'noholes');clear tmpIM;
%preallocation of variables
nB     = zeros(1,numel(B));
Vec    = nB; %temporary indexing vector
rectG  = Vec;
for j = 1:numel(B)
    % nB is the number of elements on the region boundary
    nB(j) = size(B{j},1);
    %get rid of too big and too small regions
    if nB(j) >= 1000 && nB(j) < 3000
        Vec(j) = j;
        % calculate area of the element if it would be rectangle
        rectA  = (max(B{j}(:,1)) - min(B{j}(:,1)))*...
            (max(B{j}(:,2)) - min(B{j}(:,2)));
        tmp1     = B{j}(1:2:end,1);
        if mod(numel(B{j}(:,1)),2) == 1
            tmp2 = B{j}(end-1:-2:1,1);
        else
            tmp2 = B{j}(end:-2:1,1);
        end
        % take only the first n elements - vectors must have same size
        tmp1     = tmp1(1:min(numel(tmp1),numel(tmp2)));
        tmp2     = tmp2(1:min(numel(tmp1),numel(tmp2)));
        % calculate actual area of the element
        trueA    = sum(abs(tmp1 - tmp2));
        % rectangularity of an element as relative diference of
        % rectangular and actual area of the element
        rectG(j) = abs(trueA - rectA)/rectA;
    else
        Vec(j) = 0;
    end
end
% cut of zero elements
Vec = Vec(Vec~=0);
rectG = rectG(rectG~=0);
B = B(Vec);clear Vec; %cut of non-wanted elements of B, clear Vec
% cuvettes should have similar length of boundary and similar x coords
% finding the most rectangular elements
tmpR     = sort(rectG);
IrG      = find(rectG == tmpR(1),1,'first');
JrG      = find(rectG == tmpR(2),1,'first');
B = B([IrG JrG]); %reduce found boundaries only to cuvettes
% Find the vertices of cuvettes
% program works with x-coordinate for the width middle of the cuvette
% and y
% rows -> coordinates for each pictures
% columns -> coordinates for each boundary
% temporary positioning vector
PosVec = [1 4];
for j = 1:2 %I'm working only with 2 cuvettes/boundaries
    EdgCoord(PosVec(j))  = round(mean(B{j}(:,2)));
    Vec  = sort(B{j}(:,1));
    Vec  = Vec(10:end-10); %cut of potentially strange values
    EdgCoord(PosVec(j)+1)= round(mean(Vec(1:20)));
    EdgCoord(PosVec(j)+2)= round(mean(Vec(end-20:end)));
end
% check if the cuvettes coordinates are saved in right order
if EdgCoord(2) > EdgCoord(5)
    EdgCoord(end-2:end) = EdgCoord(1:3);
    EdgCoord(1:3)       = EdgCoord(4:6);
    EdgCoord(4:6)       = EdgCoord(end-2:end);
end
