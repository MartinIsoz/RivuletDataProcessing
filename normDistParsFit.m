function varargout = normDistParsFit(varargin)
% NORMDISTPARSFIT M-file for normDistParsFit.fig
%      NORMDISTPARSFIT, by itself, creates a new NORMDISTPARSFIT or raises the existing
%      singleton*.
%
%      H = NORMDISTPARSFIT returns the handle to a new NORMDISTPARSFIT or the handle to
%      the existing singleton*.
%
%      NORMDISTPARSFIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NORMDISTPARSFIT.M with the given input arguments.
%
%      NORMDISTPARSFIT('Property','Value',...) creates a new NORMDISTPARSFIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before normDistParsFit_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to normDistParsFit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help normDistParsFit

% Last Modified by GUIDE v2.5 04-Feb-2013 09:57:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @normDistParsFit_OpeningFcn, ...
                   'gui_OutputFcn',  @normDistParsFit_OutputFcn, ...
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

%% GUI handling

% --- Executes just before normDistParsFit is made visible.
function normDistParsFit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to normDistParsFit (see VARARGIN)

% Initialize gui
if(nargin > 3)
    for index = 1:2:(nargin-3),
        if nargin-3==index, break, end
        switch lower(varargin{index})                                       %input of the program are metricdata and prgmcontrol
            case 'metricdata'
                metricdata =  varargin{index+1};
            case 'prgmcontrol'
                prgmcontrol = varargin{index+1};
        end
    end
    % extract immediatly needed inputs
    strCellIm = cell(1,numel(metricdata.imNames));
    for i = 1:numel(metricdata.imNames)
        strCellIm{i} = metricdata.imNames{i};                               %create string with availible images names
    end
end

% Fill in the list with availible images
set(handles.avImList,'String',strCellIm,'Max',numel(strCellIm));            %update string in the listbox

% Fill the textfield avCutsText with maximal number of cuts that can be
% made
set(handles.avCutsText,'String',num2str(...                                 %get the number of rows from EdgCoord vector
    metricdata.EdgCoord(end)-metricdata.EdgCoord(end-2)));
% Fill the editable field nCutsEdit with number of cuts to be made preset
% into the RivProcPars (default value is 5)
set(handles.nCutsEdit,'String',num2str(...
    metricdata.RivProcPars{5}));

% Save input data into handles
handles.metricdata = metricdata;
handles.prgmcontrol= prgmcontrol;

% Initialize necessary variables
handles.prgmcontrol.expDelta = 0;
handles.prgmcontrol.expMFit  = 0;
handles.prgmcontrol.expGOF   = 0;

% Choose default command line output for normDistParsFit
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Make the GUI invisible (so it cannot be closed from MATLAB)
set(handles.figure1,'Visible','off');

% UIWAIT makes normDistParsFit wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = normDistParsFit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set statusbar - this function is executed after GUI is made visible and
% before user can set any inputs => java object is ready for statusbar
handles.statusbar = statusbar(hObject,'Program is ready');

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on selection change in avImList.
function avImList_Callback(hObject, eventdata, handles)
% hObject    handle to avImList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns avImList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from avImList

handles.metricdata.selIm = get(hObject,'Value');                            %get selected data (indexes)

set(handles.runButton,'Enable','on')                                        %enable the run pushbutton

guidata(hObject,handles);
end


% --- Executes during object creation, after setting all properties.
function avImList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to avImList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in expDataButton.
function expDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to expDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get which data are to be exported
expDelta = handles.prgmcontrol.expDelta;
expMFit  = handles.prgmcontrol.expMFit;
expGOF   = handles.prgmcontrol.expGOF;

% get the program runtime variables
storDir  = handles.metricdata.storDir;                                      %directory for storing results
imSourceDir = handles.metricdata.imSourceDir;                               %directory with original images

% get the experimental set up parameters
fluidType= handles.metricdata.fluidType;                                    %fluid type
RivProcPars = handles.metricdata.RivProcPars;                               %other exp. data
plateSize= RivProcPars{1};
inclAngle= RivProcPars{2};
FFact    = RivProcPars{6};
nCuts    = RivProcPars{5};
EdgCoord = handles.metricdata.EdgCoord;
DistanceP= round((EdgCoord(end)-EdgCoord(end-2))/(nCuts+1));                %distance between 2 cuts in pixels
DistanceM= DistanceP*plateSize(2)/(EdgCoord(end)-EdgCoord(end-2));          %distance between 2 cuts in m

% get the selected images names
imNames  = handles.metricdata.imNames;
selImU   = handles.metricdata.selImU;
imNames  = imNames(selImU);

% get data to export
Delta    = handles.metricdata.resFitCell{1};                                %matrix
MFit     = handles.metricdata.resFitCell{2};                                %matrix
GOF      = handles.metricdata.resFitCell{3};                                %cell of structures

% if it doesn't exists, create a folder to export data (will be located in
% the './storDir/normDistPars
d         = dir(storDir);                                                   %create list of subdirectories in checked dir
isub      = [d(:).isdir];                                                   %returns logical vector
namesFolds = {d(isub).name};                                                %get list of names of folders
namesFolds(ismember(namesFolds,{'.','..'})) = [];                           %remove . and .. from the list
if sum(strcmp(namesFolds,'normDistPars')) == 0                              %if the subdirectory is not present in current dir
        mkdir([storDir '/normDistPars']);                                   %create it
end

expDir  = [storDir '/normDistPars'];                                        %save the name of the directory where to save data

% create the file to export data
dataInd = [expDelta expMFit expGOF];
nameCell = {'-Delta' '-MFit' '-GOF'};
fileName = ['Exp' nameCell{dataInd~=0} '_' ...                              %create the fileName - exproted data + current date
    datestr(now,'HH-MM-SS_dd-mm-yy')...
    '.txt'];

% open or create file for writing (the probability of opening and rewriting
% existing file is extremely low, but...)
file2Wr  = fopen([expDir '/' fileName],'w+');

% writing the head of the file
fprintf(file2Wr,'===HEAD==================================================\n\n');
fprintf(file2Wr,...
    ['Exported data from the normDistPars.m program\n\n' ...
    'This file contains following data:\n']);
fprintf(file2Wr,...
    '%s\n\n',nameCell{dataInd==1});
fprintf(file2Wr,...
    ['Where:\n'...
    'Delta is local maximal height of the rivulet along its vertical\n'...
    'coordinate obtained from measurements at it is described for example\n'...
    'in [1]\n'...
    'MFit is standard deviation as used in equation (1) (m(z)), these\n'...
    'values are obtained by fitting the local profile using the relation (1)\n'...
    'with m(z) as fitted coefficient and delta0(z) as problem dependent\n'...
    'parameter.\n'...
    'GOF are goodness-of-fit information for each fitted profile as\n'...
    'provided by MATLAB function FIT\n\n']);
fprintf(file2Wr,'Equation used for fitting:\n');
fprintf(file2Wr,...
   ['                          +       2   +\n'...
    '                          |      x    |\n'...
    ' delta(x,z) = delta0(z)exp|- ---------|,        (1)\n'...
    '                          |          2|\n'...
    '                          +   2*m(z)  +\n\n']);
fprintf(file2Wr,...
    ['where delta(x,z) is the local height of the rivulet, delta0(z) is\n'...
    'the measured problem dependent parameter, saved as Delta, and m(z) is\n'...
    'the fitted coefficient.\n\n']);
fprintf(file2Wr,'File creation time: %s\n\n',datestr(now,'HH-MM-SS_dd-mm-yyyy'));
fprintf(file2Wr,'Image source directory: %s\n\n',imSourceDir);
fprintf(file2Wr,'Procesed images (in order):\n');
fprintf(file2Wr,'%s\n',imNames{:});fprintf(file2Wr,'\n');
fprintf(file2Wr,'Experimental set up data:\n');
fprintf(file2Wr,'Plate size: %f x %f m\n',plateSize(1),plateSize(2));
fprintf(file2Wr,'Plate inclination angle: %d deg\n',inclAngle);
fprintf(file2Wr,'Fluid type: %s\n',fluidType);
fprintf(file2Wr,'Gas f-factor: %5.3f Pa^0.5\n',FFact);
fprintf(file2Wr,'Number of cuts made along the plate: %d\n',nCuts);
fprintf(file2Wr,'Distance between 2 cuts: %d pixels ~ %5.3e m\n\n',DistanceP,DistanceM);
fprintf(file2Wr,'References:\n');
fprintf(file2Wr,'[1] Isoz, M. RivuletExpDataProcessing Program Documentation, 0.9th ed.; Freiberg, 2012.\n');
fclose(file2Wr);                                                            %close file

% exporting the delta(z) data
if expDelta == 1
    file2Wr  = fopen([expDir '/' fileName],'a');                            %open file and append
    fprintf(file2Wr,'\n===DELTA=(m)==============================================\n\n');
    fclose(file2Wr);                                                        %close file for use in dlmwrite
    dlmwrite([expDir '/' fileName],Delta','delimiter','\t',...
        'precision','%5.5e','-append')
    
end

% exporting the m(z) data
if expMFit == 1
    file2Wr  = fopen([expDir '/' fileName],'a');                            %open file and append
    fprintf(file2Wr,'\n===MFIT=(m)===============================================\n\n');
    fclose(file2Wr);                                                        %close file for use in dlmwrite
    dlmwrite([expDir '/' fileName],MFit','delimiter','\t',...
        'precision','%10.5e','-append')
end

% exporting the GOF data
fieldsList = fields(GOF{1}{1});                                             %get list of the fields
printList  = fieldsList;                                                    %initialize list of names to print
maxChar    = max(cellfun(@numel,fieldsList));                               %get maximal length of the word
for i = 1:numel(fieldsList) %#ok<FORPF>
    printList{i} = sprintf(['%' num2str(maxChar) 's'], printList{i});
end
if expGOF == 1
    file2Wr  = fopen([expDir '/' fileName],'a');                            %open file and append
    fprintf(file2Wr,'\n===GOF==================================================\n\n');
    for i = 1:numel(GOF{1})                                                 %for all the lines
        fprintf(file2Wr,'%04.f:\n',i);
        for j = 1:numel(fieldsList)
            fprintf(file2Wr,'%-s:\t\t',printList{j});                           %print the field name
            for k = 1:numel(GOF)                                            %for all the images
                fprintf(file2Wr,'%5.5e\t',GOF{k}{i}.(fieldsList{j}));       %print current field values
            end
            fprintf(file2Wr,'\n');                                          %end line
        end
    end
    fclose(file2Wr);                                                        %close file for use in dlmwrite
end

% update statusbar
handles.statusbar = statusbar(handles.figure1,...
            ['Chosen data were exported to ' fileName]);
handles.statusbar.ProgressBar.setVisible(false);
end


% --- Executes on button press in plotResButton.
function plotResButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotResButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% prepare the data
resFitCell = handles.metricdata.resFitCell;                                 %get the data from handles
delta0     = resFitCell{1};                                                 %maximal rivulet heights along the plate
mFit       = resFitCell{2};                                                 %standard deviation of the normal distribution along the plate
plateSize  = handles.metricdata.RivProcPars{1};                             %get plate size
zLinSpace  = linspace(0,plateSize(2),numel(delta0(1,:)));                   %create linspace of plate vertical coords
imNames    = handles.metricdata.imNames;                                    %get the cell fith imNames
selImU     = handles.metricdata.selImU;                                     %get indexes of selected images

% create the colors
Colors     = distinguishable_colors(numel(selImU));                         %create different colors for all the data

% plot the max. rivulet height along the plate
figure('Units','Pixels','Position',[20 20 800 600]);
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
    plot(zLinSpace,delta0(i,:),'Color',Colors(i,:))
end
legend(imNames(selImU),'interpreter','none')
xlabel('z, [m]');ylabel('\delta_0, [m]');
axis tight

% plot the standard deviation of the normal distribution along the plate
figure('Units','Pixels','Position',[20 20 800 600]);
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
    plot(zLinSpace,mFit(i,:),'Color',Colors(i,:))
end
legend(imNames(selImU),'interpreter','none')
xlabel('z, [m]');ylabel('\sigma, [m]');
axis tight

end


% --- Executes on button press in plotFitButton.
function plotFitButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotFitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% prepare the data
fitGoodCell= handles.metricdata.resFitCell{3};                              %get the data from handles
plateSize  = handles.metricdata.RivProcPars{1};                             %get plate size
imNames    = handles.metricdata.imNames;                                    %get the cell fith imNames
selImU     = handles.metricdata.selImU;                                     %get indexes of selected images
nCuts      = handles.metricdata.RivProcPars{5};                             %get number of made cuts

nImages    = numel(fitGoodCell);
nData      = numel(fitGoodCell{1});

% prepare the linetype according to used nCuts
if nCuts ~= 0 || nCuts < 500                                                %if the image was cutted before fitting
    lSpec = '-';
    mSize = 2;
else
    lSpec = '.';
    mSize = 1;
end

% create the colors
Colors     = distinguishable_colors(numel(selImU));                         %create different colors for all the data

% data extraction
sse    = zeros(nImages,nData);                                              %variable allocation
rsquare= sse;dfe = sse;adjrsquare = sse;rmse = sse;
for i  = 1:nImages
    for j = 1:nData
        sse(i,j)        = fitGoodCell{i}{j}.sse;                            %get sum of squared errors
        rsquare(i,j)    = fitGoodCell{i}{j}.rsquare;                        %get the coeff of determination
        dfe(i,j)        = fitGoodCell{i}{j}.dfe;                            %get degrees of freedom
        adjrsquare(i,j) = fitGoodCell{i}{j}.adjrsquare;                     %get adjusted rsquare
        rmse(i,j)       = fitGoodCell{i}{j}.rmse;                           %get root mean squared error
    end
end
zLinSpace  = linspace(0,plateSize(2),nData);                   %create linspace of plate vertical coords

% plot the standard deviation of the normal distribution along the plate
figure('Units','Pixels','Position',[20 20 800 600]);
subplot(221)
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
plot(zLinSpace,rsquare(i,:),'LineStyle',lSpec,'Color',Colors(i,:),'MarkerSize',mSize)
end
hLegend = legend(imNames(selImU),'interpreter','none','Location','Best');   %this is necessary to have visible legend
legChil = get(hLegend,'Children');
assignin('base','legChil',legChil)
set(legChil(1:3:end),'MarkerSize',7);
xlabel('z, [m]');ylabel('R^2, [m]');
axis([0 plateSize(2) 0 1])

subplot(222)
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
plot(zLinSpace,sse(i,:),'LineStyle',lSpec,'Color',Colors(i,:),'MarkerSize',mSize)
end
hLegend = legend(imNames(selImU),'interpreter','none','Location','Best');   %this is necessary to have visible legend
legChil = get(hLegend,'Children');
assignin('base','legChil',legChil)
set(legChil(1:3:end),'MarkerSize',7);
xlabel('z, [m]');ylabel('sse, [m]');
axis tight

subplot(223)
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
plot(zLinSpace,dfe(i,:),'LineStyle',lSpec,'Color',Colors(i,:),'MarkerSize',mSize)
end
hLegend = legend(imNames(selImU),'interpreter','none','Location','Best');   %this is necessary to have visible legend
legChil = get(hLegend,'Children');
assignin('base','legChil',legChil)
set(legChil(1:3:end),'MarkerSize',7);
xlabel('z, [m]');ylabel('dfe, [m]');
axis tight

subplot(224)
hold(gca,'on')
for i = 1:numel(selImU) %#ok<FORPF>
plot(zLinSpace,rmse(i,:),'LineStyle',lSpec,'Color',Colors(i,:),'MarkerSize',mSize)
end
hLegend = legend(imNames(selImU),'interpreter','none','Location','Best');   %this is necessary to have visible legend
legChil = get(hLegend,'Children');
assignin('base','legChil',legChil)
set(legChil(1:3:end),'MarkerSize',7);
xlabel('z, [m]');ylabel('rmse, [m]');
axis tight

end


% --- Executes on button press in runButton.
function runButton_Callback(hObject, eventdata, handles)
% hObject    handle to runButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% enable the cancel button
% set(handles.cancelButton,'Enable','on')

% extraction of input data from handles
DNTLoadIM = handles.prgmcontrol.DNTLoadIM;                                  %are the images present into handles?
if DNTLoadIM ~= 1                                                           %if images are loaded
    daten = handles.metricdata.daten;                                       %save them into temporary function variable
end
imNames = handles.metricdata.imNames;                                       %names of images to be processed
selIm   = handles.metricdata.selIm;                                         %get images selected for the processing
nImages = numel(selIm);                                                     %number of selected images
subsImDir=handles.metricdata.subsImDir;                                     %get the directory with subtracted images
smImDir   = [subsImDir '/Smoothed'];                                        %directory with smoothed images

EdgCoord    = handles.metricdata.EdgCoord;                                  %get the coordinates of plate and cuv. edges
Treshold    = handles.metricdata.Treshold;                                  %get treshold for the noise distinguishon
plateSize   = handles.metricdata.RivProcPars{1};
filmTh      = handles.metricdata.RivProcPars{3};
RegressionPlate = handles.metricdata.RivProcPars{4};
nCuts       = handles.metricdata.RivProcPars{5};

FilterSensitivity = handles.metricdata.FSensitivity;


% Program execution itself
% Check, if the rivulet is to be cut and the properties of the results
if nCuts ~= 0 || nCuts ~= EdgCoord(end)-EdgCoord(end-2)                     %if the image is to be cutted before fitting
    % for all the images, all the YProfilPlatte have the same size
    Distance     = round((EdgCoord(end)-EdgCoord(end-2))/(nCuts+1));            %number of points in each mean profile
    % prepare variables and cut the rivulet
    if nCuts == 0 || Distance < 50                                              %if too much cuts is specified
        warndlg(['The number of cuts specified is bigger than'...               %notify user by dialog
            ' number of rows necessary to obtain mean values for each cut'],...
            'modal');uiwait(gcf);drawnow;
    end
end

% Image transformation, cutting and fitting
if DNTLoadIM == 0                                                           %are all the data loaded?
    % !! This part of the code was NOT tested !!
    handles.statusbar = statusbar(handles.figure1,...
        ['Converting grayscale values into distances for all images ',...   %updating th statusbar
        'loaded in memory']);
    YProfilPlatte = ImConv(daten(selIm),EdgCoord,filmTh,RegressionPlate);   %I can process all the loaded and chosen images at once
    tmpCell = cell(1,nImages);                                              %create empty cell with number of elements corresponding to nImages
    tmpCell(:) = {fspecial('disk',FilterSensitivity)};
    YProfilPlatte = cellfun(@imfilter,YProfilPlatte,...                     %apply selected filter to YProfilPlatte
        tmpCell,'UniformOutput',0);
    if nCuts ~= 0 || nCuts ~= EdgCoord(end)-EdgCoord(end-2)                 %if the image is to be cutted before fitting
        handles.statusbar.ProgressBar.setVisible(false);                        %hide progressbar
        handles.statusbar = statusbar(handles.figure1,...
            'Cutting images loaded in memory into.');
        YProfilPlatte = CutRiv(YProfilPlatte,nCuts);                        %cut it and save
    end
    handles.statusbar.ProgressBar.setVisible(false);                        %hide progressbar
    handles.statusbar = statusbar(handles.figure1,...
        ['Fitting local profiles for all images ',...                       %updating the statusbar
        'loaded in memory']);
    resFitCell = FitProf(YProfilPlatte,Treshold,plateSize);                 %calculate the parameters of the normal distribution
    % !! This part of the code was NOT tested !!
else                                                                        %otherwise, i need to do this image from image...
    k = 1;l = 1;                                                            %auxiliary indexing variables
    for i = selIm                                                           %for all the selected images
        handles.statusbar = statusbar(handles.figure1,...
            ['Converting grayscale values into distaces ',...
            'for image %d of %d (%.1f%%)'],...                              %updating statusbar
            l,nImages,100*l/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(2*nImages);
        handles.statusbar.ProgressBar.setValue(k);
        tmpIM = {imread([subsImDir '/' imNames{i}])};                       %load image from substracted directory and save it as cell
        tmpIM = ImConv(tmpIM,EdgCoord,filmTh,RegressionPlate);              %convert the image grayscale values to distances
        tmpIM = imfilter(tmpIM{:},...                                       %use selected filter
            fspecial('disk',FilterSensitivity));
        k = k+1;                                                            %increase statusbar counter
        if nCuts ~= 0 || nCuts ~= EdgCoord(end)-EdgCoord(end-2)             %if the image is to be cutted before fitting
            tmpIM = CutRiv({tmpIM'},nCuts);                                 %cut it and save
            tmpIM = tmpIM{1}';                                              %dirty, dirty, dirty
        end
        handles.statusbar = statusbar(handles.figure1,...
            ['Fitting local profiles ',...
            'for image %d of %d (%.1f%%)'],...                              %updating statusbar
            l,nImages,100*l/nImages);
        handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
        handles.statusbar.ProgressBar.setMinimum(0);
        handles.statusbar.ProgressBar.setMaximum(2*nImages);
        handles.statusbar.ProgressBar.setValue(k);
        tempVar = FitProf({tmpIM'},Treshold,plateSize);                     %calculate the parameters of the normal distribution
        resFitCell{1}(l,:) = tempVar{1}(1,:);                               %resave obtained deltaZ
        resFitCell{2}(l,:) = tempVar{2}(1,:);                               %resave obtained deltaZ
        resFitCell{3}{l}   = tempVar{3};                                    %resave obtained goodness-of-fit
        k = k+1;l = l+1;                                                    %increase the counter and statusbar mover
    end
end

% if DNTLoadIM == 0                                                           %are all the data loaded?
%     handles.statusbar = statusbar(handles.figure1,...
%         ['Converting grayscale values into distances for all images ',...   %updating th statusbar
%         'loaded in memory']);
%     YProfilPlatte = ImConv(daten(selIm),EdgCoord,filmTh,RegressionPlate);   %I can process all the loaded and chosen images at once
%     tmpCell = cell(1,nImages);                                              %create empty cell with number of elements corresponding to nImages
%     tmpCell(:) = {fspecial('disk',FilterSensitivity)};
%     YProfilPlatte = cellfun(@imfilter,YProfilPlatte,...                     %apply selected filter to YProfilPlatte
%         tmpCell,'UniformOutput',0);
%     parfor i = 1:numel(selIm)
%         tmpCell(i) = {[smImDir '/' imNames{i}]};                            %create second argument for cell function 
%     end
%     handles.statusbar.ProgressBar.setVisible(false);                        %hide progressbar
%     handles.statusbar = statusbar(handles.figure1,...
%         ['Fitting local profiles for all images ',...                       %updating the statusbar
%         'loaded in memory']);
%     set(handles.statusbar,'Text','Saving smoothed images');
%     cellfun(@imwrite,YProfilPlatte,tmpCell);                                %write images into smoothed folder (under original names)
% else                                                                        %otherwise, i need to do this image from image...
%     mkdir(tmpfDir);                                                         %I need to create directory for temporary files
%     k = 1;l = 1;                                                            %auxiliary indexing variables
%     for i = selIm                                                           %for all the selected images
%         handles.statusbar = statusbar(handles.figure1,...
%             ['Converting grayscale values into distaces ',...
%             'for image %d of %d (%.1f%%)'],...                              %updating statusbar
%             l,nImages,100*l/nImages);
%         handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
%         handles.statusbar.ProgressBar.setMinimum(0);
%         handles.statusbar.ProgressBar.setMaximum(2*nImages);
%         handles.statusbar.ProgressBar.setValue(k);
%         tmpIM = {imread([subsImDir '/' imNames{i}])};                       %load image from substracted directory and save it as cell
%         tmpIM = ImConv(tmpIM,EdgCoord,filmTh,RegressionPlate);              %convert the image grayscale values to distances
%         tmpIM = imfilter(tmpIM{:},...                                       %use selected filter
%             fspecial('disk',FilterSensitivity));
%         k = k+1;                                                            %increase statusbar counter
%         handles.statusbar = statusbar(handles.figure1,...
%             ['Fitting local profiles ',...
%             'for image %d of %d (%.1f%%)'],...                              %updating statusbar
%             l,nImages,100*l/nImages);
%         handles.statusbar.ProgressBar.setVisible(true);                     %showing and updating progressbar
%         handles.statusbar.ProgressBar.setMinimum(0);
%         handles.statusbar.ProgressBar.setMaximum(2*nImages);
%         handles.statusbar.ProgressBar.setValue(k);
%         tempVar = FitProf({tmpIM'},Treshold,plateSize);                     %calculate the parameters of the normal distribution
%         resFitCell{1}(l,:) = tempVar{1}(1,:);                               %resave obtained deltaZ
%         resFitCell{2}(l,:) = tempVar{2}(1,:);                               %resave obtained deltaZ
%         resFitCell{3}{l}   = tempVar{3};                                    %resave obtained goodness-of-fit
%         imwrite(tmpIM,[smImDir '/' imNames{i}]);                            %save it into 'Smoothed' folder (but under original name)
%         save([tmpfDir '/' imNames{i}(1:end-4) '.mat'],'tmpIM');             %save obtained data matrix into temporary directory
%         k = k+1;l = l+1;                                                    %increase the counter and statusbar mover
%     end
% end
% rmdir(tmpfDir,'s')

% update statusbar
handles.statusbar = statusbar(handles.figure1,...
            'Program run ended succesfully');
        
% enable buttons for results overview and export
set([handles.plotResButton ...
     handles.plotFitButton],'Enable','on')
 
% fil in the uitables with results
ColNames = imNames(selIm);                                                  %initialize the variable for column names
DataDelta= resFitCell{1}';                                                  %gather the data for tables
DataMFit = resFitCell{2}';
set(handles.deltaTable,'Data',DataDelta,'ColumnName',ColNames,...           %fill the tables
    'ColumnWidth',{100});
set(handles.mFitTable,'Data',DataMFit,'ColumnName',ColNames,...
    'ColumnWidth',{100});
 
% get the results and save them into handles
handles.metricdata.resFitCell = resFitCell;
handles.metricdata.selImU     = handles.metricdata.selIm;                   %save used images
guidata(hObject,handles);

% disable the cancel button
% set(handles.cancelButton,'Enable','off')
end


% --- Executes on button press in exitButton.
function cancelButton_Callback(~, ~, ~)
% hObject    handle to exitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


end


% --- Executes on button press in exitButton.
function exitButton_Callback(hObject, eventdata, handles)
% hObject    handle to exitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.figure1);                                                     %call closing function
end


% --- Executes on button press in expDeltaChBox.
function expDeltaChBox_Callback(hObject, eventdata, handles)
% hObject    handle to expDeltaChBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of expDeltaChBox

handles.prgmcontrol.expDelta = get(hObject,'Value');                        %get toggle state

% get state of the other buttons
expDelta = handles.prgmcontrol.expDelta;
expMFit  = handles.prgmcontrol.expMFit;
expGOF   = handles.prgmcontrol.expGOF;

if sum([expDelta expMFit expGOF]) > 0 && ...                                %if at least 1 checkbox is checked
        isfield(handles.metricdata,'resFitCell') == 1                       %and some results are availible 
    set(handles.expDataButton,'Enable','on');                               %enable exp. data button
else
    set(handles.expDataButton,'Enable','off');                               %otherwise disable it
end

guidata(hObject,handles);                                                   %update handles
end


% --- Executes on button press in expFitChBox.
function expFitChBox_Callback(hObject, eventdata, handles)
% hObject    handle to expFitChBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of expFitChBox

handles.prgmcontrol.expGOF = get(hObject,'Value');                         %get toggle state

% get state of the other buttons
expDelta = handles.prgmcontrol.expDelta;
expMFit  = handles.prgmcontrol.expMFit;
expGOF   = handles.prgmcontrol.expGOF;

if sum([expDelta expMFit expGOF]) > 0 && ...                                %if at least 1 checkbox is checked
        isfield(handles.metricdata,'resFitCell') == 1                       %and some results are availible 
    set(handles.expDataButton,'Enable','on');                               %enable exp. data button
else
    set(handles.expDataButton,'Enable','off');                               %otherwise disable it
end

guidata(hObject,handles);                                                   %update handles
end


% --- Executes on button press in expMChBox.
function expMChBox_Callback(hObject, eventdata, handles)
% hObject    handle to expMChBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of expMChBox

handles.prgmcontrol.expMFit = get(hObject,'Value');                         %get toggle state

% get state of the other buttons
expDelta = handles.prgmcontrol.expDelta;
expMFit  = handles.prgmcontrol.expMFit;
expGOF   = handles.prgmcontrol.expGOF;

if sum([expDelta expMFit expGOF]) > 0 && ...                                %if at least 1 checkbox is checked
        isfield(handles.metricdata,'resFitCell') == 1                       %and some results are availible 
    set(handles.expDataButton,'Enable','on');                               %enable exp. data button
else
    set(handles.expDataButton,'Enable','off');                               %otherwise disable it
end

guidata(hObject,handles);                                                   %update handles
end

function nCutsEdit_Callback(hObject, ~, handles)
% hObject    handle to nCutsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nCutsEdit as text
%        str2double(get(hObject,'String')) returns contents of nCutsEdit as a double

handles.metricdata.RivProcPars{5} = str2double(get(hObject,'String'));      %get number of cuts

guidata(hObject,handles);                                                   %update handle
end


% --- Executes during object creation, after setting all properties.
function nCutsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nCutsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

%% Data processing - calculation

%% Function to convert gray values ​​in distances
% Is required for the image and the regression coefficients of quadratic regression
% 21/11/2011, rewritten July 2012, by Martin Isoz
% 29/01/2013 simplified for use in the normDistParsFit.m function by Martin
% Isoz (there are no graphic outputs needed)

function ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree)
%
%   ImgConv = ImConv(ImData,EdgCoord,filmTh,RegDegree,...
%    GR,GRregime,GRformat,txtPars,storDir,rootDir,[imNumber])
%
% function for conversion images from grayscale to distances using
% polynomial regression with polynomial of degree specified in RegDegree
%
% INPUT variables
% ImData    ... images of the plate (in form of matrix)to be converted,cell
% EdgCoord  ... coordinates of section edges of the plate(plate, cuvettes),
%               pixels/indexes, matrix (1 x 10)
% filmTh    ... film thickness, in mm + width of cuvettes in pixels
%               [maxCuvette1 minCuvette1 maxCuvette2 minCuvette2 CuvWidth]
% RegDegree ... degree of polynomial used for the regression
%
% OUTPUT variebles
% ImgConv   ... converted image, gray values -> local heights of the riv,
%               in mm
%
% !! at the time, the BIG cuvette is NOT used !!

% for all the images
ImgConv     = cell(1,numel(ImData));                                        %preallocation of output variable
% read coordinates of the cuvettes and plate on each image
% small cuvette
xoS = EdgCoord(1);                                                          %mean  x-Value
yoS = EdgCoord(2);                                                          %top y-Value
yuS = EdgCoord(3);                                                          %bottom y-Value
%     % big cuvette        BIG CUVETTE NOT USED
%     xoB = EdgCoord(4);
%     yoB = EdgCoord(5);
%     yuB = EdgCoord(6);
% plate
xol = EdgCoord(7);                                                          %left x-Value
yol = EdgCoord(8);                                                          %top  y-Value
xur = EdgCoord(9);                                                          %right x-Value
yur = EdgCoord(10);                                                         %bottom y-Value

% prepare cuvette calibration
XS  = linspace(filmTh(1),filmTh(2),yuS-yoS+1)';                             %thickness of the film in mm small cuvette
% XB  = linspace(filmTh(3),filmTh(4),yuB-yoB+1)';                           %thickness of the film in mm big cuvette
CW  = filmTh(5)/2;                                                          %cuvette width/2
    
% for each image
parfor i = 1:numel(ImData)                                                     %for each file
    % load i-th image
    Image = ImData{i};                                                      %temporary variablefor each image
    % find mean grayscale value for each row of the cuvette
    YS   = mean(Image(yoS:yuS,xoS-CW:xoS+CW),2);
%     YB   = mean(Image(yoB:yuB,xoB-CW:xoB+CW),2);
    % combine grayscale value and film thickness into 1 matrix
    CuvetteS  =[YS XS];                                                     %Y ... brightness, X ... height of liquid
% 	CuvetteB  =[YB XB];                                                     %calibration data for image conversion
    
    Image   = double(Image(yol:yur,xol:xur));                               %reduce Image only to plate and convert to double
    tmpMatS = CuvetteS(50:end-50,:);                                        %cut off potentially strange values on sides
%     tmpMatB = CuvetteB(50:end-20,:);                                        %... brute and unelegant
    
    impS    = numel(tmpMatS(:,1));                                          %i must cheat matlab to polyfit through point (0,0) artificialy add
%     impB    = numel(tmpMatB(:,1));                                        % point (0,0) with the same importance as all other points together
    [RegS ErrorEstS]    = polyfit([tmpMatS(:,1);zeros(impS,1)],...
        [tmpMatS(:,2);zeros(impS,1)],RegDegree);                            %Regression small cuvette (with the point (0,0))
%     [RegB ErrorEstB]= polyfit(tmpMatB(:,1),tmpMatB(:,2),RegDegree);         %Regression big cuvette (without the point (0,0))
%     RegB = polyfit([tmpMatB(:,1);zeros(impB,1)],... BIG CUVETTE NOT USED
%         [tmpMatB(:,2);zeros(impB,1)],RegDegree);                          %Regression big cuvette (with the point (0,0)
%     % split image into 2 based on grayscale values and convert it to the
%     % distances separately BIG CUVETTE NOT USED
%     [rowSize colSize] = size(Image);                                        %save dimensions of the original image
%     ImgConv{i}(Image<=max(YS)) = polyval(RegS,Image(Image<=max(YS)));       %convert small values
%     ImgConv{i}(Image >max(YS)) = polyval(RegB,Image(Image >max(YS)));       %convert big values
%     ImgConv{i}        = reshape(ImgConv{i},rowSize,colSize);                %reshape the matrix into original dimensions
    ImgConv{i}  = polyval(RegS,Image);
%     ImgConv{i} = polyval(RegS,Image);                                       %original conversion command
end
end

%% Function for fitting the data
function resFitCell = ...
    FitProf(YProfilPlatte,Treshold,plateSize)
%
%   function resFitCell = ...
%          FitProf(YProfilPlatte,Treshold,plateSize)
%
% function for the rivulet interfacial area, width, height and borders
% calculation
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet, in mm
% Treshold          ... Treshold for finding ~ 0 values of the profile
%                       derivation, usually it is < 5e-5, so default value
%                       1e-3 is setted with big enough tollerance
% plateSize         ... size of the plate [width length], in m
%
% OUTPUT variables
% resFitCell        ... cell 3 x 1, first row containts matrix with
%                       the fitted parameters delta0[Z], m[Z], second the
%                       cells of structures with info about the
%                       goodnes-of-fit
%
% resFitCell:   +---------------------------------+
%               |           delta0Matrix          |
%               +---------------------------------+
%               |            mFitMatrix           |
%               +---------------------------------+
%               |       goodnes-of-fit cells      |
%               +---------------------------------+
%
% delta0Matrix: nImages x nRows cell,in each column, there is a vector with
% found maximal heights of the n-th profile of the rivulet
% mFitMatrix: nImages x nRows cell, in each column, there is a vector with
% fitted profile parameters (standard deviation in the normal probability
% distribution)
% goodness-of-fit cells: n x nImages cell, in each field, there is a
% structure with gof parameters as obtained from the FIT function
%
% Note: even if the algorithm is called only for 1 image, the YProfilPlatte
% variable has to be a cell
%
% to keep the axis marking
% X -> width of the plate, m
% Y -> height of the film
% Z -> length of the plate, m
%
% Note: the estimation of the rivulet extremities is based on the algorithm
% used in the RIVSURF function (see the RIVULETPROCESSING function), the
% used version of the algorithms is 'simple', which is also the preset
% version to be used in the RIVULETPROCESSING function. Please note that if
% you change the algorithm there (which will affect the Treshold), this
% algorithm could stop working
%
% -> advised values of treshold:
%    simple  algorithm: 5e-5;
%
% The profiles are fitted using the normal distribution on form:
%
%                          +       2   +
%                          |      x    |
% delta(x,z) = delta0(z)exp|- ---------|
%                          |          2|
%                          +   2*m(z)  +
%
% See also: FIT, FITTYPE, CFLIBHELP, RIVULETPROCESSING


% allocating space for variables
[m,n]        = size(YProfilPlatte{1});                                      %all the YProfilPlatte elements have the same size
nImages      = numel(YProfilPlatte);                                        %number of images to be processed
delta0Matrix = zeros(nImages,n);                                            %variable for rivulet height
mFitMatrix   = delta0Matrix;                                                %variable for storing the standard deviation parameter (fitted)
gofCell      = cell(nImages,n);                                             %variable for storing goodness-of-fit data

TrVec  = zeros(1,n);                                                        %background/noise liquid height
maxInd = TrVec;                                                             %index of the center of the plate

% for all the images
% calculating the deltaX (distance between 2 pixels)
deltaX  = plateSize(1)/m;                                                   %distance between 2 points on X-axis (in m)

% mean X coordinate of the pictures
IndXMean= round(m/2);                                                       %X coordinate of the plate center (horizontal)

% for each image
for i = 1:numel(YProfilPlatte) 
    YProfilPlatte{i} = YProfilPlatte{i}*1e-3;                               %mm -> m
    smtProf          = smooth(YProfilPlatte{i}(:),30);                      %smooth all the data at once
    smtProf          = reshape(smtProf,m,n);                                %reshape to the original size
    q025Mat          = quantile(smtProf,0.25);                              %calculate 25% quantile of the each column of smtProf
    for j = 1:n                                                             %for all the columns of YProfilPlatte (Z-coordinates)
        % find the maximal height of the rivulet in current YPP column
        tmpProf      = smtProf(:,j);q025Prof = q025Mat(j);                  %assign temporary profile and its lower quartile
        [~,IndX]     = findpeaks(tmpProf-q025Prof,'MinPeakHeight',...       %take into account only the actual height of the rivulet
            max(tmpProf-q025Prof)/2);
        IndX         = IndX(abs(IndX-IndXMean)==...
            min(abs(IndX-IndXMean)));                                       %take the first of the peaks nearest to the center of the plate
        if numel(IndX)>1,IndX=IndX(tmpProf(IndX)==max(tmpProf(IndX)));end   %if there is more than 1 index found, take the highest value
        delta0Matrix(i,j)=YProfilPlatte{i}(IndX,j);                         %save current rivulet height
        TrVec(j)     = q025Prof + Treshold;                                 %calculate treshold to be used
        tmpVecL      = tmpProf(1:IndX);                                     %left side of the SMOOTHED rivulet
        tmpVecR      = tmpProf(IndX+1:end);                                 %right side of the SMOOTHED rivulet
        tmpIndL      = max([1 find(tmpVecL <= TrVec(j),1,'last')]);         %find the last element lower then Treshold in L side of the rivulet
        tmpIndR      = min([find(tmpVecR <= TrVec(j),1,'first')+IndX...
            numel(tmpProf)]);                                               %find the first element lower then Treshold in R side of the rivulet
        TrVec(j)     = q025Prof;                                            %resave treshold for subtracting from profile
        maxInd(j)    = IndX;                                                %save the position of the profile maxima
        % save left and right side of the rivulet
        minLVec(i,j) = tmpIndL;
        minRVec(i,j) = tmpIndR;
    end
    % smooth the found rivulet edges - remove jumps in rivulet width
    % pictures are high-res enough not to contain any big jums in the
    % rivulet edges positions
    if n > 300
        minLVec(i,:) = round(smooth(minLVec(i,:),100));                     %values need to be rounded (they are indexes) -> integers
        minRVec(i,:) = round(smooth(minRVec(i,:),100));                     %n > 1600 (usually), so 100 neighbouring values isnt that many
    end
    % subtract the treshold from the current profile (it is a bacground
    % noise)
    TresholdC        = mean(TrVec);                                         %calculate mean value of the treshold/background liquid height
    YProfilPlatte{i} = YProfilPlatte{i} - TresholdC;                        %subtract it from the profile
    delta0Matrix(i,:)= delta0Matrix(i,:) - TresholdC;                       %subtract it from the rivulet Heights
    
    % walk through all the horizontal cut and fit the local profiles
    % Note: this is actually the new part of the code
    % Note: for each cut, the coordinate system has to be appropriately
    % modified at first
    
    ffunc = fittype('delta0*exp(-x.^2/(2*mZ^2))',...                        %create function to be fitted
        'coefficients','mZ',...                                             %coefficient to be fitted
        'independent','x',...                                               %independent variable
        'problem','delta0');                                                %problem-dependent parameter, max height of the cut
    
    for j = 1:n
        xVals = ((minLVec(i,j):minRVec(i,j))' - maxInd(j))*deltaX;          %move the center of the coordinate system to the max height of the riv.
        yVals = YProfilPlatte{i}(minLVec(i,j):minRVec(i,j),j);
        delta0= delta0Matrix(i,j);                                          %save the max height of the current profile
        
        % fit the date using the curve fitting toolbox
        if j > 1                                                            %use the info about previous fit as startpoint to the new one
            startPoint = mFitMatrix(i,j-1);
        else
            startPoint = 1e-3;
        end
        [cfun,gof] = fit(xVals,...                                          %xdata - created and transformed linspace
            yVals,...                                                       %ydata - current horizontal profile
            ffunc,'problem',delta0,'startpoint',startPoint);                %function to be fitted, problem dependent parameter and initial guess
        
        % get data from the fit
        mFitMatrix(i,j) = coeffvalues(cfun);                                %save fitted coefficient
        gofCell{i,j}    = gof;                                              %save the goodness-of-fit data
    end
    
    % smooth calculated data
    mFitMatrix(i,:) = smooth(mFitMatrix(i,:),100);
    
end
resFitCell = {delta0Matrix;mFitMatrix;gofCell};
end

function YProfilPlatte =...
    CutRiv(YProfilPlatte,nCuts)
%
%   [YProfilPlatte XProfilPlatte] =...
%       CutRiv(YProfilPlatte,nCuts)
%
% Clensed variant of the CutRiv function from rivuletProcessing program,
% this function does not contain any possibilities of graphic output.
%
% INPUT variables
% YProfilPlatte     ... variable with heights of the rivulet
% nCuts             ... number of cuts to make along the rivulet (scalar)
%
% OUTPUT variables
% YProfilPlatte     ... heights of the rivulet, reduced to mean values
%                       cell of matrixes (nPointsX x nCuts), mm
% XProfilPlatte     ... linspace coresponding to plate width, m
%

% for all the images, all the YProfilPlatte have the same size
Distance     = round(size(YProfilPlatte{1},2)/(nCuts+1));                   %number of points in each mean profile

% for each image
for i=1:numel(YProfilPlatte)
    for n = 2:nCuts-1
        if n*Distance-25 <= 0                                               %is there enough space at the beginning
            YProfilPlatte{i}(:,1) = mean(YProfilPlatte{i}...
                (:,1:n*Distance+25),2);
        elseif n*Distance+24 >= numel(YProfilPlatte{i}(1,:))                %is there enought space at the end
            YProfilPlatte{i}(:,nCuts) = mean(YProfilPlatte{i}...
                (:,n*Distance-25:end),2);
        else
            YProfilPlatte{i}(:,n)=mean(YProfilPlatte{i}...                      %create mean profiles in the place of the cut, over 50 pixels
            (:,n*Distance-25:n*Distance+25),2);
        end
    end
    YProfilPlatte{i}(:,nCuts) = mean(YProfilPlatte{i}...                    %for the last cut, there may be less than 50 pixels
            (:,n*Distance-25:end),2);
    YProfilPlatte{i} = YProfilPlatte{i}(:,1:nCuts)*1e-3;                    %need to change size of output matrix, mm -> m
%     !! all the functions are at the time working with height of the
%     rivulet in mm !!
    YProfilPlatte{i} = YProfilPlatte{i}*1e3;                                %plots in m, m -> mm
end
end
