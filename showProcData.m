function varargout = showProcData(varargin)
% SHOWPROCDATA M-file for showProcData.fig
%
% M-file for handling the GUI for showing data availible for
% postprocessing. It is to be called from Postprocessing menu of the main
% program (RivuletExpDataProcessing.m).
%
% At the begining, the list with current availible data is show (the ID
% string of the data are displayed). User can load other data, save the
% current data and start the postprocessing tool with the data selected in
% the list.
%
% ID string of each data is composed in the following way:
% liquid type_gasFlow_inclinationAngle_date (in the format
% DD_MM_YY-HH_MM_SS)
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         08. 08. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also: RIVULETEXPDATAPROCESSING, POSTPROCPLOTTING

% Edit the above text to modify the response to help showProcData

% Last Modified by GUIDE v2.5 08-Aug-2012 16:56:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @showProcData_OpeningFcn, ...
                   'gui_OutputFcn',  @showProcData_OutputFcn, ...
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

%% Initialization functions

% --- Executes just before showProcData is made visible.
function showProcData_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
%
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to showProcData (see VARARGIN)

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})
         case 'handles'
            tmpVar =  varargin{index+1};                                    %input of the function are handles
            % extract input
            if isfield(tmpVar.metricdata,'Availible') == 1
                Availible = tmpVar.metricdata.Availible;
                strCellAV = cell(1,numel(Availible));
                for i = 1:numel(Availible)
                    strCellAV{i} = Availible{i}.ID;                         %create string with availible data names from handles
                end
                handles.metricdata.Availible = Availible;
            else
                strCellAV{1} = 'No data are availible for postprocessing';
                set(handles.PushSaveAll,'Enable','off');                    %disable useless buttons
                set(handles.PushSaveSel,'Enable','off');
                set(handles.PushClearSel,'Enable','off');
                set(handles.PushStartPostProc,'Enable','off');
                handles.metricdata.Availible = [];                          %create empty matrix
            end
        end
    end
end
set(handles.ListData,'String',strCellAV,'Max',numel(strCellAV));            %update string in the listbox

% Choose default command line output for showProcData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = showProcData_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% this function actually doesn't have any output at the time

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Listbox

% --- Executes on selection change in ListData.
function ListData_Callback(hObject, ~, handles) %#ok<DEFNU>
% listbox to show currently avalible data for postprocessing

handles.metricdata.selDT = get(hObject,'Value');                            %get selected data (indexes)

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function ListData_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% function for setting properties of ListData listbox

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in PushLoad.
function PushLoad_Callback(hObject, ~, handles) %#ok<DEFNU>
% function for loading data from presaved processed_data .mat files. the
% loaded data are merged with the currents. Current data with the same ID
% strings as loaded are rewritten

uiopen('load');                                                             %open dialog for loading variable
if exist('Availible','var') == 0
    msgbox(['You can use this option only to load Processed data saved by'...
        '"Save all processed data into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
else
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
end
set(handles.PushSaveAll,'Enable','on');                                     %enable buttons
set(handles.PushSaveSel,'Enable','on');
set(handles.PushClearSel,'Enable','on');
set(handles.PushStartPostProc,'Enable','on');
% Update handles structure
guidata(hObject, handles);

%% Pushbuttons

% --- Executes on button press in PushSaveAll.
function PushSaveAll_Callback(~, ~, handles) %#ok<DEFNU>
% function for saving all the postprocessing (output) data currently
% present in the listbox (and more importantly in the handles.metricdata)

Availible = handles.metricdata.Availible; %#ok<NASGU>                       %this variable is used 'indirectly'
uisave('Availible','Processed_data');


% --- Executes on button press in PushClearSel.
function PushClearSel_Callback(hObject, ~, handles) %#ok<DEFNU>
% function for clearing selected data from the list. if there are no data
% left, the pushbuttons using the data are disabled

if isfield(handles.metricdata,'selDT') == 1
    selDT     = handles.metricdata.selDT;
    Availible = handles.metricdata.Availible;
    Availible = Availible(1:numel(Availible)~=selDT);                       %keep only unselected data
    if isempty(Availible) == 1
        strCellAV{1} = 'No data are availible for postprocessing';
        set(handles.PushSaveAll,'Enable','off');                            %disable useless buttons
        set(handles.PushSaveSel,'Enable','off');
        set(handles.PushClearSel,'Enable','off');
        set(handles.PushStartPostProc,'Enable','off');
    else
        for i = 1:numel(Availible) %#ok<FORPF>
            strCellAV{i} = Availible{i}.ID;                                 %create string with availible data names from handles
        end
    end
    set(handles.ListData,'String',strCellAV,'Max',max([2 numel(strCellAV)]),...%keep the listbox multiselect for nothing-selected option
        'Value',[]);                                                        %update listbox
    handles.metricdata = rmfield(handles.metricdata,'selDT');               %nothing is selected
else
    msgbox('Please select data first','modal');uiwait(gcf);
end

handles.metricdata.Availible = Availible;                                   %resave availible into handles

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in PushSaveSel.
function PushSaveSel_Callback(~, ~, handles) %#ok<DEFNU>
%function for saving selected data into the .mat file

if isfield(handles.metricdata,'selDT') == 1
    selDT     = handles.metricdata.selDT;
    Availible = handles.metricdata.Availible{selDT}; %#ok<NASGU>            %resave only selected data, var Availible is used indirectly
    uisave('Availible','Processed_data');
else
    msgbox('Please select data first','modal');uiwait(gcf);
end


% --- Executes on button press in PushStartPostProc.
function PushStartPostProc_Callback(~, ~, handles) %#ok<DEFNU>
% button that stars the postprocessing tool with the selected data from
% ListData listbox. if no data are selected, user is notified

if isfield(handles.metricdata,'selDT')
    selDT = handles.metricdata.selDT;
    postProcPlotting(handles.metricdata.Availible(selDT));                  %start post processing tool with only selected
else
    msgbox('Please select data first','modal');uiwait(gcf);
end