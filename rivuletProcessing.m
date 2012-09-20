function OUT = rivuletProcessing(handles)
%
%   function rivuletProcessing(handles)
%
% My modification of Andres function for evaluation of rivulet-LIF images
% Required parameters:
% 1 Threshold for distinguishing between background and rivulet in mm
% Threshold recommended: 1e-3
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
%                   noise on the plate (base on the derivative of the
%                   profile, dY/dX < Treshold -> dY/dX == 0
% FSensitivity.     filter sensitivity for image smoothing
% EdgCoord  ...     coordinates of plate and cuvette edges on each image,
%                   matrix 1 x 10 -> !! cammera cannot be moved during
%                   experiments !!
%                   [xCMS yCLS yCHS xCMB yCLB yCHB xL yL xH yH]
% fluidData ...     data concerning the liquid phase, regression
%                   coeficients for rotameter calibration, surface tension,
%                   density and dynamic viscosity of the liquid phase
%                   (formerly stored in Konstanten_Fluid.txt)
% fluidType ...     string containing type of the selected liquid
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
% DNTLoadIM ...     0 - images are loaded into structure
%
% OUTPUT variable
% OUT       ... structure with same data as are saved into files
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
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
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

%% Disabling useless warnings
%#ok<*LAXES>                                                                %axes have to be in loops, otherwise they would be created in the MW

%% Creating subdirectories
% is taken care of in "Choose storDir"

%% Processing function input

% experimental setup parameters
plateSize   = handles.metricdata.RivProcPars{1};
InclAngle   = handles.metricdata.RivProcPars{2};
filmTh      = handles.metricdata.RivProcPars{3};
RegressionPlate = handles.metricdata.RivProcPars{4};
nCuts       = handles.metricdata.RivProcPars{5};
FFactor     = handles.metricdata.RivProcPars{6};

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
if GR.regime ~= 0                                                           %if user wants to save the plots
    plotDir   = [storDir '/Plots'];                                         %directory for saving plots
end
tmpfDir   = [storDir '/tmp'];                                               %directory for saving temporary files
% program execution parameters
Treshold  = handles.metricdata.Treshold;
FilterSensitivity = handles.metricdata.FSensitivity;
EdgCoord  = handles.metricdata.EdgCoord;
fluidType = handles.metricdata.fluidType;

% auxiliary variable
nImages = numel(files);                                                     %number of processed images

%% Rotameter calibration
% create fluidData by calling the fluid database function for current
% chosen liquid and experimental parameters
fluidData = fluidDataFcn(fluidType,InclAngle);                              %call database function
% call calibration function for current fluidData
[M,V_Pumpe]= rotameterCalib(files,fluidData);                               %rotameter calibration
sigma = fluidData(2);                                                       %save input parameters for correlations
rho   = fluidData(3);
eta   = fluidData(4);
clear fluidData

%% Creating parameters for plots descriptions
% to each plot, there is added description specifying the dimensionless
% flow rate, f-factor, type of the liquid and measurement number (within
% the measurements with the same dimensionless flow rates)
tmpVar = zeros(1,nImages);
parfor i = 1:nImages
    tmpVar(i) = str2double(files{i}(5:end-4));
end
txtPars = {M FFactor tmpVar fluidType InclAngle};                           %parameters for graphs descriptions

%% Importing images into workspace
% is taken care of in "Load Images"

%% Subtraction of frames minus background
% is taken care of in "Load Images"

%% Finding edges of cuvettes and plate
% is taken care of in "Image Processing"

%% Image conversion from grayscale values to distances and saving of
%% smoothed images
% heights of the film in mm
if DNTLoadIM == 0                                                           %are all the data loaded?
    handles.statusbar = statusbar(handles.MainWindow,...
        ['Converting grayscale values into distances for all images ',...   %updating th statusbar
        'loaded in memory']);
    YProfilPlatte = ImConv(daten,EdgCoord,filmTh,RegressionPlate,...        %if the are, I can process them all at once
        GR.regr,GR.regime,GR.format,txtPars,storDir,rootDir);
    tmpCell = cell(1,nImages);                                              %create empty cell with number of elements corresponding to nImages
    tmpCell(:) = {fspecial('disk',FilterSensitivity)};
    YProfilPlatte = cellfun(@imfilter,YProfilPlatte,...                     %apply selected filter to YProfilPlatte
        tmpCell,'UniformOutput',0);
    parfor i = 1:nImages
        tmpCell(i) = {[smImDir '/' files{i}]};                              %create second argument for cell function 
    end
    handles.statusbar.ProgressBar.setVisible(false);                        %hide progressbar
    set(handles.statusbar,'Text','Saving smoothed images');
    cellfun(@imwrite,YProfilPlatte,tmpCell);                                %write images into smoothed folder (under original names)
else                                                                        %otherwise, i need to do this image from image...
    mkdir(tmpfDir);                                                         %I need to create directory for temporary files
    for i = 1:nImages
        handles.statusbar = statusbar(handles.MainWindow,...
            ['Converting grayscale values into distaces ',...
            'for image %d of %d (%.1f%%)'],...                              %updating statusbar
            i,nImages,100*i/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(nImages);
        handles.statusbar.ProgressBar.setValue(i);
        tmpIM = {imread([subsImDir '/' files{i}])};                         %load image from substracted directory and save it as cell
        tmpIM = ImConv(tmpIM,EdgCoord,filmTh,RegressionPlate,...            %convert it to distances
            GR.regr,GR.regime,GR.format,txtPars,storDir,rootDir,i);
        tmpIM = imfilter(tmpIM{:},...                                       %use selected filter
            fspecial('disk',FilterSensitivity));
        imwrite(tmpIM,[smImDir '/' files{i}]);                              %save it into 'Smoothed' folder (but under original name)
        save([tmpfDir '/' files{i}(1:end-4) '.mat'],'tmpIM');               %save obtained data matrix into temporary directory
    end
end

% Note: now I have stored smoothed images (only the plate) into Smoothed
% folder and (or) present YProfilPlatte into handles. YProfilPlatte is a
% cell of size (1,nImages) and each of its elements is a matrix with same
% size (xR - xL, yB - yT)

%% Read the individual profiles over the length of the plate -> rivulet
%% area
% !! Rivulet height maximum should be in the rivulet, not around !!
% read the profile from the maximum to the left and right, stop after the
% fall under treshold thickness
% lets draw the rivulet (from the maximum to the treshold, for each row)

% subtract background/noise from the image, calculate rivulets interfacial
% areas and obtain matrixes of indexes containing the rivulet borders

if DNTLoadIM == 1
    IFArea = zeros(numel(files),1);                                         %images are not loaded, preallocat variable
    minLVec= cell(1,nImages);minRVec = minLVec;                             %preallocate variable for vector sides
    for i = 1:nImages
        handles.statusbar = statusbar(handles.MainWindow,...
            'Calculating interfacial area of rivulet %d of %d (%.1f%%)',... %updating statusbar
            i,nImages,100*i/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(nImages);
        handles.statusbar.ProgressBar.setValue(i);
        load([tmpfDir '/' files{i}(1:end-4) '.mat']);                       %if images are not present in handles, load them from tmpfDir
        [IFArea(i),tmpIM,~,~,minLVec{i},minRVec{i}]= ...
            RivSurf({tmpIM'},Treshold,plateSize);                           %I need to transpose tmpIM -> coherence with YProfilPlatte
        tmpIM            = tmpIM{:}';                                       %transpose back (this should be cleaned) and convert from cell to dbl
        save([tmpfDir '/' files{i}(1:end-4) '.mat'],'tmpIM');               %resave image with subtracted "background/noise"
    end
    minLVec = reshape([minLVec{:}],numel(minLVec),[]);                      %convert cell to double (original vectors are saved in rows)
    minRVec = reshape([minRVec{:}],numel(minRVec),[]);
%     a = [1 1] + [1;1]
else
    handles.statusbar = statusbar(handles.MainWindows,...
        'Calculating interfacial area of rivulets');                        %update statusbar
    [IFArea,YProfilPlatte,~,~,minLVec,minRVec] =...
        RivSurf(YProfilPlatte,Treshold,plateSize);                          %this function does not need graphical output
end

%% Creating visualizations of the rivulet
% plot smoothed images
if GR.contour == 1 || GR.profcompl == 1                                     %if any of the graphics are wanted, enter the cycle
    for i=1:nImages                                                         %for each image
        % update statusbar
        handles.statusbar = statusbar(handles.MainWindow,...
            ['Creating profiles and/or contour plots ',...
            'for image %d of %d (%.1f%%)'],...                              %updating statusbar
            i,nImages,100*i/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(nImages);
        handles.statusbar.ProgressBar.setValue(i);
        % create description of the plot - id of the measurement
        txtStr = ['Liq. tp.: ' txtPars{4} 10 ...                            %liquid type
            'M = ' mat2str(txtPars{1}(i),4) 10 ...                          %dimensionless flow
            'F = ' mat2str(txtPars{2},4) ' Pa^{0.5}' 10 ...                 %f-factor, [Pa^0.5]
            '\alpha = ' mat2str(txtPars{5}) '^\circ{}' 10 ...               %plate inclination angle, [degrees]
            'image n^o: ' mat2str(txtPars{3}(i))];                          %number of image
        % load images if needed
        if DNTLoadIM == 1
            load([tmpfDir '/' files{i}(1:end-4) '.mat']);                   %if images are not present in handles, load them from tmpfDir
        else
            tmpIM   = YProfilPlatte{i};                                     %if they are, just resave current image and cut out the rivulet
            YProfilPlatte{i} = YProfilPlatte{i}';                           %transpose image for next functions
        end
        % replace "non-rivulet" values by zeros
        for j = 1:size(tmpIM,1)                                             %for each column of the tmpIM
            tmpIM(j,setxor(minLVec(i,j):minRVec(i,j),1:size(tmpIM,2))) = 0;
%             a = [1 1] + [1;1]
        end
        if GR.contour == 1                                                  %contour visualization
            % graphical output, look on the rivulets from top
            if GR.regime == 1
                Visible = 'off';                                            %if I want the graphs only to be saved, I dont have to make them
            else                                                            %visible
                Visible = 'on';
            end
            hFig = figure('Visible',Visible);figSet_size(hFig,[400 700]);
            hAxs = axes('OuterPosition',[0 0 1 1]);                         %this is usefull when user does something else on the computer
            set(hFig,'CurrentAxes',hAxs);
            XProfilPlatte = linspace(0,plateSize(1),...
                size(tmpIM,2));                                             %width coord, number of columns in YProfilPlatte
            ZProfilPlatte = linspace(0,plateSize(2),...
                size(tmpIM,1));                                             %length coord, number of rows in YProfilPlatte
            [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
            contour(hAxs,XX,ZZ,tmpIM);                                      %here I keep rivulet height in mm because it looks better
            title(hAxs,'\bf Look on rivulet from the top','FontSize',13);   %what is on the plot
            xlabel(hAxs,'width coordinate, [m]');
            ylabel(hAxs,'length coordinate, [m]');
            colbarh = colorbar('peer',hAxs);                                %open colorbar in desired axes
            set(colbarh,'Location','East');                                 %add the colorbar - scale
            ylabel(colbarh,'rivulet height, [mm]')                          %set units to colorbar
            text(0.05,0.9,txtStr,'Units','Normal');                         %write the description on the plot
            axis(hAxs,'ij');                                                %switch axis to match photos
            % save plot if needed
            if GR.regime ~= 0                                               %if I want to save the images
                saveas(hFig,[plotDir '/riv' mat2str(i) 'fromtop'],...
                    GR.format);
                if GR.regime == 1                                           %I want images only to be saved
                    close(hFig)
                end
            end
        end
        if GR.profcompl == 1                                                %Y-Profile over entire plate width
            if GR.regime == 1
                Visible = 'off';                                            %if I want the graphs only to be saved, I dont have to make them
            else                                                            %visible
                Visible = 'on';
            end
%             hFig = figure('Visible',Visible);figSet_size(hFig,[1100 600]);
            hFig = figure('Visible',Visible);figSet_size(hFig,[400 700]);
            hAxs = axes('OuterPosition',[0 0 1 1]);
            set(hFig,'CurrentAxes',hAxs);
            XProfilPlatte = linspace(0,plateSize(1),...
                size(tmpIM,2));
            ZProfilPlatte = linspace(0,plateSize(2),...
                size(tmpIM,1));
            [XX,ZZ] = meshgrid(XProfilPlatte,ZProfilPlatte);
            mesh(hAxs,XX,ZZ,tmpIM)
            view(180,90);                                                   %set the viewpoint from the top
            axis tight
            xlabel(hAxs,'width of the plate, [m]')
            ylabel(hAxs,'length of the plate, [m]')
            zlabel(hAxs,'height of the rivulet, [mm]')
            title(hAxs,'\bf Profile of the rivulet','FontSize',13);         %create title
            text(0.05,0.9,txtStr,'Units','Normal');                         %write the description on the plot
            % save the plot if needed
            if GR.regime ~= 0                                               %if I want to save the images
                saveas(hFig,[plotDir '/riv' mat2str(i) 'complprof'],...
                    GR.format);
                if GR.regime == 1                                           %I want images only to be saved
                    close(hFig)
                end
            end
        end
    end
end

%% Calculate mean values of riv. heights over each rivLength/nCuts of the
%% rivulet
% the number of cuts (nCuts) << number of rows of the photo, so I will load
% all the cutted rivulets into memory (the memory consumption shouldn be
% extremely high - if the user will not choose like 300 cuts...)
if DNTLoadIM == 1
    YProfilPlatte = cell(1,nImages);                                        %preallocate variable for YProfilPlatte
    for i = 1:nImages
        handles.statusbar = statusbar(handles.MainWindow,...
            'Calculating mean profiles for image %d of %d (%.1f%%)',...     %updating statusbar
            i,nImages,100*i/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(nImages);
        handles.statusbar.ProgressBar.setValue(i);
        load([tmpfDir '/' files{i}(1:end-4) '.mat']);                       %if images are not present in handles, load them from tmpfDir
        [YProfilPlatte(i),XProfilPlatte]=CutRiv({tmpIM'},nCuts,plateSize,...%call with calculation variables
            GR.profcut,GR.regime,GR.format,txtPars,storDir,rootDir,i);      %auxiliary variables for graphics and data manipulation
    end
    rmdir(tmpfDir,'s');                                                     %remove unnecessary temporary folder with all its contents
else
    set(handles.statusbar,'Text','Calculating mean profiles along the rivulets');%update statusbar
    [YProfilPlatte,XProfilPlatte]=CutRiv(YProfilPlatte,nCuts,plateSize,...  %call with calculation variables
        GR.profcut,GR.regime,GR.format,txtPars,storDir,rootDir);            %auxiliary variables for graphics and data manipulation
end

%% Calculate variables to be saved, mean values in each cut
% - if I understand it correctly, it is the same calculation as before,
% only for the mean profiles - these 2 calculations can be put together in
% 1 function and called separately

handles.statusbar.ProgressBar.setVisible(false);                            %update statusbar
set(handles.statusbar,'Text','Calculating output data of the program');
[~,~,RivWidth2,RivHeight2,minLVec,minRVec] =...                             %calculates the mean widths of the rivulet and return indexes of
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
    handles.statusbar.ProgressBar.setVisible(true);                         %showing and updating progressbar
    handles.statusbar.ProgressBar.setMinimum(0);
    handles.statusbar.ProgressBar.setMaximum(nImages);
    handles.statusbar.ProgressBar.setValue(i);
    for j = 1:size(RivWidth2,2)
        SurfMat = trapz(XProfilPlatte(minLVec(i,j):minRVec(i,j)),...        %rows - number of images, columns - number of cuts
            YProfilPlatte{i}(minLVec(i,j):minRVec(i,j),j)*1e-3);            %again, conversion mm -> m
        mSpeed(i,j)  = V_Pumpe(i)/SurfMat;                                  %local mean speed V_/S, m/s
    end
end

%% Saving results in text files

handles.statusbar.ProgressBar.setVisible(false);                            %hiding the progressbar
set(handles.statusbar,'Text','Saving data into text files');

% 1. Smoothed/averaged profiles
cd([storDir '/Profile'])
% in 1 file for each image, i will save:
% impairs columns: x-coordinates
% pairs   columns: heights of the rivulet correspondings to the x-coord.
OUT.Profiles = saveProf(XProfilPlatte,YProfilPlatte,minLVec,minRVec,files);
cd(rootDir)

sPars = {M FFactor plateSize nCuts};                                        %common variables for all saved files

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
varIN = {sigma rho eta M InclAngle FFactor};                                %input variables for correlation
varOUT= IFArea;                                                             %output variable for correlation
OUT.IFACorr = saveCorrData(varOUT,varIN,'IFAreaCorr');
cd(rootDir)

set(handles.statusbar,'Text','Rivulet processing ended succesfully');
end

%% Function for the rotameter calibration
function [M,V_Pumpe] = rotameterCalib(filenames,fluidData)
%
%   [M,V_Pumpe] = rotameterCalib(filenames,fluidData)
%
% function for calibration of the rotameter. The rotameter on the
% experimental device is calibrated for the water at 15 deg C. In this
% case, it shows volumetric flow rate of the water in L/h. However, the
% liquid type is changed during the experiments and also the working
% temperature is 25 deg C instead of 15.
% because of this, it is necessary to calibrate the rotameter for different
% conditions
%
% princip of the calibration
% for different values show at rotameter is measured the mass of the liquid
% going through the device during 1 minute. this way, for each tested value
% of volumetric flow rate show on the rotameter scale are availible mass
% flow rates in kg/min. These values are transformed into g/s and then, the
% polynomial regression is made for obtaining the dependecy of actual mass
% flow rates on the volumetric flow rates shown on the rotameter scale.
%
% INPUT variables
% filenames     ... cell with filenames of the processed images. each
%                   filename has structure ***_***.tif (for example
%                   001_004.tif), where the first number corresponds to the
%                   volumetric flow rate shown on the rotameter scale.
%                   second number is the rank of the experiment with the
%                   same volumetric flow rate
% fluidData     ... informations about currently processed fluid. this
%                   variable is a vector containing g, gravitational
%                   acceleration for the current plate inclination angle,
%                   sigma, surface tension of the liquid, rho, liquid
%                   density, eta, liquid viscosity and Reg - coefficients
%                   of the polynomial regression obtained during the
%                   rotameter calibration (view princip of the calibration)
%                   Reg has no pre-specified length, so the degree of the
%                   polynomial used for volumetric to mass flow rates
%                   recalculation depends only on the number of specified
%                   coefficients on the input.
%
% Rq: Reg should have at most 3 coefficients. usually, the linear
% regression is ok for the water and tensids (water with surfactants), but
% for the silicon oils, quadratic regression could be needed.
%
% OUTPUT variables
% M             ... vector with dimensionless flow rate specified for each
%                   image, obviously, there are multiple same values
% V_Pumpe       ... volumetric flow rate of the pumpe, in m3/s, it is used
%                   in calculation of the mean speed of the liquid in cuts.
%                   Same as for M, there are multiple times the same
%                   values.

% extracting parameters
g       = fluidData(1);                                                     %m/s^2
sigma   = fluidData(2);                                                     %N/m
rho     = fluidData(3);                                                     %kg/m^3
eta     = fluidData(4);                                                     %Pa s
Reg     = fluidData(5:end);                                                 %pumpe constants

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

%% Function to convert gray values ​​in distances
% Is required for the image and the regression coefficients of quadratic regression
% 21/11/2011, rewritten July 2012, by Martin Isoz

function ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
    GR,GRregime,GRformat,txtPars,storDir,rootDir,imNumber)
%
%   ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
%    GR,GRregime,GRformat,txtPars,storDir,rootDir,[imNumber])
%
% function for conversion images from grayscale to distances using
% polynomial regression with polynomial of degree specified in RegDegree
%
% INPUT variables
% ImData    ... images of the plate (in form of matrix)to be converted,cell
% EdgCoord  ... coordinates of section edges of the plate(plate, cuvettes),
%               pixels/indexes, matrix (1 x 10)
% filmTh    ... film thickness, in mm + width of cuvettes in pixels
%               [maxCuvette1 minCuvette1 maxCuvette2 minCuvette2 CuvWidth]
% RegDegree ... degree of polynomial used for the regression
% GR                ... variable for graphics (yes/no)
% GRregime          ... variable for graphics (show/save/show+save)
% GRformat          ... format of save graphics (compatible with SAVEAS)
% txtPars   ... description of the plots (to be shown on them)
% storDir   ... directory for storing outputs
% rootDir   ... main execution directory
% imNumber  ... optional input parameter, if the images are processed 1 by
%               1, this i the number of the currently processed image
%
% OUTPUT variebles
% ImgConv   ... converted image, gray values -> local heights of the riv,
%               in mm
%
% !! at the time, the BIG cuvette is NOT used !!

% for all the images
ImgConv     = cell(1,numel(ImData));                                        %preallocation of output variable
% read coordinates of the cuvettes and plate on each image
% small cuvette
xoS = EdgCoord(1);                                                          %mean  x-Value
yoS = EdgCoord(2);                                                          %top y-Value
yuS = EdgCoord(3);                                                          %bottom y-Value
%     % big cuvette        BIG CUVETTE NOT USED
%     xoB = EdgCoord(4);
%     yoB = EdgCoord(5);
%     yuB = EdgCoord(6);
% plate
xol = EdgCoord(7);                                                          %left x-Value
yol = EdgCoord(8);                                                          %top  y-Value
xur = EdgCoord(9);                                                          %right x-Value
yur = EdgCoord(10);                                                         %bottom y-Value

% prepare cuvette calibration
XS  = linspace(filmTh(1),filmTh(2),yuS-yoS+1)';                             %thickness of the film in mm small cuvette
% XB  = linspace(filmTh(3),filmTh(4),yuB-yoB+1)';                           %thickness of the film in mm big cuvette
CW  = filmTh(5)/2;                                                          %cuvette width/2
    
% for each image
for i = 1:numel(ImData)                                                     %for each file
    if nargin < 10
        imNumber = i;
    end
    % load i-th image
    Image = ImData{i};                                                      %temporary variablefor each image
    % find mean grayscale value for each row of the cuvette
    YS   = mean(Image(yoS:yuS,xoS-CW:xoS+CW),2);
%     YB   = mean(Image(yoB:yuB,xoB-CW:xoB+CW),2);
    % combine grayscale value and film thickness into 1 matrix
    CuvetteS  =[YS XS];                                                     %Y ... brightness, X ... height of liquid
% 	CuvetteB  =[YB XB];                                                     %calibration data for image conversion
    
    Image   = double(Image(yol:yur,xol:xur));                               %reduce Image only to plate and convert to double
    tmpMatS = CuvetteS(50:end-50,:);                                        %cut off potentially strange values on sides
%     tmpMatB = CuvetteB(50:end-20,:);                                        %... brute and unelegant
    
    impS    = numel(tmpMatS(:,1));                                          %i must cheat matlab to polyfit through point (0,0) artificialy add
%     impB    = numel(tmpMatB(:,1));                                        % point (0,0) with the same importance as all other points together
    [RegS ErrorEstS]    = polyfit([tmpMatS(:,1);zeros(impS,1)],...
        [tmpMatS(:,2);zeros(impS,1)],RegDegree);                            %Regression small cuvette (with the point (0,0))
%     [RegB ErrorEstB]= polyfit(tmpMatB(:,1),tmpMatB(:,2),RegDegree);         %Regression big cuvette (without the point (0,0))
%     RegB = polyfit([tmpMatB(:,1);zeros(impB,1)],... BIG CUVETTE NOT USED
%         [tmpMatB(:,2);zeros(impB,1)],RegDegree);                          %Regression big cuvette (with the point (0,0)
%     % split image into 2 based on grayscale values and convert it to the
%     % distances separately BIG CUVETTE NOT USED
%     [rowSize colSize] = size(Image);                                        %save dimensions of the original image
%     ImgConv{i}(Image<=max(YS)) = polyval(RegS,Image(Image<=max(YS)));       %convert small values
%     ImgConv{i}(Image >max(YS)) = polyval(RegB,Image(Image >max(YS)));       %convert big values
%     ImgConv{i}        = reshape(ImgConv{i},rowSize,colSize);                %reshape the matrix into original dimensions
    ImgConv{i}  = polyval(RegS,Image);
%     ImgConv{i} = polyval(RegS,Image);                                       %original conversion command
    if GR == 1
        % create description of the plot - id of the measurement
        txtStr = ['Liq. tp.: ' txtPars{4} 10 ...                            %liquid type
            'M = ' mat2str(txtPars{1}(imNumber),4) 10 ...                   %dimensionless flow rate
            'F = ' mat2str(txtPars{2},4) ' Pa^{0.5}' 10 ...                 %f-factor, [Pa^0.5]
            '\alpha = ' mat2str(txtPars{5}) '^\circ{}' 10 ...               %plate inclination angle, [degrees]
            'image n^o: ' mat2str(txtPars{3}(imNumber))];                   %number of image
        % Calculate fitted values
        [fitS deltaS] = polyval(RegS,CuvetteS(:,1),ErrorEstS);              %fitted values and estimated errors
        %     [fitB deltaB] = polyval(RegB,CuvetteB(:,1),ErrorEstB); NOT USED
        % Graphs to control regression state..
        if GRregime == 1
            Visible = 'off';                                                %if I want the graphs only to be saved, I dont have to make them
        else                                                                %visible
            Visible = 'on';
        end
        hFig = figure('Visible',Visible);figSet_size(hFig,[1100 600]);
        hAxsL = axes('OuterPosition',[0 0 0.5 1]);                          %create axes for left side of the image
        hAxsR = axes('OuterPosition',[0.5 0 0.5 1]);                        %axes for the right side of the image
        subplot(hAxsL)
        plot(hAxsL,CuvetteS(:,1),CuvetteS(:,2),'+',...                      %experimental points
            CuvetteS(:,1),fitS,'g-',...                                     %fit
            CuvetteS(:,1),fitS+2*deltaS,'r:',...                            %95% confidence interval for large samples
            CuvetteS(:,1),fitS-2*deltaS,'r:');
        text(0.05,0.85,txtStr,'Units','Normal');                            %add the description to the current plot
        title(hAxsL,'\bf Calibration, small cuvette','FontSize',13)
        xlabel(hAxsL,'grayscale value')
        ylabel(hAxsL,'height of the liquid, mm')
        subplot(hAxsR) % BIG CUVETTE NOT USED
%             plot(hAxsR,CuvetteB(:,1),CuvetteB(:,2),'+',...                  %experimental points
%                 CuvetteB(:,1),fitB,'g-',...                                 %fit
%                 CuvetteB(:,1),fitB+2*deltaB,'r:',...                        %95% confidence interval for large samples
%                 CuvetteB(:,1),fitB-2*deltaB,'r:');
%             text(0.05,0.85,txtStr,'Units','Normal');                        %add the description to the current plot
%             title(hAxsR,'\bf Calibration big cuvette','FontSize',13)
%             xlabel(hAxsR,'grayscale value')
%             ylabel(hAxsR,'height of the liquid, mm')
        set(hAxsR,'Visible','off') %BIG CUVETTE NOT USED - nothing to show
        title('\bf Big cuvette not used','FontSize',13,'Units','Normal',...     %notify user about the white space on the right side of the plot
            'Visible','on')
        if GRregime ~= 0                                                        %if I want to save the images
            cd([storDir '/Plots']);
            saveas(hFig,['riv' mat2str(imNumber) 'regrstate'],GRformat);
            if GRregime == 1                                                    %I want images only to be saved
                close(hFig);
            end
            cd(rootDir);
        end
    end
end
end

%% Function for cutting rivulet into nCuts parts along the vertical
%% coordinate (Z)
function [YProfilPlatte XProfilPlatte] =...
    CutRiv(YProfilPlatte,nCuts,plateSize,GR,GRregime,GRformat,txtPars,...
    storDir,rootDir,imNumber)
%
%   [YProfilPlatte XProfilPlatte] =...
%       CutRiv(YProfilPlatte,nCuts,plateSize,GR,GRregime,GRformat,storDir,rootDir,imNumber)
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet
% nCuts             ... number of cuts to make along the rivulet (scalar)
% plateSize         ... size of the plate [width length], in m
% GR                ... variable for graphics (yes/no)
% GRregime          ... variable for graphics (show/save/show+save)
% GRformat          ... format of saved graphics (compatible with SAVEAS)
% txtPars           ... description of the plots (to be shown on them)
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

% for all the images, all the YProfilPlatte have the same size
Distance     = round(size(YProfilPlatte{1},2)/(nCuts+1));                   %number of points in each mean profile
% prepare variables and cut the rivulet
if nCuts == 0 || Distance < 50                                              %if too much cuts is specified
    warndlg(['The number of cuts specified is bigger than'...               %notify user by dialog
        ' number of rows necessary to obtain mean values for each cut'],...
        'modal');uiwait(gcf);
    fprintf(1,'Change the number of cuts\n');
    nCuts = input('nCuts = ');                                              %inputs from keyboard, to command window (!!)
    Distance     = round(size(YProfilPlatte{1},2)/(nCuts+1));               %need to recalculate distance
end
XProfilPlatte= linspace(0,plateSize(1),size(YProfilPlatte{1},1));           %this is the same for all the images, m

% for each image
for i=1:numel(YProfilPlatte)
    if nargin < 9
        imNumber = i;
    end
    for n = 1:nCuts
        YProfilPlatte{i}(:,n)=mean(YProfilPlatte{i}...                      %create mean profiles in the place of the cut, over 50 pixels
            (:,n*Distance-25:n*Distance+25),2);
    end
    YProfilPlatte{i} = YProfilPlatte{i}(:,1:nCuts)*1e-3;                    %need to change size of output matrix, mm -> m
% ploting results
    if GR == 1
        % create description of the plot - id of the measurement
        txtStr = ['Liq. tp.: ' txtPars{4} 10 ...                            %liquid type
            'M = ' mat2str(txtPars{1}(imNumber),4) 10 ...                   %dimensionless flow
            'F = ' mat2str(txtPars{2},4) ' Pa^{0.5}' 10 ...                 %f-factor, [Pa^0.5]
            '\alpha = ' mat2str(txtPars{5}) '^\circ{}' 10 ...               %plate inclination angle, [degrees]
            'image n^o: ' mat2str(txtPars{3}(imNumber))];                   %number of image
        % decide if show plot
        if GRregime == 1
            Visible = 'off';                                                %if I want the graphs only to be saved, I dont have to make them
        else                                                                %visible
            Visible = 'on';
        end
        hFig = figure('Visible',Visible);figSet_size(hFig,[700 550]);
        hAxs = axes('OuterPosition',[0 0 1 1]);
        set(hFig,'CurrentAxes',hAxs);
        plot(hAxs,XProfilPlatte,YProfilPlatte{i})
        axis(hAxs,'tight');
        text(0.05,0.9,txtStr,'Units','Normal');                             %add the description to the plot
        xlabel(hAxs,'width of the plate, [m]')
        ylabel(hAxs,'height of the rivulet, [m]')
        ttl=title(hAxs,['\bf Mean profiles of riv. ' mat2str(imNumber)...
            ' over every ' mat2str(plateSize(2)/(nCuts+1)*1e3,3)...
            ' mm of the plate']);
        set(ttl,'FontSize',13,'Interpreter','tex')
        legCell = (1:nCuts) * plateSize(2)/(nCuts+1)*1e3;                   %create vector of legend entries
        legCell = cellstr(num2str(legCell(:)));                             %convert vector to cell of string
        for j = 1:numel(legCell)
            legCell{j} = [legCell{j} ' mm'];                                %add to every element units
        end
        legend(hAxs,legCell);                                               %create legend automatically
        if GRregime ~= 0                                                    %if I want to save the images
            cd([storDir '/Plots']);
            saveas(hFig,['riv' mat2str(imNumber) 'cutprof'],GRformat);
            if GRregime == 1                                                %I want images only to be saved
                close(hFig);
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
function [IFArea YProfilPlatte RivWidth RivHeight minLVec minRVec] = ...
    RivSurf(YProfilPlatte,Treshold,plateSize)
%
%   function [IFArea RivWidth RivHeight minLVec minRVec] = ...
%       RivSurf(YProfilPlatte,Treshold,plateSize)
%
% function for the rivulet interfacial area, width, height and borders
% calculation
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet, in mm
% Treshold          ... Treshold for finding ~ 0 values of the profile
%                       derivation, usually it is < 5e-5, so default value
%                       1e-3 is setted with big enough tollerance
% plateSize         ... size of the plate [width length], in m
%
% OUTPUT variables
% IFArea            ... liquid/gas interfacial area of the rivulet, m^2,
%                       vector of scalar values for each image
% YProfilPlatte     ... YProfilPlatte with subtracted background noise
%                       (sets the treshold)
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

% allocating space for variables
[m,n] = size(YProfilPlatte{1});                                             %all the YProfilPlatte elements have the same size
IFArea  = zeros(numel(YProfilPlatte),1);                                    %variable for interfacial area
RivWidth= zeros(numel(YProfilPlatte),n);                                    %variable for rivulet width
RivHeight=zeros(numel(YProfilPlatte),n);                                    %variable for rivulet height
minLVec = zeros(numel(YProfilPlatte),n);                                    %left sides of the rivulet
minRVec = zeros(numel(YProfilPlatte),n);                                    %right sides of the rivulet

TrVec=zeros(1,n);                                                           %background/noise liquid height

% for all the images
% calculating the deltaX (distance between 2 pixels)
deltaX  = plateSize(1)/m;                                                   %distance between 2 points on X-axis (in m)
deltaZ  = plateSize(2)/n;                                                   %distance between 2 points on Z-axis (in m)

% mean X coordinate of the pictures
IndXMean= round(m/2);                                                       %X coordinate of the plate center (horizontal)

% for each image
for i = 1:numel(YProfilPlatte) 
    YProfilPlatte{i} = YProfilPlatte{i}*1e-3;                               %mm -> m
    YMin = 0;
    YMax = max(max(YProfilPlatte{i}));
    for j = 1:n                                                             %for all the columns of YProfilPlatte (Z-coordinates)
        % find the maximal height of the rivulet in current YPP column
        tmpProf      = smooth(YProfilPlatte{i}(:,j),30);                    %very hard smoothing of current profile (only highest peaks wanted)
        [~,IndX]     = findpeaks(tmpProf,'MinPeakHeight',...                %find all peaks in smoothed profile higher then its max/2
            max(tmpProf)/2);
        IndX         = IndX(abs(IndX-IndXMean) == min(abs(IndX-IndXMean))); %take the first of the peaks nearest to the center of the plate
        RivHeight(i,j)=YProfilPlatte{i}(IndX,j);                            %save current rivulet height
        tmpVecL      = tmpProf(1:IndX);                                     %left side of the SMOOTHED rivulet
        tmpVecR      = tmpProf(IndX+1:end);                                 %right side of the SMOOTHED rivulet
        % calculate numeric derivative of the profile (on treshold,
        % dy/dx~=0), I use a smoothed profile -> get rid of the oscilations
        diffVecL     = abs(diff(tmpVecL)/deltaX);                           %abs. val. of numeric derivation of the left side of the profile
        diffVecR     = abs(diff(tmpVecR)/deltaX);                           %abs. val. of numeric derivation of the right side of the profile
        tmpIndL      = find(diffVecL<=Treshold,60,'last');                  %find last 60 values with dy/dx~0 on the left side of the riv.
        tmpIndR      = find(diffVecR<=Treshold,60,'first');                 %find first 60 values with dy/dx~0 on the right side of the riv.
        % reduce tmpIndL and ..R to the pieces longer than 10 elements
        % finding tmpIndL
        aux          = tmpIndL'-(1:numel(tmpIndL));                         %define auxiliary variable to identify jumps
        aux          = [true; diff(aux(:)) ~= 0; true];                     %identify starting indexes of new groups
        split        = mat2cell(tmpIndL(:).', 1, diff(find(aux)));          %split the vector according to the found indexes
        split        = split(cellfun(@numel,split)>=10);                    %reduce splited vector to the elements with numel >= 10
        split        = [split{:}];                                          %convert cell to vector
        if isempty(split) == 1                                              %if there were no edges found
            warning('MyWrng:REdgNF','Did not find the left edge of rivulet');
            split    = 1;                                                   %take whole left side of the rivulet
        end
        tmpIndL      = split(end);                                          %tmpIndL is the last value in the split vector
        TrVec(j)     = min(YProfilPlatte{i}(split,j));                      %treshold is the lowest value of the contstant part of the profile
        %finding tmpIndR
        aux          = tmpIndR'-(1:numel(tmpIndR));                         %define auxiliary variable to identify jumps
        aux          = [true; diff(aux(:)) ~= 0; true];                     %identify starting indexes of new groups
        split        = mat2cell(tmpIndR(:).', 1, diff(find(aux)));          %split the vector according to the found indexes
        split        = split(cellfun(@numel,split)>=10);                    %reduce splited vector to the elements with numel >= 10
        split        = [split{:}] + numel(tmpVecL);                         %convert cell to vector and add length of the profiles left side
        if isempty(split) == 1                                              %no edges found
            warning('MyWrng:LEdgNF','Did not find the right edge of rivulet');
            split    = m-1;                                                 %take the whole right side of the rivulet
        end
        tmpIndR      = split(1);                                            %tmpIndR is the first value in the split vector
        TrVec(j)     = min([TrVec(j);YProfilPlatte{i}(split,j)]);           %treshold is the lowest value of the contstant part of the profile
        % save left and right side of the rivulet
        minLVec(i,j) = tmpIndL;
        minRVec(i,j) = tmpIndR;
%         if j == 1
%             figHandle = figure;
%         end
%         figure(figHandle);
%         plot(1:numel(tmpProf),YProfilPlatte{i}(:,j));
%         hold on
%         plot(1:numel(tmpProf),tmpProf,'r');
%         plot(tmpIndL,tmpProf(tmpIndL),'r^','MarkerFaceColor','Red')
%         plot(tmpIndR,tmpProf(tmpIndR),'r^','MarkerFaceColor','Red')
%         xlabel(['{\bf diff LEFT:} ' num2str(diffVecL(tmpIndL)) ...
%             '{\bf diff RIGHT:}' num2str(diffVecR(tmpIndR-numel(tmpVecL)))])
%         title(['\bf Profile ' num2str(j) ' of ' num2str(n)]);
%         ylim([YMin YMax]);
%         xlim([1 numel(tmpProf)])
%         hold off
%         drawnow
%         if n < 100
%             pause(1)
%         end
    end
    if n > 300                                                              %for large number of cuts (probably the whole image)
        % smooth the found rivulet edges - remove jumps in rivulet width
        % pictures are high-res enough not to contain any big jums in the
        % rivulet edges positions
        minLVec(i,:) = round(smooth(minLVec(i,:),100));                     %values need to be rounded (they are indexes) -> integers
        minRVec(i,:) = round(smooth(minRVec(i,:),100));                     %n > 1600 (usually), so 100 neighbouring values isnt that many
    end
    % subtract the treshold from the current profile (it is a bacground
    % noise)
    % note: in second and following runs of the function, TresholdC->0
    TresholdC        = mean(TrVec);                                         %calculate mean value of the treshold/background liquid height
    YProfilPlatte{i} = YProfilPlatte{i} - TresholdC;                        %subtract it from the profile
    RivHeight(i,:)   = RivHeight(i,:) - TresholdC;                          %subtract it from the rivulet Heights

    % calculate local widths and heights of i-th rivulet
    RivWidth(i,:) = (minRVec(i,:) - minLVec(i,:))*deltaX;                   %number of elements in rivulet x width of element
    meanRW        = mean(RivWidth(i,:));                                    %calculate mean rivulet width
    
    % calculate the interfacial area of the rivulet
    % IFArea = lengthOfArc x lengthOfPlate(between 2 arcs)
    
    % for all horizontal cuts
    for j = 1:n-1                                                           %need to omit the last piece (but the error wouldn't be big)
        % walking through the arc and adding the approximate length of the
        % element
        lArc  = 0;                                                          %restart the length counter
        for k = minLVec(i,j):minRVec(i,j)-1                                 %from left to right side of the rivulet
            deltaY = YProfilPlatte{i}(k+1,j) - YProfilPlatte{i}(k,j);
            lArc = lArc + sqrt(deltaY.^2 + deltaX.^2);                      %total length of arc + aproximate length of an element
        end
        if RivWidth(i,j) > 3*meanRW                                         %this is necessary for IFArea correlations but
            warning('Pers:RIV2W',['skipping line ' mat2str(j) ' of '...     %cannot be use for mass transfer calculations
                mat2str(n)...
                ' widht of the rivulet > 3 x mean riv. width']);
            continue                                                        %if rivulet is too wide, skip current line
        end
        IFArea(i) = IFArea(i) + lArc*deltaZ;                                %length of j-th arc x length of an element of the plate length
    end
    YProfilPlatte{i} = YProfilPlatte{i}*1e3;                                %convert YPP back to mm (m -> mm)
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
            [zeros(zerLeft,1);...
            YProfilPlatte{i}(minLVec(i,k):minRVec(i,k),k)*1e-3;...
            zeros(zerRight,1)];
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

% for each pumpe regime create 1 file and save Var into this file
tmpVec = zeros(1,numel(files));                                             %temporary vector for slicing mVar
for i = 1:numel(files)
    tmpVec(i)  = str2double(...                                             %find all the characters in filename before first _
        regexp(files{i}, '.+(?=\_[0-9]+.tif)', 'match'));                   %and convert them to double
    slInd      = [1 find(diff(tmpVec) ~= 0)+1 numel(tmpVec)+1];             %find slicing indexes, last index must be length of Vec + 1
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
    volFl   = regexp(files{slInd(i)}, '.+(?=\_[0-9]+.tif)', 'match');       %find all the characters in filename before first _
    nameStr = [fileNm '_' volFl{:} '.txt'];                                 %create filename
    dlmwrite(nameStr,tmpMat,'delimiter','\t','precision','%5.6e')           %write write data matrix into file, SI unist
    VarOUT{i} = tmpMat;                                                     %save i-th regime into cell output
    VarOUT{end}(i) = regexp(files{slInd(i)}, '.+(?=\_[0-9]+.tif)', 'match');
end
% save_to_base(1)
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

dlmwrite([fileNM '.txt'],CorMat,'delimiter','\t','precision','%5.6e')       %write write data matrix into file, SI unist

end

%% Functions for Graphics
% Function handle for setting figure size
function figSet_size(figHandle,size)
set(figHandle,'Units','Pixels',...                                          %nastavi pevnou velikost zobrazovaneho okna
    'Position',[10 10 size(1) size(2)],'Color',[1 1 1]);
end
