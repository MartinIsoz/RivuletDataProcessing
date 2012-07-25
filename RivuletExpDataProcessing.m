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

% Last Modified by GUIDE v2.5 17-Jul-2012 16:51:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @progGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @progGUI_OutputFcn, ...
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


% --- Executes just before progGUI is made visible.
function progGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to progGUI (see VARARGIN)

% initialize metricdata and prgmcotrol fields
% handles.metricdata = struct([]);
% handles.prgmcontrol= struct([]);
% fill gui with defaults values
[handles.metricdata handles.prgmcontrol] =...
    initializeGUI(hObject, eventdata, handles);

% Choose default command line output for progGUI
handles.output = hObject;

%Rq: creation of the field handles.metricdata at the begining of the
%program execution also simplifies checking for all the needed fields in
%different parts of the program

handles.output = hObject;
set(hObject,'CloseRequestFcn',@my_closereq)


% Update handles structure
guidata(hObject, handles);

% My own closereq fcn -> to avoid closing with close command
function my_closereq(src,evnt)
% User-defined close request function 
% to display a question dialog box 
   selection = questdlg('Close This Figure?',...
      'Close Request Function',...
      'Yes','No','Yes'); 
   switch selection, 
      case 'Yes',
         delete(gcf)
      case 'No'
      return 
   end

% UIWAIT makes progGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


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
mkdir(storDir,'Substracted');                                               %directory for substracted images
mkdir(storDir,'Substracted/Smoothed');                                      %smoothed images -> appears not to be *.tiff ?!
mkdir(storDir,'Height');                                                    %height of the rivulet
mkdir(storDir,'Profile');                                                   %vertical profiles of the rivulet
mkdir(storDir,'Speed');                                                     %mean velocity
mkdir(storDir,'Width');                                                     %width of the rivulet
mkdir(storDir,'Correlation');                                               %directory for saving data necessary for correlations
mkdir(storDir,'Plots');                                                     %directory for saving plots

% display output
msgbox(['Directory for storing outputs was chosen and subdirectories'...
    ' was created'],'modal');uiwait(gcf);

% saving outputs
handles.metricdata.storDir = storDir;
end

% Update handles structure
guidata(handles.figure1, handles);

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
msgbox('Bacground image was succesfully loaded','modal');uiwait(gcf);

% save variable into handle
handles.metricdata.bgImage = bgImage;
end
% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in PushLoadIM.
function daten = PushLoadIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushLoadIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% imNames   ... cell of strings, selected filenames
% imDir     ... string, path to the directory with images

% extract used variables from handles.metricdata
rootDir = handles.metricdata.rootDir;
% check if the directory for storing outputs is chosen
if isfield(handles.metricdata,'storDir') == 0                               %if not, force user to choose it
    msgbox('You must choose storDir before loading images','modal');
    uiwait(gcf);
    storDir = PushChooseDir_Callback(hObject, eventdata, handles);
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
parfor i = 1:numel(imNames)
    daten{i} = imread([imDir '/' imNames{i}]);                              %load images from selected directory
end
% substract background from images
cd([storDir '/Substracted'])                                                %go to the folder for saving substracted images
parfor i = 1:numel(imNames)
    daten{i} = imsubtract(daten{i},bgImage);                                %substract bacground from picture
    imwrite(daten{i},imNames{i});                                           %save new images into subfolder
end
cd(rootDir)                                                                 %return to rootdir

msgbox('Images was succesfully loaded','modal');uiwait(gcf);

% save variables into handles
handles.metricdata.daten   = daten;                                         %images
handles.metricdata.imNames = imNames;                                       %names of the images (~ var. "files" in R..._A...MOD)
handles.metricdata.bgImage = bgImage;                                       %background image (dont want to load it repetedly)
handles.metricdata.storDir = storDir;                                       %need to resave also the location for storing outputs
% save information about succesfull ending of the function
handles.prgmcontrol.loadIM = 0;                                             %0 ... OK, 1 ... warnings, 2 ... errors (for now without use)
end
% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in PushClearIM.
function PushClearIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.metricdata,'daten') == 1                                 %field metricdata.daten exists
    clear('handles.metricdata.daten');
    % Update handles structure
    guidata(handles.figure1, handles);
    msgbox('Images were cleared')
else
    msgbox('No images were loaded');
end
% Update handles structure
guidata(handles.figure1, handles);

%% Pushbuttons - Image Processing


% --- Executes on button press in PushFindEdg.
function [EdgCoord daten] =...
    PushFindEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushFindEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
stmt1 = isfield(handles.metricdata,'daten');                                %are there loaded images?
if stmt1 == 0                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    daten = PushLoadIM_Callback(hObject, eventdata, handles);
else
    daten = handles.metricdata.daten;
end
stmt2 = isfield(handles.prgmcontrol,'autoEdges');                           %is there selected method for edges finding
if stmt2 == 1
    AUTO = handles.prgmcontrol.autoEdges;                                   %if there is selected method, save it
else
    msgbox('Select level of automaticallity for the program','modal');      %if not, ask for it
    uiwait(gcf);
end
stmt3 = isfield(handles.metricdata,'GREdges');                              %is selected graphical output
if stmt3 == 1
    GR = handles.metricdata.GREdges;
end

% create varargin optional input from editable textfields
hpTr        = handles.metricdata.hpTr;
numPeaks    = handles.metricdata.numPeaks;
fG          = handles.metricdata.fG;
mL          = handles.metricdata.mL;

% call function findEdges
EdgCoord = findEdges(daten,GR,AUTO,hpTr,numPeaks,fG,mL);

% call control function
[state,prbMsg,sumMsg] = controlFunction(EdgCoord);

save_to_base(1)
% modify potential mistakes
EdgCoord = modifyFunction(EdgCoord,daten,state,prbMsg,sumMsg);

% save output into handles
handles.metricdata.EdgCoord = EdgCoord;

% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in PushClearEdg.
function PushClearEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata = rmfield(handles.metricdata,'EdgCoord');

msgbox('Edges coordinates were cleared','modal');uiwait(gcf);

% Update handles structure
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);

%% Editable fields - Image Processing

function EdithpTr_Callback(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdithpTr as text
%        str2double(get(hObject,'String')) returns contents of EdithpTr as a double

handles.metricdata.hpTr = str2double(get(hObject,'String'));                %get value from editable textfield
% Update handles structure
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);



% --- Executes on button press in CheckPlate.
function CheckPlate_Callback(hObject, eventdata, handles)
% hObject    handle to CheckPlate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckPlate

handles.metricdata.GREdges(2) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.figure1, handles);

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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);



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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);

% --- Executes on button press in CheckRivTopGR.
function CheckRivTopGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckRivTopGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckRivTopGR

handles.prgmcontrol.GR.contour = get(hObject,'Value');

% Update handles structure
guidata(handles.figure1, handles);

% --- Executes on button press in CheckCompProfGR.
function CheckCompProfGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCompProfGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCompProfGR

handles.prgmcontrol.GR.profcompl = get(hObject,'Value');

% Update handles structure
guidata(handles.figure1, handles);

% --- Executes on button press in CheckMeanCutsGR.
function CheckMeanCutsGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckMeanCutsGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckMeanCutsGR

handles.prgmcontrol.GR.profcut = get(hObject,'Value');

% Update handles structure
guidata(handles.figure1, handles);

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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


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
guidata(handles.figure1, handles);


% --- Executes on button press in PushClosePlots.
function PushClosePlots_Callback(hObject, eventdata, handles)
% hObject    handle to PushClosePlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.figure1,'HandleVisibility','off');                              %dont want to close the main program
close all                                                                   %close every other figure
set(handles.figure1,'HandleVisibility','on');

%% Auxiliary functions
function [metricdata prgmcontrol] = ...
    initializeGUI(hObject,eventdata,handles)
%
% function for gui inicialization, to be executed just before progGui is
% made visible

% set default values for fields in Image Processing
handles.prgmcontrol.autoEdges = 2;                                          %default - completely automatic program execution
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
guidata(handles.figure1, handles);

function [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
%   [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
% function for controling the output of findEdges function. The algorithm
% walks through the EdgCoord matrix and saves positions of the wrongly
% guessed coordinates into problemIndexes matrix. If the control is passed
% without any problems, the state variable is set to 0.
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
for i = 1:nCol                                                              %better to do for each column sep. (remove only parts of NaN row)
    tmpVar = EdgCoord(:,i);                                                 %reduce input matrix only to i-th column
    % find NaN values in the EdgCoord matrix
    INaN = find(isnan(EdgCoord) == 1);
    tmpVar(any(isnan(tmpVar)'),:) = [];                                     %remove rows with NaN in them
    % calculate standard deviation of each column of EdgCoord
    coordSTD= std(tmpVar);
    coordMU = mean(tmpVar);                                                 %mean value in each column
    nRow    = numel(tmpVar);                                                %number of elements in tmpVar after removing the NaNs

    % find outliers - values more different than 2 * std. deviation
    % Rq: usually it is used 3 * std. deviation, but here the values should
    % be very similar (if the camera was not tempered with)
    outliers= abs(tmpVar-coordMU(ones(nRow,1),:))>...
        2*coordSTD(ones(nRow,1),:);                                         %matrix of indexes of values more different than 2 * std. dev.
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

function EdgCoord = modifyFunction(EdgCoord,IMdataCell,state,prbMsg,sumMsg)
%
%   EdgCoord = modifyFunction(EdgCoord,daten,state,prbMsg,sumMsg)
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
% EdgCoord  ... matrix with estimated edge coordinates
% IMdataCell... cell with image data
% state
% prbMsg    ... outputs from controlFunction
% sumMsg

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
        tmpMat = EdgCoord;                                                  %introduce temporary matrix
        tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
        for i = 1:numel(prbCoord(:,1))
            tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                %modify format of the problematic value
                '<html><span style="color: #FF0000; font-weight: bold;">', ...
                tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
                '</span></html>');
        end
        colNames = {'Small cuv. xMean',...                                  %set column names
            'Small cuv. yTop', 'Small cuv. yBottom',...
            'Big cuv. xMean',...
            'Big cuv. yTop', 'Big cuv. yBottom',...
            'Plate xLeft','Plate yTop',...
            'Plate xRight','Plate yBottom'};
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 950 750]);                %set window size +- matching the EdgeCoord needs
        uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...                %open uitable
            'ColumnEditable',false,...
            'ColumnWidth','auto', ...
            'Units','Normal', 'Position',[0 0 1 1]);                        %open EdgeCoord in uitable
        choice = questdlg(stringCell,...                                    %ask user again what he wants to do
        'Edge estimation correction',...
        'From mean values', 'Manually','Don`t modify',options);
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
            save_to_base(1);
            EdgCoord(prbCoord(prbCoord(:,2) == i),i) =...                   %all values with specified column index
                round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i))));%replace all outliers and NaN with mean values of the rest
        end
    case 'Manually'
        se      = strel('disk',12);                                         %morphological structuring element
        strVerL = 'Specify {\bf 3} times left vertical edge of the ';       %string preparation
        strVerR = 'Specify {\bf 3} times right vertical edge of the ';
        strHorT = 'Specify {\bf 3} times top horizontal edge of the ';
        strHorB = 'Specify {\bf 3} times bottom horizontal edge of the ';
        options.WindowStyle = 'modal';
        options.Interpreter = 'tex';
        for k = 1:numel(prbCoord(:,2));                                     %for all problems
            i = prbCoord(k,1);j = prbCoord(k,2);                            %save indexes into temporary variables
            switch prbMsg(k).device                                         %check the device, extreme SWITCH...
                case 'plate'
                    tmpIM = IMdataCell{i}(:,1:2*round(end/3));              %for the plate I need only left side of the image
                    trVec = [0 0];
                    if mod(j,7) == 0                                        %left vertical edge
                        str = [strVerL prbMsg(k).device];
                        chInd   = 1;
                    elseif mod(j,7) == 1                                    %top horizontal edge
                        str = [strHorT prbMsg(k).device];
                        chInd   = 2;
                    elseif mod(j,7) == 2                                    %right vertical edge
                        str = [strVerR prbMsg(k).device];
                        chInd   = 1;
                    else                                                    %bottom horizontal edge
                        str = [strHorB prbMsg(k).device];
                        chInd   = 2;
                    end
                    nInput  = 3;
                otherwise
                    if strcmp(prbMsg(k).device,'small cuvette') == 1        %choose which part of the image I want to show
                        tmpIM = IMdataCell{i}(1:round(2*end/3),round(end/2):end);%for small cuvette I need only top right side of the image
                        trVec = [round(size(IMdataCell{i},2)/2)-1 0];
                    else
                        tmpIM = IMdataCell{i}(round(end/3):end,round(end/2):end);%for big cuvette I need only bottom right side of the imagee
                        trVec = [round(size(IMdataCell{i},2)/2)-1 round(size(IMdataCell{i},1))];
                    end
                    if mod(j,3) == 1                                        %indexes 1 or 4, mean x values of cuvettes
                        str = ['Specify both vertical edges of the '...
                            prbMsg(k).device ', both of them {\bf 3} times.'];
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
    case 'Don`t modify'
end

% see if hFig is opened and if it is, actualize it
if exist('hFig','var') == 1
    tmpMat = EdgCoord;                                                      %introduce temporary matrix
    tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
    for i = 1:numel(prbCoord(:,1))
        tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                    %modify format of the problematic value
            '<html><span style="color: #FF0000; font-weight: bold;">', ...
            tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
            '</span></html>');
    end
    colNames = {'Small cuv. xMean',...                                      %set column names
        'Small cuv. yTop', 'Small cuv. yBottom',...
        'Big cuv. xMean',...
        'Big cuv. yTop', 'Big cuv. yBottom',...
        'Plate xLeft','Plate yTop',...
        'Plate xRight','Plate yBottom'};
    uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...                    %rewrite values into table
        'ColumnEditable',false,...
        'ColumnWidth','auto', ...
        'Units','Normal', 'Position',[0 0 1 1]);                            %open EdgeCoord in uitable
end
hMBox = msgbox('Values were modified','modal');uiwait(hMBox);               %notify user about end of the program
if exist('hFig','var')                                                      %if exists, close uitable
    close(hFig)
end