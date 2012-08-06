function postProcPlotting(Availible)
%
%   function postProcPlotting(OUT)
%
% function for plotting calculated data (just for basic data overview).
% there is automatically created simple gui that offers user to plot
% selected data. In comparison with "Quick outputs overview" from the main
% gui, there are only few additional plotting possibilities
% 
% INPUT variables
% Availible   ... cell of structures obtained from rivuletProcessing.m


%% GUI preparation
PosVec = [10 30 1100 700];                                                  %position and the size of the window
appdata= struct('metricdata',[],'prgmcontrol',[]);                          %create data for gui
% create GUI elements
hFig    = figure('Units','Pixels','Position',PosVec,...
    'NumberTitle','off','Name','Post processing data plotting',...
    'DockControl','off',...
    'ResizeFcn',@MyResizeFcn,'Tag','MainWindow');                           %create figure window with specified size

% initialize appdata
appdata.prgmcontrol.comp = 0;                                               %for ListData, compatible data are not selected
guidata(hFig,appdata);                                                      %assign data to gui

% fill in initialize data
strCellGR = cell(1,numel(Availible));
parfor i = 1:numel(Availible)
    strCellGR{i} = Availible{i}.ID;
end
separators = {'-------' ' '};                                               %separators used in ListData

% create listboxes and their titles
ListGroup  = uicontrol(hFig, 'Style','listbox',...                          %create listbox for avalible data
    'String',strCellGR,'Callback',@ListGroup_Callback,...
    'Tag','ListGroup','Max',numel(strCellGR));                              %enable multiselect in listboxes
TextGroup = uicontrol(hFig,'Style','text',...                               %create text string
    'HorizontalAlignment','left',...
    'String','Choose data group:',...
    'Tag','TextGroup');

ListData  = uicontrol(hFig, 'Style','listbox',...                           %create listbox for chosing subdata
    'Tag','ListData','Callback',@ListData_Callback,...
    'Enable','off');                                                        %enable multiselect in listboxes
TextData = uicontrol(hFig,'Style','text',...                                %create text string
    'HorizontalAlignment','left',...
    'String','Select data:',...
    'Tag','TextData');

ListMsrt  = uicontrol(hFig, 'Style','listbox',...                           %create listbox for chosing measurements to plot
    'Tag','ListMsrt','Callback',@ListMsrt_Callback,...
    'Enable','off');                                                        %enable multiselect in listboxes
TextMsrt = uicontrol(hFig,'Style','text',...                                %create text string
    'HorizontalAlignment','left',...
    'String','Select variables to plot:',...
    'Tag','TextMsrt');

% create pushbuttons
PushPlot = uicontrol(hFig,'Style','pushbutton','Tag','PushPlot',...
    'String','Plot Selected','Callback',@PushPlot_Callback);
% create checkbox
CheckLink= uicontrol(hFig,'Style','checkbox','Tag','CheckLink',...
    'String','Link plot with table');
set(CheckLink,'Value',1);                                                   %check the checkbox by default
% create data table
TableData = uitable(hFig,'Tag','TableData');                                %create table for showing selected data


%% Creating callbacks

    function ListGroup_Callback(hObject,~,~)
        selGR = get(hObject,'Value');                                       %get selected value(s)
        % automatic creation of the content of ListData
        % all data structures have the same fields
        strCellDT  = fieldnames(Availible{1});                              %get fieldnames of structures
        % get rid of auxiliary data fileds
        strCellDT  = strCellDT(strcmp(strCellDT,'ID') == 0);                %get rid of ID field
        strCellDT  = strCellDT(strcmp(strCellDT,'imNames') == 0);           %get rid of imNames field
        strCellDT  = strCellDT(strcmp(strCellDT,'plateSize') == 0);         %get rid of plateSize field
        % set string in ListData
        set(ListData,'Max',numel(strCellDT),'String',strCellDT);            %fill in list box and allow selection of all the strings
        set(ListData,'Enable','on');                                        %enable filled list for chosing
        set(ListMsrt,'Enable','off','Value',[]);                            %disable list which is yet to be filled
        % updating application data
        appdata.metricdata.strCellDT = strCellDT;                           %assign variables to appdata
        appdata.prgmcontrol.selGR    = selGR;
        appdata.prgmcontrol.comp     = 0;                                   %all data are restored, set selected compatible crit. to 0
        guidata(hFig,appdata);                                              %update appdata
    end
    function ListData_Callback(hObject,~,~)
        % actualize list according to selection
        appdata = guidata(hObject);                                         %get app data
        strCellDT = appdata.metricdata.strCellDT;
        comp      = appdata.prgmcontrol.comp;                               %are the compatible data selected yet
        selDT = get(hObject,'Value');                                       %get selected value(s)
        if numel(selDT) == 1 && comp == 0                                   %check for length of the selection for strcmp
            set(ListData,'Value',1);                                        %if it rest only single selection listbox, select the only option
            if strcmp(strCellDT{selDT},'Profiles') == 1                     %actualize listbox selection to show compatible data
                strCellNDT = strCellDT(strcmp(strCellDT,'Profiles')==1);    %reduce only to profiles
                appdata.prgmcontrol.comp = 1;                               %store info about choosing compatible data
                appdata.prgmcontrol.shTable = 'Profiles';                   %store info about choosed data
                guidata(hObject,appdata);
            elseif strcmp(strCellDT{selDT},'IFACorr') == 1
                strCellNDT = strCellDT(strcmp(strCellDT,'IFACorr')==1);     %reduce only to interfacial area correlation data
                appdata.prgmcontrol.comp = 1;                               %store info about choosing compatible data
                appdata.prgmcontrol.shTable = 'IFACorr';                    %store info about choosed data
                guidata(hObject,appdata);
            else
                strCellNDT = strCellDT(strcmp(strCellDT,'Profiles') == 0&...%get rid of profiles and IFACorr
                    strcmp(strCellDT,'IFACorr') == 0);
                appdata.prgmcontrol.comp = 1;                               %store info about choosing compatible data
                appdata.prgmcontrol.shTable = 'Other';                      %store info about choosed data
                guidata(hObject,appdata);
                set(ListData,'Value',[]);                                   %unselect all
            end
            set(ListData,'String',strCellNDT,'Max',numel(strCellNDT));      %update list content (leave only compatible data)
            appdata.metricdata.strCellDT = strCellNDT;
            guidata(hObject,appdata);
        end
        % fill in table accordingly to selected data
        strCellDT = appdata.metricdata.strCellDT;
        if comp == 1                                                        %this case occurs if there are only compatible data present in listbox
            selGR = appdata.prgmcontrol.selGR;                              %selected groups
            plateSize = zeros(numel(selGR),2);                              %preallocate variable for plateSizes
            for j = 1:numel(selGR)                                          %for all selected groups
                k = selGR(j);
                plateSize(k,:) = Availible{k}.plateSize;                    %save plate size for selected groups
                for l = 1:numel(selDT)                                      %for all selected datas
                    m = selDT(l);
                    dataSH{j,l} = Availible{k}.(strCellDT{m});              %save all data to be ploted into 1 cell, row -> group, column ->msrmt
                end
            end
            % automatic creation of the content of ListMsrt
            shTable  = appdata.prgmcontrol.shTable;                         %variable defining the regime/type of shown data
            stInd    = ones(1,numel(selGR)+1);                              %variable for storing length of selected data
            strCellMS= {};                                                  %prepare empty cell
            for j = 1:numel(selGR)                                          %for all selected groups
                k = selGR(j);                                               %idex of the selected group
                switch shTable
                    case 'Profiles'                                         %profiles are to be shown
                        imNames = Availible{k}.imNames;                     %names of the measurements to show ~ names of the images
                        stInd(j+1)  = stInd(j) + numel(imNames);            %starting position of the next data group
                        for l = 1:numel(imNames)
                            imNames{l} = imNames{l}(1:end-4);               %get rid of the file suffix
                        end
                        strCellMS = [strCellMS strCellGR(k) separators(1)...
                            imNames separators(2)];
                        set(ListMsrt,'Enable','on');
                    case 'IFACorr'                                          %correlations are to be shown
                        strCellMS = [strCellMS strCellGR(k) separators(1)...
                            'IFACorr' separators(2)];
                        stInd(j+1) = stInd(j) + 1;                          %only IFACorr in the group, dont need the last listbox
                        fillIFACorrUITable(TableData,dataSH);
                    case 'Other'                                            %mSpeed, rivWidth and/or rivHeight are to be shown
                        Msrt = dataSH{j}{end};                              %get list of regimes saved into 'other' variables
                        strCellMS = [strCellMS strCellGR(k) separators(1)...
                            Msrt separators(2)];
                        stInd(j+1) = stInd(j) + numel(Msrt);
                        set(ListMsrt,'Enable','on');
                end
            end
            set(ListMsrt,'Max',numel(strCellMS),'String',strCellMS,...
                'Value',[]);
            % update appdata
            appdata.metricdata.strCellMS = strCellMS;                       %save string displayed into ListMsrt
            appdata.metricdata.dataSH    = dataSH;                          %save data to be shown into uitable
            appdata.metricdata.stInd     = stInd;                           %save starting position of new groups
            appdata.metricdata.plateSize = plateSize;                       %save concerning plate sizes into appdata
            guidata(hObject,appdata);
        end
    end
    function ListMsrt_Callback(hObject,~,~)
        appdata = guidata(hObject);                                         %get application data
        % extract variables from appdata
        shTable = appdata.prgmcontrol.shTable;                              %type of data to be shown
        dataSH  = appdata.metricdata.dataSH;                                %data to be shown
        strCellMS=appdata.metricdata.strCellMS;                             %cell of strings shown into the ListMsrt
        stInd   = appdata.metricdata.stInd;
        % get selected
        selMS   = get(hObject,'Value');
        selMST  = selMS;
        tmpVar  = ones(1,numel(selMS));
        for j = 1:numel(selMS)
            if sum(strcmp(strCellMS{selMS(j)},...                           %compare string with descriptors and separators
                    [strCellGR separators])) ~= 0                           %current string is a separator or descriptor
                tmpVar(j) = 0;                                              %if its a separator, replace 1 in tmpVar by 0
            end
        end
        if isempty(tmpVar(tmpVar~=0)) == 1                                  %if all selected are separators, issue errordlg
            errordlg('You must choose data, not separators');
            return
        end
        for j = 1:max(selMS)                                                %for all strings until max. selected object
            if sum(strcmp(strCellMS{j},...                                  %compare string with descriptors and separators
                    [strCellGR separators])) ~= 0                           %current string is a separator or descriptor
                selMST(selMS>=j) = selMST(selMS>=j)-1;                      %if its a separator, reduce all the following indexes by 1
            end
        end
        selMS = unique(selMST(selMST~=0));                                  %convert selected to valid indexes
        for j = 2:numel(stInd)
            GR{j-1} = selMS(selMS<stInd(j)&selMS>=stInd(j-1))-stInd(j-1)+1; %categorize data into groups and transform indexes to gr. indexes
        end
        GRInd  = find(cellfun(@isempty,GR)==0);                             %find position of non-empty groups
        GR     = GR(GRInd);                                                 %left out empty groups
        tmpVar = {};
        l      = 1;
        assignin('base','GR',GR)
        assignin('base','GRInd',GRInd)
        assignin('base','stInd',stInd)
        for j = 1:numel(GR)
            for k = 1:size(dataSH,2)
                tmpVar{l} = dataSH{GRInd(j),k}(GR{j});                      %reduce data to show only to selected
                l = l+1;
            end
        end
        dataSH = tmpVar;clear('tmpVar')
        switch shTable
            case 'Profiles'
                plateSize = appdata.metricdata.plateSize;
                fillProfilesUITable(TableData,dataSH,plateSize);            
            case 'Other'
                fillOtherUITable(TableData,dataSH);
                
        end
    end
    function PushPlot_Callback(hObject,~,~)
        shTable = appdata.prgmcontrol.shTable;
        selGR   = appdata.prgmcontrol.selGR;                                %selected data groups
        Data = get(TableData,'UserData');                                   %get data from the table
        hPlotFig= figure('Units','Pixels','Position',[10 10 1100 700],...
            'UserData',Data);                                               %save data into handles of figure, for later use
        hAxes   = axes('OuterPosition',[0 0.1 1 0.9],'Tag','hAxes');
        % extract handles from hObject
        Children = get(hObject,'Children');                                 %get uicontrol and axes of the resized figure
        parfor j = 1:numel(Children)
            Tag = get(Children(j),'Tag');                                   %get tag property of every child
            switch Tag
                case 'TableData'
                    TableData = Children(j);
                case 'ListGroup'
                    ListGroup = Children(j);
                case 'ListData'
                    ListData = Children(j);
                case 'ListMsrt'
                    ListMsrt = Children(j);
                case 'TextGroup'
                    TextGroup = Children(j);
                case 'TextData'
                    TextData = Children(j);
                case 'TextMsrt'
                    TextMsrt = Children(j);
                case 'PushPlot'
                    PushPlot = Children(j);
                case 'CheckLink'
                    CheckLink = Children(j);
            end
        end
        clear('Children');
        switch shTable
            case 'Profiles'
            case 'IFACorr'
                uicontrol(hPlotFig,'Style','popupmenu',...
                    'String',['Dimensionless liquid flow rate|'...
                    'Volumetric gas flow rate'],...
                    'Units','Normal',...
                    'Callback',@PopUpXAxsCorr_Callback,...
                    'Position',[0.3 0.01 0.4 0.08],'Value',1);              %create popup menu for choosing x axes
                brks = [1 find(diff(Data(:,4))<0)+1 numel(Data(:,4))];      %indexes of new data starts
                hold(hAxes,'on');
                for j = 1:numel(brks)-1
                    hPlot(j) = plot(hAxes,Data(brks(j):brks(j+1),4),...
                        Data(brks(j):brks(j+1),end),'^');
                    set(hPlot(j),'Color',rand(1,3));
                end
                title(hAxes,['\bf Interfacial area as fun. of '...
                    'dimensionless liq. flow rate'],'FontSize',13);
                xlabel(hAxes,'dimensionless flow rate, [-]');
                ylabel(hAxes,'interfacial area of the rivulet, [m^2]');
                set(hPlot,'MarkerSize',10);
                % create leged entries (ID strings of data groups)
                legendCellStr = {};
                for j = 1:numel(selGR)
                    legendCellStr{j} = Availible{selGR(j)}.ID;
                end
                legend(hAxes,legendCellStr,'Location','Best',...
                    'Interpreter','none');
            case 'Other'
        end
    end
    function CheckLink_Callback(hObject,~,handles)
    end
    function PopUpXAxsCorr_Callback(hObject,~,~)
        Parent = get(hObject,'Parent');                                     %get parent of uicontrol
        Data   = get(Parent,'UserData');                                    %get data from the table
        contents = cellstr(get(hObject,'String'));
        xAxes    = contents{get(hObject,'Value')};                          %get selected value from popmenu
        Children = get(Parent,'Children');                                  %get children of parent -> axes that need to be set up
        for j = 1:numel(Children)
            Tag = get(Children(j),'Tag');                                   %get tag property of every child
            switch Tag
                case 'hAxes'
                    hAxes = Children(j);
                case 'legend'
                    lgstr = get(Children(j),'UserData');                    %get user data from legend - in lstrings are saved legend entries
                    lgstr = lgstr.lstrings;
            end
        end
        clear('Children');
        switch xAxes
            case 'Dimensionless liquid flow rate'
                indX = 4;                                                   %column index of x-data in table
                ttlStr = ['\bf Interfacial area as fun. of '...
                    'dimensionless liq. flow rate'];
                xlblStr= 'dimensionless liq. flow rate, []';
            case 'Volumetric gas flow rate'
                indX = 6;                                                   %column index of x-data in table
                ttlStr = ['\bf Interfacial area as fun. of '...
                    'volumetric gas flow rate'];
                xlblStr= 'volumetric gas flow rate, [m^3/s]';
        end
        brks = [1 find(diff(Data(:,4))<0)+1 numel(Data(:,4))];              %indexes of new data starts
        cla(hAxes);                                                         %clear axes for the new plot
        hold(hAxes,'on');
        for j = 1:numel(brks)-1
            hPlot(j) = plot(hAxes,Data(brks(j):brks(j+1),indX),...
                Data(brks(j):brks(j+1),end),'^');
            set(hPlot(j),'Color',rand(1,3));
        end
        title(hAxes,ttlStr,'FontSize',13);
        xlabel(hAxes,xlblStr);
        ylabel(hAxes,'interfacial area of the rivulet, [m^2]');
        set(hPlot,'MarkerSize',10);
        legend(hAxes,lgstr,'Location','Best',...
                    'Interpreter','none');
    end

end

%% Resize function
function MyResizeFcn(hObject,~)
%
%   function MyResizeFcn(hObject,evendata)
%
% function for keeping uicontrol sizes ratio when resizing figure
%

% extract variables from hObject
Children = get(hObject,'Children');                                         %get uicontrol and axes of the resized figure
for i = 1:numel(Children)
   Tag = get(Children(i),'Tag');                                            %get tag property of every child
   switch Tag
       case 'TableData'
           TableData = Children(i);
       case 'ListGroup'
           ListGroup = Children(i);
       case 'ListData'
           ListData = Children(i);
       case 'ListMsrt'
           ListMsrt = Children(i);
       case 'TextGroup'
           TextGroup = Children(i);
       case 'TextData'
           TextData = Children(i);
       case 'TextMsrt'
           TextMsrt = Children(i);
       case 'PushPlot'
           PushPlot = Children(i);
       case 'CheckLink'
           CheckLink = Children(i);
   end
end
clear('Children');

% get actual figure size
set(hObject,'Units','Pixels');
PosVec = get(hObject,'Position');

% prepare positioning data
listWidth = 150;                                                            %width of the lists in pixels
pushWidth = 100;                                                            %width of pushbutton
checkWidth= 2*listWidth-pushWidth;                                          %width of checkbox
pushHeight= 30;                                                             %height of the pushbutton
grLeftX   = 20;                                                             %distance of the listboxes from left edge of the figure window, pixels
grTopY    = 20;                                                             %distance of the listboxes from the top edge of the fig., pixels
grBotY    = 20;                                                             %distance of the listboxes from the bottom edge of the fig., pixels
gapX      = 20;                                                             %horizontal and vertical gap between listboxes
gapY      = 10;

heightText= 20;                                                             %height of text fields
heightAv  = PosVec(4) - (grTopY + grBotY);                                  %availible height
coef = (heightAv - 2*heightText - 4*gapY - pushHeight)/(3*heightAv);        %find coefficient for multipliing the height of listboxes
height1   = max([heightAv*2*coef 20]);                                      %height of the first listbox, min 20 pixels
height2   = max([heightAv*coef 40]);                                        %height of the second listbox, min 20 pixels
height3   = height1 + height2 + heightText + 2*gapY;                        %height of the third listbox

% horizontal coordinates
Hpos1     = grLeftX;
Hpos2     = Hpos1;
Hpos3     = grLeftX + listWidth + gapX;
Htble     = Hpos3 + listWidth + gapX;
Hpush     = Hpos1;
% vertical coordinates
Vpos2     = grBotY + pushHeight + gapY;                                     %vertical position of the second listbox
Vpos3     = Vpos2;                                                          %second and third listboxes have the same vertical position
Vpos1     = Vpos2 + height2 + gapY + heightText + gapY;                     %vertical position of the first listbox
Vpush     = grBotY;

% scale ui elements
% scale listboxes and texts
set(ListGroup,'Position',[Hpos1 Vpos1 listWidth height1]);
set(ListData, 'Position',[Hpos2 Vpos2 listWidth height2]);
set(ListMsrt, 'Position',[Hpos3 Vpos3 listWidth height3]);
set(TextGroup,'Position',[Hpos1 Vpos1+height1+gapY listWidth heightText]);
set(TextData, 'Position',[Hpos2 Vpos2+height2+gapY listWidth heightText]);
set(TextMsrt, 'Position',[Hpos3 Vpos3+height3+gapY listWidth heightText]);
% position pushbutton and checkbox
set(PushPlot, 'Position',[Hpush Vpush pushWidth pushHeight]);
set(CheckLink,'Position',[Hpush+pushWidth+gapY Vpush...
    checkWidth pushHeight]);
% fill remaining place with axes
set(TableData,'Units','Pixels',...
    'Position',[Htble 0,...
    max([PosVec(3)-Htble 20]) max([PosVec(4) 20])]);

end

%% Filling in the table
function fillProfilesUITable(hTable,dataSH,plateSize)
% all the profiles have different width - number of cuts and different
% length - max width of the rivulet=>
%=>I must discover number of cuts for each variable/picture
%=>I must rearrange profiles accordingly to place where they were taken

% creating column names for uitable
nCuts = zeros(1,numel(dataSH));                                             %numbers of cuts throught the rivulet
dTops = cell(1,numel(dataSH));                                              %distances from the top of the plate
parfor i = 1:numel(dataSH)
    nCuts(i) = size(dataSH{i}{1},2)/2;                                      %nCuts -> nCols/2
    dTops{i} = (1:nCuts(i)) * plateSize(i,2)/(nCuts(i)+1)*1e3;
end
dTopsU = unique(cell2mat(dTops));                                           %convert cell to double and left out repeting values
for i = 1:numel(dTopsU)
    ColNames{2*i-1} = ['Cut at ' num2str(dTopsU(i),'%3.1f') ' mm|X, [m]'];
    ColNames{2*i}   = ['Cut at ' num2str(dTopsU(i),'%3.1f') ' mm|Y, [m]'];
end
assignin('base','dataSH',dataSH)
% filling the data table
Data    = [];
DataClr = [];
dTopsB  = sort([dTopsU dTopsU]);
color   = {'0000FF' '00C100'};
for i = 1:numel(dataSH)                                                     %for all selected groups
    IndCol = zeros(numel(dTops{i}),2);
    for j = 1:numel(dTops{i})
        IndCol(j,:) = find(dTopsB == dTops{i}(j));                          %find indexes of columns to write in for actual group
    end
    IndCol = sort(reshape(IndCol,1,[]));                                    %reshape indexing matrix to row vector
    for j = 1:numel(dataSH{i})                                              %for all selected profiles in the group
        tmpMat = zeros(size(dataSH{i}{j},1),sum(nCuts)*2);                  %create matrix of zeros
        tmpMat(:,IndCol) = dataSH{i}{j};
        Data   = [Data;tmpMat];                                             %create data
        tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))),...           %double -> cell of strings
            size(tmpMat));
        for k = 1:numel(tmpMat)
            tmpMat(k) = strcat(['<html><span style="color: #' ...
            color{mod(j+i,2)+1} '; font-weight: normal;">'], ...
            tmpMat(k), ...
            '</span></html>');
        end
        DataClr= [DataClr;tmpMat];
    end
end
set(hTable,'ColumnName',ColNames,'ColumnWidth',{110},...
    'Data',DataClr,'UserData',Data);
end

function fillIFACorrUITable(hTable,dataSH)
% all the correlation variables have the same number of columns, they
% differs only in number of rows - number of images for the experiment

ColNames = {'Surface tension,|[N/m]',...                                    %set up ColNames for correlation data
        'Density,|[kg/m3]','Viscosity,|[Pa s]',...
        'Dimensionless,|flow rate, [-]','Plate incl.|angle,[deg]',...
        'Vol. gas flow|rate, [m3/s]','Riv. surface|area, [m2]'};
% creating data matrix to show
Data    = [];
DataClr = [];
color   = {'0000FF' '00C100'};
for i = 1:numel(dataSH)
    % adding i-th dataset to data matrix to show
    Data = [Data;dataSH{i}];
    % coloring data matrix - each dataset has its own color
    tmpMat = reshape(strtrim(cellstr(num2str(dataSH{i}(:)))),...
        size(dataSH{i}));                                                   %convert data to cell of strings
    for j = 1:numel(tmpMat)
        tmpMat(j) = strcat(...                                              %modify format of the problematic value
            ['<html><span style="color: #' ...
            color{mod(i,2)+1} '; font-weight: normal;">'], ...
            tmpMat(j), ...
            '</span></html>');
    end
    DataClr = [DataClr;tmpMat];
end
set(hTable,'Data',DataClr,'ColumnName',ColNames,'UserData',Data,...
    'ColumnWidth',{100});
end

function fillOtherUITable(hTable,dataSH)
% other data can differ from one experiment to another in both width and
% length of data. Length is specified by number of cuts made and width by
% number of images for each regime =>
%=> I should name columns after measurement number
%=> Find all unique column names and sort them in ascending order
%=> For all datasets, locate data into appropriate column (leave all the
%   other columns blank)
%=> 1 of the inputs has to be plateSize (in m), double nSelx2, for each
%   experiment

% find maximal number of measurements for each dataset
numMS   = zeros(1,numel(dataSH));
nCuts   = numMS;
parfor i = 1:numel(dataSH)                                                  %for all data
    nCuts(i) = size(dataSH{i}{1},1);                                        %number of cuts in i-th measurement
    numMS(i) = size(dataSH{i}{1},2)-6;                                      %for all data in 1 measurement, the number of images is the same
end                                                                         %last 6 columns are added data, not measurements
ColNames = 1:max(numMS);                                                    %need space for all the data
ColNames = reshape(strtrim(cellstr(num2str(ColNames(:)))), size(ColNames)); %vector -> cell of strings
ColNames = [ColNames {'' 'Mean|value' 'Standard|deviation'...               %add names for last 6 columns
    'Dimensionless|flow rate, [-]' 'Vol. gas flow|rate, [m3/s]',...
    'Distance from|plate top, [m]'}];
% prepare data to be shown
Data = [];
DataClr = [];
for i = 1:numel(dataSH) %#ok<FORPF>
    nZeros = max(numMS) - numMS(i);                                         %number of zeros is difference between maximal and actual n of measur.
    for j = 1:numel(dataSH{i})
        switch mod(i,3)+1                                                   %create colors for the data
            case 1
                color = 'FF0000';
            case 2
                color = '00C100';
            case 3
                color = '0000FF';
        end
        tmpMat = [dataSH{i}{j}(:,1:numMS(i)) ...                            %current data + added zero columns
            zeros(nCuts(i),nZeros) dataSH{i}{j}(:,numMS(i)+1:end)];
        Data = [Data;tmpMat];                                               %add current data to Data
        tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))),...
            size(tmpMat));                                                  %convert data to cell of strings
        for k = 1:numel(tmpMat)
            tmpMat(k) = strcat(...                                          %modify format of the problematic value
                ['<html><span style="color: #' ...
                color '; font-weight: normal;">'], ...
                tmpMat(k), ...
                '</span></html>');
        end
        DataClr = [DataClr;tmpMat];
    end
end
set(hTable,'ColumnName',ColNames,'Data',DataClr,'ColumnWidth',{100},...
    'UserData',Data);
    
end

% nested functions for callbacks
function hTableSelectionCallback(hTable,eventdata)
%
% selection callback function for hTable created by showOtherDataUITable
%
% if a row/vector is selected, it will be ploted in axes

% hmkrs are handles to lines
set(hmkrs, 'Visible', 'off')                                                % turn them off to begin

% Get the list of currently selected table cells
sel = eventdata.Indices;                                                    % Get selection indices (row, col)
% Noncontiguous selections are ok
selcols = unique(sel(:,2));                                                 % Get all selected data col IDs
table = get(hTable,'Data');                                                 % Get copy of uitable data
if max(selcols) > numel(table(1,:)) - 3
    errordlg({['Flow rates and distance from the top of the plate are '...
        'not plotable.'] 'Please select different columns'})
else
    %Get vectors of x,y values for each column in the selection;
    for idx = 1:numel(selcols)
        col = selcols(idx);
        xvals = sel(:,1);
        xvals(sel(:,2) ~= col) = [];
        yvals = table(xvals, col)';
        xvals = data(xvals,1);  %end->1                                     %select x-values from data table - distance from the top of the plate
        % Create Z-vals = 1 in order to plot markers above lines
        zvals = col*ones(size(xvals));
        % Plot markers for xvals and yvals using a line object
        set(hmkrs(col), 'Visible', 'on',...
            'XData', xvals,...
            'YData', yvals,...
            'ZData', zvals)
    end
end
    
end