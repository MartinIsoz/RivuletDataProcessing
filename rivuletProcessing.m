function OUT = rivuletProcessing(daten,Treshold,FilterSensitivity,...
    EdgCoord,GR,files,fluidData,storDir,rootDir,varargin)
%
%   function rivuletProcessing(daten,Treshold,FilterSensitivity,EdgCoord,...
%       GR,files,fluidData,storDir,rootDir,[plateSize,nCuts,filmTh,RegrPlate])
%
% My modification of Andres function for evaluation of rivulet-LIF images
% Required parameters:
% 1 Threshold for distinguishing between background and rivulet in mm
% Threshold recommended: 1/10 mm
% 2 Filter sensitivity for smoothing the image
% Recommended Sensitivity: 10
%
% INPUT variables
% mandatory:
% daten     ...     cell with substracted images data
% Treshold  ...     treshold for distinguishing between the rivulet and the
%                   noise on the plate
% FilterSensitivity.filter sensitivity for image smoothing
% EdgCoord  ...     coordinates of plate and cuvette edges on each image,
%                   matrix nImages x 10
%                   [xCMS yCLS yCHS xCMB yCLB yCHB xL yL xH yH]
% GR        ...     structure with graphics output specifications
%   required fields:
%                   - GR.regr       = 0/1 - graphs from regression
%                   - GR.contour    = 0/1 - view from top
%                   - GR.profcompl  = 0/1 - complete profile
%                   - GR.profcut    = 0/1 - mean profiles in cuts
%                   - GR.regime     = 0/1/2 - show/save/show+save
% files     ...     cell with strings - name of the processed images
% fluidData ...     data concerning the liquid phase, regression
%                   coeficients for rotameter calibration, surface tension,
%                   density and dynamic viscosity of the liquid phase
%                   (formerly stored in Konstanten_Fluid.txt)
% storDir   ...     directory for storing outputs
% rootDir   ...     root directory for program execution
%
% optionals
% plateSize ...     size of the plate in metres
%                   defalut: [0.15 0.30]
% nCuts     ...     number of centered cuts to make along the rivulet
%                   default: 5
% filmTh    ...     thickness of the film in cuvettes, in mm + width of the
%                   cuvettes in pixels
%                   default: 1.93 0.33 6 2.25 80];
% RegrPlate ...     degree of polynomial to be used in conversion of image
%                   from grayscale values into distances
%
% OUTPUTS - text files
% a. text file for plotting profiles - cuts
%    1 file for each image
% b. text file with mean speeds in cuts
%    1 file for each regime
% c. text file with local width of the rivulet in each cut
%    1 file for each regime
% d. text file with local height of the rivulet in each cut
%    1 file for each regime
% e. text file with interfacial areas of the rivulets
%    1 file for each regime
%
% Scheme of algorithm
% 1. convert grayscale to distances
% 2. get rid of the noise (using predefined MATLAB filter)
% 3. construct profiles for each horiznotal cut
% 4. determine local width of the rivulet and liquid-gas interfacial area
% 5. determine mean local speed of the liquid
% 6. find mean profiles for each 50 mm of the plate
% 7. calculate width of the rivulet and liquid-gas interfacial area using
%    these mean values
% 8. save the results
%
% See also FINDEDGES FLUIDDATAFCN RIVULETEXPDATAPROCESSING SAVE_TO_BASE
%

% Notes on the code:
% - cell 'liste' has 1.19 kB in memory, so why not to keep it there?
% - import of images is pretty quick (\pm 0.6 s on C2D)
% - are the coordinates of cuvettes seted right? see regression plot...
%   !! repare regression !!
% - why is used only small portion of the cuvette width? - enlarged to 80
% - size of plate: 150 x 300 mm
% - speed determination - why? for mass transfer i need to know velocity
%   profile, this gives us only the mean value in each cut => put together
%   function to calculate velocity profiles in the rivulet
% - I'd prefere if all the code was written in basic SI units (mm -> m)
% - the most of the values of the images are below calibration scope of the
%   cuvette (but that should be ok, because on the major part of the plate,
%   there is close to none liquid)
% - why is for the extrapolation (values outside the calibration scope)
%   used different type of regression - what is the reason for believing in
%   the change of the trend
% - does the regression line have to come through the point (0,0)?
%   (especially for the big cuvette)
% - in plotting "mean cuts", there is used only 50 pixels around each cut
%
% Tasks (from Friday 06 Jully 2012)
% - complete lab. journal
% - plot, dependence of IFArea on break criterium

%% Creating subdirectories
% is taken care of in "Choose storDir"

%% Processing function input
plateSize   =[0.15 0.30];                                                   %size of the plate, [width length], in m
nCuts       = 5;                                                            %every 50 mm 5/10/15/20/25 cm
filmTh      = [1.93 0.33 6 2.25 80];                                        %max and min thickness of the film in cuvettes
RegressionPlate = 2;                                                        %degree of polynomial for regression in converting gray val. to dist.

Pars = {plateSize nCuts filmTh RegressionPlate};                            %cell of defaults parameters
for i = 1:numel(varargin)                                                   %check if optional arguments is present
    if isempty(varargin{i}) == 0
        Pars{i} = varargin{i};                                              %if it is, take the new value
    end
end
plateSize = Pars{1};
nCuts     = Pars{2};
filmTh    = Pars{3};
RegressionPlate = Pars{4};
%% Rotameter calibration
% Pumpenkonstante und Stoffwerte
[M,V_Pumpe]= rotameterCalib(files,fluidData);                               %rotameter calibration
sigma = fluidData(5);                                                       %save input parameters for correlations
rho   = fluidData(6);
eta   = fluidData(7);
clear fluidData

%% Importing images into workspace
% is taken care of in "Load Images"

%% Subtraction of frames minus background
% is taken care of in "Load Images"

%% Finding edges of cuvettes and plate
% is taken care of in "Image Processing"

%% Image conversion from grayscale values to distances
% heights of the film in mm
YProfilPlatte = ImConv(daten,EdgCoord,filmTh,RegressionPlate,...            %variables needed for calculation
    GR.regr,GR.regime,storDir,rootDir);                                     %graphics and data manipulation variables

%% Smoothing images
% Rq:
% B = imfilter(A,H)
% A ... multidimensional matrix to be filtered
% H ... multidimensional filter
% h = fspecial(type)
% Create predefined 2-D filter
parfor i=1:numel(YProfilPlatte)
    YProfilPlatte{i} = imfilter(YProfilPlatte{i},...                        %Here I use input argument FilterSensitivity
        fspecial('disk',FilterSensitivity));
end

%% Saving smoothed images and obtaining contour visualizations of the riv.
% store and plot smoothed images
cd([storDir '/Substracted/Smoothed']);
for i=1:numel(YProfilPlatte) %#ok<*FORPF>
% 	dlmwrite(strcat('Smoothing_',files{i}(1:end-4),'.txt'),...              %extremely time consuming
%         YProfilPlatte{i},'delimiter','\t','precision','%5.4f')            %write as text files
    imwrite(YProfilPlatte{i},strcat('Smoothing_',files{i}))                 %write as images
    if GR.contour == 1
        % graphical output, look on the rivulets from top
        figure;figSet_size(gcf,[400 700])
        XProfilPlatte = linspace(0,plateSize(1),...
            size(YProfilPlatte{i},1));
        ZProfilPlatte = linspace(0,plateSize(2),...
            size(YProfilPlatte{i},2));
        [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
        contour(ZZ',XX',YProfilPlatte{i});                                  %here I keep rivulet height in mm because it looks better
        title(['\bf Look on the rivulet ' mat2str(i) ' from top'],...
            'FontSize',13)
        xlabel('width coordinate, [m]');
        ylabel('length coordinate, [m]');
        colbarh = colorbar('Location','East');                              %add the colorbar - scale
        ylabel(colbarh,'rivulet height, [mm]')                              %set units to colorbar
        axis ij                                                             %switch axis to match photos
        if GR.regime ~= 0                                                   %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(i) 'fromtop'],'png');
            cd([storDir '/Substracted/Smoothed']);
            if GR.regime == 1                                               %I want images only to be saved
                close(gcf)
            end
            cd([storDir '/Substracted/Smoothed']);                          %back to the directory for saving images
        end
    end
end
cd(rootDir);                                                                %back to the rootDir

%% Plate profile
%Determination of all profiles over the plate length for obtaining rivulet
%Just transforms YProfilPlatte and, if wanted, plots it
for i = 1:numel(YProfilPlatte)
    %Y-Profile over entire plate width - just transposed Smoothing
    YProfilPlatte{i}=YProfilPlatte{i}';
    if GR.profcompl == 1
        figure;figSet_size(gcf,[1100 600])
        XProfilPlatte = linspace(0,plateSize(1),...
            size(YProfilPlatte{i},1));
        ZProfilPlatte = linspace(0,plateSize(2),...
            size(YProfilPlatte{i},2));
        [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
        mesh(XX',ZZ',YProfilPlatte{i}*1e-3)                                 %I need to convert the liquid height into mm
        axis tight
        xlabel('width of the plate, [m]')
        ylabel('length of the plate, [m]')
        zlabel('height of the rivulet, [m]')
        title(['\bf Profile of the rivulet ' mat2str(i)],'FontSize',13);
        if GR.regime ~= 0                                                   %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(i) 'complprof'],'png');
            if GR.regime == 1                                               %I want images only to be saved
                close(gcf)
            end
            cd(rootDir);                                                    %back to the rootDir
        end
    end    
end

%% Read the individual profiles over the length of the plate -> rivulet
%% area
% !! Rivulet height maximum should be in the rivulet, not around !!
% read the profile from the maximum to the left and right, stop after the
% fall under treshold thickness
% lets draw the rivulet (from the maximum to the treshold, for each row)

IFArea = RivSurf(YProfilPlatte,Treshold,plateSize);                         %this function does not need graphical output

%% Calculate mean values of riv. heights over each rivLength/nCuts of the
%% rivulet
[YProfilPlatte,XProfilPlatte]=cutRiv(YProfilPlatte,nCuts,plateSize,...      %call with calculation variables
    GR.profcut,GR.regime,storDir,rootDir);                                  %auxiliary variables for graphics and data manipulation

%% Calculate variables to be saved, mean values in each cut
% - if I understand it correctly, it is the same calculation as before,
% only for the mean profiles - these 2 calculations can be put together in
% 1 function and called separately

[~,RivWidth2,RivHeight2,minLVec,minRVec] =...                               %calculates the mean widths of the rivulet and return indexes of
    RivSurf(YProfilPlatte,Treshold,plateSize);                              %the "edges" of the rivulet + calculates max height of each part of
                                                                            %the rivulet

%% Mean speed determination from average profiles
% - calculate area of the horizontal cut through the rivulet
% - from known volumetric rate calculate local (mean) speed in the cut

% calculating the area - using trapeizoidal rule to obtain surface under
% the curve of the profile
mSpeed  = zeros(numel(YProfilPlatte),size(RivWidth2,2));                    %prealocation of var mSpeed
for i = 1:numel(YProfilPlatte)
    for j = 1:size(RivWidth2,2)
        SurfMat = trapz(XProfilPlatte(minLVec(i,j):minRVec(i,j)),...        %rows - number of images, columns - number of cuts
            YProfilPlatte{i}(minLVec(i,j):minRVec(i,j),j)*1e-3);            %again, conversion mm -> m
        mSpeed(i,j)  = V_Pumpe(i)/SurfMat;                                  %local mean speed V_/S, m/s
    end
end

%% Saving results in text files
% 1. Smoothed/averaged profiles
cd([storDir '/Profile'])
% in 1 file for each image, i will save:
% impairs columns: x-coordinates
% pairs   columns: heights of the rivulet correspondings to the x-coord.
saveProf(XProfilPlatte,YProfilPlatte,minLVec,minRVec,files)
cd(rootDir)

sPars = {M plateSize nCuts};                                                %common variables for all saved files

% 2. Local mean speed in cuts
cd([storDir '/Speed'])
saveMatSliced(mSpeed,sPars,files,'Speed')
cd(rootDir)

% 3. Width of the rivulets (local)
cd([storDir '/Width'])
saveMatSliced(RivWidth2,sPars,files,'Width')
cd(rootDir)

% 4. Max height of the rivulets
cd([storDir '/Height'])
saveMatSliced(RivHeight2,sPars,files,'Height')
cd(rootDir)

% 5. Interfacial area of the rivulets
cd([storDir '/Correlation'])
varIN = {sigma rho eta M};                                                  %input variables for correlation
varOUT= IFArea;                                                             %output variable for correlation
saveCorrData(varOUT,varIN,'IFAreaCorr')
cd(rootDir)

OUT = 0;                                                                    %currently unused output variable
end



%% Function to convert gray values ​​in distances - extremely slow
% Is required for the image and the regression coefficients of quadratic regression
% 21/11/2011

function ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
    GR,GRregime,storDir,rootDir)
%
%   ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
%    GR,GRregime,storDir,rootDir)
%
% function for conversion images from grayscale to distances using
% polynomial regression with polynomial of degree specified in RegDegree
%
% INPUT variables
% ImData    ... images of the plate (in form of matrix)to be converted,cell
% EdgCoord  ... coordinates of section edges of the plate(plate, cuvettes),
%               pixels/indexes, matrix (numImages x 10)
% filmTh    ... film thickness, in mm + width of cuvettes in pixels
%               [maxCuvette1 minCuvette1 maxCuvette2 minCuvette2 CuvWidth]
% RegDegree ... degree of polynomial used for the regression
% GR                ... variable for graphics (yes/no)
% GRregime          ... variable for graphics (show/save/show+save)
% storDir           ... directory for storing outputs
% rootDir           ... main execution directory
%
% OUTPUT variebles
% ImgConv   ... converted image, gray values -> local heights of the riv,
%               in mm

ImgConv     = cell(1,numel(ImData));                                        %preallocation of output variable
for i = 1:numel(ImData)                                                     %#ok<FORPF> %for each file
    % read coordinates of the cuvettes and plate on each image
    % small cuvette
    xoS = EdgCoord(i,1);                                                    %mean  x-Value
    yoS = EdgCoord(i,2);                                                    %upper y-Value
    yuS = EdgCoord(i,3);                                                    %lower y-Value
    % big cuvette
    xoB = EdgCoord(i,4);
    yoB = EdgCoord(i,5);
    yuB = EdgCoord(i,6);
    % plate
    xol = EdgCoord(i,7);                                                    %upper left x-Value
    yol = EdgCoord(i,8);                                                    %upper left y-Value
    xur = EdgCoord(i,9);                                                    %lower right x-Value
    yur = EdgCoord(i,10);
    % prepare cuvette calibration
    XS  = linspace(filmTh(1),filmTh(2),yuS-yoS+1)';                             %thickness of the film in mm small Kuevette
    XB  = linspace(filmTh(3),filmTh(4),yuB-yoB+1)';                             %thickness of the film in mm big Kuevette
    CW  = filmTh(5)/2;                                                          %cuvette width/2
    % load i-th image
    Image = ImData{i};                                                      %temporary variablefor each image
    % find mean grayscale value for each row of the cuvette
    YS   = mean(Image(yoS:yuS,xoS-CW:xoS+CW),2);
    YB   = mean(Image(yoB:yuB,xoB-CW:xoB+CW),2);
    % combine grayscale value and film thickness into 1 matrix
    CuvetteS  =[YS XS];                                                     %Y ... brightness, X ... height of liquid
	CuvetteB  =[YB XB];                                                     %calibration data for image conversion
    
    Image   = double(Image(yol:yur,xol:xur));                               %reduce Image only to plate and convert to double
    tmpMatS = CuvetteS(50:end-50,:);                                        %cut off potentially strange values on sides
    tmpMatB = CuvetteB(50:end-20,:);                                        %... brute and unelegant
    
    impS    = numel(tmpMatS(:,1));                                          %i must cheat matlab to polyfit through point (0,0) artificialy add
%     impB    = numel(tmpMatB(:,1));                                        % point (0,0) with the same importance as all other points together
    [RegS ErrorEstS]    = polyfit([tmpMatS(:,1);zeros(impS,1)],...
        [tmpMatS(:,2);zeros(impS,1)],RegDegree);                            %Regression small cuvette (with the point (0,0))
    [RegB ErrorEstB]= polyfit(tmpMatB(:,1),tmpMatB(:,2),RegDegree);         %Regression big cuvette (without the point (0,0))
%     RegB = polyfit([tmpMatB(:,1);zeros(impB,1)],...
%         [tmpMatB(:,2);zeros(impB,1)],RegDegree);                          %Regression big cuvette (with the point (0,0)
    % split image into 2 based on grayscale values and convert it to the
    % distances separately
    [rowSize colSize] = size(Image);                                        %save dimensions of the original image
    ImgConv{i}(Image<=max(YS)) = polyval(RegS,Image(Image<=max(YS)));       %convert small values
    ImgConv{i}(Image >max(YS)) = polyval(RegB,Image(Image >max(YS)));       %convert big values
    ImgConv{i}        = reshape(ImgConv{i},rowSize,colSize);                %reshape the matrix into original dimensions
%     ImgConv{i} = polyval(RegS,Image);                                       %original conversion command
    if GR == 1
    % Calculate fitted values
    [fitS deltaS] = polyval(RegS,CuvetteS(:,1),ErrorEstS);                  %fitted values and estimated errors
    [fitB deltaB] = polyval(RegB,CuvetteB(:,1),ErrorEstB);
    % Graphs to control regression state..
        figure;figSet_size(gcf,[1100 600])
        subplot(121)
        plot(CuvetteS(:,1),CuvetteS(:,2),'+',...                            %experimental points
             CuvetteS(:,1),fitS,'g-',...                                    %fit
             CuvetteS(:,1),fitS+2*deltaS,'r:',...                           %95% confidence interval for large samples
             CuvetteS(:,1),fitS-2*deltaS,'r:');
        title(['\bf Calibration, figure ' mat2str(i) ', small cuvette']...
            ,'FontSize',13)
        xlabel('grayscale value')
        ylabel('height of the liquid, mm')
        subplot(122)
        plot(CuvetteB(:,1),CuvetteB(:,2),'+',...                            %experimental points
             CuvetteB(:,1),fitB,'g-',...                                    %fit
             CuvetteB(:,1),fitB+2*deltaB,'r:',...                           %95% confidence interval for large samples
             CuvetteB(:,1),fitB-2*deltaB,'r:');
        title(['\bf Calibration, figure ' mat2str(i) ', big cuvette']...
            ,'FontSize',13)
        xlabel('grayscale value')
        ylabel('height of the liquid, mm')
        if GRregime ~= 0                                                    %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(i) 'regrstate'],'png');
            if GRregime == 1                                                %I want images only to be saved
                close(gcf)
            end
            cd(rootDir);
        end
    end
end
end

%% Function for the rotameter calibration
% i think it isnt very usefull to keep this in the code, because of
% symplifying the work with variable names
function [M,V_Pumpe] = rotameterCalib(filenames,DatenFluid)
% files - the first 3 numbers in filenames are volumetric flow rates in
%         L/h, so I need to read these, cell
% DatenFluid - regression coeficients for rotameter calibration, vector
%
% M     - dimensionless mass flow
% V_Pumpe-volumetric flow
%
% Function returns vector, but it is useless, all the values for same
% regimes are equal

% extracting parameters
g       = DatenFluid(1);                                                    %m/s^2
sigma   = DatenFluid(2);                                                    %N/m
rho     = DatenFluid(3);                                                    %kg/m^3
eta     = DatenFluid(4);                                                    %Pa s
Reg     = DatenFluid(5:end);                                                %pumpe constants

% computational part
parfor i = 1:numel(filenames)
    A         =regexp(filenames{i},'_','split');                            %split the filename, save all before = '_'
    Pumpe(i)  =str2double(A(1));
end
Pumpe=Pumpe';                                                               %vektor of volumetric flow rates, L/h

%Rotameter calibration for mass flow
m_Pumpe = polyval(Reg,Pumpe);                                               %doesn't depend on the degree of the polynomial
Cap     = sqrt(sigma/(rho*g));                                              %length of capilary
M       = (m_Pumpe/1000)./(eta*Cap);                                        %dimensionless mass flow
V_Pumpe = m_Pumpe./1000./rho;                                               %volumetric flow, m^3/s
end

%% Function for cutting rivulet into nCuts parts along the vertical
%% coordinate (Z)
function [YProfilPlatte XProfilPlatte] =...
    cutRiv(YProfilPlatte,nCuts,plateSize,GR,GRregime,storDir,rootDir)
%
%   [YProfilPlatte XProfilPlatte] =...
%       cutRiv(YProfilPlatte,nCuts,plateSize,GR)
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet
% nCuts             ... number of parts in which cut the rivulet (scalar)
% plateSize         ... size of the plate [width length], in m
% GR                ... variable for graphics (yes/no)
% GRregime          ... variable for graphics (show/save/show+save)
% storDir           ... directory for storing outputs
% rootDir           ... main execution directory
%
% OUTPUT variables
% YProfilPlatte     ... heights of the rivulet, reduced to mean values
%                       cell of matrixes (nPointsX x nCuts), mm
% XProfilPlatte     ... linspace coresponding to plate width, m
%

ZProfilPlatte= linspace(0,plateSize(2),nCuts)';                             %this is same for all the images


for i=1:numel(YProfilPlatte)
    Distance     = round(size(YProfilPlatte{i},2)/(nCuts+1));               %number of points in each mean profile
    if nCuts == 0 || Distance < 50                                          %if too much cuts is specified
        warning('Pers:ManCuts',['The number of cuts specified is bigger than'...
            ' number of rows necessary to obtain mean values for each cut'])
        fprintf(1,'Change the number of cuts\n');
        nCuts = input('nCuts = ');
        Distance     = round(size(YProfilPlatte{i},2)/(nCuts+1));           %need to recalculate distance
    end
    XProfilPlatte= linspace(0,plateSize(1),size(YProfilPlatte{i},1));       %this changes from image to image - auto coordinates, m
    for n = 1:nCuts
        YProfilPlatte{i}(:,n)=mean(YProfilPlatte{i}...                      %plot mean profiles in the place of the cut, over 50 pixels
            (:,n*Distance-25:n*Distance+25),2);
    end
    YProfilPlatte{i} = YProfilPlatte{i}(:,1:nCuts)*1e-3;                    %need to change size of output matrix, mm -> m
% ploting results
    if GR == 1
        figure;figSet_size(gcf,[700 550]);
        plot(XProfilPlatte,YProfilPlatte{i})
        axis tight
        xlabel('width of the plate, [m]')
        ylabel('height of the rivulet, [m]')
        if nCuts ~= 0
            ttl=title(['\bf Mean profiles of riv. ' mat2str(i)...
                ' over every ' mat2str(plateSize(2)/(nCuts+1)*1e3,3)...
                ' mm of the plate']);
        else
            ttl=title(['\bf Mean profiles of riv. ' mat2str(i)...
                ' over every ' mat2str(plateSize(2)/numel(ZProfilPlatte)*1e3,3)...
                ' mm of the plate']);
        end
        set(ttl,'FontSize',13,'Interpreter','tex')
        if GRregime ~= 0                                                    %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(i) 'cutprof'],'png');
            if GRregime == 1                                                %I want images only to be saved
                close(gcf)
            end
            cd(rootDir);
        end
    end
%     !! all the functions are at the time working with height of the
%     rivulet in mm !!
    YProfilPlatte{i} = YProfilPlatte{i}*1e3;                                %plots in m, m -> mm
end
end

%% Function for calculating the rivulet area and local width
function [IFArea RivWidth RivHeight minLVec minRVec] = ...
    RivSurf(YProfilPlatte,Treshold,plateSize)
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet (in mm?)
% Treshold          ... Treshold for distinguishing between bcgrnd and riv.
% plateSize         ... size of the plate [width length], in m
%
% OUTPUT variables
% IFArea            ... liquid/gas interfacial area of the rivulet, m^2,
%                       vector of scalar values for each image
% RivWidth          ... local width of the rivulet, matrix
%                       (numel(YProfilPlatte) x numel(ZDim))
% RivHeight         ... local max. height of the rivulet (for each cut)
%                       (numel(YProfilPlatte) x numel(ZDim))
% minLVec, minRVec  ... vertices of the rivulet (indexes), to cut of edges
%
% to keep the axis marking
% X -> width of the plate, m
% Y -> height of the film
% Z -> length of the plate, m
%
% Rq: some changes to the code had to be made because of different plates
% dimensions (as a results of automatic plate size estimation)
% => very carefully control the code for obtaining the interfacial area

% allocating space for variables
m = 0;n = 0;
mVec = zeros(1,numel(YProfilPlatte));nVec = mVec;
for i = 1:numel(YProfilPlatte)
    [mVec(i),nVec(i)]   = size(YProfilPlatte{i});                           %save dimension of YProfilPlatte arrays - should be same for all
    m = max([m mVec(i)]);n = max([n nVec(i)]);                              %find maximal size of plate
end
IFArea  = zeros(numel(YProfilPlatte),1);
RivWidth= zeros(numel(YProfilPlatte),n);
RivHeight=zeros(numel(YProfilPlatte),n);
minLVec = zeros(numel(YProfilPlatte),n);
minRVec = zeros(numel(YProfilPlatte),n);

for i = 1:numel(YProfilPlatte)
    % calculating the deltaX (distance between 2 pixels)
    deltaX  = plateSize(1)/mVec(i);                                         %distance between 2 points on X-axis (in m)
    deltaZ  = plateSize(2)/nVec(i);                                         %distance between 2 points on Z-axis (in m)
    
    [MaxVec,IndX] = max(YProfilPlatte{i});                                  %find maximum in every horizontal row and save its position
    dummyL        = YProfilPlatte{i}(1:max(IndX),:);                        %left side of the rivulet (in the middle, they are superposed)
    dummyR        = YProfilPlatte{i}(min(IndX):end,:);                      %right side of the rivulet

    for j = 1:numel(MaxVec)
        tmpIndL      = find(dummyL(:,j) >= Treshold,1,'first');             %find the first element bigger then Treshold (search from L->R)
        tmpIndR      = find(dummyR(:,j) <= Treshold,1,'first');             %find the first element lower then Treshold
        if isempty(tmpIndL) == 1                                            %low treshold
            tmpIndL = 1;
            warning('Pers:HoPiR',['Treshold is lower than liquid heigh'...
                ' for ale the left side of the rivulet'])
        elseif isempty(tmpIndR) == 1
            tmpIndR = numel(dummyR(:,j));
            warning('Pers:HoPiR',['Treshold is lower than liquid heigh'...
                ' for ale the right side of the rivulet'])
        end
        minLVec(i,j) = tmpIndL;
        minRVec(i,j) = tmpIndR;
    end
    minRVec(i,:) = minRVec(i,:)+(m-size(dummyR,1));                         %need to move right side of the rivulet by the length of skipped ind.

    % calculate local widths of i-th rivulet
    RivWidth(i,:) = (minRVec(i,:) - minLVec(i,:))*deltaX;                   %number of elements in rivulet x width of element
    
    % calculate the interfacial area of the rivulet
    % IFArea = lengthOfArc x lengthOfPlate(between 2 arcs)
    % convert YProfilPlatte to m
    YProfilPlatte{i}        = YProfilPlatte{i}*1e-3;                        %mm -> m
    RivHeight(i,1:nVec(i))  = max(YProfilPlatte{i});                        %saves maximum height of each part of the rivulet
    
    % for all horizontal cuts
    for j = 1:nVec(i)-1                                                     %need to omit the last piece (but the error wouldn't be big)
        % walking through the arc and adding the approximate length of the
        % element
        lArc  = 0;                                                          %restart the length counter
        for k = minLVec(i,j):minRVec(i,j)-1                                     %from left to right side of the rivulet
            deltaY = YProfilPlatte{i}(k+1,j) - YProfilPlatte{i}(k,j);
            lArc = lArc + sqrt(deltaY.^2 + deltaX.^2);                      %total length of arc + aproximate length of an element
        end
        if RivWidth(i,j) > 0.4*plateSize(1)                                 %this is necessary for IFArea correlations but
            warning('Pers:RIV2W',['breaking at line ' mat2str(j) ' of '...  %cannot be use for mass transfer calculations
                mat2str(n)...
                ' widht of the rivulet > ' mat2str(0.4*plateSize(1))])
            break
        end
        IFArea(i) = IFArea(i) + lArc*deltaZ;                                %length of j-th arc x length of an element of the plate length
    end

    clear dummyL dummyR                                                     %clear dummy variable at the end of each loop
end
end

%% Functions for saving files
function saveProf(XProfilPlatte,YProfilPlatte,minLVec,minRVec,files)
%
%   function saveProf(XProfilPlatte,YProfilPlatte,files)
%
% function for saving X and Y profiles on the plate into the file
% XProfilPlatte ... vector containing linspace which defines distances on
%                   the x-axes of the plate (width)
% YProfilPlatte ... cell (numel(YPP) = number of images, local heights of
%                   the rivulet
% minLVec,minRVec.. vectors containig indexes of edges of the rivulet
% files         ... cell containing the names of analyzed images
%
% function creates files with names corresponding to names of the images
% and saves there X-Y profile on the plate
% impairs columns: x-coordinates
% pairs   columns: heights of the rivulet correspondings to the x-coord.

for i = 1:numel(YProfilPlatte)                                              %1 file for each image
    widthF  = size(YProfilPlatte{i},2)*2;                                   %width of the file (number of columns)
    lengthF = max(minRVec(i,:)) - min(minLVec(i,:))+1;                      %length of the file (number of rows)
    tmp     = zeros(lengthF,widthF);                                        %create temporaty variable for data storage
    for j = 1:2:widthF
        k = (j+1)/2;                                                        %temp index
        zerLeft     = minLVec(i,k) - min(minLVec(i,:));                     %number of zeros I have to to from left side
        zerRight    = max(minRVec(i,:)) - minRVec(i,k);                     %number of zeros I have to add to the right side
        tmp(:,j) = tmp(:,j) +...                                            %write x-coordinates, in m !!
            [zeros(1,zerLeft) XProfilPlatte(minLVec(i,k):minRVec(i,k))...
            zeros(1,zerRight)]';
        tmp(:,j+1) = tmp(:,j+1) +...                                        %write local heights of the rivulet, in m !!
            [zeros(1,zerLeft)...
            YProfilPlatte{i}(minLVec(i,k):minRVec(i,k))*1e-3...
            zeros(1,zerRight)]';
    end
    clear k                                                                 %get rid of temp index
    nameStr = [files{i}(1:end-4) '.txt'];                                   %constructuin of the name string - name of the file \ .tif
    dlmwrite(nameStr,tmp,'delimiter','\t','precision','%5.6e')              %save data, in m
end
end

function saveMatSliced(Var,Pars,files,fileNm)
%
%   function saveMatSliced(Var,Pars,files,fileNm)
%
% function for saving matrix-forme variables into different files depending
% on the pumpe/flow regime
% this concerns variables like RivWidth/RivHeight/mSpeed
%
% INPUT variables
% Var   ... variable to be saved/written into a file
%           must be in shape (numel(YProfilPlatte) x numel(ZDim)), where
%           numel(YProfilPlatte) is number of images and numel(ZDim) is
%           number of horizontal cuts along the length of the plate
% Pars  ... another parametres to be saved into file
%           Pars{1} = M (dimensionless flow),
%           Pars{2} = plateSize
%           Pars{3} = nCuts (number of cuts)
% files ... cell of filenames of analyzed images
%           every filename must have structure ddd_ddd.tif (d - digit)
% fileNm... filename, string
% !! saving locations must be handled outside this function !! -
% unnecessary junk

% extract parameters
M         = Pars{1};
plateSize = Pars{2};
nCuts     = Pars{3};

% calculate distances
deltaDis  = plateSize(2)/(nCuts+1);                                         %distance between 2 cuts, m
DistVec   = linspace(deltaDis,plateSize(2)-deltaDis,nCuts);                 %dont measure 0 and plateSize(2) (edges)
n         = numel(DistVec);                                                 %number of lines in the file

% for each regime (001/005) create 1 file and save Var into this file
tmpVec = zeros(1,numel(files));                                             %temporary vector for slicing mVar
for i = 1:numel(files)
    vol        = regexp(files{i}, '[\_ \.]', 'split');                      %split file name
    tmpVec(i)  = str2double(vol{2});clear vol;                              %create number from digits in the file names
    slInd      = [find(tmpVec == 1) numel(tmpVec)+1];                       %find slicing indexes, last index must be length of Vec + 1
end

for i = 1:length(slInd)-1                                                   %for every regime
    tmpMat  = [Var(slInd(i):slInd(i+1)-1,:)' zeros(n,1) ...                 %base variable data
        mean(Var(slInd(i):slInd(i+1)-1,:),1)'...                            %mean values for each cut
        std(Var(slInd(i):slInd(i+1)-1,:),[],1)'...                          %standard deviation for each cut
        [M(slInd(i));zeros(n-1,1)]...                                       %dimensionless flow rate during regime
        DistVec'];
    nameStr = [fileNm '_' files{slInd(i)}(1:3) '.txt'];                     %create filename
    dlmwrite(nameStr,tmpMat,'delimiter','\t','precision','%5.6e')           %write write data matrix into file, SI unist
end
end

function saveCorrData(varOUT,varIN,fileNM)
%
%  saveCorrData(varOUT,varIN,fileNM)
%
% function for saving data for contstruction of correlations
%
% INPUT variables
% varOUT    ... output variables for correlation (ie IFArea)
% varIN     ... input variables for correlations (ie sigma, eta, M)
% fileNM    ... name of output file, fileNM.txt
%
% file has structure of:
% varIN \t varOUT
%
% varOUT should be a vector (n x 1) or matrix (n x m)
% varIN needs to be cell with fields of
%   ... scalar
%   ... vector (n x 1)

% processing input
numRows = size(varOUT,1);                                                   %number of rows in output variable
tmpMat  = zeros(numRows,numel(varIN) + size(varOUT,2));
for i = 1:numel(varIN)
    if size(varIN{i},2) == 1                                                %scalar value
        tmpMat(1:numRows,i) = varIN{i};                                     %write the same value in all fields
    else
        tmpMat(:,i) = varIN{i};
    end
end
tmpMat(:,numel(varIN)+1:end) = varOUT;

dlmwrite(fileNM,tmpMat,'delimiter','\t','precision','%5.6e')                %write write data matrix into file, SI unist
end

%% Functions for Graphics
% Function handle for setting figure size
function figSet_size(figHandle,size)
set(figHandle,'Units','Pixels',...                                          %nastavi pevnou velikost zobrazovaneho okna
    'Position',[10 10 size(1) size(2)],'Color',[1 1 1]);
end
