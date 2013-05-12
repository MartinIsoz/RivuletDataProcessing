function varargout = treshInflStudy(varargin)
%
%    function varargout = treshInflStudy(varargin)
%
% Function for study of threshold influence on obtained results. It is very
% advisible to run this function for every new set of images to find the
% optimal threshold to set.
%
% The default value of threshold set by the RIVULETEXPDATAPROCESSING program
% is 3e-5 m, which should be OK for most of the experimental data.
%
% Optimal threshold value can be guessed from, for example, plot of the
% rivulet width against plate length coordinate for different threshold
% values -> it is the value for which the lines begin to ressemble one to
% another.
%
% Other way to gues this would be from the plot of interfacial area size
% against the used tresholds. Optimal threshold value is the one, where this
% dependence becomes approximately linear.
%
% As this function itself calls the RIVULETPROCESSING subfunction, it is to
% be called with the same parameters as the rivulet processing itself.
%
% Because of the time dependence of the threshold influence analysis and the
% clarity of results, the analysis can be ran for only 1 image at the time.
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         06. 03. 2013
%
% License: This code is published under MIT License, please do not abuse
% it.
%
%
% See also RIVULETEXPDATAPROCESSING RIVULETPROCESSING

% --- Disabling useless warnings
%#ok<*DEFNU> - GUI cannot see what functions will be used by user

% Edit the above text to modify the response to help treshInflStudy

% Last Modified by GUIDE v2.5 07-Mar-2013 10:58:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @treshInflStudy_OpeningFcn, ...
                   'gui_OutputFcn',  @treshInflStudy_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

%% Callbacks
% --- Executes just before treshInflStudy is made visible.
function treshInflStudy_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to treshInflStudy (see VARARGIN)

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})                                       %input of the program are metricdata and prgmcontrol
            case 'metricdata'
                metricdata =  varargin{index+1};
            case 'prgmcontrol'
                prgmcontrol = varargin{index+1};
        end
    end
    % extract immediatly needed inputs
    strCellIm = cell(1,numel(metricdata.imNames));
    for i = 1:numel(metricdata.imNames)
        strCellIm{i} = metricdata.imNames{i};                               %create string with availible images names
    end
end

% Fill in the list with availible images
set(handles.avImList,'String',strCellIm);                                   %update string in the listbox

% Fill the textfield avCutsText with maximal number of cuts that can be
% made
set(handles.avCutsText,'String',num2str(...                                 %get the number of rows from EdgCoord vector
    metricdata.EdgCoord(end)-metricdata.EdgCoord(end-2)));
% Fill the editable field nCutsEdit with number of cuts to be made preset
% into the RivProcPars (default value is 5)
set(handles.nCutsEdit,'String',num2str(...
    metricdata.RivProcPars{5}));

% Set the openning title/tooltip
set(handles.axTitleText,'String',['Select images, fill in necessary fields'...
    ' and run the program'],'FontWeight','Bold','FontSize',16)

% Fill in the threshold span
set(handles.trSpanEdit,'String','[1e-6 5e-6 1e-5:1e-5:1e-4]')               %program preset value is 3e-5

% Disable the run button
set(handles.runPush,'Enable','off');                                        %will be re-enabled when image is chosen

% Set string and disable popup menu with avalible data
set(handles.avPlotPopUp,'String','No data availible yet','Enable','off')

% Disable data export buttons
set([handles.expPlotsPush handles.expDataPush],'Enable','off')

% Save input data into handles
handles.metricdata = metricdata;
handles.prgmcontrol= prgmcontrol;

handles.metricdata.trSpan = [1e-6 5e-6 1e-5:1e-5:1e-4];                     %fill in the threshold range

% Make the GUI invisible (so it cannot be closed from MATLAB)
set(handles.figure1,'Visible','off');

% Choose default command line output for treshInflStudy
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes treshInflStudy wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = treshInflStudy_OutputFcn(hObject, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set statusbar - this function is executed after GUI is made visible and
% before user can set any inputs => java object is ready for statusbar
handles.statusbar = statusbar(hObject,'Program is ready');

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on button press in runPush.
function runPush_Callback(hObject, ~, handles)
% hObject    handle to runPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get the data
trSpan = handles.metricdata.trSpan;                                         %get threshold span
nCuts  = handles.metricdata.RivProcPars{5};                                 %get number of horizontal cuts
tmpImNamesList = handles.metricdata.imNames;                                %need to save all the images names
tmpStorDir = handles.metricdata.storDir;                                    %need to save original storDir for export
handles.metricdata.imNames = handles.metricdata.imNames(...                 %run this only for selected image
    handles.metricdata.selIm);

% preallocate the variables
IFACorr = zeros(1,numel(trSpan));
ARhoCorr= IFACorr;
mSpeed  = zeros(nCuts,numel(trSpan));
RivWidth = mSpeed;
epsHR = mSpeed;locReW = mSpeed;

% create temp. dir for storing outputs of rivuletProcessing (I dont need
% it)
mkdir([handles.metricdata.rootDir '/tmpDir']);
storDir = [handles.metricdata.rootDir '/tmpDir'];
handles.metricdata.storDir = storDir;
nameList= {'Subtracted' 'Height' 'Profile' 'Speed' 'Width' 'Correlation' ...%names of the directories for saving outputs
    'Plots' 'Others'};
nameSubs= {{'Smoothed'} [] [] [] [] [] [] []};                              %names of subdirectories for every folder

if exist(storDir,'dir') == 0
    mkdir(storDir);                                                         %if user specified directory doesnt exist, create it
end
d         = dir(storDir);                                                   %create list of subdirectories in storDir
isub      = [d(:).isdir];                                                   %returns logical vector
nameFolds = {d(isub).name};                                                 %get list of names of folders
nameFolds(ismember(nameFolds,{'.','..'})) = [];                             %remove . and .. from the list
% create subdirectories
parfor i = 1:numel(nameList)
    if sum(strcmp(nameFolds,nameList{i})) == 0                              %folder of the nameList is not present into storDir
        mkdir([storDir '/' nameList{i}]);                                   %create directory
        for j = 1:numel(nameSubs{i})
            mkdir([storDir '/' nameList{i} '/' nameSubs{i}{j}]);            %and all subdirectories
        end
    elseif isempty(nameSubs{i}) == 0                                        %check if there are any subdirectories required in the checked dir.
        d         = dir([storDir '/' nameList{i}]);                         %create list of subdirectories in checked dir
        isub      = [d(:).isdir];                                           %returns logical vector
        namesFolds = {d(isub).name};                                        %get list of names of folders
        namesFolds(ismember(namesFolds,{'.','..'})) = [];                   %remove . and .. from the list
        for j = numel(nameSubs{i})                                          %for every created subfolder
            if sum(strcmp(namesFolds,nameSubs{i}{j})) == 0                  %if the subdirectory is not present in current dir
                mkdir([storDir '/' nameList{i} '/' nameSubs{i}{j}]);        %create it
            end
        end
    end
end

% open waitbar (because progressbar is controled by the rivuletProcessing
% function -> could be necessary to implement there a way to switch of the
% progressbar)
hWait = waitbar(0,'Calculating outputs');

% calculate outputs
for i = 1:numel(trSpan)
    waitbar(i/numel(trSpan),hWait,...                                       %update waitbar
        sprintf(['Processing threshold %d of %d '...
        '(%3.2f %%)'],i,numel(trSpan),i*100/numel(trSpan)));
    handles.metricdata.Treshold = trSpan(i);                                %update threshold value
    tmp        = rivuletProcessing(handles);
    % extract calculated data
    IFACorr(i) = tmp.IFACorr(end);                                          %get calculated if size
    ARhoCorr(i)= tmp.ARhoCorr(end);
    mSpeed(:,i)= tmp.mSpeed{1}(:,1);                                        %called only for 1 regime/image
    RivWidth(:,i)= tmp.RivWidth{1}(:,1);
    epsHR(:,i) = tmp.epsHR{1}(:,1);
    locReW(:,i)= tmp.locReW{1}(:,1);
    thetaApL(:,i)= tmp.thetaApL{1}(:,1);
    thetaApR(:,i)= tmp.thetaApR{1}(:,1);
    drawnow                                                                 %update gui
end

% remove tmpDir
rmdir(handles.metricdata.storDir,'s')

% close the waitbar
close(hWait);

% fill in the popup menu
popString = fields(tmp);                                                    %get fields of the OUT structure
popString(ismember(popString,...
    {'Profiles','ARhoL','RivHeight','locReA'})) = [];                       %take out unwanted ones

valPopUp = find(cellfun(@isempty,cellfun(@strfind,popString,cellfun(@(x)...
    {sprintf('IFACorr',x)},...
    cell(size(popString))),'UniformOutput',false))==0); %#ok<CTPCT>
set(handles.avPlotPopUp,'String',popString,'Enable','on','Value',valPopUp);

set([handles.expPlotsPush handles.expDataPush],'Enable','on');              %enable data export buttons

% fill the axes with basic plot
plot(handles.plotToAxes,trSpan,IFACorr,'ko',...
    'MarkerFaceColor','Black')
xlabel('Threshold, [m]');ylabel('A_{l--g}, [m^2]')
xlim([min(trSpan) max(trSpan)])
grid on
set(handles.axTitleText,'String',...
    'Size of g--l i-f area as function of preset threshold')

% save results and update the handles structure
handles.metricdata.zSpan   = tmp.mSpeed{1}(:,end);
handles.metricdata.IFACorr = IFACorr;
handles.metricdata.ARhoCorr= ARhoCorr;
handles.metricdata.mSpeed  = mSpeed;
handles.metricdata.RivWidth= RivWidth;
handles.metricdata.epsHR   = epsHR;
handles.metricdata.locReW  = locReW;
handles.metricdata.thetaApL= thetaApL;
handles.metricdata.thetaApR= thetaApR;
handles.metricdata.imNames = tmpImNamesList;                                %restore necessary fields in handles
handles.metricdata.storDir = tmpStorDir;
guidata(hObject, handles)
end


% --- Executes on button press in exitPush.
function exitPush_Callback(~, ~, handles)
% Callback to the GUI window closing button

close(handles.figure1); 
end


% --- Executes on selection change in avPlotPopUp.
function avPlotPopUp_Callback(hObject, ~, handles)
% callback for selecting the data to plot

contents = cellstr(get(hObject,'String'));                                  %get the contents of the list
selStr   = contents{get(hObject,'Value')};                                  %get selected value

data     = handles.metricdata.(selStr);                                     %get the data
trSpan   = handles.metricdata.trSpan;

switch selStr
    case {'IFACorr','ARhoCorr'}
        % fill the axes with basic plot
        plot(handles.plotToAxes,trSpan,data,'ko',...
            'MarkerFaceColor','Black')
        xlabel('Threshold, [m]');xlim([min(trSpan) max(trSpan)])
        grid on
        switch selStr
            case 'IFACorr'
                ylabel('A_{l--g}, [m^2]')
                set(handles.axTitleText,'String',...
                    'Size of g--l i-f area as function of preset threshold')
            case 'ARhoCorr'
                ylabel('a_{l--g}, [m^{-1}]')
                set(handles.axTitleText,'String',...
                    'I-f area surf. density as function of preset threshold')
        end
    otherwise
        zspan = handles.metricdata.zSpan;
        colors = distinguishable_colors(numel(trSpan));
        plot(handles.plotToAxes,zspan,data','o-');
        set(handles.plotToAxes,'ColorOrder',colors)
        xlabel('Plate length coordinate, m')
        xlim([0 handles.metricdata.RivProcPars{1}(2)])
        legend(arrayfun(@(x)...
            sprintf('Threshold = %5.2e m',x),trSpan,'UniformOutput',false))
        switch selStr
            case 'mSpeed'
                ylabel('liq. mean speed, [m s^{-1}]')
                set(handles.axTitleText,'String',...
                    {'Lig. mean speed as function of plate length coordinates'...
                    'for different preset thresholds'})
            case 'RivWidth'
                ylabel('rivulet width, [m]')
                set(handles.axTitleText,'String',...
                    {'Rivulet width as function of plate length coordinates'...
                    'for different preset thresholds'})
            case 'epsHR'
                ylabel('\epsilon, [--]')
                set(handles.axTitleText,'String',...
                    {'Rivulet height to width ratio as function of plate'...
                    'length coordinates for different preset thresholds'})
            case 'locReW'
                ylabel('liq. mean speed, [m s^{-1}]')
                set(handles.axTitleText,'String',...
                    {'Loc. Reynolds number (width dependent) as function of'...
                    'plate length coordinates for different preset thresholds'})
            case 'thetaApL'
                ylabel('apparent contact angle from left, [\pi rad]')
                set(handles.axTitleText,'String',...
                    {'Apparent contact angle from left as function of'...
                    'plate length coordinates for different preset thresholds'})
            case 'thetaApR'
                ylabel('apparent contact angle from right, [\pi rad]')
                set(handles.axTitleText,'String',...
                    {'Apparent contact angle from right as function of'...
                    'plate length coordinates for different preset thresholds'})
        end
end
guidata(hObject, handles)
end

function trSpanEdit_Callback(hObject, ~, handles)
% function for getting the desired threshold span for the analysis, can take
% only standard MATLAB sequence notation or vector of values

tmpStr = get(hObject,'String');                                             %get the string
tmpStr = regexp(tmpStr,'[[]\s,]','split');                                  %split, but left sequences alone
isSequence = ...                                                            %locate the sequences
    cellfun(@strfind,tmpStr,cellfun(@(x) {sprintf(':',x)},...
    cell(size(tmpStr))),'UniformOutput',false); %#ok<CTPCT>
for i = 1:numel(tmpStr) %#ok<FORPF>
    if isempty(tmpStr{i}),continue,end;                                     %skip empty cells
    if isempty(isSequence{i}) == 0                                          %locate sequence
        tmpStr2 = regexp(tmpStr{i},':','split');                            %split it
        if numel(tmpStr2) ~= 3
            errordlg({'Sequences must be entered in format'...
                'lower:step:upper'});
        end
        tmpStr{i} = ...
            str2double(tmpStr2{1}):str2double(tmpStr2{2}):str2double(tmpStr2{3});
    else
        tmpStr{i} = str2double(tmpStr{i});                                  %not empty, not sequence -> number
    end
end

trSpan = cell2mat(tmpStr(cellfun(@isempty,tmpStr)==0));                     %concacenate and convert to mat
handles.metricdata.trSpan = trSpan;
% Update handles structure
guidata(hObject, handles);
end

function nCutsEdit_Callback(hObject, ~, handles)
% Callback to editable textfield where the user can specify how many cuts
% along the rivulet should be made

handles.metricdata.RivProcPars{5} = str2double(get(hObject,'String'));      %get number of cuts

guidata(hObject,handles);                                                   %update handle
end

% --- Executes on selection change in avImList.
function avImList_Callback(hObject, ~, handles)
% Callback to the list containing the availible images, get the sellected
% images and enable "Run" pushbutton

handles.metricdata.selIm = get(hObject,'Value');                            %get selected data (indexes)

set(handles.runPush,'Enable','on')                                          %enable the run pushbutton

guidata(hObject,handles);
end

% --- Executes on button press in expPlotsPush.
function expPlotsPush_Callback(~, ~, handles)
% function for exporting the resulting plots, user is asked to
% choose/create the directory for storing the images and than, each image
% is exported under its name showed in the pop-up menu

contents = cellstr(get(handles.avPlotPopUp,'String'));                      %get the availible data
trSpan   = handles.metricdata.trSpan;                                       %get the threshold span
startPath= handles.metricdata.storDir;
storDir = uigetdir(startPath,'Select folder to store outputs');             %let user choose directory to store outputs

% check, if the storDir was selected
if storDir == 0
    handles.statusbar = statusbar(handles.figure1,...
        'Image export was cancelled.');                                     %updating statusbar
    return                                                                  %stop the program execution
end
    

for i = 1:numel(contents)                                                   %for every dataset
    % statusbar update
    handles.statusbar = statusbar(handles.figure1,...
        'Exporting image %d of %d (%.1f%%)',...                             %updating statusbar
        i,numel(contents),100*i/numel(contents));
    handles.statusbar.ProgressBar.setVisible(true);                         %showing and updating progressbar
    handles.statusbar.ProgressBar.setMinimum(0);
    handles.statusbar.ProgressBar.setMaximum(numel(contents));
    handles.statusbar.ProgressBar.setValue(i);
    % image export
    hFig = figure('Units','Pixels','Visible','off',...                      %open invisible figure
        'Position',[10 10 1000 700]);
    data = handles.metricdata.(contents{i});                                %get the data
    switch contents{i}
        case {'IFACorr','ARhoCorr'}
            % fill the axes with basic plot
            plot(trSpan,data,'ko','MarkerFaceColor','Black')
            xlabel('Threshold, [m]');xlim([min(trSpan) max(trSpan)])
            grid on
            switch contents{i}
                case 'IFACorr'
                    ylabel('A_{l--g}, [m^2]')
                    hTtl = ...
                        title('Size of g--l i-f area as function of preset threshold');
                case 'ARhoCorr'
                    ylabel('a_{l--g}, [m^{-1}]')
                    hTtl = ...
                        title('I-f area surf. density as function of preset threshold');
            end
        otherwise
            zspan = handles.metricdata.zSpan;
            colors = distinguishable_colors(numel(trSpan));
            plot(zspan,data','o-');
            set(gca,'ColorOrder',colors)
            xlabel('Plate length coordinate, m')
            xlim([0 handles.metricdata.RivProcPars{1}(2)])
            legend(arrayfun(@(x)...
                sprintf('threshold = %5.2e m',x),trSpan,'UniformOutput',false))
            switch contents{i}
                case 'mSpeed'
                ylabel('liq. mean speed, [m s^{-1}]')
                hTtl = title(...
                    {'Lig. mean speed as function of plate length coordinates'...
                    'for different preset thresholds'});
            case 'RivWidth'
                ylabel('rivulet width, [m]')
                 hTtl = title(...
                    {'Rivulet width as function of plate length coordinates'...
                    'for different preset thresholds'});
            case 'epsHR'
                ylabel('\epsilon, [--]')
                 hTtl = title(...
                    {'Rivulet height to width ratio as function of plate'...
                    'length coordinates for different preset thresholds'});
            case 'locReW'
                ylabel('liq. mean speed, [m s^{-1}]')
                 hTtl = title(...
                    {'Loc. Reynolds number (width dependent) as function of'...
                    'plate length coordinates for different preset thresholds'});
            case 'thetaApL'
                ylabel('apparent contact angle from left, [\pi rad]')
                 hTtl = title(...
                    {'Apparent contact angle from left as function of'...
                    'plate length coordinates for different preset thresholds'});
            case 'thetaApR'
                ylabel('apparent contact angle from right, [\pi rad]')
                 hTtl = title(...
                    {'Apparent contact angle from right as function of'...
                    'plate length coordinates for different preset thresholds'});
            end
    end
    set(hTtl,'FontSize',16,'FontWeight','Bold')                             %format title
    drawnow                                                                 %redraw
    cd(storDir)                                                             %cd to chosen data storing directory
    saveas(hFig,contents{i},'png');                                         %save current figure as png
    close(hFig);                                                            %close the invisible figure
    cd(handles.metricdata.rootDir)                                          %cd back to rootDir
end
handles.statusbar = statusbar(handles.figure1,...
        'All images were exported in %s .',storDir);                        %updating statusbar
handles.statusbar.ProgressBar.setVisible(false);                            %hide progresbar progressbar
end


% --- Executes on button press in expDataPush.
function expDataPush_Callback(~, ~, handles)
% function for storing the exported data in form of textfiles. User is
% asked to specify the filename and the storing directory. then, one file
% with results is exported
%
% the file has following structure:
%
% head with some information about the file - creation time, image source
% directory, processed image and experimental set up data
%
% trSpan IFACorr ARhoCorr (in columns)
%
%            trSpan
% zSpan      other vars
% where trSpan is in row, zSpan is in a column and other vars is in columns
% for each trSpan value

% get the data
trSpan   = handles.metricdata.trSpan;                                       %get the threshold span
zSpan = handles.metricdata.zSpan;                                           %get the plate length coordinate span
[flName,storDir] = uiputfile({...                                           %get filename and storDir
 '*.txt','Text Files (*.txt)';...
 '*.*',  'All Files (*.*)'},...
 'Save results as');

% check, if the storDir and flName were selected
if ~ischar(flName) || ~ischar(storDir)
    handles.statusbar = statusbar(handles.figure1,...
        'Data export was cancelled.');                                      %updating statusbar
    return                                                                  %stop the program execution
end

IFACorr  = handles.metricdata.IFACorr;
ARhoCorr = handles.metricdata.ARhoCorr;
mSpeed   = handles.metricdata.mSpeed;
RivWidth = handles.metricdata.RivWidth;
epsHR    = handles.metricdata.epsHR;
locReW   = handles.metricdata.locReW;
thetaApL = handles.metricdata.thetaApL;
thetaApR = handles.metricdata.thetaApR;

% get the program runtime variables
imSourceDir = handles.metricdata.imSourceDir;                               %directory with original images

% get the experimental set up parameters
fluidType= handles.metricdata.fluidType;                                    %fluid type
RivProcPars = handles.metricdata.RivProcPars;                               %other exp. data
plateSize= RivProcPars{1};
inclAngle= RivProcPars{2};
FFact    = RivProcPars{6};
nCuts    = RivProcPars{5};
EdgCoord = handles.metricdata.EdgCoord;
DistanceP= round((EdgCoord(end)-EdgCoord(end-2))/(nCuts+1));                %distance between 2 cuts in pixels
DistanceM= DistanceP*plateSize(2)/(EdgCoord(end)-EdgCoord(end-2));          %distance between 2 cuts in m

% open or create file for writing (the probability of opening and rewriting
% existing file is extremely low, but...)
file2Wr  = fopen([storDir '/' flName],'w+');

% writing the head of the file
fprintf(file2Wr,'===HEAD==================================================\n\n');
fprintf(file2Wr,'Exported data from the treshInflStudy.m program\n\n');
fprintf(file2Wr,'File creation time: %s\n\n',datestr(now,'HH-MM-SS_dd-mm-yyyy'));
fprintf(file2Wr,'Image source directory: %s\n\n',imSourceDir);
fprintf(file2Wr,'Experimental set up data:\n');
fprintf(file2Wr,'Plate size: %f x %f m\n',plateSize(1),plateSize(2));
fprintf(file2Wr,'Plate inclination angle: %d deg\n',inclAngle);
fprintf(file2Wr,'Fluid type: %s\n',fluidType);
fprintf(file2Wr,'Gas f-factor: %5.3f Pa^0.5\n',FFact);
fprintf(file2Wr,'Number of cuts made along the plate: %d\n',nCuts);
fprintf(file2Wr,'Distance between 2 cuts: %d pixels ~ %5.3e m\n\n',DistanceP,DistanceM);

% writing the IFACORR and ARHOCORR
fprintf(file2Wr,'\n===IFACORR=AND=ARHOCORR================================\n\n');
fprintf(file2Wr,'trSpan \t IFACorr \t ARhoCorr\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[trSpan' IFACorr' ARhoCorr'],'delimiter','\t',...
        'precision','%10.5e','-append')
    
% writing other variables
file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===MSPEED==============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.0000 trSpan;...
                                 zSpan mSpeed],'delimiter','\t',...
        'precision','%10.5e','-append')

file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===RIVWIDTH============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.00000 trSpan;...
                                 zSpan RivWidth],'delimiter','\t',...
        'precision','%10.5e','-append')
    
file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===EPSHR ==============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.00000 trSpan;...
                                 zSpan epsHR],'delimiter','\t',...
        'precision','%10.5e','-append')
    
file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===LOCREW==============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.00000 trSpan;...
                                 zSpan locReW],'delimiter','\t',...
        'precision','%10.5e','-append')
    
file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===THETAAPL=============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.00000 trSpan;...
                                 zSpan thetaApL],'delimiter','\t',...
        'precision','%10.5e','-append')
    
file2Wr  = fopen([storDir '/' flName],'a');
fprintf(file2Wr,'\n===THETAAPR=============================================\n\n');
fclose(file2Wr);
dlmwrite([storDir '/' flName],[0.00000 trSpan;...
                                 zSpan thetaApR],'delimiter','\t',...
        'precision','%10.5e','-append')
    
handles.statusbar = statusbar(handles.figure1,...
        'Data were exported in %s .',[storDir flName]);                     %updating statusbar
handles.statusbar.ProgressBar.setVisible(false);                            %hide progresbar progressbar
end

%% Create functions
% --- Executes during object creation, after setting all properties.
function avPlotPopUp_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
% --- Executes during object creation, after setting all properties.
function trSpanEdit_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
% --- Executes during object creation, after setting all properties.
function nCutsEdit_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end
% --- Executes during object creation, after setting all properties.
function avImList_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
