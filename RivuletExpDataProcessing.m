function varargout = RivuletExpDataProcessing(varargin)
%
%   function varargout = RivuletExpDataProcessing(varargin)
%
% function for GUI handling of the program for evaluation of
% experimental data obtained by measurements of the rivulet flow on
% inclined plate in TU Bergakademie Freiberg
%
%==========================================================================
% MENU SHORTCUTS:
%-File---------------------------------------------------------------------
% Ctrl+S    ... Save all variables into .mat file
% Ctrl+O    ... Load metricdata and prgmcontrol variables from .mat file
% Ctlr+Q    ... Quit program
%
%-Elements-edges-finding---------------------------------------------------
% Ctrl+I    ... Modify image processing parameters
% Ctrl+B    ... Try to find the best image processing method
%
%-Data-processing----------------------------------------------------------
% Ctrl+M    ... Modify rivulet processing parameters
% Ctrl+E    ... Show current rivulet processing parameters
%
%-Postprocessing-----------------------------------------------------------
% Ctrl+A    ... Show availible processed data
% Ctrl+P    ... Open postprocessing tool
%
%==========================================================================
% USER GUIDE:
%-preprocessing------------------------------------------------------------
% 1. Choose directory for storing output data (storDir)
% 2. Load background image and images to be processed
%-finding-edges-of-cuvettes-and-plate--------------------------------------
% 3. Select how much automatic should the finding of edges be
%   Force-autom.. program doesnt interact with user even if it cannot
%                 estimate some of the edges
%   Automatic ... program writes out warnings but do not interact with user
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
%    collected parameters, output of findEdges is controlled by
%    controlFunction and user can alternate results through
%    modifyFunction).
%-rivulet-data-processing--------------------------------------------------
% 7. Set the value of treshold to distinguish between rivulet and the rest
%   of the plate and FilterSensitivity for getting rid of the noises in
%   images.
% 8. Choose on which liquid was the experiment conducted
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
%10. Optional - set which graphs should be plotted and how there should be
%    saved
%11. Calculate results (this calls function rivuletProcessing with
%   specified parameters)
%-postprocmenu-----------------------------------------------------------
%12. Set defaults - sets default variable values for rivulet data
%   processing
%13. Save vars to base (calls function save_to_base)
%   Outputs all variables to base workspace (accessible from command
%   window). All user defined variables are in handles.metricdata and user
%   defined program controls (mainly graphics) are in handles.prgmcontrol
%14. Clear vars clears all the user specified variables and reinitialize
%   GUI
%15. Check the results in "Quick outputs overview", for more detailed
%   control use postprocessing tool in the Postprocessing menu
%==========================================================================
% DEMANDS OF THE PROGRAM
% -Program was written in MATLAB R2010a, but shoud be variable with all
% MATLAB versions later than R2009a (implementation of ~ character)
% -Program was tested under MATLAB R2010a on 64b linux machine and under
% MATLAB R2012a on 32b windows xp machine
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
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also FINDEDGES RIVULETPROCESSING

% Last Modified by GUIDE v2.5 08-Aug-2012 14:40:10

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


% --- Executes on attempt to close GUI
function my_closereq(~,~)
% User-defined close request function 
% to display a question dialog box and ask if the figure should be closed
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
function varargout = progGUI_OutputFcn(hObject, ~, handles) 
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
function storDir = PushChooseDir_Callback(~, ~, handles)
% function for chosing the storage directory for the program outputs, this
% function saves the path to the storage directory into
% handles.metricdata.storDir and the path to subtracted images (where
% background was subtracted from the experimental images to the
% handles.metricdata.subsImDir.
%
% function also check the existing subdirectories of the chosen directory
% and if they dont exist, it creates all the subdirectories needed for the
% program execution

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
function PushLoadBg_Callback(~, ~, handles) %#ok<DEFNU>
% function for loading the background image into the handles.metricdata
% structure. 
%
% Rq: background image is kept into the structures for all the
% program execution timem but i should check, if and where it is really
% needed

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
function daten = PushLoadIM_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% function for loading images to be processed and for subtracting the
% background from them. this functions needs for run specified storDir and
% background image, so if they are not yet loaded/chosen, the function asks
% for them.

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
    handles.statusbar.ProgressBar.setVisible(true);                         %showing and updating progressbar
    handles.statusbar.ProgressBar.setMinimum(0);
    handles.statusbar.ProgressBar.setMaximum(numel(imNames));
    handles.statusbar.ProgressBar.setValue(i);
end

% modify gui visible outputs
handles.statusbar.ProgressBar.setVisible(false);                            %made progresbar invisible again
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
function PushClearIM_Callback(~, ~, handles) %#ok<DEFNU>
% function for clearing currently loaded images. it clears the images or
% image infor from the current handles as well as the background image and
% it updates concerned editable fields

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


function EditStorDir_Callback(hObject, ~, handles) %#ok<DEFNU>
% editable field that shows current chosen storDir and also allows user to
% set it manually from the keyboard by writing full or relative path to it.
%
% if the way is setted up manually, this function checks out the existence
% of the specified folder and eventually creates the subfolders

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
function EditStorDir_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of the EditStorDir editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditBcgLoc_Callback(~, ~, ~) %#ok<DEFNU>
% uneditable text field used for showing the location of chosen background
% image


% --- Executes during object creation, after setting all properties.
function EditBcgLoc_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of the EditBcgLoc editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditIMLoc_Callback(~, ~, ~) %#ok<DEFNU>
% uneditable text field used for showing the location of processed images


% --- Executes during object creation, after setting all properties.
function EditIMLoc_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of the EditIMLoc editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Preprocessing

% --- Executes on button press in CheckDNL.
function CheckDNL_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to load all the processed
% images into the handles structure. If users computer has a lot of
% availible RAM memory and slow HDD, it is good to load all into the
% handles, otherwise, it is more efficient to load the images for every
% operation one by one
%
% by default, images are not loaded into the handles.metricdata

% Hint: get(hObject,'Value') returns toggle state of CheckDNL

handles.prgmcontrol.DNTLoadIM = get(hObject,'Value');                          %get the checkbox value

% Update handles structure
guidata(handles.MainWindow, handles);


%% Pushbuttons - Image Processing

% --- Executes on button press in PushFindEdg.
function PushFindEdg_Callback(~, ~, handles) %#ok<DEFNU>
% pushbutton that summons all the preset parameters and calls the findEdges
% function for EdgCoord specification. After the EdgCoord matrix is created
% and saved into the handles.metricdata structure, it is controlled by the
% controlFunction and the results are shown to user using modifyFunction.
% After that user can modify the found values.

% check if there all required data are present
if isfield(handles.metricdata,'imNames') == 0                               %check if there are loaded images
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
function PushClearEdg_Callback(~, ~, handles) %#ok<DEFNU>
% by pressing this button, the EdgCoord matrix is cleared from the
% handles.metricdata structure

handles.metricdata = rmfield(handles.metricdata,'EdgCoord');

msgbox('Edges coordinates were cleared','modal');uiwait(gcf);

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushDefEdg.
function PushDefEdg_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% if this button is pressed, default image processing parameters are
% loaded. This means that initializeGUI function is called with option to
% return only image processing parameters and then the old and the new
% metricdata and prgmcontrol structures are merged with rewriting of
% colliding old values

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

%% Checkboxes - Image Processing

% --- Executes on button press in CheckCuvRegrGR.
function CheckCuvettes_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to display graphs from
% cuvettes finding

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.prgmcontrol.GREdges(1) = get(hObject,'Value');                      %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in CheckPlate.
function CheckPlate_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to display graphs from plate
% edges finding

% Hint: get(hObject,'Value') returns toggle state of CheckPlate

handles.prgmcontrol.GREdges(2) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);

%% Popupmenu - Image Processing

% --- Executes on selection change in PopupIMProc.
function PopupIMProc_Callback(hObject, ~, handles) %#ok<DEFNU>
% popup menu for choosing the level of automaticity of the findEdges
% function execution. Availible options are 'Manual', 'Semi-automatic',
% 'Automatic' and 'Force-automatic'. The default option is
% 'Force-automatic'.
%
% Differences between options are explained in the main function
% (RivuletExpDataProcessing.m) help file

contents = cellstr(get(hObject,'String'));
handles.prgmcontrol.autoEdges = contents{get(hObject,'Value')};             %get selected value from popmenu

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupIMProc_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of the PopupIMProc popup list

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Editable fields - Rivulet processing

function EditTreshold_Callback(hObject, ~, handles) %#ok<DEFNU>
% field for specifying the treshold (liquid layer height) for differencing
% between the rivulet and the noise on the plate, the value is inserted
% into mm and the default value is 0.1 (but anything between 0.05 and 0.1
% would be OK)

handles.metricdata.Treshold = str2double(get(hObject,'String'));            %treshold for distinguish between the rivulet and resto of the plate

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditTreshold_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of EditTreshold editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditFSensitivity_Callback(hObject, ~, handles) %#ok<DEFNU>
% field for specifying the filter sensitivity to be used when getting rid
% of the noise on the experimental pictures, it is used when the predefined
% 2D filter is created by the MATLAB function fspecial. The default (and
% unchangeable) type of the filter is 'disk' and the default value of
% filterSensitivity is 10

handles.metricdata.FSensitivity = str2double(get(hObject,'String'));        %filter sensitivity for noise cancelation

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditFSensitivity_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for set up properties of EditFSensitivity editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Popup menu - Rivulet processing

% --- Executes on selection change in PopupLiqType.
function PopupLiqType_Callback(hObject, ~, handles) %#ok<DEFNU>
% popup menu that allows user to select between different liquid types used
% during the experiments. This menu calls function fluidDataFcn with
% specified liquid and plate inclination angles parameters and saves
% obtained fluidData into the handles.metricdata structure.
%
% fluidData is vector containing gravitational acceleration, g, viscosity,
% surface tension and density of the liquid and the calibration parameters
% for the pumpe rotameter (these parameters are used into calculating the
% dimensionless and volumetric flows of the liquid)

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

angle = handles.metricdata.RivProcPars{2};                                  %get angle from rivulet processing parameters

% save selected value to handles
handles.metricdata.fluidData = fluidDataFcn(selected,angle);                %call database function

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupLiqType_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up propertios of the PopupLiqType popup menu

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in PopupGrFormat.
function PopupGrFormat_Callback(hObject, ~, handles) %#ok<DEFNU>
% through this menu, user can specify in which format he wants to save
% plots generated during the rivuletProcessing function execution.
%
% availible formats are: 'png','fig','eps' and 'tif'
% default format is 'png'

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

handles.prgmcontrol.GR.format = selected;                                   %save selected format for later use

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupGrFormat_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting up properties of PopupGRFormat popup list

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Checkboxes - Rivulet processing

% --- Executes on button press in CheckCompProfGR.
function CheckCuvRegrGR_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to generate graphics from the
% cuvette regression. By default, no plots are generated.

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.prgmcontrol.GR.regr = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckRivTopGR.
function CheckRivTopGR_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to generates contour plots of
% the rivulet from top view. By default, no plots are generated.

% Hint: get(hObject,'Value') returns toggle state of CheckRivTopGR

handles.prgmcontrol.GR.contour = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckCompProfGR.
function CheckCompProfGR_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to generate plots of the
% complete rivulet profiles. By default, no plots are generated. Generation
% of the complete rivulet profiles plots is also the most time consuming
% part of the function

% Hint: get(hObject,'Value') returns toggle state of CheckCompProfGR

handles.prgmcontrol.GR.profcompl = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckMeanCutsGR.
function CheckMeanCutsGR_Callback(hObject, ~, handles) %#ok<DEFNU>
% checkbox for controlling if the user wants to generate plots from mean
% profiles of the rivulets into the made cuts. By default no plots are
% generated.

% Hint: get(hObject,'Value') returns toggle state of CheckMeanCutsGR

handles.prgmcontrol.GR.profcut = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

%% Radiobuttons - Rivulets processing (uibuttongroup)
% --- Executes when selected object is changed in PlotSetts.
function PlotSetts_SelectionChangeFcn(~, eventdata, handles) %#ok<DEFNU>
% uibuttongroup for specifying the handling of generated plots, by default
% the plots are only saved, but user can chose between only showing the
% plots, only saving the plots and both showing and saving the plots.
%
% If the plots are shown, for larger datasets, quite high number of windows
% would be opened.
%
% uibuttongroup hints:
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
function PushCalculate_Callback(~, ~, handles) %#ok<DEFNU>
% pushbutton that summons up all the parameters and calls the function
% rivuletProcessing.m
%
% at first, it is checked if all required fields are specified (EdgCoord
% and images), then the rivuletProcessing function is called

% the output of rivuletProcessing is stored into
% handles.metricdata.Availible cell and the number of evaluated experiments
% is increased by 1 (handles.prgmcontrol.nExp)

% check if there all required data are present
% I. are the edges of the plate and cuvettes found
if isfield(handles.metricdata,'EdgCoord') == 0                              %if EdgeCoord is not present, lets find it
    msgbox(['There are no edges of cuvettes'...
        ' and plate specified'],'modal');uiwait(gcf);
    return
elseif isfield(handles.metricdata,'imNames') == 0
    msgbox('There are no loaded images','modal');uiwait(gcf);
    return
else                                                                        %otherwise call the rivuletProcessing function
    % set up listboxes in postprocmenu
    set(handles.ListProfiles,'Value',1,'String','Preparing data')
    set(handles.ListOtherData,'Value',1,'String','Preparing data');
    
    % calculate outputs
    handles.metricdata.OUT = rivuletProcessing(handles);
    
    % saving output into cell for use in postprocmenu
    nExp = handles.prgmcontrol.nExp;                                        %number of the experiment (times that calculate was ran)
    handles.metricdata.Availible{nExp} = handles.metricdata.OUT;            %saving outputs
    handles.prgmcontrol.nExp = nExp+1;                                      %increase counter
    % create ID for experiment
    contents = cellstr(get(handles.PopupLiqType,'String'));                 %get selected liquid type
    liqType = contents{get(handles.PopupLiqType,'Value')};
    gasFlow = mat2str(handles.metricdata.RivProcPars{6});                   %get value of volumetric flow rate of gas
    angle   = mat2str(handles.metricdata.RivProcPars{2});                   %get value of plate inclination angle
    time    = datestr(now,'dd_mm_yy-HH_MM_SS');
    ID      = [liqType '_' gasFlow '_' angle '_' time];                     %set ID string
    handles.metricdata.Availible{nExp}.imNames = handles.metricdata.imNames;%set image names/measurement descriptions
    handles.metricdata.Availible{nExp}.plateSize = ...                      %save also plateSize of current experiment
        handles.metricdata.RivProcPars{1};
    handles.metricdata.Availible{nExp}.ID = ID;
    
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
function PushSetDefRiv_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% by pressing this pushbutton, the default parameters for the
% rivuletProcessing are loaded and any user set values are rewritten
% (initializeGUI function is called with option to return only the rivulet
% processing parameters and then the returned and the current metricdata
% and prgmcontrol fields are merged with rewriting any conflicting values
% by the new ones)

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
function PushSaveToBase_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>%the variables are used 'indirectly'
% by pressing this button, all the variables (hObject,eventdata and
% handles) are saved (assigned) to the 'base' workspace. please note that
% this option will not work with the compiled version of the program

save_to_base(1)                                                             %save all variables to base workspace

handles.statusbar = statusbar(handles.MainWindow,...
        'All variables were saved into base workspace');


% --- Executes on button press in PushClearALL.
function PushClearALL_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% when this button is pressed, all the user defined variables are cleared
% both from the metricdata and prgmcontrol structures

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
function PushClosePlots_Callback(~, ~, handles) %#ok<DEFNU>
% function for closing all the figure windows except of the main program
% (its handle is currently made invisible)

set(handles.MainWindow,'HandleVisibility','off');                              %dont want to close the main program
close all                                                                   %close every other figure
set(handles.MainWindow,'HandleVisibility','on');

%% Pushbuttons - Outputs overview

% --- Executes on button press in PushShowProfiles.
function PushShowProfiles_Callback(~, ~, handles) %#ok<DEFNU>
% pressing this button opens uitable with rivulet profiles data for each
% selected item in the ListProfiles listbox. Please note that opening more
% profiles at the time can cause apparition of inconveniently high number
% of figure windows

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
function PushShowOtherData_Callback(~, ~, handles) %#ok<DEFNU>
% pushbutton for showing the mSpeed, RivHeight, RivWidth and IFACorr
% variables. if the checkbox CheckShowDataPlots is checked, in the created
% window are present also axes linked to the shown uitable. otherwise, only
% the uitable is opened.
%
% handling of the uitable is solved by outside function
% showOtherDataUITable

plateSize = handles.metricdata.RivProcPars{1};                              %extract plateSize for current experiment

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
                    showOtherDataUITable(tmpVar{j},NameStr,1,plots,plateSize);%show uitable with description option, without plots
                end
                k = k+1;                                                    %increase counter
            end
        else
            NameStr = fieldsCell{i};                                        %if fields is class double, there are no subfields
            if isempty(showOther(showOther == k)) == 0                      %data are chosen to be shown
                plots = get(handles.CheckShowDataPlots,'Value');            %does user want plots?
                showOtherDataUITable(tmpVar,NameStr,0,plots,plateSize);     %show uitable with correlation options
            end
            k = k+1;                                                        %increase counter
        end
    end
end


%% Listboxes - Outputs overview

% --- Executes on selection change in ListProfiles.
function ListProfiles_Callback(hObject, ~, handles) %#ok<DEFNU>
% listbox for showing availible data for Quick outputs overview. In this
% list are present the data only for profiles from the last data
% evaluation. for more detailed of data or for comparing different
% measurements, user must open the postprocessing tool from the menus

handles.prgmcontrol.showProf = get(hObject,'Value');                        %save indexes of selected

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes during object creation, after setting all properties.
function ListProfiles_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting properties of ListProfiles listbox

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in ListOtherData.
function ListOtherData_Callback(hObject, ~, handles) %#ok<DEFNU>
% listbox for showing availible data for Quick outputs overview. In this
% list are present the data only for mSpeed, RivHeight, RivWidth and
% IFACorr from the last data evaluation. for more detailed of data or for
% comparing different measurements, user must open the postprocessing tool
% from the menus

handles.prgmcontrol.showOther = get(hObject,'Value');                       %save indexes of selected

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function ListOtherData_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting properties of ListOtherData listbox

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Outputs overview

% --- Executes on button press in CheckShowDataPlots.
function CheckShowDataPlots_Callback(~, ~, ~) %#ok<DEFNU>
% checkbox for controlling the output of PushShowOtherData. if it is
% checked, there is plot show, else there is showed only uitable. this
% callback does nothing at the time


%% Initialization function
function [metricdata prgmcontrol] = ...
    initializeGUI(~,~,handles,dataPart)
%
% function for gui inicialization, to be executed just before progGui is
% made visible
%
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
handles.prgmcontrol.nExp   = 1;                                             %set experiments counter
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
function FileMenu_Callback(~, ~, ~) %#ok<DEFNU>
% file menu header, actually doesn't have any fucntion
%
% Shortcut: --

% --------------------------------------------------------------------
function SaveBase_Callback(~, ~, handles) %#ok<DEFNU>
% function for saving all the variables into main workspace, wont work into
% compiled version
%
% Shortcut: --

save_to_base(1);                                                            %save all variables into base workspace
set(handles.statusbar,'Text','All variables were saved into base workspace');

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SaveFile_Callback(~, ~, handles) %#ok<DEFNU>
% function that save all the program execution variables into .mat file
%
% Shortcut: Ctrl+S

metricdata = handles.metricdata; %#ok<NASGU>                                %these variables are used "indirectly"
prgmcontrol= handles.prgmcontrol; %#ok<NASGU>

strCell = {'metricdata' 'prgmcontrol'};

uisave(strCell,'RivProc_UsrDefVar');

set(handles.statusbar,'Text',...
    'User defined variables were saved into file.');


% --------------------------------------------------------------------
function LoadFile_Callback(~, ~, handles) %#ok<DEFNU>
% menu entry that loads variables saved by SaveFile_Callback function and
% merges them with the existing data. If there are the fields with the same
% names in both old and new data, old value is rewritten
%
% Shortcut: Ctrl+O

% Remarque: at the time, this doesn't fill the fields accordingly to loaded
% parameters. This should be implemented

uiopen('load');                                                             %open dialog for loading variable
if exist('metricdata','var') == 0 || exist('prgmcontrol','var') == 0
    msgbox(['You can use this option only to load variables saved by'...
        '"save variables into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading variables from file failed.');
else
    
    % obtain data
    newData{1} = metricdata;                                                %save loaded as cell of structures
    newData{2} = prgmcontrol;
    % merge structures
    oldData = {handles.metricdata handles.prgmcontrol};                     %create cell of old data
    
    parfor i = 1:numel(newData)
        fNamesNew = fieldnames(newData{i});                                 %get list of field names for new data structure
        for j = 1:numel(fNamesNew)                                          %for all the fields in newData{i} structure
            oldData{i}.(fNamesNew{j}) = newData{i}.(fNamesNew{j});          %replace same field in oldData or make field with corr. name
        end
    end
    
    % extract resulting variables
    handles.metricdata = oldData{1};
    handles.prgmcontrol= oldData{2};
    handles.statusbar = statusbar(handles.MainWindow,...
        'Variables were loaded into workspace.');
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function QuitPrgm_Callback(~, ~, handles) %#ok<DEFNU>
% simple quitting command, call close request function
%
% Shortcut: Ctrl+Q
close(handles.MainWindow);                                                  %call closing function


%% Elements edges finding menu
% --------------------------------------------------------------------
function findEdgesMenu_Callback(~, ~, ~) %#ok<DEFNU>
% Element edges finding menu header, doesn't have any function
%
% Shortcut: --


% --------------------------------------------------------------------
function SaveEdgCoord_Callback(~, ~, handles) %#ok<DEFNU>
% function for saving actual EdgCoord variable into the .mat file for later
% use.
%
% Shortcut: --

if isfield(handles.metricdata,'EdgCoord') == 1
    EdgCoord = handles.metricdata.EdgCoord; %#ok<NASGU>
    uisave('EdgCoord','EdgCoord')
else
    msgbox('You must specify EdgCoord at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Edges of plate and cuvettes were saved into .mat file');


% --------------------------------------------------------------------
function LoadEdgCoord_Callback(~, ~, handles) %#ok<DEFNU>
% function for loading EdgCoord matrix from the .mat file. The file has to
% be saved by SaveEdgCoord_Callback
%
% Shortcut: --

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
function ModIMPars_Callback(~, ~, handles) %#ok<DEFNU>
% function that call changeIMPars.m with no inputs => user is allowed to
% modify parameters and at the begining, the default parameters are shown
%
% Shortcut: Ctrl+I

IMProcPars = changeIMPars;                                                  %call gui for changing parameters

% check ouptuts
if isempty(IMProcPars) == 0
    handles.metricdata.IMProcPars = IMProcPars;                             %if parameters are changed, save them into structure
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function ShowIMPars_Callback(~, ~, handles) %#ok<DEFNU>
% function that call changeIMPars.m with 'onlyshow' option => user is no
% allowed to modify the parameters and current parameters are shown

changeIMPars('onlyshow',handles.metricdata.IMProcPars);                     %call gui for changing parameters with loaded current


% --------------------------------------------------------------------
function SaveIMPars_Callback(~, ~, handles) %#ok<DEFNU>
% function for saving IMProcPars into .mat file for later use
%
% Shortcut: --

if isempty(handles.metricdata.IMProcPars) == 0
    IMProcPars = handles.metricdata.IMProcPars; %#ok<NASGU>                 %this variable is used "indirectly"
    uisave('IMProcPars','IMProcPars')
else
    msgbox('You must specify IMProcPars at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Image processing parameters were saved into .mat file');


% --------------------------------------------------------------------
function LoadIMPars_Callback(~, ~, handles) %#ok<DEFNU>
% function for loading IMProcPars saved by SaveIMPars_Callback. This
% rewrites current IMProcPars variable with loaded values
%
% Shortcut: --

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
function BestMethod_Callback(~, ~, handles) %#ok<DEFNU>
% from this menu entry is called function bestMethod.m for specifying the
% best image processing parameters (IMProcPars).
% the original IMProcPars are rewritten new values => user is asked if he
% wants to save the actual parameters before running bestMethod function
%
% Shortcut: Ctrl+B

% check if there all required data are present
if isfield(handles.metricdata,'imNames') == 0                               %are there loaded images?                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    return
end
choice = questdlg({'Actual IMProcPars will be rewritten.'...                %ask user if he wants to save actual parameters
    'Do you want to save before proceeding?'},...
    'Save original', ...
    'Yes','No','No');
% Handle response
switch choice
    case 'Yes'
        IMProcPars = handles.metricdata.IMProcPars; %#ok<NASGU>             %this variable is used "indirectly"
        uisave('IMProcPars','IMProcPars')
    case 'No'                                                               %do nothing
end

handles.metricdata.IMProcPars = ...                                         %call method for finding best image processing method
    bestMethod(handles);

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SpecAppPlatePos_Callback(~, ~, handles) %#ok<DEFNU>
% function that allows user to specify approximate plate position on photos
% outside of the findEdges function. This is usefull when the user wants to
% run findEdges more times at the row because specyfying the approximate
% plate position each time can be annoying
%
% Shortcut: --

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
function rivProcMenu_Callback(~, ~, ~) %#ok<DEFNU>
% Data processing menu header, this doesn't do anything
%
% Shortcut: --


% --------------------------------------------------------------------
function ModExpPars_Callback(~, ~, handles) %#ok<DEFNU>
% function for calling changeRPPars.m without any specification => at the
% begining, the default values are loaded and user is allowed to change
% them
%
% Shortcut: Ctrl+M

RivProcPars = changeRPPars;                                                 %call gui for changing parameters

%check output
if isempty(RivProcPars) == 0                                                %if parameters were modified, save them into structures
    handles.metricdata.RivProcPars = RivProcPars;
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --------------------------------------------------------------------
function ShowExpPars_Callback(~, ~, handles) %#ok<DEFNU>
% function that calls changeRPPars.m with specification 'onlyshow' =>
% current values of RivProcPars are loaded at the GUI initialization and
% user is not allowed to modify them
%
% Shortcut: Ctrl+E

changeRPPars('onlyshow',handles.metricdata.RivProcPars);                    %call gui for changing parameters with loaded current

% --------------------------------------------------------------------
function SaveRPPars_Callback( ~, ~, handles) %#ok<DEFNU>
% function for saving current RivProcPars into .mat file for later use
%
% Shortcut: ..

if isempty(handles.metricdata.RivProcPars) == 0
    RivProcPars = handles.metricdata.RivProcPars; %#ok<NASGU>               %this variable is used "indirectly"
    uisave('RivProcPars','RivProcPars')
else
    msgbox('You must specify RivProcPars at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Rivulet processing parameters were saved into .mat file');


% --------------------------------------------------------------------
function LoadRPPars_Callback(~, ~, handles) %#ok<DEFNU>
% function for loading RivProcPars from .mat file, saved by
% SaveRPPars_Callback. Current RivProcPars are rewritten with new values
%
% Shortcut: --

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

%% postprocmenu menu

% --------------------------------------------------------------------
function PostProcMenu_Callback(~, ~, ~) %#ok<DEFNU>
% Postprocessing menu header, doesn't do anything
%
% Shortcut: --


% --------------------------------------------------------------------
function ShowGenPlots_Callback(~, ~, handles) %#ok<DEFNU>
% function that allows user to open images created during the program
% executin (after pressing the "Calculate" button).
%
% if the .fig files are loaded, they are opened using openfig. for the
% other formats, imshow is used instead
%
% Shortcut: --

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

% --------------------------------------------------------------------
function ShowAvProcData_Callback(~, ~, handles) %#ok<DEFNU>
% this function calls showProcData.m with current data availible for
% postprocessing. from the raised GUI is possible to start postprocessing
% tool or load other data from .mat files
%
% Shortcut: Ctrl+A

showProcData('handles',handles);


% --------------------------------------------------------------------
function SaveProcessedData_Callback(~, ~, handles) %#ok<DEFNU>
% this function allows user to save outputs from the rivuletProcessing.m
% into .mat file for later use in postprocessing tool
%
% Shortcut: --

if isfield(handles.metricdata,'Availible') == 1
    Availible = handles.metricdata.Availible; %#ok<NASGU>                   %this variable is used "indirectly"
    uisave('Availible','Processed_data');
    set(handles.statusbar,'Text',...
        'Processed data were saved into .mat file');
else
    msgbox('There are no availible processed data yet','modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
    'No data were saved into .mat file');
end


% --------------------------------------------------------------------
function LoadProcessedData_Callback(~, ~, handles) %#ok<DEFNU>
% function for loading output data saved by SaveProcessedData_Callback
% the loaded data are merged into existing handles.metricdata.Availible
% cell. If there are two sets of data with the same ID, current values are
% replaced by loaded ones

uiopen('load');                                                             %open dialog for loading variable
if exist('Availible','var') == 0
    msgbox(['You can use this option only to load Processed data saved by'...
        '"Save all processed data into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading Availible from file failed.');
else
    if isfield(handles.metricdata,'Availible') == 0                         %if this field doesnt exist, create empty matrix
        handles.metricdata.Availible = [];
    end
    Availible = [handles.metricdata.Availible Availible];                   %#ok<NODEF> %append new data to the structure
    strCellAV = cell(1,numel(Availible));
    k         = 1;                                                          %auxiliary indexing variable
    for i = 1:numel(Availible)
        if sum(strcmp(strCellAV,Availible{i}.ID))==0                        %if the same ID isn't present
            strCellAV{k} = Availible{i}.ID;                                 %create string with availible data names from handles
            Availible{k} = Availible{i};                                    %resave availible onto k-th position
            k            = k+1;
        end
    end
    strCellAV = strCellAV(cellfun(@isempty,strCellAV)==0);                  %strip off empty fields
    Availible = Availible(cellfun(@isempty,Availible)==0);
    set(handles.ListData,'String',strCellAV,'Max',numel(strCellAV));        %update listbox
    handles.metricdata.Availible = Availible;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' Availible is prepared for postprocessing.']);
end
if exist('Availible','var') == 0
    msgbox(['You can use this option only to load Processed data saved by'...
        '"Save all processed data into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading Availible from file failed.');
else
    handles.metricdata.Availible = Availible;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' Availible is prepared for postprocessing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function OpenPostProcTool_Callback(~, ~, handles) %#ok<DEFNU>
% function that calls postProcPlotting.m (postprocessing tool) with output
% data currently present into the handles.metricdata.Availible cell
%
% Shortcut: Ctrl+P

if isfield(handles.metricdata,'Availible') == 1
    postProcPlotting(handles.metricdata.Availible);
else
    msgbox('There are no availible processed data yet','modal');uiwait(gcf);
end
