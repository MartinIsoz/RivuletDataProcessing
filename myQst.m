function varargout = myQst(varargin)
% Custom question dialog for modifyFunction
%
% it is to be called with in the following way:
%
% choice = myQst('autstr',stringCell);
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% note: this function should be rewritten so that in doesn't need the .fig
% file (the GUI is quite simple and it shouldnt be to difficult)
%
% See also RIVULETEXPDATAPROCESSING MODIFYFUNCTION

% Edit the above text to modify the response to help myQst

% Last Modified by GUIDE v2.5 25-Jul-2012 15:00:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @myQst_OpeningFcn, ...
                   'gui_OutputFcn',  @myQst_OutputFcn, ...
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


% --- Executes just before myQst is made visible.
function myQst_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to myQst (see VARARGIN)

% Choose default command line output for myQst
handles.output = 'From mean values';

if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})
         case 'autstr'
            set(handles.AutGenStr, 'String', varargin{index+1});            %proces input - automatic string
        end
    end
end

% Update handles structure
guidata(hObject, handles);

% Determine the position of the dialog - centered on the callback figure
% if available, else, centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
if isempty(gcbf)
    ScreenUnits=get(0,'Units');
    set(0,'Units','pixels');
    ScreenSize=get(0,'ScreenSize');
    set(0,'Units',ScreenUnits);

    FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
    FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf,'Units');
    set(gcbf,'Units','pixels');
    GCBFPos = get(gcbf,'Position');
    set(gcbf,'Units',GCBFOldUnits);
    FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                   (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);


% Make the GUI modal
set(handles.figure1,'WindowStyle','modal')

% UIWAIT makes myQst wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = myQst_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);

% --- Surpres inutile warnings
%#ok<*DEFNU>


% --- Executes on button press in PushMean.
function PushMean_Callback(hObject, ~, handles)
% repaire outliers and NaN from mean values

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes on button press in PushManually.
function PushManually_Callback(hObject, ~, handles)
% manually repair outliers and mean values

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

% --- Executes on button press in PushDntMod.
function PushDntMod_Callback(hObject, ~, handles)
% leave the values as they are, do not modify them. please note that if
% there will be any NaN in the EdgCoord matrix, rivuletProcessing function
% will fail

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

% --- Executes on button press in PushShow.
function PushShow_Callback(hObject, ~, handles)
% show found EdgCoord matrix

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


function AutGenStr_Callback(~, ~, ~)
% callback for the autogenerated string, this function doesnt do anything

% 
% % --- Executes during object creation, after setting all properties.
% this function is not used - i want the same background as the rest of the
% window
% function AutGenStr_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to AutGenStr (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, ~)
% custom close request function, needed for sending selected option to
% output

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, ~, handles)
% handling closing from the keyboard

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'No';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figure1);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure1);
end    
