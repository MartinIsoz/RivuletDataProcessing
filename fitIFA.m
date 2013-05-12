function varargout = fitIFA(varargin)
%   function varargout = fitIFA(varargin)
%
% function for fitting the experimental data using derived model, at the
% time, there are three fitted parameters.
%
% INPUT variables (optional)
% Availible     ... cell with the current availible results. if this
% argument is not presents in the call, user has to load the data first
% (these data are the results of the Processed data saving)
% - thanks to this, this function can be started up in standalone mode
%
% Example call: fitIFA('Availible',Availible)
%
% See also: RIVULETEXPDATAPROCESSING, RIVULETPROCESSING,
% POSTPROCDATAPLOTTING

% Edit the above text to modify the response to help fitIFA

% Last Modified by GUIDE v2.5 23-Apr-2013 12:22:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fitIFA_OpeningFcn, ...
                   'gui_OutputFcn',  @fitIFA_OutputFcn, ...
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

%% GUI functions
% --- Executes just before fitIFA is made visible.
function fitIFA_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fitIFA (see VARARGIN)

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})                                       %input of the program are metricdata and prgmcontrol
            case 'availible'
                Availible =  varargin{index+1};
                % fill in initialize data
                strCellGR = cell(1,numel(Availible));
                parfor i = 1:numel(Availible)
                    strCellGR{i} = Availible{i}.ID;
                end
                set(handles.dataList,'String',strCellGR,'Max',numel(Availible))
                handles.metricdata.Availible = Availible;
        end
    end
end
if ~isfield(handles,'metricdata')
    set(handles.fitPush,'enable','off');
    handles.metricdata.Availible = [];
end

% initialize the values and fields
handles.metricdata.KK = 1.0;                                                %fill in values
handles.metricdata.L  = 3e-5;
handles.metricdata.beta0 = 0.055;
handles.metricdata.lb = [1e-5 1e-3 0.999];
handles.metricdata.ub = [5e-5 2e-1 1.001];
handles.metricdata.TolX = optimget(optimset('lsqcurvefit'),'TolX');
handles.metricdata.TolFun = optimget(optimset('lsqcurvefit'),'TolFun');
handles.metricdata.MaxIter= 10;
setappdata(hObject,'optimStop',false);                                       %set the iteration terminatio flag

set(handles.multConstEdit,'String',num2str(handles.metricdata.KK));         %fill in gui fields
set(handles.flThEdit,'String',num2str(handles.metricdata.L));
set(handles.beta0Edit,'String',num2str(handles.metricdata.beta0));
lString = {'Parameter Estimation:'};
set(handles.iterText,'String',lString,'Max',1);
set(handles.lbMCEdit,'String',num2str(handles.metricdata.lb(3)));
set(handles.ubMCEdit,'String',num2str(handles.metricdata.ub(3)));
set(handles.lbFTEdit,'String',num2str(handles.metricdata.lb(1)));
set(handles.ubFTEdit,'String',num2str(handles.metricdata.ub(1)));
set(handles.lbBeta0Edit,'String',num2str(handles.metricdata.lb(2)));
set(handles.ubBeta0Edit,'String',num2str(handles.metricdata.ub(2)));
set(handles.TolXEdit,'String',num2str(handles.metricdata.TolX));
set(handles.TolFunEdit,'String',num2str(handles.metricdata.TolFun));
set(handles.MaxIterEdit,'String',num2str(handles.metricdata.MaxIter));

% prepare the axes
title(handles.curAxes,'Current fitting state','FontWeight','Bold');
xlabel(handles.curAxes,'liquid mass flow rate, [g/s]');
ylabel(handles.curAxes,'S_{l--g}, [m^2]')
grid(handles.curAxes,'on')
title(handles.resAxes,'Resulting fit','FontWeight','Bold');
xlabel(handles.resAxes,'liquid mass flow rate, [g/s]');
ylabel(handles.resAxes,'S_{l--g}, [m^2]')
hold(handles.resAxes,'on')
grid(handles.resAxes,'on')

% disable useless fields
set(handles.beta0Edit,'enable','off');                                      %these fields are not used any more, beta0 is calculated
set(handles.lbBeta0Edit,'enable','off');                                    %from the maximal initial width of the rivulet
set(handles.ubBeta0Edit,'enable','off');

% Choose default command line output for fitIFA
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fitIFA wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = fitIFA_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%% Push buttons
% --- Executes on button press in fitPush.
function fitPush_Callback(hObject, ~, handles)
% hObject    handle to fitPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get the data from handles
parsC = [handles.metricdata.L handles.metricdata.beta0 ...
    handles.metricdata.KK];                                                 %L,beta0,KK
if ~isfield(handles.metricdata,'parsO')
    errordlg('Not all needed inputs specified - choose data');
    return
end
parsO = handles.metricdata.parsO;
selGR = handles.metricdata.selGR;
strGR = cellstr(get(handles.dataList,'String'));
% get the fitting options
ub    = handles.metricdata.ub;
lb    = handles.metricdata.lb;
TolX  = handles.metricdata.TolX;
TolFun= handles.metricdata.TolFun;
MaxIter=handles.metricdata.MaxIter;

setappdata(hObject,'optimStop',false);                                      %reset the optim term flag

% prepare th gui - common for all the calculations
hold(handles.resAxes,'off');                                                %restart the resulting axes
% initiate the calculation
mCell = cell(1,numel(handles.metricdata.IFACorr));                          %preallocate variables
targCell = mCell;
LVec  = zeros(1,numel(handles.metricdata.IFACorr));KKVec = LVec;beta0Vec = LVec;
legStr= {};
colorMat = distinguishable_colors(numel(handles.metricdata.IFACorr));       %generate matrix of colors for plotting results
for i = 1:numel(handles.metricdata.IFACorr)
    % prepare the gui
    lString = {...
            '                                         Norm of      First-order ';...
            ' Iteration  Func-count     f(x)          step          optimality   CG-iterations       L        betaO      K';...
            '  --------------------------------------------------------------------------------------------------------------'};
    set(handles.iterText,'String',[get(handles.iterText,'String');...
        {' ';sprintf('New fitting process (%s):',strGR{selGR(i)})};...
        {'==================================================='}]);
    set(handles.iterText,'String',[get(handles.iterText,'String');...
        lString]);
    set(handles.iterText,'Value',numel(get(handles.iterText,'String')),...
        'SelectionHighlight','off')
    legend(handles.resAxes,legStr,...
        'Location','Best')
    title(handles.resAxes,'Resulting fit','FontWeight','Bold');
    xlabel(handles.resAxes,'liquid mass flow rate, [g/s]');
    ylabel(handles.resAxes,'S_{l--g}, [m^2]')

    % calculation itself
    mCell{i} = handles.metricdata.IFACorr{i}(:,4);                          %get the vector of mass flow rates
    if max(mCell{i}) > 2e2                                                  %if the data are saved with dim. fl rate
        flData   = handles.metricdata.IFACorr{i}(1,1:end-2);
        mCell{i} = mCell{i}*1e3*flData(3)...
            *sqrt(flData(1)/(flData(2)*9.81*cos(flData(5)*pi/180)));
    end
    targCell{i} = handles.metricdata.IFACorr{i}(:,end);                      %get the target values
    parsIn   = [parsO{i} handles];
    
    % prepare plots
    hold(handles.curAxes,'off')
    plot(handles.curAxes,mCell{i},targCell{i},'o');hold(handles.curAxes,'on')
    title(handles.curAxes,'Current fitting state','FontWeight','Bold');
    xlabel(handles.curAxes,'liquid mass flow rate, [g/s]');
    ylabel(handles.curAxes,'S_{l--g}, [m^2]')
    
    % define what is needed to fit the data
    modelFun    = @(coefs,x) model(x,coefs,parsIn);                         %specify the model function

    lsqcurvefitopts = optimset('Display','off',...                          %get the lsqcurvefit properties
        'OutputFcn',@(x,optimVals,state)outFcn(x,optimVals,state,handles,hObject),...
        'MaxIter',MaxIter,'TolX',TolX,'TolFun',TolFun);

    coefEsts = lsqcurvefit(modelFun,...                                     %fit the function using nonlinear least squares
        parsC,mCell{i},targCell{i},lb,ub,lsqcurvefitopts);
    LVec(i) = coefEsts(1);beta0Vec(i) = coefEsts(2);KKVec(i) = coefEsts(3);%save the results
    
    % plot the results
    xgrid    = linspace(min(mCell{i}),max(mCell{i}),100)';                  %function must be called with column vector
    IFACalc  = model(xgrid,coefEsts,parsIn);
    plot(handles.resAxes,mCell{i},targCell{i},'o','Color',colorMat(i,:));
    hold(handles.resAxes,'on');
    plot(handles.resAxes,xgrid,IFACalc, 'Color',colorMat(i,:));
    grid(handles.resAxes,'on');
    legStr   = [legStr {sprintf('data %0d',i)} {sprintf('fit  %0d',i)}];
end
legend(handles.resAxes,legStr,...
        'Location','Best')
title(handles.resAxes,'Resulting fit','FontWeight','Bold');
end


% --- Executes on button press in closePush.
function closePush_Callback(~, ~, handles)
% hObject    handle to closePush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.figure1);                                                     %call closing function
end

% --- Executes on button press in exportPush.
function exportPush_Callback(~, ~, handles)
% hObject    handle to exportPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get the data from handles
strCell = get(handles.iterText,'String');                                   %get the string cell from handles/list

assignin('base','strCell',strCell)

[fileNm,path] = uiputfile('fitResults.txt','Save results');

if ~fileNm,return,end;                                                      %check the input

file2Wr  = fopen([path fileNm],'w+');                                       %open file for writing
fprintf(file2Wr,'*****************************************************\n');
fprintf(file2Wr,'*                                                   *\n');
fprintf(file2Wr,'* Fitting session %s              *\n',datestr(now));
fprintf(file2Wr,'*                                                   *\n');
fprintf(file2Wr,'*****************************************************\n');
for i = 1:numel(strCell) %#ok<FORPF>
    fprintf(file2Wr,'%s\n',strCell{i});                                     %write the results
end
fclose(file2Wr);

end

% --- Executes on button press in stopPush.
function stopPush_Callback(hObject, ~, ~)
% hObject    handle to stopPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setappdata(hObject,'optimStop',true)
drawnow;
end

% --- Executes on button press in loadDataPush.
function loadDataPush_Callback(hObject, ~, handles)
% hObject    handle to loadDataPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('Availible','var') == 0
    msgbox(['You can use this option only to load Processed data saved by'...
        '"Save all processed data into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
else
    if iscell(Availible) == 0 %#ok<NODEF>
        Availible = {Availible};                                            %convert to cell if needed
    end
    Availible = [handles.metricdata.Availible Availible];                   %append new data to the structure
    strCellAV = cellstr(num2str((1:numel(Availible))',1))';
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
    set(handles.dataList,'String',strCellAV,'Max',numel(strCellAV));        %update listbox
    handles.metricdata.Availible = Availible;
end
set(handles.fitPush,'enable','on');
% Update handles structure
guidata(hObject, handles);
end

%% Editable fields
function multConstEdit_Callback(hObject, ~, handles)
% hObject    handle to multConstEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of multConstEdit as text
%        str2double(get(hObject,'String')) returns contents of multConstEdit as a double

handles.metricdata.KK = str2double(get(hObject,'String'));

guidata(hObject,handles)
end


% --- Executes during object creation, after setting all properties.
function multConstEdit_CreateFcn(hObject, ~, ~)
% hObject    handle to multConstEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function flThEdit_Callback(hObject, ~, handles)
% hObject    handle to flThEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of flThEdit as text
%        str2double(get(hObject,'String')) returns contents of flThEdit as a double

handles.metricdata.L = str2double(get(hObject,'String'));

guidata(hObject,handles);
end


% --- Executes during object creation, after setting all properties.
function flThEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flThEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function beta0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to beta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beta0Edit as text
%        str2double(get(hObject,'String')) returns contents of beta0Edit as a double
handles.metricdata.beta0 = str2double(get(hObject,'String'));

guidata(hObject,handles)
end


% --- Executes during object creation, after setting all properties.
function beta0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function lbMCEdit_Callback(hObject, eventdata, handles)
% hObject    handle to lbMCEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbMCEdit as text
%        str2double(get(hObject,'String')) returns contents of lbMCEdit as a double

handles.metricdata.lb(3) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function lbMCEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbMCEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function ubMCEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ubMCEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubMCEdit as text
%        str2double(get(hObject,'String')) returns contents of ubMCEdit as a double

handles.metricdata.ub(3) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function ubMCEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubMCEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function lbFTEdit_Callback(hObject, eventdata, handles)
% hObject    handle to lbFTEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbFTEdit as text
%        str2double(get(hObject,'String')) returns contents of lbFTEdit as a double

handles.metricdata.lb(1) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function lbFTEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbFTEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function ubFTEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ubFTEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubFTEdit as text
%        str2double(get(hObject,'String')) returns contents of ubFTEdit as a double

handles.metricdata.ub(1) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function ubFTEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubFTEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function lbBeta0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to lbBeta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbBeta0Edit as text
%        str2double(get(hObject,'String')) returns contents of lbBeta0Edit as a double

handles.metricdata.lb(2) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function lbBeta0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbBeta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function ubBeta0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to ubBeta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubBeta0Edit as text
%        str2double(get(hObject,'String')) returns contents of ubBeta0Edit as a double

handles.metricdata.ub(2) = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function ubBeta0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubBeta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function TolXEdit_Callback(hObject, eventdata, handles)
% hObject    handle to TolXEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TolXEdit as text
%        str2double(get(hObject,'String')) returns contents of TolXEdit as a double

handles.metricdata.TolX = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function TolXEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TolXEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function TolFunEdit_Callback(hObject, eventdata, handles)
% hObject    handle to TolFunEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TolFunEdit as text
%        str2double(get(hObject,'String')) returns contents of TolFunEdit as a double

handles.metricdata.TolFun = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function TolFunEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TolFunEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function MaxIterEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MaxIterEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxIterEdit as text
%        str2double(get(hObject,'String')) returns contents of MaxIterEdit as a double

handles.metricdata.MaxIter = str2double(get(hObject,'String'));
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function MaxIterEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxIterEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


%% Listboxes

% --- Executes on selection change in dataList.
function dataList_Callback(hObject, ~, handles)
% hObject    handle to dataList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dataList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataList

selGR = get(hObject,'Value');                                               %get selected value(s)
IFACorr = cell(1,numel(selGR));parsO = cell(1,numel(selGR));
for i = 1:numel(selGR)
    IFACorr{i} = handles.metricdata.Availible{selGR(i)}.IFACorr;
    tmpVar = regexp(handles.metricdata.Availible{selGR(i)}.ID,'_','split'); %cut the string between '_'
    parsO{i} = {tmpVar{1} str2double(tmpVar{3}) 20 0.3};                    %construct other parameters, hardcode plate length and num of pts
end
handles.metricdata.IFACorr = IFACorr;
handles.metricdata.parsO   = parsO;
handles.metricdata.selGR   = selGR;
guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function dataList_CreateFcn(hObject, ~, ~)
% hObject    handle to dataList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in iterText.
function iterText_Callback(hObject, eventdata, handles)
% hObject    handle to iterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns iterText contents as cell array
%        contents{get(hObject,'Value')} returns selected item from iterText
end

% --- Executes during object creation, after setting all properties.
function iterText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


%% Fitting model
function [IFACalc betaVec aVec sVec kVec xMax] = model(m,parsC,parsO)
%function that calculates the interfacial area of the rivulet as function
%of the mass flow rate and correlated parameters
%
% INPUT variables
% m     ... mass flow rate, g/s (scalar)
% parsC ... parameters for the correlation (vector)
% pars0 ... other parameters, type of the fluid, plate inclination angle,
%           number of points in which the contact angle shoud be 
%           evaluated and the plate length(cell)
%
% OUTPUT variables
% IFACalc.. calculated size of the g--l interfacial ares, m2
% betaVec.. vector of contact angles along the plate, pirad
% aVec  ... vector of the rivulet half width along the plate, m
% sVec  ... vector of the arc lengths along the plate, m
% kVec  ... vector of the beta-dependent multiplicatives constants, s = a*k
% xMax  ... maximal time coordinate


% extract other parameters
liqName = parsO{1};                                                         %get the liquid name
alpha   = parsO{2};                                                         %get the plate inclination angle
nPts    = parsO{3};                                                         %get the number of points to evaluate the beta in
lPlate  = parsO{4};                                                         %plate length
handles = parsO{5};                                                         %handles to the calling gui

% extract model parameters
L       = parsC(1);                                                         %precursor film thickness
% beta0   = parsC(2);                                                         %initial contact angle
KK      = parsC(3);                                                         %multiplicative constant

% print iteration to the window
% set(handles.iterText,'String',[get(handles.iterText,'String');...
%     {sprintf('\nL = %3.4e, beta0 = %2.4f, KK = %3.3f',L,beta0,KK)}]);
% set(handles.iterText,'Value',numel(get(handles.iterText,'String')),...
%     'SelectionHighlight','off')
% fprintf(1,'L = %3.4e, beta0 = %2.4f, KK = %3.3f\n',L,beta0,KK);             %write down coefficients

% get the liquid parameters
liqPars = fluidDataFcn(liqName,alpha);
gx      = liqPars(2);
gamma   = liqPars(3);rho= liqPars(4);mu = liqPars(5);                       %surf. tens., density, dyn. viscosity
q       = m*1e-3/rho;                                                       %calculate vol. flow rate, m3/s

a0      = 1/2*sqrt(3)*1e-2;
beta0   = (105/4*mu*q/(rho*gx*a0^4)).^(1/3);

% define parameters used in solution
const   = 105/4;                                                            %model constants, to be checked/modified
K       = (const*mu*q/(rho*gx)).^(1/4);
A       = 27/4.*K*mu./gamma;
B       = K./(2*exp(1)^2*L);

% find the transformation between the time and space using the free falling
% film speed aproximation at L
uL0 = rho*gx*L^2/(2*mu);                                                    %find the contact line moving speed
xMax= lPlate/uL0;                                                           %transform

% lhs = @(x,beta) x...                                                        %implicitly defined function for contact angle in dependence of 
%     -(1/5)*A.*log(CC.*B./beta.^(7/4))./beta.^(15/4)...                      %the "time"
%     +(7/75)*A./beta.^(15/4)+(1/75)*A.*(15*log(CC*B./beta0.^(7/4))-7)./beta0.^(15/4);

lhs = @(x,beta) x...                                                        %implicitly defined function for contact angle in dependence of 
    - (4/15*A./beta.^(15/4)).*(log(B./beta.^(3/4)) - 1/5)...
    + beta0.^(5/4) + (4/15*A./beta0.^(15/4)).*(log(B./beta0.^(3/4)) - 1/5);

xVec    = ones(numel(q),1)*linspace(0,xMax,nPts);                           %matrix of the linspace
betaVec = zeros(size(xVec));kVec = betaVec;sVec = betaVec;                  %preallocate variables
% fopts   = optimset('Display','off','TypicalX',ones(numel(q),1)*beta0);%,...
%     'PlotFcns',{@optimplotfval,@optimplotx});                             %set up options for fzero
fopts   = optimset('Display','off','TypicalX',beta0);%,...

for i = 1:nPts %#ok<FORPF>
%     betaVec(:,i)= fsolve(@(beta) lhs(xVec(:,i),beta),ones(numel(q),1)*beta0,fopts);%find the current beta
    betaVec(:,i)= fsolve(@(beta) lhs(xVec(:,i),beta),beta0,fopts);%find the current beta
    aVec(:,i)   = K./tan(betaVec(:,i)).^(3/4);                              %find the current riv. half width
    kVec(:,i)   = sqrt(1+tan(betaVec(:,i)).^2)...                           %find the beta-dep. constant for calculating the arc length
        + 1/(2*tan(betaVec(:,i)))*log((tan(betaVec(:,i))...
        + sqrt(1 + tan(betaVec(:,i)).^2))./(-tan(betaVec(:,i))...
        + sqrt(1 + tan(betaVec(:,i)).^2)));
    sVec(:,i)   = aVec(:,i).*kVec(:,i);                                     %calculate the current arc length
end

IFACalc = KK/(nPts-1)*lPlate*trapz(sVec,2);                                 %calculate the interfacial area size using trapeizoidal rule

plot(handles.curAxes,m,IFACalc,'Color',rand(1,3));
hold(handles.curAxes,'on');
grid(handles.curAxes,'on')
drawnow
end

function stop = outFcn(x,optimVals,state,handles,hObject)
% 1st iteration does not show last column norm(step) because it's undefined
formatstrFirstIter = ' %5.0f      %5.0f   %13.6g                  %12.3g                    %3.4e    %2.4f    %3.3f';
formatstr = ' %5.0f      %5.0f   %13.6g  %13.6g   %12.3g      %7.0f       %3.4e    %2.4f    %3.3f';
iter = optimVals.iteration;
numFunEvals = optimVals.funccount;
val = optimVals.resnorm;
optnrm = optimVals.firstorderopt;
switch state
    case 'iter'
        if iter > 0
            nrmsx = optimVals.stepsize;
            pcgit = optimVals.cgiterations;
            currOutput = sprintf(formatstr,iter,numFunEvals,val,nrmsx,optnrm,pcgit,x(1),x(2),x(3));
        else
            currOutput = sprintf(formatstrFirstIter,iter,numFunEvals,val,optnrm,x(1),x(2),x(3));
        end
        set(handles.iterText,'String',[get(handles.iterText,'String');...
            {currOutput}]);
        set(handles.iterText,'Value',numel(get(handles.iterText,'String')),...
            'SelectionHighlight','off')
end
drawnow;
stop = getappdata(hObject,'optimStop');
end
