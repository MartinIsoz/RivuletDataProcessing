function EdgCoord = findEdges(ImDataCell,GR,AUTO,varargin)
%
%  EdgCoord = findEdges(ImDataCell,GR,AUTO)
%  EdgCoord = findEdges(ImDataCell,GR,AUTO,hpTr,numPeaks,fG,mL)
%
% Measurement of the rivulet flow on an inclined plate
%
% Function to find coordinates of the plate and of the cuvette on the
% images from measurement.
%
% INPUT variables
% necessary variables
% ImDataCell    ... cell of the imread images
% GR            ... variable for handling graphics
% AUTO          ... variable that enables enforcing of completely automated
%                   image processing (if there is problem with line
%                   finding, processing throught weighted mean values is
%                   chosen automatically)
%               ... 0 -> completely manual, edges are chosen manually for
%                   each image
%               ... 1 -> semi-manual, if there is a problem, option to
%                   chose concerning edges manually is presented
%               ... 2 -> completely automatic (in fact, its "not 0 or 1")
% optional variables (varargin)
% hpTr  ... treshold parameter for the hough peaks function
% numPeaks. number of peaks to identify by houghpeaks
% fG    ... maximal gap between two lines that will be filled by houghlines
% mL    ... minimal length of the line recognized by houghlines
% defalut values: hpTr      = 0.33;
%                 numPeaks  = 200;
%                 fG        = 35;
%                 mL        = 25;
%
%
% OUTPUT variables
% EdgCoord      ... array containing for each image vector with plate and
%                   cuvette coordinates
% EdgCoord(i,:) = [xCMS yCLS yCHS xCMB yCLB yCHB xL yL xH yH]
% where:
% xCMS ... width coordinate of the middle of the small cuvette
% yCLS ... top edge of the small cuvette (lower number in pixels)
% yCHS ... bottom edge of the small cuvette (higher number in pixels)
% xCMB ... width coordinate of the middle of the big cuvette
% ....
% ....
% xL   ... left edge of the plate
% yL   ... top edge of the plate
% xH   ... right edge of the plate
% yH   ... bottom edge of the plate
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         11. 07. 2012
%
% Remarques on the code:
%
%
% CUVETTES
% cuvettes are on the images fairly visible so for finding them, it was
% enough to enhance the contrast of the image, convert it to black and
% white and use matlab function BWBOUNDARIES to find the boundaries of
% different elements on the photos. Then, it was used simple algorithm to
% choose from the found objects only cuvettes and to obtain the cuvettes
% coordinates
%
% PLATE
% the main plate is much less distinctive than cuvettes so it was necessary
% to use different aproach.
% from the main image was cut out only the part with the plate, then the
% contrast on this part was enhanced (it was possible to enhance it more
% rudely than with the cuvettes)
% after, hough transform was used to obtain straight lines in the images
% then, an algorithm was used to distinguish the lines on the edges of the
% plate a to obtain the plate coordinates from them
%
% Rq: dimensions found by this method differs +- 3.3mm (20 pixels) in
% plate length and +- 1.6(10 pixels) mm in plate width
%
% EXEMPLES
%
% 1.
%  EdgCoord = findEdges(ImDataCell,GR,AUTO)
%
% Finds cuvettes and plate edges on photos specified in ImDataCell, shows
% graphics depending on GR and behaves with automaticality specified in
% AUTO. Predefined parameter for image processing are used.
%
% 2.
%  EdgCoord = findEdges(ImDataCell,GR,AUTO,[],[],30,25)
%
% finds cuvettes and plate edges ... . For image processing are used
% default values of hpTr and numPeaks. fG and mL are specified by user
%
% See also IM2BW IMADJUST STRETCHLIM BWBOUNDARIES EDGE HOUGH
% RIVULETPROCESSING RIVULETEXPDATAPROCESSING
%

% tasks:
% - clean up the code
% - test the code on other images

%% Turn of "image is too big" warning
% Turn off this warning "Warning: Image is too big to fit on screen; displaying at 33% "
% To set the warning state, you must first know the message identifier for the one warning you want to enable. 
% Query the last warning to acquire the identifier.  For example: 
warning('off', 'Images:initSize:adjustingMag');

%% Processing function input
IMProcPars  = [0.33 200 35 25];                                             %default parameters for image processing
if nargin == 3                                                              %no IMProcPars are specified
    hpTr      = IMProcPars(1);
    numPeaks  = IMProcPars(2);
    fG        = IMProcPars(3);
    mL        = IMProcPars(4);
else
    parfor i = 1:numel(varargin)                                            %there are some IMProcPars specified
        if isempty(varargin{i}) == 0                                        %check if i-th parameter exists
            IMProcPars(i) = varargin{i};                                    %if yes, read his value
        end
    end
    hpTr      = IMProcPars(1);
    numPeaks  = IMProcPars(2);
    fG        = IMProcPars(3);
    mL        = IMProcPars(4);
end

%% Variable preallocation and main auxiliary variebles iniciation
% preallocation of variables for findig of the edges of the cuvettes
EdgCoord = zeros(numel(ImDataCell),10);                                     %OUTPUT variable
% preallocation of variables and auxiliary variables for finding the edges
% of the plate
% Position of the plate differs one measurement to another, so I have to
% ask the user to specify approximate position of the plate on the
% precessed images
% options.Interpreter = 'tex';
% options.WindowStyle = 'modal';
% msgbox({['Please specify approximate position of the'...
%     ' plate on processed images']...
%     ['Click little bit outside of {\bf upper left} '...
%     'and {\bf lower right corner}']},options);uiwait(gcf);
% se      = strel('disk',12);                                                 %morphological structuring element
% tmpIM   = imtophat(ImDataCell{1},se);
% tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                    %enhance contrasts
% tmpIM   = im2bw(tmpIM,0.16);                                                %conversion to black and white
% figure;imshow(tmpIM);                                                       %show image to work with
% cutMat  = round(ginput(2));close(gcf);                                      %let the user specify approximate position of the plate
% cutLeft = cutMat(1,1);cutRight = cutMat(2,1);
% cutTop  = cutMat(1,2);cutBottom= cutMat(2,2);                               %cut out \pm the plate (less sensitive than exact borders)
% epsX    = 15; epsY     = 15;                                                %maximal non-verticality/non-horizontality of found lines
% edgXL   = round((cutRight - cutLeft)*0.10);                                 %max. distance from left edge of the picture
% edgXR   = cutRight - cutLeft - edgXL;                                       %max. distance from right edge of the picture
% edgYT   = round((cutBottom - cutTop)*0.02);                                 %....          from top ....
% edgYB   = cutBottom - cutTop - edgYT;                                       %....          from bottom....
%preallocation of variables
ind     = cell(1,2);                                                        %indexes of "jumps" in x/y coordinate of lines

%% Main cycle of the program
for i = 1:numel(ImDataCell)                                                 %for each image
% Find cuvettes on the image
    trLeft = round(size(ImDataCell{i},2)/2);                                %i dont care about the left side of the image (with the plate)
    tmpIM  = ImDataCell{i}(:,trLeft:end);                                   %cut of unwanted part of the image and save temp. image var.
    tmpIM  = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                 %temporary image variable, enhance contrasts
    tmpIM  = im2bw(tmpIM, 0.055);                                            %temporary black and white image, convert image to BW
    sizeIM = size(tmpIM);                                                   %save size of the image
    [B,L]  = bwboundaries(tmpIM,'noholes');clear tmpIM;                     %find boundaries of each element, clear tmpIM
    % preallocation of variables
    Vec    = zeros(1,numel(B));                                             %temporary indexing vector
    trueA  = Vec;
    rectG  = Vec;
%     i
    for j = 1:numel(B)
        nB= size(B{j},1);                                                   %nB is the number of elements on the region boundary
        stmt1 = nB >= 1000 && nB < 2000;                                    %get rid of too big and too small regions (hardcoded, 2B polished)
        % i dont want elements close to the borders (would be better to
        % code distances in relative way)
        stmt2 = min(B{j}(:,1)) > 200 && max(B{j}(:,1)) < sizeIM(1)-200;     %get rid of the elements to much on the top and bottom
        stmt3 = min(B{j}(:,2)) > 200 && max(B{j}(:,2)) < sizeIM(2)-200;     %get rid of the elements to much on the left and right
        if stmt1 == 1 && stmt2 == 1 && stmt3 == 1
            Vec(j) = j;
            rectA  = (max(B{j}(:,1)) - min(B{j}(:,1)))*...
                (max(B{j}(:,2)) - min(B{j}(:,2)));                          %Area if the element if it would be rectangle
            tmp1     = B{j}(1:2:end,1);                                     %revrite temporary variables
            if mod(numel(B{j}(:,1)),2) == 1                                 %impair number of elements
                tmp2 = B{j}(end-1:-2:1,1);
            else
                tmp2 = B{j}(end:-2:1,1);
            end
            tmp1     = tmp1(1:min(numel(tmp1),numel(tmp2)));                %take only the first n elements - the vectors have to have
            tmp2     = tmp2(1:min(numel(tmp1),numel(tmp2)));                %the same size
            trueA(j) = sum(abs(tmp1 - tmp2));                               %calculate actual area of the element
            rectG(j) = abs(trueA(j) - rectA)/rectA;                         %rectangularity of the element (cuvettes are the most rectangular)
            [tmp1 tmpI1] = sort(B{j}(:,1));                                 %sort vectors in ascending order
            [tmp2 tmpI2] = sort(B{j}(:,2));
            vec1 = [tmp2(150) B{j}(tmpI2(150))]...                          %vectors in top left corner
                - [tmp2(1) tmp1(1)];
            vec2 = [B{j}(tmpI1(150),2) tmp1(150)]...
                - [tmp2(1) tmp1(1)];
            vec3 = [tmp2(end-150) B{j}(tmpI2(end-150))]...                  %vectors in bottom right corner
                - [tmp2(end),tmp1(end)];
            vec4 = [B{j}(tmpI1(end-150),2) tmp1(end-150)]...
                - [tmp2(end),tmp1(end)];
            dotPr(1) = dot(vec1/norm(vec1),vec2/norm(vec2));                %specify dot products on edges
            dotPr(2) = dot(vec3/norm(vec2),vec4/norm(vec3));
            rectG(j) = rectG(j) + max(dotPr)/sum(dotPr);                    %rectangularity - sum of dotproducts + ratio of areas
        else
            Vec(j) = 0;
        end
    end
    clear tmp1 tmpI1 tmp2 tmpI2  vec1 vec2 vec3 vec4                        %clear temporary variables
    Vec = Vec(Vec~=0);                                                      %cut of zero elements
    rectG = rectG(rectG~=0);
    trueA = trueA(trueA~=0);
    B = B(Vec);clear Vec;                                                   %cut of non-wanted elements of B, clear Vec
    % introducing objective function - sum of rectangularity and relative
    % difference in element areas
    sFunc = zeros(numel(B));
    for j = 1:numel(B)
        for k = j+1:numel(B)
            sFunc(j,k) = abs(trueA(j)-trueA(k))/(max(trueA)-min(trueA))...  %diference of true areas of elements
                + sum(rectG([j k]));                                        %sum of rectangularities of elements
        end
    end
    sFunc(~sFunc) = inf;                                                    %convert zeros to Inf (min finding)
    minsFunc = min(min(sFunc));                                             %find minimal value of the objective function
    [IsF JsF]= find(sFunc == minsFunc,1,'first');
    B   = B([IsF JsF]);                                                     %reduce found boundaries only to cuvettes
    % Find the vertices of cuvettes
    % program works with x-coordinate for the width middle of the cuvette 
    % and y
    % rows -> coordinates for each pictures
    % columns -> coordinates for each boundary
    PosVec = [1 4];                                                         %temporary positioning vector
    for j = 1:2                                                             %I'm working only with 2 cuvettes/boundaries
        EdgCoord(i,PosVec(j))  = round(mean(B{j}(:,2)))+trLeft;             %mean column coordinate should be the center of the cuvett
        Vec  = sort(B{j}(:,1));                                             %sort row indexes of boundary in ascending order
        Vec  = Vec(10:end-10);                                              %cut of potentially strange values
        EdgCoord(i,PosVec(j)+1)= round(mean(Vec(1:20)));                    %cuvette should be about 100 pixels wide, take mean of 20 lwst values
        EdgCoord(i,PosVec(j)+2)= round(mean(Vec(end-20:end)));              %cuvette should be about 100 pixels wide, take mean of 20 hgst values
    end
    if EdgCoord(i,2) > EdgCoord(i,5)                                        %small and big cuvettes are switched
        EdgCoord(i,end-2:end) = EdgCoord(i,1:3);                            %use nonset elements as storage space
        EdgCoord(i,1:3)       = EdgCoord(i,4:6);                            %switch values in right order
        EdgCoord(i,4:6)       = EdgCoord(i,end-2:end);
    end
    clear Vec PosVec                                                        %clear temporary variables
    % Control plot (white border around cuvettes)
    if GR(1) == 1                                                           %if I want graphics
        figure;                                                             %simple plot, no need to put it in external function
        imshow(label2rgb(L, @jet, [.5 .5 .5]))
        title(['\bf Cuvettes finding, image ' mat2str(i)],'FontSize',13)
        hold on
        for k = 1:length(B)
                        [sort1 I1] = sort(B{k}(:,1));
            [sort2 I2] = sort(B{k}(:,2));
            plot(B{k}(:,2), B{k}(:,1), 'w', 'LineWidth', 2)
            plot(sort2(1),sort1(1),'mx','LineWidth',5);
            plot(sort2(end),sort1(end),'bx','LineWidth',5);
            plot(sort2(150),B{k}(I2(150),1),'gx','LineWidth',5);
            plot(sort2(end-50),B{k}(I2(end-150),1),'rx','LineWidth',5);
            plot(B{k}(I1(150),2),sort1(150),'yx','LineWidth',5);
            plot(B{k}(I1(end-150),2),sort1(end-150),'kx','LineWidth',5);
            plot([EdgCoord(i,1) EdgCoord(i,1)],...
                [EdgCoord(i,2) EdgCoord(i,3)],...
                'Color','Black','LineWidth',3);
            plot([EdgCoord(i,4) EdgCoord(i,4)],...
                [EdgCoord(i,5) EdgCoord(i,6)],...
                'Color','Black','LineWidth',3);
        end
    end
end
return;
% Find edges of the plate
    tmpIM = ImDataCell{i}(cutTop:cutBottom,cutLeft:cutRight);               %cut out the plate from the image
    tmpIM = imtophat(tmpIM,se);
    tmpIM = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                  %enhance contrasts
    tmpIM = im2bw(tmpIM,0.40);                                              %simple conversion to black and white
    tmpIM = edge(tmpIM,'prewitt');                                            %find edges in the image
    tmpIM(edgYT:edgYB,edgXL:edgXR) = ...                                    %replace values in the image center with 0 - dont care about rivulet
        zeros(numel(edgYT:edgYB),numel(edgXL:edgXR));                       %convert center of the image to black
    [H,theta,rho] = hough(tmpIM);                                           %use hough transform on the image
    P = houghpeaks(H,numPeaks,'threshold',ceil(hpTr*max(H(:))));            %Find the peaks in the Hough trnsfm matrix, using the houghpeak fun
    % from this, i get pretty good position of 2 edges, fair position of 1
    % and close to zero information about the last one (on the first set of
    % testing images) -> i must use the information about side length ratio
    % of the plate to calculate position of the remaining edge
    lines = houghlines(tmpIM,theta,rho,P,'FillGap',fG,'MinLength',mL);      %Find lines in the image using the houghlines function
%     figure;imshow(tmpIM);hold on;
%     for k = 1:length(lines)
%         xy = [lines(k).point1; lines(k).point2];
%         plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
%         
%         % Plot beginnings and ends of lines
%         plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%         plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
%     end
% here a do a bit wrong indenation, but otherwise, the code would be to
% wide
if AUTO ~= 0                                                                %if some automatic processing is wanted
    % from this, i get pretty good position of 2 edges, fair position of 1
    % and close to zero information about the last one (on the first set of
    % testing images) -> i must use the information about side length ratio
    % of the plate to calculate position of the remaining edge
    xyVer   = zeros(numel(lines),2);xyHor = xyVer;                          %arrays for storing vertical and horizontal lines
    lV = 1; lH = 1;                                                         %aditional indexing variables
    for k = 1:numel(lines)
        xy          = [lines(k).point1 lines(k).point2];                    %save coordinates into a matrix
        % Useless code, just to keep the if madness readable
        edgDH(1)    = length(find([xy(1) xy(3)] >= edgXL));                 %number of X coordinates right of the predefined left edge
        edgDH(2)    = length(find([xy(1) xy(3)] <= edgXR));                 %....                    left ....               right
        edgDV(1)    = length(find([xy(2) xy(4)] >= edgYT));                 %....
        edgDV(2)    = length(find([xy(2) xy(4)] <= edgYB));                 %....
        SedgH       = sum(edgDH);SedgV = sum(edgDV);
        deltaX      = abs(xy(1) - xy(3));                                   %difference in the X-coordinate of start and end point of the line
        deltaY      = abs(xy(2) - xy(4));                                   %.....             Y-coordinate....
        % if madness
        stmt(1)     = deltaX <= epsX || deltaY <= epsY;                     %take out non-vertical and non-horizontal lines
        stmt(2)     = deltaX <= epsX && SedgH == 4;                         %line is vertical and between horizontal margins
        stmt(3)     = deltaY <= epsY && SedgV == 4;                         %line is horizontal and between vertical margins
        if stmt(1) == 1 && stmt(2) == 0 && stmt(3) == 0                     %line must be hor/vert and in margins
            % decide if the line is vertilal or horizontal
            if deltaX < epsX
                xyVer(lV,:) = xy([1 3]);                                    %in vertical lines, i'm interested only in x-coords
                lV = lV + 1;
            else
                xyHor(lH,:) = xy([2 4]);                                    %in horizontal....                  ....in y-coords
                lH = lH + 1;
            end
        end
    end
    % plotting
    if GR(2) == 1
       tmpPars = [edgXL edgXR edgYT edgYB epsX epsY i];
       plotLines(tmpIM,lines,tmpPars)
       clear tmpPars
    end
    % cut of zero values from xyVer, xyHor
    l     = find(xyVer(:,1) ~= 0,1,'last');                                 %find the last non-zero value in first column of xyMat
    xyVer = xyVer(1:l,:);xyVer = reshape(xyVer,[],1);                       %array (lH)x2 -> vector (2lH)x1
    l     = find(xyHor(:,1) ~= 0,1,'last');                                 %find the last non-zero value in first column of xyMat
    xyHor = xyHor(1:l,:);xyHor = reshape(xyHor,[],1);
    clear l
    % sort vectors in ascending order
    xyVer = sort(xyVer);xyHor = sort(xyHor);
    % find "jumps" in pixel numbers (coordinates)
    ind{1}  = find(diff(xyVer) > epsY);                                     %find indexes, where xyVer(i) - xyVer(i-1) > epsY
    ind{2}  = find(diff(xyHor) > epsX);
    xyCell  = {xyVer xyHor};clear xyVer xyHor                               %create cell for use in for loops and clear unnecessary variables
    % control results
    dataC = 0;                                                              %variable for data control
    meanC = cell(1,numel(ind));                                             %preallocate variable
    for k = 1:numel(ind)
        if isempty(ind{k}) == 1
            dataC = dataC+1;
            meanC{k} = round(mean(xyCell{k}));                              %calculate mean x/y coordinate of ver/hor line
        elseif numel(ind{k}) == 1
            Ind = [0 ind{k}' numel(xyCell{k})];                             %temporary indexing vector
            for l = 1:numel(Ind)-1
                meanC{k}(l) = round(mean(xyCell{k}(Ind(l)+1:...
                    Ind(l+1))));
            end
        else                                                                %more than 1 jump means to many lines found
            if AUTO == 1                                                    %if i dont want completely automatic run
                % Construct a questdlg with 2 options
                options.Interpreter = 'tex';                                %choose interpreter of the texts in dialog window
                options.Default     = 'Automatically';                      %default options to choose
                strLine1 = ['{\bf Image ' mat2str(i) ':}'];                 %number of image
                strLine2 = ['There was found more than 1 ('...              %what happened
                    mat2str(numel(ind{k})) ...
                    ') distinct lines on 1 of the plate edges'];
                strLine3 = 'Do you want to choose edges manually?';         %question
                strLine4 = ['Rq: Automatical estimation of the edge '...    %remarque on the solution method
                    'position uses weighted mean values of coordinates '...
                    'of similar lines'];
                save_to_base(1);
                choice = questdlg(sprintf('%s\n\n%s\n%s\n\n',...            %create question dialog
                    strLine1,strLine2,strLine3,strLine4), ...
                    'Choose edges of the plate', ...
                    'Manually','Automatically',options);
                switch choice                                               %handle responses
                    case 'Manually'
                        tmpPars = [edgXL edgXR edgYT edgYB epsX epsY i];    %contruct vector of parameters for plotLines
                        meanC{k} = plotLines(tmpIM,lines,tmpPars,k);        %call plotLines with fourth parameter (viz function comments)
                        clear tmpPars
                    case 'Automatically'
                        meanC{k} = autEdgEst(ind{k},xyCell{k});             %automatic edge position estimation
                end
            else                                                            %case i want completely automated image processing
                warning('Pers:TMDatPl',['There was found more than 2 ('...  %write out warning
                    mat2str(numel(ind{k})+1)...                             %number of found lines
                    ') distinct lines - edges of the plate, taking the '...
                    'weighted mean values of similar lines']);              %!! check this later !!
                meanC{k} = autEdgEst(ind{k},xyCell{k});                     %automatic edge position estimation
            end
        end
        if dataC == 2                                                       %I need to find at least 3 edges => 1 jump
            warndlg({['There is not enough found edges to'...               %if there is not enough edges, user must specify them manually
            ' estimate the plate position']...
            'You must specify edges manually'},'modal');uiwait(gcf);
            found = 0;                                                      %ith plate edges werent specified
        else
            found = 1;
        end
        clear Ind Weights
    end
    if dataC == 0  && found ~= 0                                            %there were found all 4 edges
        xL = meanC{1}(1);xH = meanC{1}(2);                                  %lower and higher x-coordinates
        yL = meanC{2}(1);yH = meanC{2}(2);                                  %....             y-coordinates
    elseif numel(ind{1}) == 0 && found ~= 0                                 %found only 1 x-coordinate
        yL = meanC{2}(1);yH = meanC{2}(2);                                  %....             y-coordinates
        if meanC{1} < edgXL                                                 %found left edge of the plate
            xL = meanC{1}(1);xH = xL + round((yH-yL)/2);                    %side ratio of the plate is width x length = 1x2
        else
            xH = meanC{1}(1);xL = xH - round((yH-yL)/2);
        end
    elseif numel(ind{2}) == 0 && found ~= 0                                 %found only 1 y-coordinate
        xL = meanC{1}(1);xH(i) = meanC{1}(2);                               %....             x-coordinates
        if meanC{2} < edgYT                                                 %found top edge of the plate
            yL = meanC{2}(1);yH = yL + round((xH-xL)*2);                    %plate is side ratio of the plate is width x length = 1x2
        else
            yH = meanC{2}(1);yL = yH - round((xH-xL)*2);
        end
    else                                                                    %did not find enough edges - must find manually
        tmpPars = [edgXL edgXR edgYT edgYB epsX epsY i];                    %contruct vector of parameters for plotLines 
        ManEdg  = plotLines(tmpIM,lines,tmpPars);                           %call the function for manual edge selection
        clear tmpPars
        xL = ManEdg(1);yL = ManEdg(2);xH = ManEdg(3);yH = ManEdg(4);        %unify output with the rest of the program
    end
else                                                                        %case of completely manual edges choosing
    tmpPars = [edgXL edgXR edgYT edgYB epsX epsY i];                        %contruct vector of parameters for plotLines 
    ManEdg  = plotLines(tmpIM,lines,tmpPars);                               %call the function for manual edge selection
    clear tmpPars
    xL = ManEdg(1);yL = ManEdg(2);xH = ManEdg(3);yH = ManEdg(4);            %unify output with the rest of the program
    found = 1;                                                              %ith plate edges were specified
end
    % saving data into OUTPUT variable
    EdgCoord(i,7) = xL + cutLeft;EdgCoord(i,9) = xH + cutLeft;              %i need to add back previously cuted out coordinates
    EdgCoord(i,8) = yL + cutTop; EdgCoord(i,10)= yH + cutTop;
end
% end

%% Auxiliary functions
function ManEdg = plotLines(tmpIM,lines,pars,cellInd)
%
%  function ManEdg = plotLines(tmpIM,lines,pars)
%
% function for plotting found lines on the images and for manually choosing
% edge position
%
% INPUT variables
% tmpIM     ... processed image to plot (enhanced contrast + found edges)
% lines     ... lines coordinates obtained by the hough transform
% pars      ... additional parameters for choosing only the lines on the
%               plate edges
% cellInd   ... variable to distinguish between horizontal and vertical
%               coordinate. to be used when the function is called to
%               manually chose "problematic edge"
%
% OUTPUT variables
% ManEdg    ... manually chosen coordinates
%           ... nargin = 3 -> ManEdg = [xL yL xH yH]
%           ... nargin = 4 -> ManEdg = [xL xH] or [yL yH], depending on
%               cellInd
%
% Rq: if I want the graphics, this takes longer than straight
% implementation in the main function code, but I can use this function not
% only for plotting, but also for manually choosing coordinates of the
% plate

% parameter extraction
edgXL = pars(1);
edgXR = pars(2);
edgYT = pars(3);
edgYB = pars(4);
epsX  = pars(5);
epsY  = pars(6);
IMNmbr= pars(7);                                                            %number of the image

% ploting of the images
figure, imshow(tmpIM), hold on;                                             %plot the input image
for k = 1:numel(lines)
    xy          = [lines(k).point1 lines(k).point2];                        %save coordinates into a matrix
    % Useless code, just to keep the if madness readable
    edgDH(1)    = length(find([xy(1) xy(3)] >= edgXL));                     %number of X coordinates right of the predefined left edge
    edgDH(2)    = length(find([xy(1) xy(3)] <= edgXR));                     %....                    left ....               right
    edgDV(1)    = length(find([xy(2) xy(4)] >= edgYT));                     %....
    edgDV(2)    = length(find([xy(2) xy(4)] <= edgYB));                     %....
    SedgH       = sum(edgDH);SedgV = sum(edgDV);
    deltaX      = abs(xy(1) - xy(3));                                       %difference in the X-coordinate of start and end point of the line
    deltaY      = abs(xy(2) - xy(4));                                       %.....             Y-coordinate....
    % if madness
    stmt(1)     = deltaX <= epsX || deltaY <= epsY;                         %take out non-vertical and non-horizontal lines
    stmt(2)     = deltaX <= epsX && SedgH == 4;                             %line is vertical and between horizontal margins
    stmt(3)     = deltaY <= epsY && SedgV == 4;                             %line is horizontal and between vertical margins
    if stmt(1) == 1 && stmt(2) == 0 && stmt(3) == 0                         %line must be hor/vert and in margins
        plot(xy([1 3]),xy([2 4]),'LineWidth',2,'Color','green');            %superimpose the lines over the processed image
        % Plot beginnings and ends of lines
        plot(xy(1),xy(2),'x','LineWidth',2,'Color','yellow');
        plot(xy(3),xy(4),'x','LineWidth',2,'Color','red');
    end
    title(['\bf Hough transform for finding edges of the plate, '...        %title of graphics
            'image ' mat2str(IMNmbr)])
end

% manual specification of the coordinates
if nargout == 1
    if nargin < 4                                                           %cellInd is not specified
        ManEdg      = zeros(4,1);                                           %preallocating variable, 4 edges, xL yL xH yH
        strLine1    = 'Specify the edges to choose manually';
        strLine2    = '[left top right bottom], {\bf choose at least 3}';
        prompt      = {sprintf('%s\n%s',strLine1,strLine2)};
        dlg_title   = 'Manual edge specification';
        def         = {'[1 1 0 1]'};
        num_lines   = 1;
        options.Interpreter = 'tex';
        %window options for the dialog
        Sansw       = 1;                                                    %auxiliary variable for checking input
        while sum(Sansw) < 3 || sum(Sansw) > 4                              %repete selection until 3 or 4 lines are chosen
            answer      = inputdlg(prompt,dlg_title,num_lines,def,options); %open input dialog for specification of manually chosen edges
            if isempty(answer) == 1                                         %if user cancels
                msgbox('Stopped by user, skipping image','modal');
                uiwait(gcf);
                return
            end
            answer      = str2num(answer{1});%#ok<ST2NM>                    %convert cell string into answer into row vector
            Sansw       = sum(answer);                                      %number of chosen lines
        end
        tmpEdg      = round(ginput(Sansw));                                 %storing graphical input
        % processing the input
        l           = 1;                                                    %auxiliary indexing variable
        for k = 1:numel(answer)
            if answer(k) == 1 && mod(k,2) == 1                              %impairs rows -> I want x-coordinate
                ManEdg(k) = tmpEdg(l,1);                                    %save gr. input into 4 elm. vector with zeros in non-specified row
                l = l+1;
            elseif answer(k) == 1 && mod(k,2) == 0                          %pairs rows -> I want y-coordinate
                ManEdg(k) = tmpEdg(l,2);                                    %save gr. input into 4 elm. vector with zeros in non-specified row
                l = l+1;
            else
                ind = k;                                                    %save the position of the zero element
            end
        end
        % this if statement is not very elegant
        if exist('ind','var') == 1 && mod(ind,2) == 1                       %3 edges are specified, 1 vertical is not
            xW = round((ManEdg(4)-ManEdg(2))/2);                            %specify horiznotal edges and width of the plate
            if ind == 1                                                     %well, this is not very elegant
                    ManEdg(ind) = ManEdg(3) - xW;                           %find remaining vertical edge
                else
                    ManEdg(ind) = ManEdg(1) + xW;
            end
        elseif  exist('ind','var') == 1 && mod(ind,2) == 0                  %3 edges are specified, 1 horizontal is not
            yW = round((ManEdg(3)-ManEdg(1))*2);                            %specify horiznotal edges and width of the plate
            if ind == 2                                                     %well, this is not very elegant
                    ManEdg(ind) = ManEdg(4) - yW;                           %find remainign horizontal edge
                else
                    ManEdg(ind) = ManEdg(2) + yW;
            end
        end
    else
        strCell = {'vertical' 'horizontal'};
        msgbox(['Specify ' strCell{cellInd}...
            ' edges of the plate'],'modal');uiwait(gcf);
        tmpEdg  = round(ginput(2));                                         %need to specify 2 edges
        if cellInd == 1                                                     %choosing between vertical lines
            ManEdg = tmpEdg(:,1);                                           %save vertical coordinates
        else
            ManEdg = tmpEdg(:,2);                                           %save horizontal coordinates
        end
    end
    close(gcf);                                                             %close current graphiquw window
end
end

function meanC = autEdgEst(ind,xyCell)
%
%  function meanC = autEdgEst(ind,xyCell)
%
% function for automatic estimation of problematic edge position, computes
% with weighted mean values of the coordinates of similar lines
%
% INPUT variables
% ind       ... indexes of "jumps" into coords values, vector, length>1
% xyCell    ... vector with hor/ver coordinates of the edges, name is kept
%               because of the coherence
%
% OUTPUT variables
% meanC     ... meand vert/hor coordinates of the edges, vector of length 2

Ind = [0 ind' numel(xyCell)];
Vec = zeros(numel(Ind)-1,1);
for l  = 1:numel(Ind)-1                                                     %create mean values for all segments
    Vec(l) = round(mean(xyCell(Ind(l)+1:Ind(l+1))));
end
while numel(Vec) > 2                                                        %I need 2 edges
    DiffVec= diff(Vec);                                                     %differences in mean values
    PosVec = [find(DiffVec == min(DiffVec))...
        find(DiffVec == min(DiffVec))+1];                                   %position of values with minimal difference
    Weights = diff(Ind);
    Weights = Weights(PosVec)/sum(Weights(PosVec));                         %weights
    wVal   = round(Weights*Vec(PosVec));
    Vec = [Vec(1:PosVec(1)-1);wVal;...
        Vec(PosVec(2)+1:end)];                                              %construct the vector of appropriate mean coordinates
end
meanC= Vec;                                                                 %construct the vector of appropriate mean coordinates
end