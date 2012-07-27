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

% Last Modified by GUIDE v2.5 27-Jul-2012 10:13:22

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
    initializeGUI(hObject, eventdata, handles);

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

% UIWAIT makes progGUI wait for user response (see UIRESUME)
% uiwait(handles.MainWindow);


% --- Outputs from this function are returned to the command line.
function varargout = progGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

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
mkdir(storDir,'Subtracted');                                                %directory for subtracted images
mkdir(storDir,'Subtracted/Smoothed');                                       %smoothed images -> appears not to be *.tiff ?!
mkdir(storDir,'Height');                                                    %height of the rivulet
mkdir(storDir,'Profile');                                                   %vertical profiles of the rivulet
mkdir(storDir,'Speed');                                                     %mean velocity
mkdir(storDir,'Width');                                                     %width of the rivulet
mkdir(storDir,'Correlation');                                               %directory for saving data necessary for correlations
mkdir(storDir,'Plots');                                                     %directory for saving plots

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
statusStr = 'Choosing of data storage directory cancelled.'; 
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
bgImage        = imread([bgDir bgName]);

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
statusStr = 'Choosing of Background image cancelled.'; 
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

% auxiliary variebles for dialogs
FilterSpec  = '*.tif';
DlgTitle1   = 'Select background image';
DlgTitle2   = 'Select images to be processed';
start_path  = '~/Documents/Freiberg/Experiments/';
selectmode  = 'on';

% load background image
if isfield(handles.metricdata,'bgImage') == 0                               %check if bgImage is already loaded, if not, choose it
    msgbox('Choose background image','modal');uiwait(gcf);
    [bgName bgDir] = uigetfile(FilterSpec,DlgTitle1,start_path);
    bgImage        = imread([bgDir '/' bgName]);
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
for i = 1:numel(imNames)
    tmpIM = imread([imDir imNames{i}]);                                     %load images from selected directory
    tmpIM = imsubtract(tmpIM,bgImage);                                      %subtract background from image
    imwrite(tmpIM,[subsImDir imNames{i}]);                                  %save new images into subfolder
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
statusStr = 'Loading images cancelled.'; 
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

handles.metricdata.storDir = str2double(get(hObject,'String'));             %get value from editable textfield
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
EdgCoord = modifyFunction(handles.metricdata);                              %call modifyFunction with handles.metricdata input
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

% set default values for fields in Image Processing
handles.prgmcontrol.autoEdges = 2;                                          %default - completely automatic program execution
set(handles.PopupIMProc,'String',...
    {'Automatic' 'Semi-automatic' 'Manual'});
minVal = get(handles.CheckCuvettes,'Min');                                  %default - no graphic output
set(handles.CheckCuvettes,'Value',minVal);
minVal = get(handles.CheckPlate,'Min'); 
set(handles.CheckPlate,'Value',minVal);
handles.metricdata.GREdges    = [0 0];                                      %default - dont want any graphics
% default values for hough transform
handles.metricdata.hpTr     = [];                                           %do not need to set up default values - they are present in the prgm
handles.metricdata.numPeaks = [];
handles.metricdata.fG       = [];
handles.metricdata.mL       = [];

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

%% Checkbuttons - Image Processing

% --- Executes on button press in CheckCuvRegrGR.
function CheckCuvettes_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCuvRegrGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.metricdata.GREdges(1) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in CheckPlate.
function CheckPlate_Callback(hObject, eventdata, handles)
% hObject    handle to CheckPlate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckPlate

handles.metricdata.GREdges(2) = get(hObject,'Value');                       %see if checkbox is checked

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
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

% save selected value to handles
switch selected
    case 'Automatic'
        handles.prgmcontrol.autoEdges = 2;                                  % 2 ... completely automatic finding
    case 'Semi-automatic'
        handles.prgmcontrol.autoEdges = 1;                                  % 1 ... ask in case of problem
    case 'Manual'
        handles.prgmcontrol.autoEdges = 0;                                  % 0 ... ask every time
end

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

function EditpltSX_Callback(hObject, eventdata, handles)
% hObject    handle to EditpltSX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditpltSX as text
%        str2double(get(hObject,'String')) returns contents of EditpltSX as a double

handles.metricdata.plateSize(1) = str2double(get(hObject,'String'));        %save width of the plate

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes during object creation, after setting all properties.
function EditpltSX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditpltSX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditpltSY_Callback(hObject, eventdata, handles)
% hObject    handle to EditpltSY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditpltSY as text
%        str2double(get(hObject,'String')) returns contents of EditpltSY as a double

handles.metricdata.plateSize(2) = str2double(get(hObject,'String'));        %save length of the plate

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditpltSY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditpltSY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditnCuts_Callback(hObject, eventdata, handles)
% hObject    handle to EditnCuts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditnCuts as text
%        str2double(get(hObject,'String')) returns contents of EditnCuts as a double

handles.metricdata.nCuts = str2double(get(hObject,'String'));               %save number of horizontal cuts

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditnCuts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditnCuts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditScuvHW_Callback(hObject, eventdata, handles)
% hObject    handle to EditScuvHW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditScuvHW as text
%        str2double(get(hObject,'String')) returns contents of EditScuvHW as a double

handles.metricdata.filmTh(1) = str2double(get(hObject,'String'));           %highest film thickness in small cuvette

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditScuvHW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditScuvHW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditScuvLW_Callback(hObject, eventdata, handles)
% hObject    handle to EditScuvLW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditScuvLW as text
%        str2double(get(hObject,'String')) returns contents of EditScuvLW as a double

handles.metricdata.filmTh(2) = str2double(get(hObject,'String'));           %lowest film thickness in small cuvette

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditScuvLW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditScuvLW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditBcuvHW_Callback(hObject, eventdata, handles)
% hObject    handle to EditBcuvHW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditBcuvHW as text
%        str2double(get(hObject,'String')) returns contents of EditBcuvHW as a double

handles.metricdata.filmTh(3) = str2double(get(hObject,'String'));           %highest film thickness in big cuvette

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditBcuvHW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditBcuvHW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditBcuvLW_Callback(hObject, eventdata, handles)
% hObject    handle to EditBcuvLW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditBcuvLW as text
%        str2double(get(hObject,'String')) returns contents of EditBcuvLW as a double

handles.metricdata.filmTh(4) = str2double(get(hObject,'String'));           %lowest film thickness in big cuvette

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditBcuvLW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditBcuvLW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditCuvWidth_Callback(hObject, eventdata, handles)
% hObject    handle to EditCuvWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditCuvWidth as text
%        str2double(get(hObject,'String')) returns contents of EditCuvWidth as a double

handles.metricdata.filmTh(5) = str2double(get(hObject,'String'));           %width of cuvettes, in pixels

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditCuvWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditCuvWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function EditPolDeg_Callback(hObject, eventdata, handles)
% hObject    handle to EditPolDeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditPolDeg as text
%        str2double(get(hObject,'String')) returns contents of EditPolDeg as a double

handles.metricdata.PolDeg = str2double(get(hObject,'String'));              %degree of polynomial for cuvette regression

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditPolDeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditPolDeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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

% save selected value to handles
handles.metricdata.fluidData = fluidDataFcn(selected);                      %call database function

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
    case 'RadioSavePlots'
        handles.prgmcontrol.GR.regime = 1;                                  %only save plots
    case 'RadioShowSavePlots'
        handles.prgmcontrol.GR.regime = 2;                                  %show and save plots
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
else                                                                        %if there is EdgeCoord present, all the other variables should
    EdgCoord = handles.metricdata.EdgCoord;                                 %be there as well
    daten    = handles.metricdata.daten;
    % extract variables from handles
    % metricdata
    FilterSensitivity = handles.metricdata.FSensitivity;
    Treshold          = handles.metricdata.Treshold;
    files             = handles.metricdata.imNames;
    plateSize         = handles.metricdata.plateSize;
    nCuts             = handles.metricdata.nCuts;
    filmTh            = handles.metricdata.filmTh;
    RegrPlate         = handles.metricdata.PolDeg;
    storDir           = handles.metricdata.storDir;
    rootDir           = handles.metricdata.rootDir;
    fluidData         = handles.metricdata.fluidData;
    % prgmcontrol
    GR                = handles.prgmcontrol.GR;
    rivuletProcessing(daten,Treshold,FilterSensitivity,EdgCoord,...         %call function for rivulet processing with collected parameters
        GR,files,fluidData,storDir,rootDir,plateSize,nCuts,filmTh,RegrPlate);
    
    msgbox('Program succesfully ended','modal');uiwait(gcf);
end



% --- Executes on button press in PushSetDefRiv.
function PushSetDefRiv_Callback(hObject, eventdata, handles)
% hObject    handle to PushSetDefRiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set defaults values for fields in rivutel processing
% program controls
handles.prgmcontrol.GR.regr     = 0;                                        %no graphics at all
handles.prgmcontrol.GR.contour  = 0;
handles.prgmcontrol.GR.profcompl= 0;
handles.prgmcontrol.GR.profcut  = 0;
handles.prgmcontrol.GR.regime   = 1;                                        %want only to save images
minVal = get(handles.CheckCuvRegrGR,'Min');                                 %uncheck checkboxes
set(handles.CheckCuvRegrGR,'Value',minVal);
minVal = get(handles.CheckRivTopGR,'Min');                                  %uncheck checkboxes
set(handles.CheckRivTopGR,'Value',minVal);
minVal = get(handles.CheckCompProfGR,'Min');                                %uncheck checkboxes
set(handles.CheckCompProfGR,'Value',minVal);
minVal = get(handles.CheckMeanCutsGR,'Min');                                %uncheck checkboxes
set(handles.CheckMeanCutsGR,'Value',minVal);
% set default values for mandaroty variables
handles.metricdata.Treshold     = 0.1;                                      %set value
set(handles.EditTreshold, 'String', handles.metricdata.Treshold);           %fill in the field
handles.metricdata.FSensitivity = 10;
set(handles.EditFSensitivity, 'String', handles.metricdata.FSensitivity);
% set empty spaces in places of varargin variables
handles.metricdata.plateSize    = [];
set(handles.EditpltSX, 'String', handles.metricdata.plateSize);
set(handles.EditpltSY, 'String', handles.metricdata.plateSize);
handles.metricdata.nCuts        = [];
set(handles.EditnCuts, 'String', handles.metricdata.nCuts);
handles.metricdata.filmTh        = [];
set(handles.EditScuvHW, 'String', handles.metricdata.filmTh);
set(handles.EditScuvLW, 'String', handles.metricdata.filmTh);
set(handles.EditBcuvHW, 'String', handles.metricdata.filmTh);
set(handles.EditBcuvLW, 'String', handles.metricdata.filmTh);
set(handles.EditCuvWidth, 'String', handles.metricdata.filmTh);
handles.metricdata.PolDeg       = [];
set(handles.EditPolDeg, 'String', handles.metricdata.PolDeg);
% popup menu
handles.metricdata.fluidData = fluidDataFcn('???');                         %set vaules into handles
set(handles.PopupLiqType,'Value',1);                                        %select 2 choice



% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushSaveToBase.
function PushSaveToBase_Callback(hObject, eventdata, handles)
% hObject    handle to PushSaveToBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_to_base(1)                                                             %save all variables to base workspace


% --- Executes on button press in PushClearALL.
function PushClearALL_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearALL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = rmfield(handles,'metricdata');                                    %remove all user-defined data
handles = rmfield(handles,'prgmcontrol');

[handles.metricdata handles.prgmcontrol] =...                               %reinitialize GUI
    initializeGUI(hObject, eventdata, handles);

msgbox({'All user defined variables were cleared.'...
    'Start by loading images again'},'modal');uiwait(gcf);

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

%% Auxiliary functions
function [metricdata prgmcontrol] = ...
    initializeGUI(hObject,eventdata,handles)
%
% function for gui inicialization, to be executed just before progGui is
% made visible

% set default values for Preprocessing
set(handles.EditStorDir,'String',['No outputs storage directory is'...      %field the edit boxes
    ' selected.']);
set(handles.EditBcgLoc,'String','No background is loaded.');
set(handles.EditIMLoc,'String','No images are loaded.');
minVal = get(handles.CheckDNL,'Min');                                       %uncheck checkbox
set(handles.CheckDNL,'Value',minVal);
handles.prgmcontrol.DNTLoadIM = minVal;                                        %by default, i dont want to store all iamge data in handles

% set default values for fields in Image Processing
handles.prgmcontrol.autoEdges = 2;                                          %default - completely automatic program execution
minVal = get(handles.CheckCuvettes,'Min');                                  %default - no graphic output
set(handles.CheckCuvettes,'Value',minVal);
minVal = get(handles.CheckPlate,'Min'); 
set(handles.CheckPlate,'Value',minVal);
handles.metricdata.GREdges    = [0 0];                                      %default - dont want any graphics
% default values for image processing
handles.metricdata.IMProcPars = [];                                         %empty field -> use default built-in parameters

% set defaults values for fields in rivutel processing
% program controls
handles.prgmcontrol.GR.regr     = 0;                                        %no graphics at all
handles.prgmcontrol.GR.contour  = 0;
handles.prgmcontrol.GR.profcompl= 0;
handles.prgmcontrol.GR.profcut  = 0;
handles.prgmcontrol.GR.regime   = 1;
minVal = get(handles.CheckCuvRegrGR,'Min');                                 %uncheck checkboxes
set(handles.CheckCuvRegrGR,'Value',minVal);
minVal = get(handles.CheckRivTopGR,'Min');                                  %uncheck checkboxes
set(handles.CheckRivTopGR,'Value',minVal);
minVal = get(handles.CheckCompProfGR,'Min');                                %uncheck checkboxes
set(handles.CheckCompProfGR,'Value',minVal);
minVal = get(handles.CheckMeanCutsGR,'Min');                                %uncheck checkboxes
set(handles.CheckMeanCutsGR,'Value',minVal);
% metricdata
% set default values for mandaroty variables
handles.metricdata.Treshold     = 0.1;                                      %set value
set(handles.EditTreshold, 'String', handles.metricdata.Treshold);           %fill in the field
handles.metricdata.FSensitivity = 10;
set(handles.EditFSensitivity, 'String', handles.metricdata.FSensitivity);
% set empty spaces in places of varargin variables
handles.metricdata.plateSize    = [];
set(handles.EditpltSX, 'String', handles.metricdata.plateSize);
set(handles.EditpltSY, 'String', handles.metricdata.plateSize);
handles.metricdata.nCuts        = [];
set(handles.EditnCuts, 'String', handles.metricdata.nCuts);
handles.metricdata.filmTh       = [];
set(handles.EditScuvHW, 'String', handles.metricdata.filmTh);
set(handles.EditScuvLW, 'String', handles.metricdata.filmTh);
set(handles.EditBcuvHW, 'String', handles.metricdata.filmTh);
set(handles.EditBcuvLW, 'String', handles.metricdata.filmTh);
set(handles.EditCuvWidth, 'String', handles.metricdata.filmTh);
handles.metricdata.PolDeg       = [];
set(handles.EditPolDeg, 'String', handles.metricdata.PolDeg);
% set data for the liquid
handles.metricdata.fluidData = fluidDataFcn('DC 10');                       %set vaules into handles
set(handles.PopupLiqType,'Value',1);                                        %select 2 choice

% Specify root folder for program execution (must contain all the used
% functions)
handles.metricdata.rootDir = pwd;

metricdata = handles.metricdata;
prgmcontrol= handles.prgmcontrol;
% Update handles structure
guidata(handles.MainWindow, handles);

function [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
%   [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
% function for controling the output of findEdges function. The algorithm
% walks through the EdgCoord matrix and saves positions of the wrongly
% guessed coordinates into problemIndexes matrix. If the control is passed
% without any problems, the state variable is set to 0.
%
% Algorithm:
% - at first, the NaN values are removed.
% - than the mean value and kurtosis of each column are calculated
% - from kurtosis is defined coefficient for search for outliers in each
%   column
% - outliers are found
%
% INPUT variables
% EdgCoord  ... matrix of guessed edge coordinates, output of function
%               findEdges
%
% OUTPUT variables
% state     ... how well are defined the edges
%               [nSC oSC nBC oBC nPl oPl], where
%               nSc     ... number of NaN in small cuvettes
%               oSc     ... number of outerliers in small cuvettes
%               and so on...
%           ... the length of state variable can vary in dependence of
%               found problem from 1(scalar) up to 4 [1 2 3 4];
% prbMsg    ... structure containing indexes of rows (images)
%               where was found something odd
% sumMsg    ... summary message for the found problems

nCol = size(EdgCoord,2);                                                    %number of columns in the input matrix (10)
k    = 1;                                                                   %auxiliary indexing variable for prbMsg
% problem counters
nSC  = 0; oSC = 0;                                                          %n* counts NaN and o* outliers
nBC  = 0; oBC = 0;
nPl  = 0; oPl = 0;
for i = 1:nCol                                                              %better to do for each column separately(remove only parts of NaN row)
    tmpVar = EdgCoord(:,i);                                                 %reduce input matrix only to i-th column
    % find NaN values in the EdgCoord matrix
    INaN = find(isnan(EdgCoord) == 1);
    tmpVar(any(isnan(tmpVar)'),:) = [];                                     %remove rows with NaN in them
    % calculate standard deviation of each column of EdgCoord
    coordSTD= std(tmpVar);
    coordMU = mean(tmpVar);                                                 %mean value in each column
    coordKUR= kurtosis(tmpVar);                                             %curtosis of each column (should be 3 for normally distr. data)
    nRow    = numel(tmpVar);                                                %number of elements in tmpVar after removing the NaNs
    
    % calculating the coeficient for identifying outliers, for std. data
    % distr, it should be 3 and I will decrease it for more outlier-prone
    % datasets
    coef    = 7/coordKUR;                                                   %should be 9/.. but I am expecting very narrow data

    % find outliers - values more different than coef * std. deviation
    outliers= abs(tmpVar-coordMU(ones(nRow,1),:))>...
        coef*coordSTD(ones(nRow,1),:);                                      %matrix of indexes of values more different than coef * std. dev.
    Iout    = find(outliers == 1);                                          %find position of outliers
    % translate the Iout for each found NaN
    if isempty(INaN) == 0
        for j = INaN
            Iout(Iout>=INaN(j)) = Iout(Iout>=INaN(j))+1;                    %must add 1 for every left out row
        end
    end
    % write out messages for the column
    Iwr = [Iout INaN];
    for j = 1:length(Iwr)                                                   %for all problems
        prbMsg(k).coords = [Iwr(j) i];                                      %coordinates of the problem in the EdgCoord matrix
        prbMsg(k).nImg   = Iwr(j);                                          %number of problematic image
        if isempty(find(Iwr(j) == Iout, 1)) == 1
            prbMsg(k).type   = 'NaN';
        else
            prbMsg(k).type   = 'outliers';
        end
        if i < 4
            prbMsg(k).device = 'small cuvette';                             %write the device type to the structure
            if isempty(find(Iwr(j) == Iout, 1)) == 1                        %set counter for the device
                nSC = nSC + 1;
            else
                oSC = oSC + 1;
            end
        elseif i >= 4 && i < 7
            prbMsg(k).device = 'big cuvette';
            if isempty(find(Iwr(j) == Iout, 1)) == 1
                oBC = nBC + 1;
            else
                oBC = oBC + 1;
            end
        else
            prbMsg(k).device = 'plate';
            if isempty(find(Iwr(j) == Iout, 1)) == 1
                nPl = nPl + 1;
            else
                oPl = oPl + 1;
            end
        end
        k = k+1;
    end
end

% setting up state variable
state = [nSC oSC nBC oBC nPl oPl];

% setting up summary report
sumMsg.totalPrb = nSC + nBC + nPl + oSC + oBC + oPl;                        %total number of "warnings"
sumMsg.oSC      = oSC;
sumMsg.nSc      = nSC;
sumMsg.oBC      = oBC;
sumMsg.nBC      = nBC;
sumMsg.oPl      = oPl;
sumMsg.nPl      = nPl;
if sum(state) ~= 0                                                          %write out human readable string string for user
    sumMsg.string   = {['In EdgCoord matrix from '...
        mat2str(numel(EdgCoord(:,1))) ' images, there were found at total '...
        mat2str(sumMsg.totalPrb) ' problems. Namely there were found:']...
        [mat2str(oSC) ' outer values and ' mat2str(nSC)...
        ' NaN in Small cuvettes edges estimation,']...
        [mat2str(oBC) ' outer values and ' mat2str(nBC)...
        ' NaN in Big cuvettes edges estimation and']...
        [mat2str(oPl) ' outer values and ' mat2str(nPl)...
        ' NaN in plate edges estimation.']};
else
    sumMsg.string = 'There were no problems found.';
end

% check prbMsg variable existence
if exist('prbMsg','var') == 0
    prbMsg = struct([]);
end

function EdgCoord = modifyFunction(metricdata)
%
%   EdgCoord = modifyFunction(metricdata)
%
% Function that takes found coordinates and messages about rate of finding
% succes and returns modified coordinates base on user interaction
%
% For prefered automatic estimation, the outliers and NaN are replaced by
% mean values of found coordinates. Otherwise, the user can choose to find
% the problematic edges manually and then, is asked to specify 3 different
% points on each border from which is estimated the mean coordinate
%
% Rq: The code for manual selection is not very elegant, but it is doing
% what it is suppose to do...
%
% INPUT variables
% metricdata... structure obtained by previous run of the program,
%               must contain following fields:
% EdgCoord  ... matrix with estimated edge coordinates
% state
% prbMsg    ... outputs from controlFunction
% sumMsg
%
%               there also must be present specific combination of
%               following fields:
% daten     ... cell with image data
% imNames   ... if daten is not present this list of processed images
%               names is used for loading images from subsImDir
% subsImDir ... if daten is not present, images specified by imNames are
%               loaded from this directory

% check if it is necessary to run the function
if isempty(metricdata.prbMsg) == 1                                          %no problem, than return
    EdgeCoord = handles.metricdata.EdgCoord;                                %#ok<NASGU> %assign output variable
    return
end

% process input:
EdgCoord = metricdata.EdgCoord;
state    = metricdata.state;
prbMsg   = metricdata.prbMsg;
sumMsg   = metricdata.sumMsg;
if isfield(metricdata,'daten') == 1                                         %there are present image data into metricdata
    IMDataCell = metricdata.daten;
    DNTLoadIM  = 0;
else
    imNames    = metricdata.imNames;
    subsImDir  = metricdata.subsImDir;
    DNTLoadIM  = 1;
end

% extract variables auxiliary variables from structures
% prbMsg.coords -> [row column] of the problem
prbCoord = zeros(numel(prbMsg),2);                                          %preallocate variable for problems coordinates
parfor i = 1:numel(prbMsg)
    prbCoord(i,:) = prbMsg(i).coords;
end

% write out results of edge finding and ask user what to do
if sum(state) ~= 0                                                          %there are some problems
    options.Default = 'From mean values';
    options.Interpreter = 'tex';
    stringCell= [sumMsg.string{:} {'Do you want to modify these edges:'}];
    choice = myQst('autstr',stringCell);
    if strcmp(choice,'Show EdgCoord') == 1                                  %user wants to show the EdgeCoord matrix
        coefVec= 7./kurtosis(EdgCoord);
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
            'Name','EdgCoord');                                             %set window size +- matching the EdgeCoord needs
        openUITable(hFig,EdgCoord,prbCoord,coefVec,0);
        choice = menu('Modify selected values',...
            'From mean values','Manually','Don`t modify');                  %questdlg is prettier, but menu is not modal
        switch choice
            case 1
                choice = 'From mean values';
            case 2
                choice = 'Manually';
            case 3
                choice = 'Don`t modify';
        end
    end
else
    msgbox('Edges of the plate and cuvettes were found','modal');
    uiwait(gcf);
    choice = 'Don`t modify';
end

% switch in dependence on user choice
% manual specification of the cuvettes edges shoud be fun :-/ (let's leave
% it out for now - cuvettes edge finding is quite solid, the mean values
% shoud be enough)
switch choice
    case 'From mean values'
        tmpVec= unique(prbCoord(:,2));
        for j = 1:numel(tmpVec)                                             %for every column with problem
            i = tmpVec(j);
            EdgCoord(prbCoord(prbCoord(:,2) == i),i) =...                   %all values with specified column index
                round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i))));%replace all outliers and NaN with mean values of the rest
        end
    case 'Manually'
        choice  = menu('Do you want to:',...                                %open new menu, and let user choose between graphical and text input
            'Specify new values graphically',...
            'Directly modify values in table');
        if choice == 1                                                      %user wants to specify new values from images
            se      = strel('disk',12);                                     %morphological structuring element
            strVerL = 'Specify {\bf 3} times left vertical edge of the ';   %string preparation
            strVerR = 'Specify {\bf 3} times right vertical edge of the ';
            strHorT = 'Specify {\bf 3} times top horizontal edge of the ';
            strHorB = 'Specify {\bf 3} times bottom horizontal edge of the ';
            options.WindowStyle = 'modal';
            options.Interpreter = 'tex';
            for k = 1:numel(prbCoord(:,2));                                 %for all problems
                i = prbCoord(k,1);j = prbCoord(k,2);                        %save indexes into temporary variables
                if DNTLoadIM == 1                                           %if the images are not loaded, i need to get the image from directory
                    tmpIM = imread([subsImDir imNames{1}]);                 %load image from directory with substracted images
                else
                    tmpIM = IMDataCell{i};                                  %else i can get it from handles
                end
                switch prbMsg(k).device                                     %check the device, extreme SWITCH...
                    case 'plate'
                        tmpIM = tmpIM(:,1:2*round(end/3));                  %for the plate I need only left side of the image
                        trVec = [0 0];
                        if mod(j,7) == 0                                    %left vertical edge
                            str = [strVerL prbMsg(k).device];
                            chInd   = 1;
                        elseif mod(j,7) == 1                                %top horizontal edge
                            str = [strHorT prbMsg(k).device];
                            chInd   = 2;
                        elseif mod(j,7) == 2                                %right vertical edge
                            str = [strVerR prbMsg(k).device];
                            chInd   = 1;
                        else                                                %bottom horizontal edge
                            str = [strHorB prbMsg(k).device];
                            chInd   = 2;
                        end
                        nInput  = 3;
                    otherwise
                        if strcmp(prbMsg(k).device,'small cuvette') == 1        %choose which part of the image I want to show
                            tmpIM = tmpIM(1:round(2*end/3),round(end/2):end);   %for small cuvette I need only top right side of the image
                            trVec = [round(size(tmpIM,2)/2)-1 0];
                        else
                            tmpIM = tmpIM(round(end/3):end,round(end/2):end);   %for big cuvette I need only bottom right side of the imagee
                            trVec = [round(size(tmpIM,2)/2)-1 round(size(tmpIM,1))];
                        end
                        if mod(j,3) == 1                                        %indexes 1 or 4, mean x values of cuvettes
                            str = ['Specify both vertical edges of the '...
                                prbMsg(k).device...
                                ', both of them {\bf 3} times.'];
                            nInput = 6;                                         %need to take 6 inputs from ginput
                            chInd   = 1;                                        %I am interested in first ginput coordinate
                        elseif mod(j,3) == 2                                    %top horizontal edge
                            str = [strHorT prbMsg(k).device];
                            nInput  = 3;                                        %need to take 3 inputs from ginput
                            chInd   = 2;                                        %I am interested second ginput coordinate
                        else                                                    %bottom horiznotal edge
                            str = [strHorB prbMsg(k).device];
                            nInput  = 3;                                        %need to take 3 inputs from ginput
                            chInd   = 2;                                        %I am interested in second ginput coordinate
                        end
                end                
            % write out info about what should be specified
            msgbox(str,options);uiwait(gcf);
            % some image processing
            tmpIM   = imtophat(tmpIM,se);
            tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);        %enhance contrasts
            tmpIM   = im2bw(tmpIM,0.16);                                    %conversion to black and white
            figure;imshow(tmpIM);                                           %show image to work with
            tmpMat  = ginput(nInput);close(gcf);
            EdgCoord(i,j) = round(mean(tmpMat(:,chInd))) + trVec(chInd);
            end
        else                                                                %user wants directly modify values
            if exist('coefVec','var') == 0                                  %if coefVec is not specified (no table was opened yet)
                coefVec= 7./kurtosis(EdgCoord);
                hFig = figure;                                              %open figure window
                set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
                    'Name','EdgCoord');                                     %set window size +- matching the EdgeCoord needs
            end
            EdgCoord = openUITable(hFig,EdgCoord,prbCoord,coefVec,1);
        end
    case 'Don`t modify'
end

% see if hFig is opened and if it is, actualize it
if exist('hFig','var') == 1
    openUITable(hFig,EdgCoord,prbCoord,coefVec,0);
end
hMBox = msgbox('Press Enter to continue','modal');uiwait(hMBox);            %notify user about end of the program
if exist('hFig','var')                                                      %if exists, close uitable
    close(hFig)
end

function modData = openUITable(hFig,EdgCoord,prbCoord,coefVec,allowEdit)
%
%   function openUITable(EdgCoord,prbCoord,coefVec,allowEdit)
%
% function for opening uitable with specified parameters and highlighted
% outlietr and NaNs
%
% INPUT variables
% hFig      ... handles to figure where uitable shoud be opened
% EdgCoord  ... variable to be shown in uitable
% prbCoord  ... coordinates of NaNs and outliers in the EdgCoord
% coefVec   ... vector of coeficients used for identifying outliers
% allowEdit ... 0/1 if I want allow user to edit fields in resulting
%               uitable
%
% OUTPUT variables
%

tmpMat = [EdgCoord;round(mean(EdgCoord));kurtosis(EdgCoord);...             %tmpMat with mean value, kurtosis and used coefficient for finding
    coefVec];                                                               %outliers in each column
tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
for i = 1:numel(prbCoord(:,1))
    tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                        %modify format of the problematic value
        '<html><span style="color: #FF0000; font-weight: bold;">', ...
        tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
        '</span></html>');
end
tmpMat(end-2,:) = strcat(...                                                %modify format of the mean value
    '<html><span style="color: #FF00FF; font-weight: bold;">', ...
    tmpMat(end-2,:), ...
    '</span></html>');
tmpMat(end-1,:) = strcat(...                                                %modify format of the kurtosis
    '<html><span style="color: #0000FF; font-weight: bold;">', ...
    tmpMat(end-1,:), ...
    '</span></html>');
tmpMat(end,:) = strcat(...                                                  %modify format of the used coeficient
    '<html><span style="color: #FFFF00; font-weight: bold;">', ...
    tmpMat(end,:), ...
    '</span></html>');
colNames = {'Small cuv. xMean',...                                          %set column names
    'Small cuv. yTop', 'Small cuv. yBottom',...
    'Big cuv. xMean',...
    'Big cuv. yTop', 'Big cuv. yBottom',...
    'Plate xLeft','Plate yTop',...
    'Plate xRight','Plate yBottom'};
rowNames = 1:numel(EdgCoord(:,1));                                          %set row names
rowNames = reshape(strtrim(cellstr(num2str(rowNames(:)))), size(rowNames));
rowNames = [rowNames {'Mean Value' 'Kurtosis' 'Used coef.'}];
if allowEdit == 1                                                           %want I let user to change columns
    ColumnEditable = zeros(1,numel(EdgCoord(1,:)));
    ColumnEditable(unique(prbCoord(:,2))) = 1;                              %make columns with NaNs and outliers editable
    ColumnEditable = logical(ColumnEditable);
else
    ColumnEditable = [];
end
hTable = uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...               %open uitable
    'RowName',rowNames,...
    'ColumnEditable',ColumnEditable,...
    'ColumnWidth','auto', ...
    'Units','Normal', 'Position',[0 0 1 1]);
if allowEdit == 1
    set(hTable,'CellEditCallback', @hTableEditCallback);                    %set cell edit callback and DeleteFcn
    choice = menu('Save values and stop editing','OK');
    if choice == 1                                                          %if user is done editing values
        modData = get(hTable,'Data');
        modData = regexp(modData,'([1-9])[\d.]\d+','match');                %'unformat' these values
        modData = cellfun(@str2double,modData);                             %convert them to double
        modData = modData(1:end-2,:);                                       %strip off automatically generated values
    end
end

function hTableEditCallback(o,e)
tableData = get(o, 'Data');
if (e.Indices(1) > numel(tableData(:,1))-3)                                 %check if the user is not trying to modify automatically gen. data
    tableData{e.Indices(1), e.Indices(2)} = e.PreviousData;
    set(o, 'data', tableData);
    errordlg('Do not modify automatically generated values','modal')
else
    tmpData = regexp(tableData(:,e.Indices(2)),'([1-9])[\d.]\d+','match');  %unformat column of data with modified value
    tmpData = cellfun(@str2double,tmpData);                                 %convert column into doubles
    tmpData = [round(mean(tmpData(1:end-2)));                               %update automatically modified values
               kurtosis(tmpData(1:end-2))];
    tmpData = reshape(strtrim(cellstr(num2str(tmpData(:)))),size(tmpData)); %convert results into string
    tmpData(1) = strcat(...                                                 %modify format of automatically modified data
        '<html><span style="color: #FF00FF; font-weight: bold;">', ...
        tmpData(1), ...
        '</span></html>');
    tmpData(2) = strcat(...
        '<html><span style="color: #0000FF; font-weight: bold;">', ...
        tmpData(2), ...
        '</span></html>');
    tableData(end-2:end-1,e.Indices(2)) = tmpData;                          %reconstruct data table
    set(o,'data',tableData);                                                %push data back to uitable
end

%% Copied functions, not my own
function statusbarHandles = statusbar(varargin)
%statusbar set/get the status-bar of Matlab desktop or a figure
%
%   statusbar sets the status-bar text of the Matlab desktop or a figure.
%   statusbar accepts arguments in the format accepted by the <a href="matlab:doc sprintf">sprintf</a>
%   function and returns the statusbar handle(s), if available.
%
%   Syntax:
%      statusbarHandle = statusbar(handle, text, sprintf_args...)
%
%   statusbar(text, sprintf_args...) sets the status bar text for the
%   current figure. If no figure is selected, then one will be created.
%   Note that figures with 'HandleVisibility' turned off will be skipped
%   (compare <a href="matlab:doc findobj">findobj</a> & <a href="matlab:doc findall">findall</a>).
%   In these cases, simply pass their figure handle as first argument.
%   text may be a single string argument, or anything accepted by sprintf.
%
%   statusbar(handle, ...) sets the status bar text of the figure
%   handle (or the figure which contains handle). If the status bar was
%   not yet displayed for this figure, it will be created and displayed.
%   If text is not supplied, then any existing status bar is erased,
%   unlike statusbar(handle, '') which just clears the text.
%
%   statusbar(0, ...) sets the Matlab desktop's status bar text. If text is
%   not supplied, then any existing text is erased, like statusbar(0, '').
%
%   statusbar([handles], ...) sets the status bar text of all the
%   requested handles.
%
%   statusbarHandle = statusbar(...) returns the status bar handle
%   for the selected figure. The Matlab desktop does not expose its
%   statusbar object, so statusbar(0, ...) always returns [].
%   If multiple unique figure handles were requested, then
%   statusbarHandle is an array of all non-empty status bar handles.
%
%   Notes:
%      1) The format statusbarHandle = statusbar(handle) does NOT erase
%         any existing statusbar, but just returns the handles.
%      2) The status bar is 20 pixels high across the entire bottom of
%         the figure. It hides everything between pixel heights 0-20,
%         even parts of uicontrols, regardless of who was created first!
%      3) Three internal handles are exposed to the user (Figures only):
%         - CornerGrip: a small square resizing grip on bottom-right corner
%         - TextPanel: main panel area, containing the status text
%         - ProgressBar: a progress bar within TextPanel (default: invisible)
%
%   Examples:
%      statusbar;  % delete status bar from current figure
%      statusbar(0, 'Desktop status: processing...');
%      statusbar([hFig1,hFig2], 'Please wait while processing...');
%      statusbar('Processing %d of %d (%.1f%%)...',idx,total,100*idx/total);
%      statusbar('Running... [%s%s]',repmat('*',1,fix(N*idx/total)),repmat('.',1,N-fix(N*idx/total)));
%      existingText = get(statusbar(myHandle),'Text');
%
%   Examples customizing the status-bar appearance:
%      sb = statusbar('text');
%      set(sb.CornerGrip, 'visible','off');
%      set(sb.TextPanel, 'Foreground',[1,0,0], 'Background','cyan', 'ToolTipText','tool tip...')
%      set(sb, 'Background',java.awt.Color.cyan);
%
%      % sb.ProgressBar is by default invisible, determinite, non-continuous fill, min=0, max=100, initial value=0
%      set(sb.ProgressBar, 'Visible','on', 'Minimum',0, 'Maximum',500, 'Value',234);
%      set(sb.ProgressBar, 'Visible','on', 'Indeterminate','off'); % indeterminate (annimated)
%      set(sb.ProgressBar, 'Visible','on', 'StringPainted','on');  % continuous fill
%      set(sb.ProgressBar, 'Visible','on', 'StringPainted','on', 'string',''); % continuous fill, no percentage text
%
%      % Adding a checkbox
%      jCheckBox = javax.swing.JCheckBox('cb label');
%      sb.add(jCheckBox,'West');  % Beware: East also works but doesn't resize automatically
%
%   Technical description:
%      http://UndocumentedMatlab.com/blog/setting-status-bar-text
%      http://UndocumentedMatlab.com/blog/setting-status-bar-components
%
%   Notes:
%     Statusbar will probably NOT work on Matlab versions earlier than 6.0 (R12)
%     In Matlab 6.0 (R12), figure statusbars are not supported (only desktop statusbar)
%
%   Warning:
%     This code heavily relies on undocumented and unsupported Matlab
%     functionality. It works on Matlab 7+, but use at your own risk!
%
%   Bugs and suggestions:
%     Please send to Yair Altman (altmany at gmail dot com)
%
%   Change log:
%     2007-04-25: First version posted on MathWorks file exchange: <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14773">http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14773</a>
%     2007-04-29: Added internal ProgressBar; clarified main comment
%     2007-05-04: Added partial support for Matlab 6
%     2011-10-14: Fix for R2011b
%
%   See also:
%     ishghandle, sprintf, findjobj (on the <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14317">file exchange</a>)

% License to use and modify this code is granted freely without warranty to all, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.5 $  $Date: 2011/10/14 04:10:04 $

    % Check for available Java/AWT (not sure if Swing is really needed so let's just check AWT)
    if ~usejava('awt')
        error('YMA:statusbar:noJava','statusbar only works on Matlab envs that run on java');
    end

    % Args check
    if nargin < 1 | ischar(varargin{1})  %#ok for Matlab 6 compatibility
        handles = gcf;  % note: this skips over figures with 'HandleVisibility'='off'
    else
        handles = varargin{1};
        varargin(1) = [];
    end

    % Ensure that all supplied handles are valid HG GUI handles (Note: 0 is a valid HG handle)
    if isempty(handles) | ~all(ishandle(handles))  %#ok for Matlab 6 compatibility
        error('YMA:statusbar:invalidHandle','invalid GUI handle passed to statusbar');
    end

    % Retrieve the requested text string (only process once, for all handles)
    if isempty(varargin)
        deleteFlag = (nargout==0);
        updateFlag = 0;
        statusText = '';
    else
        deleteFlag = 0;
        updateFlag = 1;
        statusText = sprintf(varargin{:});
    end

    % Loop over all unique root handles (figures/desktop) of the supplied handles
    rootHandles = [];
    if any(handles)  % non-0, i.e. non-desktop
        try
            rootHandles = ancestor(handles,'figure');
            if iscell(rootHandles),  rootHandles = cell2mat(rootHandles);  end
        catch
            errMsg = 'Matlab version is too old to support figure statusbars';
            % Note: old Matlab version didn't have the ID optional arg in warning/error, so I can't use it here
            if any(handles==0)
                warning([errMsg, '. Updating the desktop statusbar only.']);  %#ok for Matlab 6 compatibility
            else
                error(errMsg);
            end
        end
    end
    rootHandles = unique(rootHandles);
    if any(handles==0), rootHandles(end+1)=0; end
    statusbarObjs = handle([]);
    for rootIdx = 1 : length(rootHandles)
        if rootHandles(rootIdx) == 0
            setDesktopStatus(statusText);
        else
            thisStatusbarObj = setFigureStatus(rootHandles(rootIdx), deleteFlag, updateFlag, statusText);
            if ~isempty(thisStatusbarObj)
                statusbarObjs(end+1) = thisStatusbarObj;
            end
        end
    end

    % If statusbarHandles requested
    if nargout
        % Return the list of all valid (non-empty) statusbarHandles
        statusbarHandles = statusbarObjs;
    end

%end  % statusbar  %#ok for Matlab 6 compatibility

% Set the status bar text of the Matlab desktop
function setDesktopStatus(statusText)
    try
        % First, get the desktop reference
        try
            desktop = com.mathworks.mde.desk.MLDesktop.getInstance;      % Matlab 7+
        catch
            desktop = com.mathworks.ide.desktop.MLDesktop.getMLDesktop;  % Matlab 6
        end

        % Schedule a timer to update the status text
        % Note: can't update immediately, since it will be overridden by Matlab's 'busy' message...
        try
            t = timer('Name','statusbarTimer', 'TimerFcn',{@setText,desktop,statusText}, 'StartDelay',0.05, 'ExecutionMode','singleShot');
            start(t);
        catch
            % Probably an old Matlab version that still doesn't have timer
            desktop.setStatusText(statusText);
        end
    catch
        %if any(ishandle(hFig)),  delete(hFig);  end
        error('YMA:statusbar:desktopError',['error updating desktop status text: ' lasterr]);
    end
%end  %#ok for Matlab 6 compatibility

% Utility function used as setDesktopStatus's internal timer's callback
function setText(varargin)
    if nargin == 4  % just in case...
        targetObj  = varargin{3};
        statusText = varargin{4};
        targetObj.setStatusText(statusText);
    else
        % should never happen...
    end
%end  %#ok for Matlab 6 compatibility

% Set the status bar text for a figure
function statusbarObj = setFigureStatus(hFig, deleteFlag, updateFlag, statusText)
    try
        jFrame = get(handle(hFig),'JavaFrame');
        jFigPanel = get(jFrame,'FigurePanelContainer');
        jRootPane = jFigPanel.getComponent(0).getRootPane;

        % If invalid RootPane, retry up to N times
        tries = 10;
        while isempty(jRootPane) & tries>0  %#ok for Matlab 6 compatibility - might happen if figure is still undergoing rendering...
            drawnow; pause(0.001);
            tries = tries - 1;
            jRootPane = jFigPanel.getComponent(0).getRootPane;
        end
        jRootPane = jRootPane.getTopLevelAncestor;

        % Get the existing statusbarObj
        statusbarObj = jRootPane.getStatusBar;

        % If status-bar deletion was requested
        if deleteFlag
            % Non-empty statusbarObj - delete it
            if ~isempty(statusbarObj)
                jRootPane.setStatusBarVisible(0);
            end
        elseif updateFlag  % status-bar update was requested
            % If no statusbarObj yet, create it
            if isempty(statusbarObj)
               statusbarObj = com.mathworks.mwswing.MJStatusBar;
               jProgressBar = javax.swing.JProgressBar;
               jProgressBar.setVisible(false);
               statusbarObj.add(jProgressBar,'West');  % Beware: East also works but doesn't resize automatically
               jRootPane.setStatusBar(statusbarObj);
            end
            statusbarObj.setText(statusText);
            jRootPane.setStatusBarVisible(1);
        end
        statusbarObj = handle(statusbarObj);

        % Add quick references to the corner grip and status-bar panel area
        if ~isempty(statusbarObj)
            addOrUpdateProp(statusbarObj,'CornerGrip',  statusbarObj.getParent.getComponent(0));
            addOrUpdateProp(statusbarObj,'TextPanel',   statusbarObj.getComponent(0));
            addOrUpdateProp(statusbarObj,'ProgressBar', statusbarObj.getComponent(1).getComponent(0));
        end
    catch
        try
            try
                title = jFrame.fFigureClient.getWindow.getTitle;
            catch
                title = jFrame.fHG1Client.getWindow.getTitle;
            end
        catch
            title = get(hFig,'Name');
        end
        error('YMA:statusbar:figureError',['error updating status text for figure ' title ': ' lasterr]);
    end
%end  %#ok for Matlab 6 compatibility

% Utility function: add a new property to a handle and update its value
function addOrUpdateProp(handle,propName,propValue)
    try
        if ~isprop(handle,propName)
            schema.prop(handle,propName,'mxArray');
        end
        set(handle,propName,propValue);
    catch
        % never mind... - maybe propName is already in use
        %lasterr
    end
%end  %#ok for Matlab 6 compatibility

%% Menus
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
    set(handles.statusbar,'Text',...
        'Loading variables from file failed.');
else
    handles.metricdata = metricdata;
    handles.prgmcontrol= prgmcontrol;
    set(handles.statusbar,'Text',...
        'User defined variables were loaded from file.');
end

% Update handles structure
guidata(handles.MainWindow, handles);


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

EdgCoord = handles.metricdata.EdgCoord;
uisave('EdgCoord','EdgCoord')

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
    handles.prgmcontrol= prgmcontrol;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' EdgCoord is prepared for rivulet processing.']);
end


% --------------------------------------------------------------------
function ModHough_Callback(hObject, eventdata, handles)
% hObject    handle to ModHough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata.IMProcPars = changeIMPars;                               %call gui for changing parameters

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function BestMethod_Callback(hObject, eventdata, handles)
% hObject    handle to BestMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function QuitPrgm_Callback(hObject, eventdata, handles)
% hObject    handle to QuitPrgm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.MainWindow);                                                  %call closing function
