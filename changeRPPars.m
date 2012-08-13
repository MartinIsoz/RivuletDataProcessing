function varargout = changeRPPars(varargin)
% CHANGERPPARS M-file for changeRPPars.fig
%
% M-file for handling gui for changing rivulet processing parameters. To be
% called from Data processing menu of the main program
% (RivuletExpDataProcessing.m). This function returns cell of optional
% parameters for rivuletProcessing function. Or it can be called with input
% option 'onlyshow' and then, the current rivulet processing parameters are
% displayed without possibility to modify them.
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         30. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also RIVULETEXPDATAPROCESSING RIVULETPROCESSING
%

% Edit the above text to modify the response to help changeRPPars

% Last Modified by GUIDE v2.5 13-Aug-2012 12:20:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @changeRPPars_OpeningFcn, ...
                   'gui_OutputFcn',  @changeRPPars_OutputFcn, ...
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

%% Initialization and setting defaults GUI properties

% --- Executes just before changeRPPars is made visible.
function changeRPPars_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to changeRPPars (see VARARGIN)

% Choose default command line output for changeRPPars
handles.output = hObject;

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})
            case 'onlyshow'
                tmpVar =  varargin{index+1};                                %input - parameters to show
                % extract input
                handles.metricdata.Width    = tmpVar{1}(1);
                handles.metricdata.Length   = tmpVar{1}(2);
                handles.metricdata.Angle    = tmpVar{2};
                handles.metricdata.HfThS    = tmpVar{3}(1);
                handles.metricdata.HfThB    = tmpVar{3}(3);
                handles.metricdata.LfThS    = tmpVar{3}(2);
                handles.metricdata.LfThB    = tmpVar{3}(4);
                handles.metricdata.CuvWidth = tmpVar{3}(5);
                handles.metricdata.PolDeg   = tmpVar{4};
                handles.metricdata.nCuts    = tmpVar{5};
                handles.metricdata.FFact    = tmpVar{6};
                handles.prgmcontrol         = 'onlyshow';                   %save to handles, that user is not allowed to modify values
                set(handles.PushOK,'enable','off');                         %if parameters are only shown, they cannot be set
                set(handles.PushDef,'enable','off');                        %this button is useless
        end
    end
else
     handles.prgmcontrol = 'modify';                                        %save to handles, that user can modify values
end

handles.metricdata = initializeGUI(hObject,eventdata,handles);              %call initialization function

set(hObject,'CloseRequestFcn',@my_closereq)                                 %set custom closerequest function

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes changeIMPars wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Executes on attempt to close GUI
function my_closereq(~,~)
%this function just resumes GUI execution on close. otherwise there would
%be and error if the window would be closed for example by Alf+F4 or the
%cross (from window manager)
uiresume(gcf)

% --- Outputs from this function are returned to the command line.
function varargout = changeRPPars_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);

% --- Disabling useless warnings
%#ok<*DEFNU> - GUI cannot see what functions will be used by user

%% Pushbuttons

% --- Executes on button press in PushOK.
function PushOK_Callback(hObject, ~, handles)
% by pressing this button the output is created and GUI is resumed (output
% is stored into handles.output and exported to the called function)

%extract handles.metricdata
Width   = handles.metricdata.Width;
Length  = handles.metricdata.Length;
Angle   = handles.metricdata.Angle;
FFact   = handles.metricdata.FFact;

HfThS   = handles.metricdata.HfThS;
LfThS   = handles.metricdata.LfThS;
HfThB   = handles.metricdata.HfThB;
LfThB   = handles.metricdata.LfThB;
PolDeg  = handles.metricdata.PolDeg;
CuvWidth= handles.metricdata.CuvWidth;

nCuts   = handles.metricdata.nCuts;


% assign the output cell
handles.output = {[Width Length] Angle [HfThS LfThS HfThB LfThB CuvWidth]... 
    PolDeg nCuts FFact};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

% --- Executes on button press in PushDef.
function PushDef_Callback(hObject, eventdata, handles)
% by pressing this button, the default values are loaded into GUI

% reinitialize gui
handles.metricdata = initializeGUI(hObject,eventdata,handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in PushCancelClose.
function PushCancelClose_Callback(hObject, ~, handles)
% button that allows user to exit the function without modifying any values

% assign the output cell
handles.output = [];

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

%% Edit fields - plate size

function EditWidth_Callback(hObject, ~, handles)
% editable field allowing user to modify the experimental plate/cell width,
% this values is needed both as input parameters for the rivuletProcessing
% function and for calculation of the f-factor in the cell
%
% modifying this value will cause recalculation of the f-factor

handles.metricdata.Width = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditWidth_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditWidth editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditLength_Callback(hObject, ~, handles)
% function allowing user to edit the experimental plate length, input
% parameter of the rivuletProcessing function. this values is expected to
% change only with major experimental set up modification

handles.metricdata.Length = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditLength_CreateFcn(hObject, ~, ~)
% function for setting properties of EditLength editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditHeight_Callback(hObject, ~, handles)
% field for modification of the experimental cell height - this and cell
% width is needed for the calculation of the f-factor in the cell. the
% cross-section of the rivulet itself is neglected in the calculation
%
% modifying this field causes recalculation of the f-factor

handles.metricdata.Height = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditHeight_CreateFcn(hObject, ~, ~)
% function for setting properties of EditHeight editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditAngle_Callback(hObject, ~, handles)
% function for editing the incilantion angle of the plate, expends software
% usability even for measurements of interfacial area as the function of
% the plate inclination angle

handles.metricdata.Angle = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditAngle_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditAngle editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Edit fields - cuvette calibration
% at the time, big cuvette is not used, so user cannot modify its
% properties

function EditHfThS_Callback(hObject, ~, handles)
% setting up cuvette regression parameters - higher film thickness in the
% small cuvette

handles.metricdata.HfThS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditHfThS_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditHfThS editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditLfThS_Callback(hObject, ~, handles)
% setting up cuvette regression parameters - lower film thickness in the
% small cuvette

handles.metricdata.LfThS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditLfThS_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditLfThS editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditHfThB_Callback(hObject, ~, handles)
% setting up cuvette regression parameters - higher film thickness in the
% big cuvette
%
% at the time, big cuvette is not used and this control is disabled

handles.metricdata.HfThB = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditHfThB_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditHfThB

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditLfThB_Callback(hObject, ~, handles)
% setting up cuvette regression parameters - lower film thickness in the
% big cuvette
%
% at the time, big cuvette is not used and this control is disabled

handles.metricdata.LfThB = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditLfThB_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditLfThB editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditPolDeg_Callback(hObject, ~, handles)
% editable field for specifying degree of the polynomial used for cuvettes
% regression, defalt value is 2, because the linear function doesnt fit
% data precisely enough. please note that values > 4 can cause unwanted
% "trend" to appear

handles.metricdata.PolDeg = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditPolDeg_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditPolDeg editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditCuvWidth_Callback(hObject, ~, handles)
% function for editing values of cuvettes width in pixels, the cuvettes are
% approximately 110 pixels wide, the default value of used width is 80
% pixesl

handles.metricdata.CuvWidth = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditCuvWidth_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditCuvWidth editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Edit fields - gas flow parameters

function EditGasFl_Callback(hObject, ~, handles)
% editable field that handles modifications of volumetric gas flow, default
% values is 0 (no counter-current gas flow).
%
% modifying this field causes recalculation of the f-factor

handles.metricdata.GasFl = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditGasFl_CreateFcn(hObject, ~, ~)
% setting up properties of EditGasFl editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditTc_Callback(hObject, ~, handles)
% field that handles modifications of gas critical temperature. Tc is used
% as input parameter for van der Walls state equation (calculatin of the
% coefficients). this way user can change the parameters of the f-factor
% calculations according to the gas type
%
% modifying this field causes recalculation of the f-factor

handles.metricdata.Tc = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditTc_CreateFcn(hObject, ~, ~)
% setting properties of EditTc editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditPc_Callback(hObject, ~, handles)
% field that handles modifications of gas critical pressure. pc is used
% as input parameter for van der Walls state equation (calculatin of the
% coefficients). this way user can change the parameters of the f-factor
% calculations according to the gas type
%
% modifying this field causes recalculation of the f-factor

handles.metricdata.Pc = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditPc_CreateFcn(hObject, ~, ~)
% function for setting properties of EditPc editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditM_Callback(hObject, ~, handles)
% edit field for modifying the molar weight of the gas, the value is
% inserted in g/mol for getting rid of the e-3 at the end
%
% modifying this value will cause recalculation of the f-factor

handles.metricdata.M = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditM_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditM editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditFFact_Callback(~, ~, ~)
% field that displays f-factor calculated for the inserted parametrs in the
% Gas flow parameters and Cell height. at this time, this doesnt do
% anything

% --- Executes during object creation, after setting all properties.
function EditFFact_CreateFcn(hObject, ~, ~)
% setting properties for the EditFFact editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Edit fields - experimental conditions

function EditT_Callback(~, ~, ~)
% function for setting up temperature during the experiment. The liquid is
% temepered to 298.15 K and the gas is saturated, so this temeprature is
% considered constant, uneditable and equal to 298.15 K. so this callback
% at the time doesnt do anythign

% --- Executes during object creation, after setting all properties.
function EditT_CreateFcn(hObject, ~, ~)
% function for setting properties of EditT editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditP_Callback(hObject, ~, handles)
% pressure during the experiment. for the liquid properties, the changes in
% the pressure are neglectable (p ~ 100 kPa), but for the gas, the
% influence of the pressure is more important, so the calculation of the
% f-factor depends on this field
%
% modifying this field will cause recalculation of the f-factor

handles.metricdata.P = str2double(get(hObject,'String'));

handles.metricdata.FFact = FFactFcn(handles.metricdata);                    %updating the f-factor
set(handles.EditFFact,'String',handles.metricdata.FFact);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditP_CreateFcn(hObject, ~, ~)
% function for setting properties of the EditP editable field

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Edit fields - other parameters

function EditnCuts_Callback(hObject, ~, handles)
% edit field for inserting the number of cuts to make along the plate,
% default number is 5, which makes cuts at 5, 10, 15, 20 and 25 cm from the
% top of the plate

handles.metricdata.nCuts = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function EditnCuts_CreateFcn(hObject, ~, ~)
% function to setting properties of EditnCuts editable fiedl

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% GUI values initialization
function metricdata = ...
    initializeGUI(~,~,handles)
%
% function for gui inicialization, to be executed just before progGui is
% made visible or after the 'Set defaults' button is pressed

if strcmp(handles.prgmcontrol,'modify') == 1                                %mod. mode, every time this function is called, def. vals are setted
    % set editable fields values
    % plate size
    handles.metricdata.Width    = 0.15;                                     %m
    handles.metricdata.Length   = 0.30;                                     %m
    handles.metricdata.Height   = 0.01;                                     %m
    handles.metricdata.Angle    = 60;                                       %deg
    % cuvettes calibration
    handles.metricdata.HfThS    = 1.93;                                     %mm
    handles.metricdata.HfThB    = 6.00;                                     %mm
    handles.metricdata.LfThS    = 0.33;                                     %mm
    handles.metricdata.LfThB    = 2.25;                                     %mm
    handles.metricdata.PolDeg   = 2;
    handles.metricdata.CuvWidth = 80;
    % gas flow parameters
    handles.metricdata.GasFl    = 0;                                        %m3/hod
    handles.metricdata.Tc       = 132.64;                                   %default values are for the air, K
    handles.metricdata.Pc       = 3.766e3;                                  %kPa
    handles.metricdata.M        = 28.84;                                    %g/mol
    % experimental conditions
    handles.metricdata.T        = 298.15;                                   %K
    handles.metricdata.P        = 100;                                      %kPa
    % other parameters
    handles.metricdata.nCuts    = 5;
    % calculate value of f-factor
    handles.metricdata.FFact    = FFactFcn(handles.metricdata);             %calculate F-Factor for the default parameters
else                                                                        %onlyshow mode, only some fields are setted, others are imported
    if strcmp(handles.prgmcontrol,'onlyshow') == 1                          %handles.metricdata field exists, but is generated from fcn input
        handles.metricdata.Height   = 0;                                    %this (hopefully) doesnt change (0.01), but its unsetted by input
        handles.metricdata.GasFl    = 0;                                    %if the main function is used only to show parameters
        handles.metricdata.Tc       = 0;                                    %values replaced by 0 are the ones that are not in the input
        handles.metricdata.Pc       = 0;
        handles.metricdata.M        = 0;
        handles.metricdata.T        = 298.15;
        handles.metricdata.P        = 0;
    end
end

% fill in the values into editable fields
% plate size
set(handles.EditWidth,'String',handles.metricdata.Width);
set(handles.EditLength,'String',handles.metricdata.Length);
set(handles.EditHeight,'String',handles.metricdata.Height);
set(handles.EditAngle,'String',handles.metricdata.Angle);
% cuvettes calibration
set(handles.EditGasFl,'String',handles.metricdata.GasFl);
set(handles.EditHfThS,'String',handles.metricdata.HfThS);
set(handles.EditHfThB,'String',handles.metricdata.HfThB);
set(handles.EditLfThS,'String',handles.metricdata.LfThS);
set(handles.EditLfThB,'String',handles.metricdata.LfThB);
set(handles.EditPolDeg,'String',handles.metricdata.PolDeg);
set(handles.EditCuvWidth,'String',handles.metricdata.CuvWidth);
% gas flow parameters
set(handles.EditGasFl,'String',handles.metricdata.GasFl);
set(handles.EditTc,'String',handles.metricdata.Tc);
set(handles.EditPc,'String',handles.metricdata.Pc);
set(handles.EditM,'String',handles.metricdata.M);
set(handles.EditFFact,'String',handles.metricdata.FFact);
% experimental conditions
set(handles.EditT,'String',handles.metricdata.T);
set(handles.EditP,'String',handles.metricdata.P);
% other parameters
set(handles.EditnCuts,'String',handles.metricdata.nCuts);

% set up output
metricdata = handles.metricdata;

% Update handles structure
guidata(handles.figure1, handles);

%% F-factor calculation
function FFact = FFactFcn(metricdata)
%
%   FFact = FFactFcn(metricdata)
%
% the f-factor is calculated from the plate width, experimental cell
% height, critical properties of the gas and its volumetric flow factor.
%
% for calculating the desity of the is used Van der Waals state equation,
% because the conditions of the experimet are not extreme (1 bar, 298.15 K)
%
% INPUT variables
% metricdata    ... structure containing the metricdata of the program,
%                   from this structure, the following fields are used:
%   Width       ... width of the plate, for calculation of uG (velocity of
%                   the gas)
%   Height      ... height of the experimental cell, for calculation of the
%                   uG
%   GasFl       ... volumetric gas flow, for calculation of the uG
%   Tc          ... critical temperature of the gas, for calculating
%                   coefficients of the Van der Waals state equation
%   Pc          ... critical pressure of the gas, for calculating
%                   coefficients of the Van der Waals state equation
%   T           ... current temperature, input of the Van der Waals state
%                   eq. for calculating the density of the gas
%   P           ... current pressure, input of the Van der Waals state
%                   eq. for calculating the density of the gas
%   M           ... molar mass of the gas, needed for conversion of molar
%                   volume into density
%
% OUTPUT variables
% FFact         ... f-factor of the gas, in Pa^0.5

% extracting parameters + conversion to SI units
Width   = metricdata.Width;
Height  = metricdata.Height;
GasFl   = metricdata.GasFl/3600;                                            %m3/hod->m3/s
Tc      = metricdata.Tc;
Pc      = metricdata.Pc*1e3;                                                %kPa->Pa
T       = metricdata.T;
P       = metricdata.P*1e3;                                                 %kPa->Pa
M       = metricdata.M;

% constants
R       = 8.314;                                                            %universal gas constant

% calculating the velocity of the gas (vol. flow/cross-section)
uG      = GasFl/(Width*Height);                                             %convert gas flow to m3/s and divide by cross-section of the device

% calculating the gas density
a       = 27/64*(R*Tc/Pc)^2; b = 1/8*(R*Tc/Pc);                             %coefficients of the equation

Vm      = fzero(@(Vm) P*Vm^3-(b*P+R*T)*Vm^2+a*Vm-b*a,30e-3);                %finding the molar volume of the gas
% Rq: this equation has 3 roots, molar volume of the gas is the highest one

rho     = M/Vm;

% calculating the f-factor
FFact   = uG*sqrt(rho);
