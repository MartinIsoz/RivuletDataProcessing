function IMProcPars = bestMethod(handles)
%
%   function IMProcPars = bestMethod(metricdata,prgmcontrol)
%
% Function for finding best combination of IMProcPars for edge finding
% (modified are only values for finding plate, error rate in finding
% cuvettes is very low - for 1 week of testing, there were no mistaktes).
%
% Algorithm: Function simply tries different combinations of IMProcPars and
% then returns combination that has lowest value of objective function.
% Objective function is weighted sum of state vector (output of
% modifyFunction). The weight of NaN is double the weight of outliers. The
% only parameters that are moved are 'method' and 'DUIM2BW'. Parameters for
% Hough transform were optimized before and are the same for all tested
% experimental data.
%
% INPUT variables
% handles   ... structure with program data, must have all fields required
%               by function findEdges.m
%
% OUTPUT variables
% IMProcPars... cell with image processing parameters for findEdges.m.
%               these parameters are the most dependable for the specific
%               set of experimental data
%
% Remarque: it is advisible to run this function with only few (<20) images
%           loaded and then use find parameters to process all the
%           experimental data. this function is to be used when processing
%           rather large datasets (>40 images).
%
% See also FINDEDGES RIVULETEXPDATAPROCESSING MODIFYFUNCTION
% CONTROLFUNCTION

% preparing different sets of image processing parameters
hpTr    = 0.33;
fG      = 35;
mL      = 25;
im2bwTr = 0.4;
DUIM2BW = [0 1];
method  = {'Sobel' 'Prewitt' 'Roberts' 'Canny'};

handles.metricdata.IMProcPars = cell(1,7);

% Remarque: numPeaks is dependent on the value of DUIM2BW
handles.metricdata.IMProcPars{1} = hpTr;
handles.metricdata.IMProcPars{3} = fG;
handles.metricdata.IMProcPars{4} = mL;
handles.metricdata.IMProcPars{5} = im2bwTr;

% auxiliary variables
nExp    = numel(DUIM2BW)*numel(method);                                     %number of edge finding needed
% weight vector
% NaN are more important than outliers. in plate, the NaN are always in
% pairs
weights = [0 0 0 0 2 1];                                                    %weight vector for construction of objective function

% forcing completely automatic run of findEdges
handles.prgmcontrol.autoEdges = 'Force-automatic';
% disabling graphics
handles.metricdata.GREdges = [0 0];

% extracting needed values from handles
if isfield(handles.metricdata,'AppPlatePos') == 0                           %if approximate plate position is not yet specified
    % obtaining approximate coordinates of the plate
    handles.statusbar = statusbar(handles.MainWindow,...                    %update the statusbar
        'Waiting for user response');
    options.Interpreter = 'tex';
    options.WindowStyle = 'modal';
    msgbox({['Please specify approximate position of the'...
        ' plate on processed images']...
        ['Click little bit outside of {\bf upper left} '...
        'and {\bf lower right corner}']},options);uiwait(gcf);
    se      = strel('disk',12);                                             %morphological structuring element
    if isfield(handles.metricdata,'daten') == 1                             %see if there are images saved into handles
        DNTLoadIM = 0;
    else
        DNTLoadIM = 1;
        imNames   = handles.metricdata.imNames;                             %if not, obtain info for loading
        subsImDir = handles.metricdata.subsImDir;
    end
    if DNTLoadIM == 1                                                       %if the images are not loaded, i need to get the image from directory
        tmpIM = imread([subsImDir '/' imNames{1}]);                         %load image from directory with substracted images
    else
        tmpIM = handles.metricdata.daten{1};                                %else i can get it from handles
    end
    tmpIM   = imtophat(tmpIM,se);
    tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                %enhance contrasts
    tmpIM   = im2bw(tmpIM,0.16);                                            %conversion to black and white
    figure;imshow(tmpIM);                                                   %show image to work with
    cutMat  = round(ginput(2));close(gcf);                                  %let the user specify approximate position of the plate
    cutLeft = cutMat(1,1);cutRight = cutMat(2,1);
    cutTop  = cutMat(1,2);cutBottom= cutMat(2,2);                           %cut out \pm the plate (less sensitive than exact borders)
    
    handles.metricdata.AppPlatePos = ...                                    %save approximate plate position into handles
        [cutLeft cutTop cutRight cutBottom];
end

% preallocating variables
objFcn = zeros(nExp,3);                                                     %matrix of objective values function
% first column are values of objective function, second column is value of
% DUIM2BW parameter and third column is index of the used method

% obtaining values of objective function
k = 1;                                                                      %auxiliary index
j = 1;
for i = 1:nExp
    if i == numel(method)+1                                                 %if all method were tryied
        k = k+1;
        j = 1;
    end
    % load specific combination of changed parameters
    handles.metricdata.IMProcPars{6} = DUIM2BW(k);
    if handles.metricdata.IMProcPars{6} == 1
        handles.metricdata.IMProcPars{2} = 40;                              %if I dont use im2bw, its better to take fewer peaks
    else
        handles.metricdata.IMProcPars{2} = 200;                             %otherwise I can use many peaks (found lines)
    end
    handles.metricdata.IMProcPars{7} = method{j};
    %find edges with preset parameters
    EdgCoord = findEdges(handles);
    % call control function
    state = controlFunction(EdgCoord);                                      %I am interested only in state variable for objective function
    % calculate objective value function
    objFcn(i,:) = [sum(weights.*state) k j];
end

% find minimum of the objective function
[~,minInd] = min(objFcn(:,1));                                              %I am interested only in index of the minimal value

% set up output variable
IMProcPars{1} = hpTr;
IMProcPars{3} = fG;
IMProcPars{4} = mL;
IMProcPars{5} = im2bwTr;
IMProcPars{6} = DUIM2BW(objFcn(minInd,2));
IMProcPars{7} = method{objFcn(minInd,3)};
if IMProcPars{6} == 1                                                       %set up value of numpeaks
    IMProcPars{2} = 40;                                                     %if I dont use im2bw, its better to take fewer peaks
else
    IMProcPars{2} = 200;                                                    %otherwise I can use many peaks (found lines)
end


% ask user if he wants to save these parameters into mat file
% Construct a questdlg with 2 options
choice = questdlg('Do you want to save found parameters into .mat file?',...
 'Save found', ...
 'Yes','No','No');
% Handle response
switch choice
    case 'Yes'
        strAdd = ' and saved. Handles were updated.';
        uisave('IMProcPars','IMProcPars')
    case 'No'
    	strAdd = '. Handles were updated.';
end
set(handles.statusbar,'Text',['Optimal image processing '...
    'parameters were found' strAdd]);                                       %update the statusbar in the main window

end
