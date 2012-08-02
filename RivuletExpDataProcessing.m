function varargout = RivuletExpDataProcessing(varargin)
%
%   function varargout = RivuletExpDataProcessing(varargin)
%
% function for GUI handling of the program for evaluation of
% experimental data obtained by measurements of the rivulet flow on
% inclined plate in TU Bergakademie Freiberg
%
%==========================================================================
% USER GUIDE:
%-preprocessing------------------------------------------------------------
% 1. Choose directory for storing output data (storDir)
% 2. Load background image and images to process
%-finding-edges-of-cuvettes-and-plate--------------------------------------
% 3. Select how much automatic should the finding of edges be
%   Automatic ... program writes out warnings but do not interact with user
%                 !! add control of standard deviation of found sizes of 
%                    the plate -> std(X) > maxTol => force user
%                    interaction !!
%   Semi-autom... if there should be warning output, asks for user
%                 interaction
%   Manual    ... asks for manual specification of edges for each plate
% 4. Optional - change default parameters for hough transform
%   Hough transform is used for finding the edges of the plate. The
%   parameters were optimized for minimial standard deviation of found
%   plate sizes on images from DC 5 measurements
% 5. Optional - set graphical output from the program execution
%   At the time, the images will be only shown as control of how
%   succesfully were found the edges)
% 6. Find edges of the plate and cuvettes (executes function findEdges with
%    collected parameters)
%-rivulet-data-processing--------------------------------------------------
% 7. Set the value of treshold to distinguish between rivulet and the rest
%   of the plate and FilterSensitivity for getting rid of the noises in
%   images.
% 8. Choose on which liquid was experiment conducted
%   This liquid has to be in database. To add it, edit file fluidDataFcn.
%   In this point are loaded liquid data from file fluidDataFcn
% 9. Optional - change optional parameters for the program execution
%   Plate Size... this shoud not be changed unless there has been major
%                 modification of experimental set up
%   Num. of Cuts. number of meaned profiles that user want get from program
%                 execution. default value is 5 which displays cut every 50
%                 mm of the plate (5/10/15/20/15 cm)
%   Parameters for conversion of grayscale values into distances
%             ... thicknesses of the film in calibration cuvettes
%             ... degree of polynomial to use in cuvette regression
%             ... width of cuvette in pixels (default 80)
%   !! If you want to change 1 of the parametres for conversion of
%   greyscale values into distances, you MUST fill out all the fields !!
%10. Optional - set which graphs should be plotted and how there should be
%    saved
%11. Calculate results (this calls function rivuletProcessing with
%   specified parameters)
%-postprocessing-----------------------------------------------------------
%12. Set defaults - sets default variable values for rivulet data
%   processing
%13. Save vars to base (calls function save_to_base)
%   Outputs all variables to base workspace (accessible from command
%   window). All user defined variables are in handles.metricdata and user
%   defined program controls (mainly graphics) are in handles.prgmcontrol
%   !! restructurilize handles.metricdata and handles.prgmcontrol with
%   better distinction between controls and data variables !!
%14. Clear vars clears all the user specified variables and reinitialize
%   GUI
%==========================================================================
% DEMANDS OF THE PROGRAM
% -Program was written in MATLAB R2010a, but shoud be variable with all
% MATLAB versions later than R2009a (implementation of ~ character)
% -Until now (17.07.2012) program was tested only on images from DC10
% measurements
% -For succesfull program execution there has to be following files in the
% root folder of the program:
% 1. RivuletExpDataProcessing.m/.fig (main program files)
% 2. findEdges.m (function for automatic edge finding in images)
% 3. rivuletProcessing.m (main function for data evaluation)
% 4. save_to_base.m (function for saving data into base workspace)
% 5. fluidDataFcn.m (database with fluid data)
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% See also: FINDEDGES FLUIDDATAFCN RIVULETPROCESSING SAVE_TO_BASE

% Edit the above text to modify the response to help
% RivuletExpDataProcessing

% Last Modified by GUIDE v2.5 02-Aug-2012 10:57:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @progGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @progGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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

% --- Executes just before progGUI is made visible.
function progGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to progGUI (see VARARGIN)

% fill gui with defaults values
[handles.metricdata handles.prgmcontrol] =...
    initializeGUI(hObject, eventdata, handles,'all');                       %call initialize function for all availible data

set(handles.MainWindow,'DockControl','off');                                %I want to make the window undockable

% handles.statusbar = statusbar(handles.MainWindow,'Program is ready');


% Choose default command line output for progGUI
handles.output = hObject;
set(hObject,'CloseRequestFcn',@my_closereq)

% Update handles structure
guidata(hObject, handles);


% My own closereq fcn -> to avoid closing with close command
function my_closereq(src,evnt)
% User-defined close request function 
% to display a question dialog box 
selection = questdlg('Close Rivulet data processing program?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        delete(gcf)
    case 'No'
        return
end


% --- Outputs from this function are returned to the command line.
function varargout = progGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set statusbar - this function is executed after GUI is made visible and
% before user can set any inputs => java object is ready for statusbar
handles.statusbar = statusbar(hObject,'Program is ready');

% Get default command line output from handles structure
varargout{1} = handles.output;

% Update handles structure
guidata(hObject, handles);                                                  %i need to do this because of the handles.statusbar

%% PushButtons - Preprocessing

% --- Executes on button press in PushChooseDir.
function storDir = PushChooseDir_Callback(hObject, eventdata, handles)
% hObject    handle to PushChooseDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% choosing directory to store outputs
start_path = '~/Documents/Freiberg/EvalExp';                                %start path for choosing directory (only for my machine)
storDir = uigetdir(start_path,'Select folder to store outputs');            %let user choose directory to store outputs

if storDir ~= 0                                                             %here i dont care about indent, its just basic input control
% create subdirectories
nameList= {'Subtracted' 'Height' 'Profile' 'Speed' 'Width' 'Correlation' ...%names of the directories for saving outputs
    'Plots'};
nameSubs= {{'Smoothed'} [] [] [] [] [] []};                                 %names of subdirectories for every folder

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

%modify string to display in statusbar
statusStr = ['Data storage directory ' storDir...
    ' loaded. Subdirectories are ready.'];
% set gui visible output
if numel(storDir) <= 45
    str   = storDir;
else
    str   = ['...' storDir(end-45:end)];
end
set(handles.EditStorDir,'String',str);                                      %display only 45 last characters or the whole string;

% saving outputs
handles.metricdata.storDir = storDir;
handles.metricdata.subsImDir = [storDir '/Subtracted'];                     %directory with subtracted images
handles.statusbar = statusbar(handles.MainWindow,statusStr);
else
%modify string to display in statusbar
statusStr = 'Choosing of data storage directory canceled by user'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in PushLoadBg.
function PushLoadBg_Callback(hObject, eventdata, handles)
% hObject    handle to PushLoadBg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% predefined input for uigetfile
FilterSpec  = '*.tif';
DlgTitle1   = 'Select background image';
start_path  = '~/Documents/Freiberg/Experiments/';
% choose background image
msgbox('Choose background image','modal');uiwait(gcf);
[bgName bgDir] = uigetfile(FilterSpec,DlgTitle1,start_path);
if bgDir ~= 0                                                               %basic input control
bgImage        = imread([bgDir '/' bgName]);

% updating statusbar
statusStr = ['Background image ' bgDir bgName...
    ' was succesfuly loaded.'];
handles.statusbar = statusbar(handles.MainWindow,statusStr);
% set gui visible output
if numel(bgDir) <= 45
    str   = bgDir;
else
    str   = ['...' bgDir(end-45:end)];
end
set(handles.EditBcgLoc,'String',str);                                       %display only 45 last characters or the whole string;

% save variable into handle
handles.metricdata.bgImage = bgImage;
else
%modify string to display in statusbar
statusStr = 'Choosing of Background image canceled.'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushLoadIM.
function daten = PushLoadIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushLoadIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% imNames   ... cell of strings, selected filenames
% imDir     ... string, path to the directory with images

% check if the directory for storing outputs is chosen
if isfield(handles.metricdata,'storDir') == 0                               %if not, force user to choose it
    msgbox('You must choose storDir before loading images','modal');
    uiwait(gcf);
    storDir = PushChooseDir_Callback(hObject, eventdata, handles);
    if storDir == 0
        set(handles.statusbar,'Text',...
            'Choosing of data storage directory canceled by user');
        return
    end
    % set gui visible output
    if numel(storDir) <= 45
        str   = storDir;
    else
        str   = ['...' storDir(end-45:end)];
    end
    set(handles.EditStorDir,'String',str);                                  %display only 45 last characters or the whole string;
else
    storDir = handles.metricdata.storDir;
end

% clear images, if they are present
if isfield(handles.metricdata,'daten');
    handles.metricdata = rmfield(handles.metricdata,{'daten' 'imNames'});
end

% auxiliary variables for dialogs
FilterSpec  = '*.tif';
DlgTitle1   = 'Select background image';
DlgTitle2   = 'Select images to be processed';
start_path  = '~/Documents/Freiberg/Experiments/';
selectmode  = 'on';

% load background image
if isfield(handles.metricdata,'bgImage') == 0                               %check if bgImage is already loaded, if not, choose it
    msgbox('Choose background image','modal');uiwait(gcf);
    [bgName bgDir] = uigetfile(FilterSpec,DlgTitle1,start_path);
    if bgName ~= 0
        bgImage        = imread([bgDir '/' bgName]);
    else
        set(handles.statusbar,'Text',...
            'Choosing of background image canceled by user');
        return
    end
    % set gui visible output
    if numel(bgDir) <= 45
        str   = storDir;
    else
        str   = ['...' bgDir(end-45:end)];
    end
    set(handles.EditBcgLoc,'String',str);                                   %display only 45 last characters or the whole string;
else
    bgImage        = handles.metricdata.bgImage;
end
% load images
msgbox({'Background is loaded,'...
    'chose images to be processed'},'modal');uiwait(gcf)
[imNames  imDir]...                                                         %get names and path to the images that I want to load
            = uigetfile(FilterSpec,DlgTitle2,'Multiselect',selectmode,...
            start_path);
if imDir ~= 0                                                               %basic input control
    subsImDir = [storDir '/Subtracted'];                                    %directory with subtracted images
if isa(imNames,'char') == 1
    imNames = {imNames};                                                    %if only 1 is selected, convert to cell
end
for i = 1:numel(imNames)
    tmpIM = imread([imDir '/' imNames{i}]);                                 %load images from selected directory
    tmpIM = imsubtract(tmpIM,bgImage);                                      %subtract background from image
    imwrite(tmpIM,[subsImDir '/' imNames{i}]);                              %save new images into subfolder
    if handles.prgmcontrol.DNTLoadIM == 0                                   %if i dont want to have stored images in handles.metricdata
        daten{i} = tmpIM;                                                   %if i want the images to be saved into handles
    end
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading and subtracting background from image %d of %d (%.1f%%)',...%updating statusbar
        i,numel(imNames),100*i/numel(imNames));
    set(handles.statusbar.ProgressBar,...
        'Visible','on', 'Minimum',0, 'Maximum',numel(imNames), 'Value',i);
end

% modify gui visible outputs
set(handles.statusbar.ProgressBar,'Visible','off');                         %made progresbar invisible again
set(handles.statusbar,...                                                   %update statusbar
    'Text','Images were succesfully loaded and substratced');
if numel(imDir) <= 45
    str   = imDir;
else
    str   = ['...' imDir(end-45:end)];
end
set(handles.EditIMLoc,'String',str);                                        %display only 45 last characters or the whole string;

% save variables into handles
if handles.prgmcontrol.DNTLoadIM == 0
    handles.metricdata.daten   = daten;                                     %save images only if user wants to
end
handles.metricdata.imNames = imNames;                                       %names of the images (~ var. "files" in R..._A...MOD)
handles.metricdata.bgImage = bgImage;                                       %background image (dont want to load it repetedly)
handles.metricdata.storDir = storDir;                                       %need to resave also the location for storing outputs
handles.metricdata.subsImDir   = subsImDir;                                 %location with subtracted images (for later image loading)
% save information about succesfull ending of the function
handles.prgmcontrol.loadIM = 0;                                             %0 ... OK, 1 ... warnings, 2 ... errors (for now without use)
else
%modify string to display in statusbar
statusStr = 'Loading images canceled by user'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClearIM.
function PushClearIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.metricdata,'bgImage') == 1                               %field metricdata.bgImage exists
    handles.metricdata = rmfield(handles.metricdata,'bgImage');
    if isfield(handles.metricdata,'daten') == 1
        handles.metricdata = rmfield(handles.metricdata,'daten');           %remove data saved into handles
    end
    if isfield(handles.metricdata,'imNames') == 1
        handles.metricdata = rmfield(handles.metricdata,'imNames');         %remove names of the loaded images
    end
    % Update handles structure
    guidata(handles.MainWindow, handles);
    set(handles.statusbar,'Text','Images were cleared');                    %notify user
    % restart the fields with texts
    set(handles.EditBcgLoc,'String','No background is loaded.');
    set(handles.EditIMLoc,'String','No images are loaded.');
else
    msgbox('No images were loaded','modal');uiwait(gcf);
end
% Update handles structure
guidata(handles.MainWindow, handles);

%% Editable fields - Preprocessing


function EditStorDir_Callback(hObject, eventdata, handles)
% hObject    handle to EditStorDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditStorDir as text
%        str2double(get(hObject,'String')) returns contents of EditStorDir as a double

storDir = get(hObject,'String');                                            %get storage directory from editable textfield
nameList= {'Subtracted' 'Height' 'Profile' 'Speed' 'Width' 'Correlation' ...%names of the directories for saving outputs
    'Plots'};
nameSubs= {{'Smoothed'} [] [] [] [] [] []};                                 %names of subdirectories for every folder

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

handles.metricdata.storDir = storDir;

statusStr = ['Data storage directory ' storDir...
    ' loaded. Subdirectories are ready.'];
set(handles.statusbar,'Text',statusStr);                                    %set statusbar


% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditStorDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditStorDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditBcgLoc_Callback(hObject, eventdata, handles)
% hObject    handle to EditBcgLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditBcgLoc as text
%        str2double(get(hObject,'String')) returns contents of EditBcgLoc as a double

%!! this textfield is not editable !!

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditBcgLoc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditBcgLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditIMLoc_Callback(hObject, eventdata, handles)
% hObject    handle to EditIMLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditIMLoc as text
%        str2double(get(hObject,'String')) returns contents of EditIMLoc as a double

%!! this textfield is not editable !!


% --- Executes during object creation, after setting all properties.
function EditIMLoc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditIMLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Preprocessing

% --- Executes on button press in CheckDNL.
function CheckDNL_Callback(hObject, eventdata, handles)
% hObject    handle to CheckDNL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckDNL

handles.prgmcontrol.DNTLoadIM = get(hObject,'Value');                          %get the checkbox value

% Update handles structure
guidata(handles.MainWindow, handles);


%% Pushbuttons - Image Processing


% --- Executes on button press in PushFindEdg.
function [EdgCoord daten] =...
    PushFindEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushFindEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
stmt1 = isfield(handles.metricdata,'imNames');                              %are there loaded images?
if stmt1 == 0                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    return
end

% call function findEdges and save output into handles
handles.metricdata.EdgCoord = findEdges(handles);

% call control function
[state,prbMsg,sumMsg] = controlFunction(handles.metricdata.EdgCoord);

% save output parameters into handles
handles.metricdata.state = state;
handles.metricdata.prbMsg= prbMsg;
handles.metricdata.sumMsg= sumMsg;

% modify potential mistakes
handles.metricdata.EdgCoord = modifyFunction(handles.metricdata);           %call modifyFunction with handles.metricdata input
set(handles.statusbar,'Text','EdgCoord is prepared for rivulet processing');%update statusbar

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClearEdg.
function PushClearEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata = rmfield(handles.metricdata,'EdgCoord');

msgbox('Edges coordinates were cleared','modal');uiwait(gcf);

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushDefEdg.
function PushDefEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushDefEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% obtain data
[newData{1} newData{2}] =...                                                %save outputs in newData cell
    initializeGUI(hObject, eventdata, handles,'imp');                       %call initialize function for image processing data

% merge structures
oldData = {handles.metricdata handles.prgmcontrol};                         %create cell of old data

parfor i = 1:numel(newData)
    fNamesNew = fieldnames(newData{i});                                     %get list of field names for new data structure
    for j = 1:numel(fNamesNew)                                              %for all the fields in newData{i} structure
        oldData{i}.(fNamesNew{j}) = newData{i}.(fNamesNew{j});              %replace same field in oldData or make field with corr. name
    end
end

% extract resulting variables
handles.metricdata = oldData{1};
handles.prgmcontrol= oldData{2};

% Update handles structure
guidata(handles.MainWindow, handles);

%% Editable fields - Image Processing

function EdithpTr_Callback(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdithpTr as text
%        str2double(get(hObject,'String')) returns contents of EdithpTr as a double

handles.metricdata.hpTr = str2double(get(hObject,'String'));                %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EdithpTr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditnumPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to EditnumPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditnumPeaks as text
%        str2double(get(hObject,'String')) returns contents of EditnumPeaks as a double

handles.metricdata.numPeaks = str2double(get(hObject,'String'));            %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditnumPeaks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditnumPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditfG_Callback(hObject, eventdata, handles)
% hObject    handle to EditfG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditfG as text
%        str2double(get(hObject,'String')) returns contents of EditfG as a double

handles.metricdata.fG = str2double(get(hObject,'String'));                  %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditfG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditfG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditmL_Callback(hObject, eventdata, handles)
% hObject    handle to EditmL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditmL as text
%        str2double(get(hObject,'String')) returns contents of EditmL as a double

handles.metricdata.mL = str2double(get(hObject,'String'));                  %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditmL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditmL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Image Processing

% --- Executes on button press in CheckCuvRegrGR.
function CheckCuvettes_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCuvRegrGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.prgmcontrol.GREdges(1) = get(hObject,'Value');                      %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in CheckPlate.
function CheckPlate_Callback(hObject, eventdata, handles)
% hObject    handle to CheckPlate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckPlate

handles.prgmcontrol.GREdges(2) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);

%% Popupmenu - Image Processing

% --- Executes on selection change in PopupIMProc.
function PopupIMProc_Callback(hObject, eventdata, handles)
% hObject    handle to PopupIMProc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupIMProc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupIMProc

contents = cellstr(get(hObject,'String'));
handles.prgmcontrol.autoEdges = contents{get(hObject,'Value')};             %get selected value from popmenu

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupIMProc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupIMProc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Editable fields - Rivulet processing

function EditTreshold_Callback(hObject, eventdata, handles)
% hObject    handle to EditTreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditTreshold as text
%        str2double(get(hObject,'String')) returns contents of EditTreshold as a double

handles.metricdata.Treshold = str2double(get(hObject,'String'));            %treshold for distinguish between the rivulet and resto of the plate

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditTreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditTreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditFSensitivity_Callback(hObject, eventdata, handles)
% hObject    handle to EditFSensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditFSensitivity as text
%        str2double(get(hObject,'String')) returns contents of EditFSensitivity as a double

handles.metricdata.FSensitivity = str2double(get(hObject,'String'));        %filter sensitivity for noise cancelation

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditFSensitivity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditFSensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Popup menu - Rivulet processing

% --- Executes on selection change in PopupLiqType.
function PopupLiqType_Callback(hObject, eventdata, handles)
% hObject    handle to PopupLiqType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupLiqType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupLiqType

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

angle = handles.metricdata.RivProcPars{2};                                  %get angle from rivulet processing parameters

% save selected value to handles
handles.metricdata.fluidData = fluidDataFcn(selected,angle);                %call database function

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupLiqType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupLiqType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in PopupGrFormat.
function PopupGrFormat_Callback(hObject, eventdata, handles)
% hObject    handle to PopupGrFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupGrFormat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupGrFormat

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

handles.prgmcontrol.GR.format = selected;                                   %save selected format for later use

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupGrFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupGrFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Checkboxes - Rivulet processing

% --- Executes on button press in CheckCompProfGR.
function CheckCuvRegrGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCuvRegrGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.prgmcontrol.GR.regr = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckRivTopGR.
function CheckRivTopGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckRivTopGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckRivTopGR

handles.prgmcontrol.GR.contour = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckCompProfGR.
function CheckCompProfGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCompProfGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCompProfGR

handles.prgmcontrol.GR.profcompl = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckMeanCutsGR.
function CheckMeanCutsGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckMeanCutsGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckMeanCutsGR

handles.prgmcontrol.GR.profcut = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

%% Radiobuttons - Rivulets processing (uibuttongroup)
% --- Executes when selected object is changed in PlotSetts.
function PlotSetts_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in PlotSetts 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'RadioShowPlots'
        handles.prgmcontrol.GR.regime = 0;                                  %only show plots
        set(handles.PopupGrFormat,'Enable','off');                          %if I am only showing pictures, the saving format doesnt matter
    case 'RadioSavePlots'
        handles.prgmcontrol.GR.regime = 1;                                  %only save plots
        set(handles.PopupGrFormat,'Enable','on');
    case 'RadioShowSavePlots'
        handles.prgmcontrol.GR.regime = 2;                                  %show and save plots
        set(handles.PopupGrFormat,'Enable','on');
end

% Update handles structure
guidata(handles.MainWindow, handles);


%% Pushbuttons - Rivulet processing

% --- Executes on button press in PushCalculate.
function PushCalculate_Callback(hObject, eventdata, handles)
% hObject    handle to PushCalculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
% I. are the edges of the plate and cuvettes found
if isfield(handles.metricdata,'EdgCoord') == 0                              %if EdgeCoord is not present, lets find it
        msgbox(['There are no edges of cuvettes'...
            ' and plate specified'],'modal');uiwait(gcf);
else                                                                        %otherwise call the rivuletProcessing function
    % set up listboxes in postprocessing
    set(handles.ListProfiles,'Value',1,'String','Preparing data')
    set(handles.ListOtherData,'Value',1,'String','Preparing data');
    
    % calculate outputs
    handles.metricdata.OUT = rivuletProcessing(handles);
    
    % create lists for listboxes - list with profiles
    liststr = cell(1,numel(handles.metricdata.imNames));
    for i = 1:numel(liststr)
        liststr{i} = handles.metricdata.imNames{i}(1:end-4);                %I dont want the .tif extension at the end of imNames
    end
    set(handles.ListProfiles,'String',liststr);                             %for each image, there is now availible profile
    
    % create lists for listboxes - list with other data
    % other data are divisible into 2 groups - description of the rivulet
    % (rivWidth, rivHeight, mSpeed) and data for correlations (IFACorr)
    fieldsCell = fields(handles.metricdata.OUT);                            %get field names of output structure
    fieldsCell = fieldsCell(strcmp(fieldsCell,'Profiles') == 0);            %get rid of the Profiles field
    % preallocate liststr
    nElmnts = 0;
    for i = 1:numel(fieldsCell);                                            %for all fields (except Profiles)
        tmpVar = handles.metricdata.OUT.(fieldsCell{i});                    %save current field
        if isa(tmpVar,'cell') == 1
            nReg = numel(tmpVar{end});                                      %number of regimes for current cell
            nElmnts = nElmnts + nReg;                                       %if current field is cell, number of elements in liststr is
        else                                                                %increased by number of regimes for current cell
            nElmnts = nElmnts + 1;                                          %if current fields is not a cell, number of elements in liststr
        end                                                                 %increases by 1
    end
    liststr = cell(1,nElmnts);
    % fill liststr
    k = 1;                                                                  %auxiliary indexing variable
    for i = 1:numel(fieldsCell)                                             %for all remaining fields
        tmpVar = handles.metricdata.OUT.(fieldsCell{i});                    %create temporary variable from structure field
        if isa(tmpVar,'cell') == 1                                          %is the variable cell? (true for descriptiv OUTPUTS)
            for j = 1:numel(tmpVar{end})
                liststr{k} = [fieldsCell{i} '_' tmpVar{end}{j}];            %create k-th list string
                k = k+1;                                                    %increase counter
            end
        else
            liststr{k} = fieldsCell{i};                                     %if fields is class double, there are no subfields
            k = k+1;                                                        %increase counter
        end
    end
    set(handles.ListOtherData,'String',liststr);                            %update list in appropriate listbox
    
    % set GUI
    msgbox('Program succesfully ended','modal');uiwait(gcf);                %inform user about ending
    set(handles.statusbar,'Text',['Program succesfully ended. '...          %update statusbar
        'Data for postprocessing are availible']);
end

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in PushSetDefRiv.
function PushSetDefRiv_Callback(hObject, eventdata, handles)
% hObject    handle to PushSetDefRiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% obtain data
[newData{1} newData{2}] =...                                                %save outputs in newData cell
    initializeGUI(hObject, eventdata, handles,'rvp');                       %call initialize function for rivulet processing data

% merge structures
oldData = {handles.metricdata handles.prgmcontrol};                         %create cell of old data

parfor i = 1:numel(newData)
    fNamesNew = fieldnames(newData{i});                                     %get list of field names for new data structure
    for j = 1:numel(fNamesNew)                                              %for all the fields in newData{i} structure
        oldData{i}.(fNamesNew{j}) = newData{i}.(fNamesNew{j});              %replace same field in oldData or make field with corr. name
    end
end

% extract resulting variables
handles.metricdata = oldData{1};
handles.prgmcontrol= oldData{2};

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushSaveToBase.
function PushSaveToBase_Callback(hObject, eventdata, handles)
% hObject    handle to PushSaveToBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_to_base(1)                                                             %save all variables to base workspace

handles.statusbar = statusbar(handles.MainWindow,...
        'All variables were saved into base workspace');


% --- Executes on button press in PushClearALL.
function PushClearALL_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearALL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = rmfield(handles,'metricdata');                                    %remove all user-defined data
handles = rmfield(handles,'prgmcontrol');

[handles.metricdata handles.prgmcontrol] =...                               %reinitialize GUI
    initializeGUI(hObject, eventdata, handles);

handles.statusbar = statusbar(handles.MainWindow,...
    ['All user defined variables were cleared.'...
    ' Start by loading images again']);

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClosePlots.
function PushClosePlots_Callback(hObject, eventdata, handles)
% hObject    handle to PushClosePlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.MainWindow,'HandleVisibility','off');                              %dont want to close the main program
close all                                                                   %close every other figure
set(handles.MainWindow,'HandleVisibility','on');

%% Pushbuttons - Outputs overview

% --- Executes on button press in PushShowProfiles.
function PushShowProfiles_Callback(hObject, eventdata, handles)
% hObject    handle to PushShowProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.prgmcontrol,'showProf') == 0
    msgbox('You must choose the profiles to be shown','modal');
    uiwait(gcf);
else
    showProf = handles.prgmcontrol.showProf;
    colNames = cell(1,numel(handles.metricdata.OUT.Profiles{1}(1,:)));      %preallocate variable for column names
    for i = 1:numel(colNames)/2
        colNames{2*i-1} = ['Cut ' mat2str(i) '|X, [m]'];
        colNames{2*i}   = ['Cut ' mat2str(i) '|Y, [m]'];
    end
    for i = 1:numel(showProf)
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
            'Name',['Mean profiles' mat2str(showProf)]);
        uitable(hFig,'Data',handles.metricdata.OUT.Profiles{showProf(i)},...
            'ColumnName',colNames,...
            'ColumnWidth',{90}, ...
            'Units','Normal', 'Position',[0 0 1 1]);
    end
end

% --- Executes on button press in PushShowOtherData.
function PushShowOtherData_Callback(hObject, eventdata, handles)
% hObject    handle to PushShowOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.prgmcontrol,'showOther') == 0
    msgbox('You must choose the data to be shown','modal');
    uiwait(gcf);
else
    % part commun for graphic and non-graphic output
    showOther = handles.prgmcontrol.showOther;                              %resave indexes of data to be shown
    fieldsCell = fields(handles.metricdata.OUT);                            %get field names of output structure
    fieldsCell = fieldsCell(strcmp(fieldsCell,'Profiles') == 0);            %get rid of the Profiles field
    k = 1;                                                                  %auxiliary indexing variable
    for i = 1:numel(fieldsCell)                                             %for all remaining fields
        tmpVar = handles.metricdata.OUT.(fieldsCell{i});                    %create temporary variable from structure field
        if isa(tmpVar,'cell') == 1                                          %is the variable cell? (true for descriptiv OUTPUTS)
            for j = 1:numel(tmpVar{end})
                NameStr = [fieldsCell{i} '_' tmpVar{end}{j}];               %create i-th list string
                if isempty(showOther(showOther == k)) == 0                  %data are chosen to be shown
                    plots = get(handles.CheckShowDataPlots,'Value');        %does user want plots?
                    showOtherDataUITable(tmpVar{j},NameStr,1,plots);        %show uitable with description option, without plots
                end
                k = k+1;                                                    %increase counter
            end
        else
            NameStr = fieldsCell{i};                                        %if fields is class double, there are no subfields
            if isempty(showOther(showOther == k)) == 0                      %data are chosen to be shown
                plots = get(handles.CheckShowDataPlots,'Value');            %does user want plots?
                showOtherDataUITable(tmpVar,NameStr,0,plots);               %show uitable with correlation options
            end
            k = k+1;                                                        %increase counter
        end
    end
end


%% Listboxes - Outputs overview

% --- Executes on selection change in ListProfiles.
function ListProfiles_Callback(hObject, eventdata, handles)
% hObject    handle to ListProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListProfiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListProfiles

handles.prgmcontrol.showProf = get(hObject,'Value');                        %save indexes of selected

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes during object creation, after setting all properties.
function ListProfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in ListOtherData.
function ListOtherData_Callback(hObject, eventdata, handles)
% hObject    handle to ListOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListOtherData contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListOtherData

handles.prgmcontrol.showOther = get(hObject,'Value');                       %save indexes of selected

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function ListOtherData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Outputs overview

% --- Executes on button press in CheckShowDataPlots.
function CheckShowDataPlots_Callback(hObject, eventdata, handles)
% hObject    handle to CheckShowDataPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckShowDataPlots


%% Auxiliary functions
function [metricdata prgmcontrol] = ...
    initializeGUI(hObject,eventdata,handles,dataPart)
%
% function for gui inicialization, to be executed just before progGui is
% made visible

% INPUT variables
% hObject,eventdata,handles ... default inputs
% dataPart  ... which part of data am I expecting
%               'all' if the function is called from opening function
%               'imp' if the function is called to set defaults for image
%                     processing
%               'rvp' if the function is called to set defaults for rivulet
%                     data processing

switch dataPart
    case 'all'
        imp = 1; rvp = 1;                                                   % i want all availible data
    case 'imp'
        imp = 1; rvp = 0;                                                   %only image processing defaults
    case 'rvp'
        imp = 0; rvp = 1;                                                   %only rivulet processing defaults
end

if imp == 1 && rvp == 1                                                     %this is to be set only when initializing gui
% specify metricdata for preprocessing
% Specify root folder for program execution (must contain all the used
% functions)
handles.metricdata.rootDir = pwd;
handles.prgmcontrol.DNTLoadIM = 1;                                          %by default, i dont want to store all image data in handles
% fill the edit boxes
set(handles.EditStorDir,'String',['No outputs storage directory is'...      %fill the edit boxes
    ' selected.']);
set(handles.EditBcgLoc,'String','No background is loaded.');
set(handles.EditIMLoc,'String','No images are loaded.');
% modify checkbuttons
set(handles.CheckDNL,'Value',handles.prgmcontrol.DNTLoadIM);
end

if imp == 1
% set default values for fields in Image Processing
% set values
handles.prgmcontrol.autoEdges = 'Force-automatic';                          %default - completely automatic program execution
handles.prgmcontrol.GREdges   = [0 0];
% modify popup menu
contents = cellstr(get(handles.PopupIMProc,'String'));                      %get the stringcell of options in popup menu
indSel   = find(strcmp(contents,handles.prgmcontrol.autoEdges)~=0);         %get position of selected value
set(handles.PopupIMProc,'Value',indSel);                                    %set value for image processing popup
% set checkboxes
set(handles.CheckCuvettes,'Value',handles.prgmcontrol.GREdges(1));
set(handles.CheckPlate,'Value',handles.prgmcontrol.GREdges(2));
% default values for image processing additional parameters
handles.metricdata.IMProcPars = {0.3300 200 35 25 0.4000 0 'Prewitt'};
end

if rvp == 1
% set defaults values for fields in Rivulet processing
% program controls - set values
handles.prgmcontrol.GR.regr     = 0;                                        %no graphics at all
handles.prgmcontrol.GR.contour  = 0;
handles.prgmcontrol.GR.profcompl= 0;
handles.prgmcontrol.GR.profcut  = 0;
handles.prgmcontrol.GR.regime   = 1;
handles.prgmcontrol.GR.format   = 'png';                                    %default format for graphics saving
% program control - make changes to gui
% popup menu - format of the saved plots
contents = cellstr(get(handles.PopupGrFormat,'String'));                    %get the stringcell of options in popup menu
indSel   = find(strcmp(contents,handles.prgmcontrol.GR.format)~=0);         %get position of selected value
set(handles.PopupGrFormat,'Value',indSel);                                  %select appropriate choice
% checkboxes - which graphs are to be plotted
set(handles.CheckCuvRegrGR,'Value',handles.prgmcontrol.GR.regr);
set(handles.CheckRivTopGR,'Value',handles.prgmcontrol.GR.contour);
set(handles.CheckCompProfGR,'Value',handles.prgmcontrol.GR.profcompl);
set(handles.CheckMeanCutsGR,'Value',handles.prgmcontrol.GR.profcut);
% radiobuttons - how the graphs are to be shown/saved
buttonHandlesCell = {handles.RadioShowPlots handles.RadioSavePlots ...      %create cell with button handles
    handles.RadioShowSavePlots};
for i = 1:3                                                                 %check radiobuttons in dependece of value stored in ...GR.regime
    if handles.prgmcontrol.GR.regime == i-1
        Val = get(buttonHandlesCell{i},'Max');
    else
        Val = get(buttonHandlesCell{i},'Min');
    end
    set(buttonHandlesCell{i},'Value',Val);
end
       

% metricdata
% additional rivulet processing parameters
handles.metricdata.RivProcPars = {[0.15 0.30] 60 [1.93 0.33 6 2.25 80]...   % PlateSize, angle, cuvettes regr. pars, polDeg, nCuts, VolGasFlow
    2 5 0};
% mandatory input fields - set values
angle = handles.metricdata.RivProcPars{2};                                  %plate inclination angle
string= 'DC 5';
handles.metricdata.fluidData = fluidDataFcn(string,angle);                  %set vaules into handles
handles.metricdata.Treshold     = 0.1;                                      %set value
handles.metricdata.FSensitivity = 10;
% mandatory input fields - fill edit boxes
set(handles.EditTreshold, 'String', handles.metricdata.Treshold);           %fill in the field
set(handles.EditFSensitivity, 'String', handles.metricdata.FSensitivity);
% mandatory input fields - modify popup menu
contents = cellstr(get(handles.PopupLiqType,'String'));                     %get the stringcell of options in popup menu
indSel   = find(strcmp(contents,string)~=0);                                %get position of selected value
set(handles.PopupLiqType,'Value',indSel);                                   %select appropriate choice
end

metricdata = handles.metricdata;
prgmcontrol= handles.prgmcontrol;
% Update handles structure
guidata(handles.MainWindow, handles);


%% Menus

%% File menu
% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function SaveBase_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save_to_base(1);                                                            %save all variables into base workspace
set(handles.statusbar,'Text','All variables were saved into base workspace');

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SaveFile_Callback(hObject, eventdata, handles)
% hObject    handle to SaveFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

metricdata = handles.metricdata;
prgmcontrol= handles.prgmcontrol;

strCell = {'metricdata' 'prgmcontrol'};

uisave(strCell,'RivProc_UsrDefVar');

set(handles.statusbar,'Text',...
    'User defined variables were saved into file.');


% --------------------------------------------------------------------
function LoadFile_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('metricdata','var') == 0 || exist('prgmcontrol','var') == 0
    msgbox(['You can use this option only to load variables saved by'...
        '"save variables into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading variables from file failed.');
else
    handles.metricdata = metricdata;
    handles.prgmcontrol= prgmcontrol;
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading variables from file failed.');
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function QuitPrgm_Callback(hObject, eventdata, handles)
% hObject    handle to QuitPrgm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.MainWindow);                                                  %call closing function


%% Elements edges finding menu
% --------------------------------------------------------------------
function findEdgesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to findEdgesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SaveEdgCoord_Callback(hObject, eventdata, handles)
% hObject    handle to SaveEdgCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.metricdata,'EdgCoord') == 1
    EdgCoord = handles.metricdata.EdgCoord;
    uisave('EdgCoord','EdgCoord')
else
    msgbox('You must specify EdgCoord at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Edges of plate and cuvettes were saved into .mat file');


% --------------------------------------------------------------------
function LoadEdgCoord_Callback(hObject, eventdata, handles)
% hObject    handle to LoadEdgCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('EdgCoord','var') == 0
    msgbox(['You can use this option only to load EdgCoord saved by'...
        '"save EdgCoord into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading EdgCoord from file failed.');
else
    handles.metricdata.EdgCoord = EdgCoord;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' EdgCoord is prepared for rivulet processing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function ModIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to ModIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

IMProcPars = changeIMPars;                                                  %call gui for changing parameters

% check ouptuts
if isempty(IMProcPars) == 0
    handles.metricdata.IMProcPars = IMProcPars;                             %if parameters are changed, save them into structure
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function ShowIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to ShowIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

changeIMPars('onlyshow',handles.metricdata.IMProcPars);                     %call gui for changing parameters with loaded current


% --------------------------------------------------------------------
function SaveIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to SaveIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.metricdata.IMProcPars) == 0
    IMProcPars = handles.metricdata.IMProcPars;
    uisave('IMProcPars','IMProcPars')
else
    msgbox('You must specify IMProcPars at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Image processing parameters were saved into .mat file');


% --------------------------------------------------------------------
function LoadIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to LoadIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('IMProcPars','var') == 0
    msgbox(['You can use this option only to load IMProcPars saved by'...
        '"save IMProcPars into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading IMProcPars from file failed.');
else
    handles.metricdata.IMProcPars = IMProcPars;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' IMProcPars is prepared for image processing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function BestMethod_Callback(hObject, eventdata, handles)
% hObject    handle to BestMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
if isfield(handles.metricdata,'imNames') == 0                               %are there loaded images?                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    return
end

handles.metricdata.IMProcPars = ...                                         %call method for finding best image processing method
    bestMethod(handles);

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SpecAppPlatePos_Callback(hObject, eventdata, handles)
% hObject    handle to SpecAppPlatePos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% extracting needed values from handles
if isfield(handles.metricdata,'daten') == 1                                 %see if there are images saved into handles
    DNTLoadIM = 0;
else
    DNTLoadIM = 1;
    imNames   = handles.metricdata.imNames;                                 %if not, obtain info for loading
    subsImDir = handles.metricdata.subsImDir;
end

% setting up the statusbar
handles.statusbar = statusbar(handles.MainWindow,...
    'Waiting for user response');

% obtaining approximate coordinates of the plate
options.Interpreter = 'tex';
options.WindowStyle = 'modal';
msgbox({['Please specify approximate position of the'...
    ' plate on processed images']...
    ['Click little bit outside of {\bf upper left} '...
    'and {\bf lower right corner}']},options);uiwait(gcf);
se      = strel('disk',12);                                                 %morphological structuring element
if DNTLoadIM == 1                                                           %if the images are not loaded, i need to get the image from directory
    tmpIM = imread([subsImDir '/' imNames{1}]);                             %load image from directory with substracted images
else
    tmpIM = handles.metricdata.daten{1};                                    %else i can get it from handles
end
tmpIM   = imtophat(tmpIM,se);
tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                    %enhance contrasts
tmpIM   = im2bw(tmpIM,0.16);                                                %conversion to black and white
figure;imshow(tmpIM);                                                       %show image to work with
cutMat  = round(ginput(2));close(gcf);                                      %let the user specify approximate position of the plate
cutLeft = cutMat(1,1);cutRight = cutMat(2,1);
cutTop  = cutMat(1,2);cutBottom= cutMat(2,2);                               %cut out \pm the plate (less sensitive than exact borders)

handles.metricdata.AppPlatePos = ...                                        %save approximate plate position into handles
    [cutLeft cutTop cutRight cutBottom];

set(handles.statusbar,'Text',['Approximate plate edges position was '...
    'saved into handles']);

% Update handles structure
guidata(handles.MainWindow, handles);


%% Data processing menu
% --------------------------------------------------------------------
function rivProcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to rivProcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ModExpPars_Callback(hObject, eventdata, handles)
% hObject    handle to ModExpPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

RivProcPars = changeRPPars;                                                 %call gui for changing parameters

%check output
if isempty(RivProcPars) == 0                                                %if parameters were modified, save them into structures
    handles.metricdata.RivProcPars = RivProcPars;
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function ShowExpPars_Callback(hObject, eventdata, handles)
% hObject    handle to ShowExpPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

changeRPPars('onlyshow',handles.metricdata.RivProcPars);                    %call gui for changing parameters with loaded current

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function SaveRPPars_Callback(hObject, eventdata, handles)
% hObject    handle to SaveRPPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.metricdata.RivProcPars) == 0
    RivProcPars = handles.metricdata.RivProcPars;
    uisave('RivProcPars','RivProcPars')
else
    msgbox('You must specify RivProcPars at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Rivulet processing parameters were saved into .mat file');


% --------------------------------------------------------------------
function LoadRPPars_Callback(hObject, eventdata, handles)
% hObject    handle to LoadRPPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('RivProcPars','var') == 0
    msgbox(['You can use this option only to load RivProcPars saved by'...
        '"save RivProcPars into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading RivProcPars from file failed.');
else
    handles.metricdata.RivProcPars = RivProcPars;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' RivProcPars is prepared for rivulet processing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);

%% Postprocessing menu

% --------------------------------------------------------------------
function PostProcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PostProcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ShowGenPlots_Callback(hObject, eventdata, handles)
% hObject    handle to ShowGenPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

FilterSpec  = {'*.fig';'*.png;*.eps;*.tif'};
DlgTitle   = 'Select figures to load';
if isfield(handles.metricdata,'storDir')                                    %if storDir is selected and subdirectories created
    start_path = [handles.metricdata.storDir '/Plots'];
else
    start_path = pwd;
end
selectmode  = 'on';
% choose background image
[fileNames fileDir] = uigetfile(FilterSpec,DlgTitle,'Multiselect',...
    selectmode,start_path);
if isa(fileNames,'char') == 1
    fileNames = {fileNames};                                                %if only 1 is selected, convert to cell
end
for i = 1:numel(fileNames)                                                  %for all loaded images
    if strcmp(fileNames{1}(end-3:end),'.fig') == 1
        openfig([fileDir '/' fileNames{i}]);
    else
        figure;imshow([fileDir '/' fileNames{i}]);
    end
end
