function varargout = changeIMPars(varargin)
% CHANGEIMPARS M-file for changeIMPars.fig
%
% M-file for handling gui for changing image processing parameters. To be
% called from menu of the main program (RivuletExpDataProcessin.m).
% This function returns cell of optional parameters for findEdges function.
%
% See also RIVULETEXPDATAPROCESSING FINDEDGES EDGE HOUGH IM2BW

% Edit the above text to modify the response to help changeIMPars

% Last Modified by GUIDE v2.5 26-Jul-2012 16:58:39

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


% --- Executes just before changeIMPars is made visible.
function changeIMPars_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to changeIMPars (see VARARGIN)

% Choose default command line output for changeIMPars
handles.output = hObject;

% Initialize gui
% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})
         case 'onlyshow'
            tmpVar =  varargin{index+1};                                    %input - parameters to show
            set(handles.PushOK,'enable','off');                             %if parameters are only shown, they cannot be set
            % extract input
            handles.metricdata.hpTr     = tmpVar{1};
            handles.metricdata.numPeaks = tmpVar{2};
            handles.metricdata.fG       = tmpVar{3};
            handles.metricdata.mL       = tmpVar{4};
            handles.metricdata.im2bwTr  = tmpVar{5};
            handles.metricdata.DUIM2BW  = tmpVar{6};
            handles.metricdata.method   = tmpVar{7};
        end
    end
end

handles.metricdata = initializeGUI(hObject,eventdata,handles);              %if there are not any parameters to show, load defaults

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes changeIMPars wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = changeIMPars_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);


%% Pushbuttons
% --- Executes on button press in PushOK.
function PushOK_Callback(hObject, eventdata, handles)
% hObject    handle to PushOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%extract handles.metricdata
hpTr    = handles.metricdata.hpTr;
numPeaks= handles.metricdata.numPeaks;
fG      = handles.metricdata.fG;
mL      = handles.metricdata.mL;
im2bwTr = handles.metricdata.im2bwTr;
DUIM2BW = handles.metricdata.DUIM2BW;
method  = handles.metricdata.method;


% assign the output cell
handles.output = {hpTr numPeaks fG mL im2bwTr DUIM2BW method};              %set the output

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes on button press in PushDef.
function PushDef_Callback(hObject, eventdata, handles)
% hObject    handle to PushDef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% reinitialize gui
handles.metricdata = initializeGUI(hObject,eventdata,handles);
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in PushCancelClose.
function PushCancelClose_Callback(hObject, eventdata, handles)
% hObject    handle to PushCancelClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% assign the output cell
handles.output = [];                                                        %set the output as empty matrix

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


%% Edit fields

function EdithpTr_Callback(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdithpTr as text
%        str2double(get(hObject,'String')) returns contents of EdithpTr as a double

handles.metricdata.hpTr = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


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

handles.metricdata.numPeaks = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


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

handles.metricdata.fG = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


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

handles.metricdata.mL = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


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

function EditIm2BW_Callback(hObject, eventdata, handles)
% hObject    handle to EditIm2BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditIm2BW as text
%        str2double(get(hObject,'String')) returns contents of EditIm2BW as a double

handles.metricdata.im2bwTr = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function EditIm2BW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditIm2BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Pop up menu
% --- Executes on selection change in PopupEdgeMethod.
function PopupEdgeMethod_Callback(hObject, eventdata, handles)
% hObject    handle to PopupEdgeMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupEdgeMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupEdgeMethod

contents = cellstr(get(hObject,'String'));
handles.metricdata.method =  contents{get(hObject,'Value')};

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function PopupEdgeMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupEdgeMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes
% --- Executes on button press in CheckDUIM2BW.
function CheckDUIM2BW_Callback(hObject, eventdata, handles)
% hObject    handle to CheckDUIM2BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckDUIM2BW

handles.metricdata.DUIM2BW = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);



%% Auxiliary functions
function metricdata = ...
    initializeGUI(hObject,eventdata,handles)
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
% set pop-up menu
handles.metricdata.method   = 'Prewitt';
end

% fill in the fields
set(handles.EdithpTr,'String',handles.metricdata.hpTr);
set(handles.EditnumPeaks,'String',handles.metricdata.numPeaks);
set(handles.EditfG,'String',handles.metricdata.fG);
set(handles.EditmL,'String',handles.metricdata.mL);
set(handles.EditIm2BW,'String',handles.metricdata.im2bwTr);

% check checkboxes
set(handles.CheckDUIM2BW,'Value',handles.metricdata.DUIM2BW);

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