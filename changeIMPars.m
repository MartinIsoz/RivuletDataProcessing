function varargout = changeIMPars(varargin)
% CHANGEIMPARS M-file for changeIMPars.fig
%
% M-file for handling gui for changing image processing parameters. To be
% called from menu of the main program (RivuletExpDataProcessin.m).
% This function returns cell of optional parameters for findEdges function.
% 
% Calling options are:
% 'onlyshow' followed by the parameters that are to be shown, in this mode,
% user is not allowed to change any parameters (and any changes will not be
% saved). this is used to show current image processing parameters
% 'imdata' followed by cell with the path to subtracted images directory,
% name of the first image in this directory and optionally by approximate
% plate position on these images. if these data are present, user can use
% sliders to control the effect of changing im2bw tresholds
% 'nodata' in this case, sliders are disabled and user has no option to see
% the effects of changing parameters
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         26. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also RIVULETEXPDATAPROCESSING FINDEDGES EDGE HOUGH IM2BW

% Edit the above text to modify the response to help changeIMPars

% Last Modified by GUIDE v2.5 17-Aug-2012 14:24:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @changeIMPars_OpeningFcn, ...
                   'gui_OutputFcn',  @changeIMPars_OutputFcn, ...
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

%% Initialization and setting default GUI properties

% --- Executes just before changeIMPars is made visible.
function changeIMPars_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to changeIMPars (see VARARGIN)
%
% this function processes the input and decides if the edited values shoud
% be returned to caller function

% Choose default command line output for changeIMPars
handles.output = hObject;

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})
            case 'onlyshow'
                tmpVar =  varargin{index+1};                                %input - parameters to show
                set(handles.PushOK,'enable','off');                         %if parameters are only shown, they cannot be set
                % extract input
                handles.metricdata.hpTr     = tmpVar{1};
                handles.metricdata.numPeaks = tmpVar{2};
                handles.metricdata.fG       = tmpVar{3};
                handles.metricdata.mL       = tmpVar{4};
                handles.metricdata.im2bwTr  = tmpVar{5};
                handles.metricdata.DUIM2BW  = tmpVar{6};
                handles.metricdata.method   = tmpVar{7};
                handles.metricdata.im2bwCuvTr=tmpVar{8};
            case 'imdata'                                                   %this will load the first image that will be processed
                tmpVar    = varargin{index+1};
                subsImDir = tmpVar{1};                                      %position from where to load the image
                imName    = tmpVar{2};                                      %name of the image
                image     = imread([subsImDir '/' imName]);                 %load image from directory with substracted images
                se        = strel('disk',12);                               %morphological structuring element
                if numel(tmpVar)==3
                    AppPlatePos = tmpVar{3};                                %extract input approximate plate position
                else
                    AppPlatePos = [0 0 2*size(image,2)/3 size(image,1)];    %otherwise take left 2/3 of the image
                    warndlg(['Full functionality of the program is reached'...
                        ' only when the approximate plate position is '...
                        'specified'],'Limited mode','modal');               %let user know that the program runs in limited mode
                end
            otherwise
                warndlg(['When the program is runned before loading the images,'...
                    'only limited functionality is availible'],...
                    'Limited mode','modal');                                %let user know that the program runs in limited mode
                set(handles.SliderIm2BW,'enable','off');                    %no image data input ->disable slider that opens images
                set(handles.SliderIm2BWCuv,'enable','off');
        end
    end
end

handles.metricdata = initializeGUI(hObject,eventdata,handles);              %if there are not any parameters to show, load defaults
if strcmpi(varargin{index},'imdata')==1
    handles.metricdata.image= image;
    handles.metricdata.se   = se;
    handles.metricdata.AppPlatePos = AppPlatePos;
end

set(hObject,'CloseRequestFcn',@my_closereq)                                 %set custom closerequest function

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes changeIMPars wait for user response (see UIRESUME)
uiwait(handles.figure1);

% My own closereq fcn -> to avoid set output even if gui is close by Alt+F4
function my_closereq(~,~)
uiresume(gcf)


% --- Outputs from this function are returned to the command line.
function varargout = changeIMPars_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% this function specifyies the output of the main function

% Get default command line output from handles structure
varargout{1} = handles.output;

if isfield(handles,'FigSlider')
    if ishandle(handles.FigSlider) == 1                                     %if figure opened by one of the sliders still exists
        close(handles.FigSlider)
    end
end

% The figure can be deleted now
delete(handles.figure1);

% --- Disabling useless warnings
%#ok<*DEFNU> - GUI cannot see what functions will be used by user


%% Pushbuttons
% --- Executes on button press in PushOK.
function PushOK_Callback(hObject, ~, handles)
% this functions reads all the variables values present into the GUI and
% sends them into the changeIMPars_OutputFcn

% extract handles.metricdata
% parameters for the plate finding
hpTr    = handles.metricdata.hpTr;
numPeaks= handles.metricdata.numPeaks;
fG      = handles.metricdata.fG;
mL      = handles.metricdata.mL;
im2bwTr = handles.metricdata.im2bwTr;
DUIM2BW = handles.metricdata.DUIM2BW;
method  = handles.metricdata.method;
% parameters for the cuvettes finding
im2bwCuvTr = handles.metricdata.im2bwCuvTr;


% assign the output cell
handles.output = {hpTr numPeaks fG mL im2bwTr DUIM2BW method im2bwCuvTr};   %set the output

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes on button press in PushDef.
function PushDef_Callback(hObject, eventdata, handles)
% by pushing this button, default values are loaded into all GUI fields

% reinitialize gui
handles.metricdata = initializeGUI(hObject,eventdata,handles);
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in PushCancelClose.
function PushCancelClose_Callback(hObject, ~, handles)
% this functions handles the output if user cancels modification of
% parameters. output is then set as empty matrix

% assign the output cell
handles.output = [];                                                        %set the output as empty matrix

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


%% Edit fields

function EdithpTr_Callback(hObject, ~, handles)
% editable field that allows user to change treshold for the HOUGH
% transform (input of the HOUGH function)

handles.metricdata.hpTr = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EdithpTr_CreateFcn(hObject, ~, ~)
% function for setting properties of EdithpTr edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditnumPeaks_Callback(hObject, ~, handles)
% function that allows user to change number of peaks to look for at image
% transformed by HOUGH transform, input of the HOUGHPEAKS function

handles.metricdata.numPeaks = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EditnumPeaks_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditnumPeaks edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditfG_Callback(hObject, ~, handles)
% function that allows user to change how big gaps between the lines with
% the same 'rho' parameters should be filled. input of HOUGHLINES

handles.metricdata.fG = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EditfG_CreateFcn(hObject, ~, ~)
% function for setting properties of EditfG edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditmL_Callback(hObject, ~, handles)
% function that allows user to change minimal length of the line taken into
% account. input of HOUGHLINES

handles.metricdata.mL = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EditmL_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditmL edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditIm2BW_Callback(hObject, ~, handles)
% function allowing user to change the treshold for IM2BW function for the
% plate finding algorithm

handles.metricdata.im2bwTr = str2double(get(hObject,'String'));             %get value from editable field

set(handles.SliderIm2BW,'Value',handles.metricdata.im2bwTr);                %set slider position according to this value

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EditIm2BW_CreateFcn(hObject, ~, ~)
% function for changing properties of the EditIm2BW edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function EditIm2BWCuv_Callback(hObject, ~, handles)
% function allowing user to change the treshold for IM2BW function for the
% cuvettes finding algorithm

handles.metricdata.im2bwCuvTr = str2double(get(hObject,'String'));          %get value from editable field

set(handles.SliderIm2BWCuv,'Value',handles.metricdata.im2bwCuvTr);          %set slider position according to this value

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditIm2BWCuv_CreateFcn(hObject, ~, ~)
% function for changing properties of the EditIm2BWCuv edit field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Pop up menu
% --- Executes on selection change in PopupEdgeMethod.
function PopupEdgeMethod_Callback(hObject, ~, handles)
% popup menu that allows user to change method used for elements edges
% finding on the processed picture. input of the EDGE function

contents = cellstr(get(hObject,'String'));
handles.metricdata.method =  contents{get(hObject,'Value')};

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function PopupEdgeMethod_CreateFcn(hObject, ~, ~)
% function for setting properties of the PopupEdgeMethod popup menu

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes
% --- Executes on button press in CheckDUIM2BW.
function CheckDUIM2BW_Callback(hObject, ~, handles)
% if this checkbox is checked, the IM2BW transformation wont be used before
% calling the EDGE function. performing this transformation can bring out
% more points to be considered as plate edges, but with some images, this
% causes finding of false edges

handles.metricdata.DUIM2BW = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);

%% Sliders

% --- Executes on slider movement.
function SliderIm2BW_Callback(hObject, ~, handles)
% slider that alows user to change the treshold for IM2BW transformation
% and to see the output immediatly in the opened window with picture

% get current values
im2bwTr = get(hObject,'Value');                                             %get the position of the slider

EdgFMethod = handles.metricdata.method;                                     %get selected method from handles
se         = handles.metricdata.se;

% perform the same transformation as it is in the findEdges function
cutLeft = handles.metricdata.AppPlatePos(1);
cutTop  = handles.metricdata.AppPlatePos(2);
cutRight= handles.metricdata.AppPlatePos(3);
cutBottom=handles.metricdata.AppPlatePos(4);

tmpIM   = handles.metricdata.image(cutTop:cutBottom,cutLeft:cutRight);      %cut out the plate from the image
tmpIM = imtophat(tmpIM,se);
tmpIM = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                      %enhance contrasts
tmpIM = im2bw(tmpIM,im2bwTr);                                               %simple conversion to black and white with specified treshold
tmpIM = edge(tmpIM,EdgFMethod);                                             %find edges on the image

% show resulting image
handles.FigSlider = figure(10);imshow(tmpIM)                                %open figure with image created with current parameters

% update the gui values
handles.metricdata.im2bwTr = im2bwTr;
set(handles.EditIm2BW,'String',handles.metricdata.im2bwTr);                 %edit string in editable field according to the sl. position

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function SliderIm2BW_CreateFcn(hObject, ~, ~)
% function for setting up the properties of SliderIm2BW slider

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function SliderIm2BWCuv_Callback(hObject, ~, handles)
% slider that alows user to change the treshold for IM2BW transformation
% and to see the output immediatly in the opened window with picture

% get current values
im2bwCuvTr = get(hObject,'Value');                                          %get the position of the slider

% perform the same transformation as it is in the findEdges function
tmpIM  = handles.metricdata.image(:,...
    round(size(handles.metricdata.image,2)/2):end);                         %cut of unwanted part of the image and save temp. image var.
tmpIM  = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                     %temporary image variable, enhance contrasts
tmpIM  = im2bw(tmpIM, im2bwCuvTr);                                          %temporary black and white image, convert image to BW

% show resulting image
handles.FigSlider = figure(10);imshow(tmpIM)                                %open figure with image created with current parameters

% update gui values
handles.metricdata.im2bwCuvTr = im2bwCuvTr;
set(handles.EditIm2BWCuv,'String',handles.metricdata.im2bwCuvTr);           %edit string in edit field according to the sl. position

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function SliderIm2BWCuv_CreateFcn(hObject, ~, ~)
% function for setting up the properties of SliderIm2BWCuv slider

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% GUI values initialization
function metricdata = ...
    initializeGUI(~,~,handles)
%
% function for gui inicialization, to be executed just before progGui is
% made visible

if isfield(handles,'metricdata') == 0;
% set checkboxes
minVal = get(handles.CheckDUIM2BW,'Min'); 
handles.metricdata.DUIM2BW = minVal;
% set editable fields
handles.metricdata.hpTr     = 0.33;
handles.metricdata.numPeaks = 200;
handles.metricdata.fG       = 35;
handles.metricdata.mL       = 25;
handles.metricdata.im2bwTr  = 0.40;
handles.metricdata.im2bwCuvTr=0.15;
% set pop-up menu
handles.metricdata.method   = 'Prewitt';
end

% fill in the fields
set(handles.EdithpTr,'String',handles.metricdata.hpTr);
set(handles.EditnumPeaks,'String',handles.metricdata.numPeaks);
set(handles.EditfG,'String',handles.metricdata.fG);
set(handles.EditmL,'String',handles.metricdata.mL);
set(handles.EditIm2BW,'String',handles.metricdata.im2bwTr);
set(handles.EditIm2BWCuv,'String',handles.metricdata.im2bwCuvTr);

% check checkboxes
set(handles.CheckDUIM2BW,'Value',handles.metricdata.DUIM2BW);

% move sliders
set(handles.SliderIm2BW,'Value',handles.metricdata.im2bwTr);
set(handles.SliderIm2BWCuv,'Value',handles.metricdata.im2bwCuvTr);

% set popup menu
contents = cellstr(get(handles.PopupEdgeMethod,'String'));                  %get cell of strings
for i = 1:numel(contents)
    if strcmp(handles.metricdata.method,contents{i}) == 1
        set(handles.PopupEdgeMethod,'Value',i);
        break
    end
end

metricdata = handles.metricdata;
% Update handles structure
guidata(handles.figure1, handles);
