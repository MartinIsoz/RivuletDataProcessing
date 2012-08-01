function OUT = rivuletProcessing(handles)
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
% For better cohesion of the programs, the input parameters are directly
% loaded from handles variable and outputs are stored in the same place.
%
% -handles structure must have fields metricdata and prgmcontrol.
% - metricdata is structure with data created during the program evaluation
% - prgmcontrol is structure with variebles for controlling program run
%
% INPUT variables
% => in handles.metricdata:
% mandatory:
% ------------------
% daten     ...     cell with substracted images data
% OR
% imNames   ...     cell with images names to be loaded from.!! this field
%                   has to be present all the times because of the saving
%                   outputs into files !!
% subsImDir ...     location of the directory with subtracted images to be
%                   processed
% ------------------
% Treshold  ...     treshold for distinguishing between the rivulet and the
%                   noise on the plate
% FSensitivity.     filter sensitivity for image smoothing
% EdgCoord  ...     coordinates of plate and cuvette edges on each image,
%                   matrix nImages x 10
%                   [xCMS yCLS yCHS xCMB yCLB yCHB xL yL xH yH]
% fluidData ...     data concerning the liquid phase, regression
%                   coeficients for rotameter calibration, surface tension,
%                   density and dynamic viscosity of the liquid phase
%                   (formerly stored in Konstanten_Fluid.txt)
% storDir   ...     directory for storing outputs
% rootDir   ...     root directory for program execution
% RivProcPars..     cell with additional parameters for rivulet
%                   processing (changeables through menus in the main
%                   program).
%   required cells:
%                   - empty [] => use default values
%                   OR
%                   - plateSize, size of the plate in metres
%                     default: [0.15 0.30]
%                   - InclAngle, inclination angle of the plate
%                     default: 60 (in degrees)
%                   - filmTh, thickness of the film in cuvettes in mm +
%                     width of the cuvettes in pixels
%                     default: [1.93 0.33 6 2.25 80]
%                   - RegrPlate, degree of polynomial to be used in
%                     conversion if image from grayscale values into
%                     distances
%                     default: 2
%                   - nCuts, number of centered cuts to make along the
%                     rivulet
%                     default: 5
%                   - countercurrent gas flow, m3/s
%                     default: 0
%
% => in handles.prgmcontrl
% GR        ...     structure with graphics output specifications
%   required fields:
%                   - GR.regr       = 0/1 - graphs from regression
%                   - GR.contour    = 0/1 - view from top
%                   - GR.profcompl  = 0/1 - complete profile
%                   - GR.profcut    = 0/1 - mean profiles in cuts
%                   - GR.regime     = 0/1/2 - show/save/show+save
%                   - GR.format     = string - format for SAVEAS
%
% OUTPUT variable
% OUT   ... structure with same data as are saved into files
% OUT.profiles  ... cell with mean profiles in cuts for every processed
%                   image
% OUT.mSpeed    ... cells with sliced var data, last cell is string with
% OUT.RivWidth      regimes of the pumpe
% OUT.RivHeight
% OUT.IFACorr   ... double with data for correlations
%
% other OUTPUTS - text files
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
% - I'd prefere if all the code was written in basic SI units (mm -> m)
%
% To Do:
% - plot, dependence of IFArea on break criterium

%% Creating subdirectories
% is taken care of in "Choose storDir"

%% Processing function input

plateSize   = handles.metricdata.RivProcPars{1};                            %now these parameters are set by default
InclAngle   = handles.metricdata.RivProcPars{2};
filmTh      = handles.metricdata.RivProcPars{3};
RegressionPlate = handles.metricdata.RivProcPars{4};
nCuts       = handles.metricdata.RivProcPars{5};
GasFlow     = handles.metricdata.RivProcPars{6};

% extracting programcontrol
DNTLoadIM = handles.prgmcontrol.DNTLoadIM;
GR        = handles.prgmcontrol.GR;

% extracting metricdata
% data
files   = handles.metricdata.imNames;                                       %names of images to be processed
if DNTLoadIM ~= 1                                                           %if images are loaded
    daten = handles.metricdata.daten;                                       %save them into temporary function variable
end
% directories
subsImDir = handles.metricdata.subsImDir;
smImDir   = [subsImDir '/Smoothed'];                                        %directory with smoothed images
storDir   = handles.metricdata.storDir;
rootDir   = handles.metricdata.rootDir;
plotDir   = [storDir '/Plots'];                                             %directory for saving plots
tmpfDir   = [storDir '/tmp'];                                               %directory for saving temporary files
% program execution parameters
Treshold  = handles.metricdata.Treshold;
FilterSensitivity = handles.metricdata.FSensitivity;
EdgCoord  = handles.metricdata.EdgCoord;
fluidData = handles.metricdata.fluidData;

% auxiliary variable
nImages = numel(files);                                                     %number of processed images

%% Rotameter calibration
% Pumpenkonstante und Stoffwerte
[M,V_Pumpe]= rotameterCalib(files,fluidData);                               %rotameter calibration
sigma = fluidData(2);                                                       %save input parameters for correlations
rho   = fluidData(3);
eta   = fluidData(4);
clear fluidData

%% Importing images into workspace
% is taken care of in "Load Images"

%% Subtraction of frames minus background
% is taken care of in "Load Images"

%% Finding edges of cuvettes and plate
% is taken care of in "Image Processing"

%% Image conversion from grayscale values to distances
% heights of the film in mm
if DNTLoadIM == 0                                                           %are all the data loaded?
    handles.statusbar = statusbar(handles.MainWindow,...
        ['Converting grayscale values into distances for all images ',...   %updating th statusbar
        'loaded in memory']);
    YProfilPlatte = ImConv(daten,EdgCoord,filmTh,RegressionPlate,...        %if the are, I can process them all at once
        GR.regr,GR.regime,GR.format,storDir,rootDir);
    tmpCell = cell(size(YProfilPlatte));                                    %create empty cell
    tmpCell(:) = {fspecial('disk',FilterSensitivity)};
    YProfilPlatte = cellfun(@imfilter,YProfilPlatte,...                     %apply selected filter to YProfilPlatte
        tmpCell,'UniformOutput',0);
    parfor i = 1:nImages
        tmpCell(i) = {[smImDir '/' files{i}]};                              %create second argument for cell function 
    end
    set(handles.statusbar.ProgressBar,'Visible','off');
    set(handles.statusbar,'Text','Saving smoothed images');
    cellfun(@imwrite,YProfilPlatte,tmpCell);                                %write images into smoothed folder (under original names)
else                                                                        %otherwise, i need to do this image from image...
    mkdir(tmpfDir);                                                         %I need to create directory for temporary files
    for i = 1:nImages
        handles.statusbar = statusbar(handles.MainWindow,...
            ['Converting grayscale values into distaces ',...
            'for image %d of %d (%.1f%%)'],...                              %updating statusbar
            i,nImages,100*i/nImages);
        set(handles.statusbar.ProgressBar,...
            'Visible','on', 'Minimum',0, 'Maximum',nImages, 'Value',i);
        tmpIM = {imread([subsImDir '/' files{i}])};                         %load image from substracted directory and save it as cell
        tmpIM = ImConv(tmpIM,EdgCoord,filmTh,RegressionPlate,...            %convert it to distances
            GR.regr,GR.regime,GR.format,storDir,rootDir,i);
        tmpIM = imfilter(tmpIM{:},...                                       %use selected filter
            fspecial('disk',FilterSensitivity));
        imwrite(tmpIM,[smImDir '/' files{i}]);                              %save it into 'Smoothed' folder (but under original name)
        save([tmpfDir '/' files{i}(1:end-4)],'tmpIM');                      %save obtained data matrix into temporary directory
    end
end

%% Saving smoothed images and obtaining visualizations of the riv.
% store and plot smoothed images
if GR.contour == 1 || GR.regime == 1                                        %if any of the graphics are wanted, enter the cycle
    set(handles.statusbar.ProgressBar,'Visible','off');                     %update statusbar
    set(handles.statusbar,'Text','Creating graphic output')
    for i=1:numel(files) %#ok<*FORPF>                                       %for each image
        if DNTLoadIM == 1
            load([tmpfDir '/' files{i}(1:end-4) '.mat']);                   %if images are not present in handles, load them from tmpfDir
        else
            tmpIM   = YProfilPlatte{i};                                     %if they are, just resave current image
            YProfilPlatte{i} = YProfilPlatte{i}';                           %transpose image for next functions
        end
        if GR.contour == 1                                                  %contour visualization
            % graphical output, look on the rivulets from top
            figure;figSet_size(gcf,[400 700])
            XProfilPlatte = linspace(0,plateSize(1),...
                size(tmpIM,2));                                             %width coord, number of columns in YProfilPlatte
            ZProfilPlatte = linspace(0,plateSize(2),...
                size(tmpIM,1));                                             %length coord, number of rows in YProfilPlatte
            [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
            contour(XX,ZZ,tmpIM);                                           %here I keep rivulet height in mm because it looks better
            title(['\bf Look on the rivulet ' mat2str(i) ' from top'],...
                'FontSize',13)
            xlabel('width coordinate, [m]');
            ylabel('length coordinate, [m]');
            colbarh = colorbar('Location','East');                          %add the colorbar - scale
            ylabel(colbarh,'rivulet height, [mm]')                          %set units to colorbar
            axis ij                                                         %switch axis to match photos
            if GR.regime ~= 0                                               %if I want to save the images
                saveas(gcf,[plotDir '/riv' mat2str(i) 'fromtop'],...
                    GR.format);
                if GR.regime == 1                                           %I want images only to be saved
                    close(gcf)
                end
            end
        end
        if GR.profcompl == 1                                                %Y-Profile over entire plate width
            figure;figSet_size(gcf,[1100 600])
            XProfilPlatte = linspace(0,plateSize(1),...
                size(tmpIM,2));
            ZProfilPlatte = linspace(0,plateSize(2),...
                size(tmpIM,1));
            [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
            mesh(XX,ZZ,tmpIM)                                               %I need to convert the liquid height into mm
            axis tight
            xlabel('width of the plate, [m]')
            ylabel('length of the plate, [m]')
            zlabel('height of the rivulet, [mm]')
            title(['\bf Profile of the rivulet ' mat2str(i)],'FontSize',13);
            if GR.regime ~= 0                                               %if I want to save the images
                saveas(gcf,[plotDir '/riv' mat2str(i) 'complprof'],...
                    GR.format);
                if GR.regime == 1                                           %I want images only to be saved
                    close(gcf)
                end
            end
        end
    end
end

%% Read the individual profiles over the length of the plate -> rivulet
%% area
% !! Rivulet height maximum should be in the rivulet, not around !!
% read the profile from the maximum to the left and right, stop after the
% fall under treshold thickness
% lets draw the rivulet (from the maximum to the treshold, for each row)

if DNTLoadIM == 1
    IFArea = zeros(numel(files),1);                                         %images are not loaded, preallocat variable
    for i = 1:nImages
        handles.statusbar = statusbar(handles.MainWindow,...
            'Calculating interfacial area of rivulet %d of %d (%.1f%%)',... %updating statusbar
            i,nImages,100*i/nImages);
        set(handles.statusbar.ProgressBar,...
            'Visible','on', 'Minimum',0, 'Maximum',nImages, 'Value',i);
        load([tmpfDir '/' files{i}(1:end-4) '.mat']);                       %if images are not present in handles, load them from tmpfDir
        IFArea(i)= RivSurf({tmpIM'},Treshold,plateSize);                    %I need to transpose tmpIM -> coherence with YProfilPlatte
    end
else
    handles.statusbar = statusbar(handles.MainWindows,...
        'Calculating interfacial area of rivulets');                        %update statusbar
    IFArea = RivSurf(YProfilPlatte,Treshold,plateSize);                     %this function does not need graphical output
end

%% Calculate mean values of riv. heights over each rivLength/nCuts of the
%% rivulet
% the number of cuts (nCuts) << number of rows of the photo, so I will load
% all the cutted rivulets into memory (the memory consumption shouldn be
% extremely high - if the user will not choose like 300 cuts...)
if DNTLoadIM == 1
    YProfilPlatte = cell(1,numel(files));                                   %preallocate variable for YProfilPlatte
    for i = 1:numel(files)
        handles.statusbar = statusbar(handles.MainWindow,...
            'Calculating mean profiles for image %d of %d (%.1f%%)',...     %updating statusbar
            i,nImages,100*i/nImages);
        set(handles.statusbar.ProgressBar,...
            'Visible','on', 'Minimum',0, 'Maximum',nImages, 'Value',i);
        load([tmpfDir '/' files{i}(1:end-4) '.mat']);                       %if images are not present in handles, load them from tmpfDir
        [YProfilPlatte(i),XProfilPlatte]=cutRiv({tmpIM'},nCuts,plateSize,...%call with calculation variables
            GR.profcut,GR.regime,GR.format,storDir,rootDir,i);              %auxiliary variables for graphics and data manipulation
    end
    rmdir(tmpfDir,'s');                                                     %remove unnecessary temporary folder with all contents
else
    set(handles.statusbar,'Text','Calculating mean profiles along the rivulets');%update statusbar
    [YProfilPlatte,XProfilPlatte]=cutRiv(YProfilPlatte,nCuts,plateSize,...  %call with calculation variables
        GR.profcut,GR.regime,GR.format,storDir,rootDir);                    %auxiliary variables for graphics and data manipulation
end

%% Calculate variables to be saved, mean values in each cut
% - if I understand it correctly, it is the same calculation as before,
% only for the mean profiles - these 2 calculations can be put together in
% 1 function and called separately

set(handles.statusbar.ProgressBar,'Visible','off');                         %update statusbar
set(handles.statusbar,'Text','Calculating output data of the program');
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
    handles.statusbar = statusbar(handles.MainWindow,...
        'Calculating mean speed in cuts for image %d of %d (%.1f%%)',...    %updating statusbar
        i,nImages,100*i/nImages);
    set(handles.statusbar.ProgressBar,...
        'Visible','on', 'Minimum',0, 'Maximum',nImages, 'Value',i);
    for j = 1:size(RivWidth2,2)
        SurfMat = trapz(XProfilPlatte(minLVec(i,j):minRVec(i,j)),...        %rows - number of images, columns - number of cuts
            YProfilPlatte{i}(minLVec(i,j):minRVec(i,j),j)*1e-3);            %again, conversion mm -> m
        mSpeed(i,j)  = V_Pumpe(i)/SurfMat;                                  %local mean speed V_/S, m/s
    end
end

%% Saving results in text files

set(handles.statusbar.ProgressBar,'Visible','off');
set(handles.statusbar,'Text','Saving data into text files');

% 1. Smoothed/averaged profiles
cd([storDir '/Profile'])
% in 1 file for each image, i will save:
% impairs columns: x-coordinates
% pairs   columns: heights of the rivulet correspondings to the x-coord.
OUT.Profiles = saveProf(XProfilPlatte,YProfilPlatte,minLVec,minRVec,files);
cd(rootDir)

sPars = {M GasFlow plateSize nCuts};                                        %common variables for all saved files

% 2. Local mean speed in cuts
cd([storDir '/Speed'])
OUT.mSpeed = saveMatSliced(mSpeed,sPars,files,'Speed');
cd(rootDir)

% 3. Width of the rivulets (local)
cd([storDir '/Width'])
OUT.RivWidth = saveMatSliced(RivWidth2,sPars,files,'Width');
cd(rootDir)

% 4. Max height of the rivulets
cd([storDir '/Height'])
OUT.RivHeight = saveMatSliced(RivHeight2,sPars,files,'Height');
cd(rootDir)

% 5. Interfacial area of the rivulets
cd([storDir '/Correlation'])
varIN = {sigma rho eta M InclAngle GasFlow};                                %input variables for correlation
varOUT= IFArea;                                                             %output variable for correlation
OUT.IFACorr = saveCorrData(varOUT,varIN,'IFAreaCorr');
cd(rootDir)

set(handles.statusbar,'Text','Rivulet processing ended succesfully');
end



%% Function to convert gray values ​​in distances
% Is required for the image and the regression coefficients of quadratic regression
% 21/11/2011, rewritten July 2012, by Martin Isoz

function ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
    GR,GRregime,GRformat,storDir,rootDir,imNumber)
%
%   ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
%    GR,GRregime,GRformat,storDir,rootDir,[imNumber])
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
% GRformat          ... format of save graphics (compatible with SAVEAS)
% storDir           ... directory for storing outputs
% rootDir           ... main execution directory
% imNumber  ... optional input parameter, if the images are processed 1 by
%               1, this i the number of the currently processed image
%
% OUTPUT variebles
% ImgConv   ... converted image, gray values -> local heights of the riv,
%               in mm

ImgConv     = cell(1,numel(ImData));                                        %preallocation of output variable
for i = 1:numel(ImData)                                                     %for each file
    if nargin < 9
        imNumber = i;
    end
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
        title(['\bf Calibration, figure ' mat2str(imNumber) ', small cuvette']...
            ,'FontSize',13)
        xlabel('grayscale value')
        ylabel('height of the liquid, mm')
        subplot(122)
        plot(CuvetteB(:,1),CuvetteB(:,2),'+',...                            %experimental points
             CuvetteB(:,1),fitB,'g-',...                                    %fit
             CuvetteB(:,1),fitB+2*deltaB,'r:',...                           %95% confidence interval for large samples
             CuvetteB(:,1),fitB-2*deltaB,'r:');
        title(['\bf Calibration, figure ' mat2str(imNumber) ', big cuvette']...
            ,'FontSize',13)
        xlabel('grayscale value')
        ylabel('height of the liquid, mm')
        if GRregime ~= 0                                                    %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(imNumber) 'regrstate'],GRformat);
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
    cutRiv(YProfilPlatte,nCuts,plateSize,GR,GRregime,GRformat,storDir,rootDir,imNumber)
%
%   [YProfilPlatte XProfilPlatte] =...
%       cutRiv(YProfilPlatte,nCuts,plateSize,GR,GRregime,GRformat,storDir,rootDir,imNumber)
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet
% nCuts             ... number of parts in which cut the rivulet (scalar)
% plateSize         ... size of the plate [width length], in m
% GR                ... variable for graphics (yes/no)
% GRregime          ... variable for graphics (show/save/show+save)
% GRformat          ... format of saved graphics (compatible with SAVEAS)
% storDir           ... directory for storing outputs
% rootDir           ... main execution directory
% imNumber          ... optional arguments, if the images are processed 1
%                       by 1, this is the number of current image
%
% OUTPUT variables
% YProfilPlatte     ... heights of the rivulet, reduced to mean values
%                       cell of matrixes (nPointsX x nCuts), mm
% XProfilPlatte     ... linspace coresponding to plate width, m
%

ZProfilPlatte= linspace(0,plateSize(2),nCuts)';                             %this is same for all the images


for i=1:numel(YProfilPlatte)
    if nargin < 8
        imNumber = i;
    end
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
            ttl=title(['\bf Mean profiles of riv. ' mat2str(imNumber)...
                ' over every ' mat2str(plateSize(2)/(nCuts+1)*1e3,3)...
                ' mm of the plate']);
        else
            ttl=title(['\bf Mean profiles of riv. ' mat2str(imNumber)...
                ' over every ' mat2str(plateSize(2)/numel(ZProfilPlatte)*1e3,3)...
                ' mm of the plate']);
        end
        set(ttl,'FontSize',13,'Interpreter','tex')
        if GRregime ~= 0                                                    %if I want to save the images
            cd([storDir '/Plots']);
            saveas(gcf,['riv' mat2str(imNumber) 'cutprof'],GRformat);
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

% processing input
Treshold= Treshold*1e-3;                                                    %convert treshold to m

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
    YProfilPlatte{i} = YProfilPlatte{i}*1e-3;                               %mm -> m
    
    % find width of the rivulet
    [MaxVec,IndX] = max(YProfilPlatte{i});                                  %find maximum in every horizontal row and save its position
    for j = 1:numel(MaxVec)
        tmpVecL      = YProfilPlatte{i}(1:IndX(j),j);                       %left side of the rivulet
        tmpVecR      = YProfilPlatte{i}(IndX(j)+1:end,j);                   %right side of the rivulet
        tmpIndL      = find(tmpVecL >= Treshold,1,'first');                 %find the first element bigger then Treshold (search from L->R)
        tmpIndR      = find(tmpVecR <= Treshold,1,'first');                 %find the first element lower then Treshold
        if isempty(tmpIndL) == 1                                            %there werent found any value higher then treshold on left side of r.
            tmpIndL = numel(tmpVecL);
            warning('Pers:LoPiL',['Treshold is higher than liquid heigh'...
                ' for all the left side of the rivulet'])
        elseif isempty(tmpIndR) == 1                                        %there werent found any value lower than treshold on right side of r.
            tmpIndR = numel(tmpVecR);
            warning('Pers:HoPiR',['Treshold is lower than liquid heigh'...
                ' for all the right side of the rivulet'])
        elseif tmpIndL == 1                                                 %first value bigger than treshold is first value on the plate
            warning('Pers:HoPiL',['Treshold is lower than liquid heigh'...
                ' for all the left side of the rivulet'])
        elseif tmpIndR == 1                                                 %first value of the right side of the rivulet is smaller than Tr.
            warning('Pers:LoPiR',['Treshold is higher than liquid heigh'...
                ' for all the right side of the rivulet'])
        end
        minLVec(i,j) = tmpIndL;
        minRVec(i,j) = tmpIndR + numel(tmpVecL);                            %I need to add length of the left side of the rivulet
    end

    % calculate local widths and heights of i-th rivulet
    RivWidth(i,:) = (minRVec(i,:) - minLVec(i,:))*deltaX;                   %number of elements in rivulet x width of element
    RivHeight(i,1:nVec(i))  = MaxVec;                                       %saves maximum height of each part of the rivulet, in m
    
    % calculate the interfacial area of the rivulet
    % IFArea = lengthOfArc x lengthOfPlate(between 2 arcs)
    
    % for all horizontal cuts
    for j = 1:nVec(i)-1                                                     %need to omit the last piece (but the error wouldn't be big)
        % walking through the arc and adding the approximate length of the
        % element
        lArc  = 0;                                                          %restart the length counter
        for k = minLVec(i,j):minRVec(i,j)-1                                 %from left to right side of the rivulet
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
function ProfOUT = saveProf(XProfilPlatte,YProfilPlatte,minLVec,minRVec,files)
%
%   ProfOUT = function saveProf(XProfilPlatte,YProfilPlatte,files)
%
% function for saving X and Y profiles on the plate into the file
%
% INPUT variables
% XProfilPlatte ... vector containing linspace which defines distances on
%                   the x-axes of the plate (width)
% YProfilPlatte ... cell (numel(YPP) = number of images, local heights of
%                   the rivulet
% minLVec,minRVec.. vectors containig indexes of edges of the rivulet
% files         ... cell containing the names of analyzed images
%
% OUTPUT variables
% ProfOUT       ... cell with profiles for the each image
%
% OTHER OUTPUTS
% function creates files with names corresponding to names of the images
% and saves there X-Y profile on the plate
% impairs columns: x-coordinates
% pairs   columns: heights of the rivulet correspondings to the x-coord.

% preallocate output variable
ProfOUT = cell(1,numel(YProfilPlatte));

% save data and fill in output
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
    ProfOUT{i} = tmp;                                                       %save created matrix also in output
end
end

function VarOUT = saveMatSliced(Var,Pars,files,fileNm)
%
%   VarOUT = function saveMatSliced(Var,Pars,files,fileNm)
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
%           Pars{2} = V_gas (volumetric gas flow, m3/s)
%           Pars{3} = plateSize
%           Pars{4} = nCuts (number of cuts)
% files ... cell of filenames of analyzed images
%           every filename must have structure ddd_ddd.tif (d - digit)
% fileNm... filename, string
%
% OUTPUT variables
% VarOUT... cell with matrix for all regimes
%
% !! saving locations must be handled outside this function !! -
% unnecessary junk

% extract parameters
M         = Pars{1};
V_gas     = Pars{2};
plateSize = Pars{3};
nCuts     = Pars{4};

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

% preallocate output variable
VarOUT = cell(1,length(slInd));

% create data files and fill in output
for i = 1:length(slInd)-1                                                   %for every regime
    tmpMat  = [Var(slInd(i):slInd(i+1)-1,:)' zeros(n,1) ...                 %base variable data
        mean(Var(slInd(i):slInd(i+1)-1,:),1)'...                            %mean values for each cut
        std(Var(slInd(i):slInd(i+1)-1,:),[],1)'...                          %standard deviation for each cut
        [M(slInd(i));zeros(n-1,1)]...                                       %dimensionless flow rate during regime
        [V_gas;zeros(n-1,1)]...                                             %volumetric gas flow rate during experiments
        DistVec'];
    nameStr = [fileNm '_' files{slInd(i)}(1:3) '.txt'];                     %create filename
    dlmwrite(nameStr,tmpMat,'delimiter','\t','precision','%5.6e')           %write write data matrix into file, SI unist
    VarOUT{i} = tmpMat;                                                     %save i-th regime into cell output
    VarOUT{end}(i) = {files{slInd(i)}(1:3)};
end
end

function CorMat = saveCorrData(varOUT,varIN,fileNM)
%
%  CorMat = saveCorrData(varOUT,varIN,fileNM)
%
% function for saving data for contstruction of correlations
%
% INPUT variables
% varOUT    ... output variables for correlation (ie IFArea)
% varIN     ... input variables for correlations (ie sigma, eta, M)
% fileNM    ... name of output file, fileNM.txt
%
% OUTPUT variables
% CorMat    ... data matrix with the same structure as output file 
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
CorMat  = zeros(numRows,numel(varIN) + size(varOUT,2));
for i = 1:numel(varIN)
    if size(varIN{i},2) == 1                                                %scalar value
        CorMat(1:numRows,i) = varIN{i};                                     %write the same value in all fields
    else
        CorMat(:,i) = varIN{i};
    end
end
CorMat(:,numel(varIN)+1:end) = varOUT;

dlmwrite(fileNM,CorMat,'delimiter','\t','precision','%5.6e')                %write write data matrix into file, SI unist

end

%% Functions for Graphics
% Function handle for setting figure size
function figSet_size(figHandle,size)
set(figHandle,'Units','Pixels',...                                          %nastavi pevnou velikost zobrazovaneho okna
    'Position',[10 10 size(1) size(2)],'Color',[1 1 1]);
end
