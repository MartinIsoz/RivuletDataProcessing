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
        set(ListData,'Max',1,'String',strCellDT);                           %fill in list box and allow selection of all the strings
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
            end
            set(ListData,'String',strCellNDT,'Value',1);                    %update list content (leave only compatible data)
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
                plateSize(j,:) = Availible{k}.plateSize;                    %save plate size for selected groups
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
            % update programcontrol
            appdata.prgmcontrol.selDT    = selDT;                           %indexes of selected
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
                [dTopsU dTopsC] =...
                    fillProfilesUITable(TableData,dataSH,plateSize);
                if isempty(dTopsC) == 1
                    set(PushPlot,'Enable','off');                           %if data are not plottable, disable plot button
                    return
                else
                    set(PushPlot,'Enable','on');
                end
                % save indexes into appdata
                appdata.metricdata.dTopsU= dTopsU;
                appdata.metricdata.dTopsC= dTopsC;
                guidata(hFig,appdata);
            case 'Other'
                fillOtherUITable(TableData,dataSH);
        end
        appdata.prgmcontrol.GR = GR;                                        %save indexes of selected data into groups into appdata
        guidata(hFig,appdata);                                              %update appdata
    end
    function PushPlot_Callback(hObject,~,~)
        % extract program controls
        shTable = appdata.prgmcontrol.shTable;
        selGR   = appdata.prgmcontrol.selGR;                                %selected data groups
        selDT   = appdata.prgmcontrol.selDT;                                %selected data in groups
        % extract data
        plateSize = appdata.metricdata.plateSize;                           %matrix with plate sizes
        Data = get(TableData,'UserData');                                   %get data from the table
        close(findobj('Tag','PlotFig'));                                    %if it exists, closes window with plotted data
        hPlFig= figure('Units','Pixels','Position',[10 10 1100 700],...     %open new figure for data plotting
            'DeleteFcn',@hPlFig_DeleteFcn,...
            'UserData',Data,'NumberTitle','off','Tag','PlotFig');           %save data into handles of figure, for later use
        % extract handles from hObject
        Children = get(hObject,'Children');                                 %get uicontrol and axes of the resized figure
        parfor j = 1:numel(Children)
            Tag = get(Children(j),'Tag');                                   %get tag property of every child
            switch Tag
                case 'TableData'
                    TableData = Children(j);
                case 'CheckLink'
                    CheckLink = Children(j);
            end
        end
        clear('Children');
        % decode the ID string
        rdblCellStr = cell(1,numel(selGR));                                 %create empty var
        for j = 1:numel(selGR)
            tmpVar = regexp(Availible{selGR(j)}.ID,'_','split');            %cut the string between '_'
            tmpVar = tmpVar(1:3);                                           %take only usefull data (liquid type, gas vol.flow and plt. incl. an.)
            tmpVar{1} = ['Liq. tp.: ' tmpVar{1}];                           %liquid type
            tmpVar{2} = ['V_g = ' tmpVar{2} ' m3/s'];                       %volumetric gas flow
            tmpVar{3} = ['\alpha = ' tmpVar{3} '\circ{}'];                  %plate inclination angle
            rdblCellStr{j} = [tmpVar{1} 10 ...
                tmpVar{2} 10 ...
                tmpVar{3}];                                                 %append string to legend
        end
        switch shTable
            case 'Profiles'
                set(hPlFig,'Name','Mean prof. in cuts');                    %set name of the plot
                hPlAxes = axes('OuterPosition',[0 0 1 1],...                %create axes filling all the space
                    'Tag','hPlAxes');
                if get(CheckLink,'Value') == 1
                    set(TableData,'CellSelectionCallback',...
                        @hTableProfilesSelectionCallback);
                end
                % extract variable from appdata
                dTopsU= appdata.metricdata.dTopsU;
                dTopsC= appdata.metricdata.dTopsC;
                % create net of subplots
                nSubPl= numel(dTopsC);                                      %number of sublots is number of common columns
                % find breaks into data and set up colors
                indPlt= find(dTopsU==dTopsC(1));
                indPlt = [2*indPlt-1 2*indPlt];                         %there are 2*numel(dTopsU) columns
                tmpVar = Data(:,indPlt);                                %reduce data
                tmpVar = reshape(tmpVar(tmpVar~=0),[],size(tmpVar,2));  %strip off 0
                brks   = [1 find(diff(tmpVar(:,1))<0)'+1 numel(tmpVar(:,1))];%new group starts
                color  = rand(numel(brks)-1,3);
                % fill in the subplots
                for j = 1:nSubPl
                    hPlAxes(j) = subplot(2,ceil(nSubPl/2),j);
                    hold(hPlAxes(j),'on');                                  %set the plot to hold
                    title(hPlAxes(j),...
                        ['\bf Cut at ' mat2str(dTopsC(j)) ' mm']);
                    xlabel(hPlAxes(j),'plate width coordinate, [m]');
                    ylabel(hPlAxes(j),'rivulet height, [m]');
                    % select data to plot
                    indPlt = find(dTopsU==dTopsC(j));                       %find index of the same distance
                    indPlt = [2*indPlt-1 2*indPlt];                         %there are 2*numel(dTopsU) columns
                    tmpVar = Data(:,indPlt);                                %reduce data
                    tmpVar = reshape(tmpVar(tmpVar~=0),[],size(tmpVar,2));  %strip off 0
                    brks   = [1 find(diff(tmpVar(:,1))<0)'+1 numel(tmpVar(:,1))];%new group starts
                    for k  = 1:numel(brks)-1
                        plot(tmpVar(brks(k):brks(k+1)-1,1),...
                            tmpVar(brks(k):brks(k+1)-1,2),'Color',color(k,:),...
                            'LineWidth',2)
                        xlim([0 plateSize(1)]);                             %width of the plate is the x-coordinate
                    end
                end
            case 'IFACorr'
                set(hPlFig,'Name','IFACorr data');                          %set name of the plot
                hPlAxes   = axes('OuterPosition',[0 0.1 1 0.9],...          %create axes with space for popupmenu
                    'Tag','hPlAxes');
                % check value of LinkData and set up selection function for
                % the table
                if get(CheckLink,'Value') == 1
                    set(TableData,'CellSelectionCallback',...
                        @hTableIFACorrSelectionCallback);
                end
                % create popupmenu for chosing the x-axis
                uicontrol(hPlFig,'Style','popupmenu',...
                    'String',['Dimensionless liquid flow rate|'...
                    'Volumetric gas flow rate'],...
                    'Units','Normal',...
                    'Callback',@PopUpXAxsCorr_Callback,...
                    'Position',[0.3 0.01 0.4 0.08],'Value',1);              %create popup menu for choosing x axes
                brks = [1 find(diff(Data(:,4))<0)'+1 numel(Data(:,4))];     %indexes of new data starts (diff in dimless fl. rate < 0)
                hold(hPlAxes,'on');
                color = zeros(numel(brks)-1,3);                             %allocate matrix for used colors
                for j = 1:numel(brks)-1
                    color(j,:) = rand(1,3);                                 %create random color and store it
                    hPlot(j) = plot(hPlAxes,Data(brks(j):brks(j+1),4),...
                        Data(brks(j):brks(j+1),end),'^');
                    set(hPlot(j),'Color',color(j,:));
                end
                title(hPlAxes,['\bf Interfacial area as fun. of '...
                    'dimensionless liq. flow rate'],'FontSize',13);
                xlabel(hPlAxes,'dimensionless flow rate, [-]');
                ylabel(hPlAxes,'interfacial area of the rivulet, [m^2]');
                set(hPlot,'MarkerSize',10);
                % create leged entries (ID strings of data groups)
                hLegend = legend(hPlAxes,rdblCellStr,'Location','Best',...
                    'Interpreter','tex');
                % save handles into appdata
                appdata.handles.hPlFig = hPlFig;
                appdata.handles.hPlAxes= hPlAxes;
                appdata.handles.hPlot  = hPlot;
                appdata.handles.hLegend= hLegend;
                % save breakpoints into appdata
                appdata.metricdata.brks= brks;
                % save colors of lines into appdata
                appdata.metricdata.color=color;
                guidata(hFig,appdata);                                      %update application data
            case 'Other'
                GR = appdata.prgmcontrol.GR;                                %indexes of the data into groups
                switch selDT                                                %switch selected data
                    case 1                                                  %switch figure title and labels
                        ttlStr = ['\bf Mean speed of liquid as function'...
                            ' of distance from the top of the plate'];
                        ylbStr = 'Speed, [m/s]';
                    case 2
                        ttlStr = ['\bf Rivulet width as function'...
                            ' of distance from the top of the plate'];
                        ylbStr = 'Width, [m]';
                    case 3
                        ttlStr = ['\bf Rivulet height as function'...
                            ' of distance from the top of the plate'];
                        ylbStr = 'Height, [m]';
                end
                set(hPlFig,'Name','Riv. Height, Width and liq. speed data');%set name of the plot
                hPlAxes = axes('OuterPosition',[0 0 1 1],...                %create axes filling all the space
                    'Tag','hPlAxes');
                % check value of LinkData and set up selection function for
                % the table
                if get(CheckLink,'Value') == 1
                    set(TableData,'CellSelectionCallback',...
                        @hTableOtherSelectionCallback);
                end
                brks = [1 find(diff(Data(:,end))<0)'+1 numel(Data(:,end))]; %indexes of new data starts (diff in distances from top < 0)
                % create leged entries (ID strings of data groups)
                legendCellStr = {};
                flRates       = Data(:,8);                                  %get present dimless flow rates
                flRates       = flRates(flRates~=0);                        %get rid of zeros
                k             = 1;                                          %auxiliary index, distinction between data groups
                l             = 1;                                          %auxiliary index
                color = zeros(numel(brks)-1,3);                             %allocate matrix for used colors
                hold(hPlAxes,'on');
                for j = 1:numel(brks)-1                                     %for all selected dimless flow rates
                    if l > numel(GR{k})                                     %distinct to which groups are the data appartening
                        k = k+1;
                        l = 1;
                    else
                        l = l+1;
                    end
                    color(j,:) = rand(1,3);
                    legendCellStr{j} =...
                        ['M = ' num2str(flRates(j),'%3.1f') 10 ...          %compose a legend entry
                        rdblCellStr{k}];
                    hPlot(j,:) = plot(hPlAxes,Data(brks(j):brks(j+1),end),...%plot datagroup
                        Data(brks(j):brks(j+1),1:end-3),'^');
                    set(hPlot(j,:),'Color',color(j,:),...                   %color the plot
                        'MarkerFaceColor',color(j,:));                      %fill the marker faces with the same color
                    set(hPlot(j,end-2),'Visible','off');                    %hide the zeros column
                end
                hLegend = legend(hPlot(:,1),legendCellStr,...               %set up legend
                    'Location','EastOutside',...
                    'Interpreter','tex');
                % modifying the plot
                set(hPlot,'MarkerSize',7);
                xlabel(hPlAxes,'Distance from the top of the plate, [m]');  %set xlabel (common to all)
                xlim(hPlAxes,[0 max(plateSize(:,2))])                       %set xLim as the biggest plate length
                ylabel(hPlAxes,ylbStr);                                     %set y label
                title(hPlAxes,ttlStr,'FontSize',13);                        %set title of the figure
                % save handles into appdata
                appdata.handles.hPlFig = hPlFig;
                appdata.handles.hPlAxes= hPlAxes;
                appdata.handles.hPlot  = hPlot;
                appdata.handles.hLegend= hLegend;
                % save breakpoints into appdata
                appdata.metricdata.brks= brks;
                % save flow rates into appdata
                appdata.metricdata.flRates =flRates;
                % save colors of lines into appdata
                appdata.metricdata.color=color;
                guidata(hFig,appdata);                                      %update application data
        end
    end
    function PopUpXAxsCorr_Callback(hObject,~,~)
        appdata = guidata(hFig);                                            %get application data from hFig
        % extract handles
        hPlFig  = appdata.handles.hPlFig;                                   %handles for figure with plotted data
        hPlAxes = appdata.handles.hPlAxes;                                  %handles for axes with plots
        hPlot   = appdata.handles.hPlot;                                    %handles for plotted lines
        hLegend = appdata.handles.hLegend;                                  %handles for legend of the plotted lines
        lgstr   = get(hLegend,'UserData');                                  %get user data from legend - in lstrings are saved legend entries
        lgstr   = lgstr.lstrings;
        % extract metricdata
        brks    = appdata.metricdata.brks;
        color   = appdata.metricdata.color;
        Data    = get(hPlFig,'UserData');                                   %get data from the table
        contents= cellstr(get(hObject,'String'));
        xAxes   = contents{get(hObject,'Value')};                           %get selected value from popmenu
        switch xAxes
            case 'Dimensionless liquid flow rate'
                indX = 4;                                                   %column index of x-data in table
                ttlStr = ['\bf Interfacial area as fun. of '...
                    'dimensionless liq. flow rate'];
                xlblStr= 'dimensionless liq. flow rate, [-]';
            case 'Volumetric gas flow rate'
                indX = 6;                                                   %column index of x-data in table
                ttlStr = ['\bf Interfacial area as fun. of '...
                    'volumetric gas flow rate'];
                xlblStr= 'volumetric gas flow rate, [m^3/s]';
        end
        cla(hPlAxes);                                                       %clear axes for the new plot
        hold(hPlAxes,'on');
        for j = 1:numel(brks)-1
            hPlot(j)   = plot(hPlAxes,Data(brks(j):brks(j+1),indX),...
                Data(brks(j):brks(j+1),end),'^');
            set(hPlot(j),'Color',color(j,:));
        end
        title(hPlAxes,ttlStr,'FontSize',13);
        xlabel(hPlAxes,xlblStr);
        ylabel(hPlAxes,'interfacial area of the rivulet, [m^2]');
        set(hPlot,'MarkerSize',10);
        hLegend = legend(hPlAxes,lgstr,'Location','Best');
        % save handles into appdata
        appdata.handles.hPlFig = hPlFig;
        appdata.handles.hPlAxes= hPlAxes;
        appdata.handles.hPlot  = hPlot;
        appdata.handles.hLegend= hLegend;
        guidata(hFig,appdata);                                              %update application data
    end
    function hPlFig_DeleteFcn(hObject,~)
        % delete function for hPlFig - if the figure is deleted, i need to unset
        % selection callback in table
        set(TableData,'CellSelectionCallback',[]);
        delete(hObject);
    end
    function hTableProfilesSelectionCallback(hTable,eventdata)
    end
    function hTableIFACorrSelectionCallback(hTable,eventdata)               %function for table selection callback of the IFACorr
        %extract handles from appdata
        appdata = guidata(hFig);
        %extract handles
        hPlot   = appdata.handles.hPlot;                                    %handles for plotted lines
        % extract values from appdata
        brks    = appdata.metricdata.brks;                                  %indexes of starts of new datasets
        color   = appdata.metricdata.color;                                 %used colors
        % hPlot are handles to lines
        set(hPlot, 'Visible', 'off')                                        %turn them off to begin
        
        % Get the list of currently selected table cells
        sel = eventdata.Indices;                                            %Get selection indices (row, col)
        % Noncontiguous selections are ok
        selcols = unique(sel(:,2));                                         %Get all selected data col IDs
        selrows = unique(sel(:,1));                                         %Get all selected rows col IDs
        table = get(hTable,'UserData');                                     %Get copy of uitable data
        if isempty(selcols(selcols~=size(table,2)))==0
            errordlg({'As Y-axis data, you can choose only from within'...
                'the IFArea column.'});
            return
        else
            %Get vectors of x,y values for each column in the selection;
            for idx = 1:numel(brks)-1                                       %there is numel(brks)-1 line series
                rows  = selrows(selrows>=brks(idx));                        %get selected rows appartening to the line
                yvals = table(rows, end)';                                  %yvals are IFACorr
                xvals = table(rows,4);                                      %select x-values from data table (flow rates)
                % Create Z-vals = 1 in order to plot markers above lines
                zvals = idx*ones(size(xvals));
                % find index of hPlot to set up
                % Plot markers for xvals and yvals using a line object
                set(hPlot(idx), 'Visible', 'on',...
                    'XData', xvals,...
                    'YData', yvals,...
                    'ZData', zvals,...
                    'Color',color(idx,:))
            end
        end
    end
    function hTableOtherSelectionCallback(hTable,eventdata)                 %function for table selection callback of the IFACorr
        %extract handles from appdata
        appdata = guidata(hFig);
        %extract handles
        hPlot   = appdata.handles.hPlot;                                    %handles for plotted lines, matrix nGR x (nMsrmts + 6)
        % extract values from appdata
        brks    = appdata.metricdata.brks;                                  %index of new group starts
        color   = appdata.metricdata.color;                                 %used colors
        % hPlot are handles to lines
        set(hPlot, 'Visible', 'off')                                        %turn them off to begin
        
        % Get the list of currently selected table cells
        sel = eventdata.Indices;                                            %Get selection indices (row, col)
        % Noncontiguous selections are ok
        selcols = unique(sel(:,2));                                         %Get all selected data col IDs
        selrows = unique(sel(:,1));                                         %Get all selected data row IDs
        table = get(hTable,'UserData');                                     %Get copy of uitable data
        
        if max(selcols) > numel(table(1,:)) - 3
            errordlg({['Flow rates and distance from the top of the plate are '...
                'not plotable.'] 'Please select different columns'})
        else
            %Get vectors of x,y values for each column in the selection;
            for jdx = 1:1:numel(selcols)
                for idx = 1:numel(brks)-1                                   %there is numel(brks)-1 line series
                    rows  = selrows(selrows>=brks(idx));                    %get selected rows appartening to the line
                    col = selcols(jdx);
                    yvals = table(rows, col)';
                    xvals = table(rows,end);                                %select x-values from data table - distance from the top of the plate
                    % Create Z-vals = 1 in order to plot markers above lines
                    zvals = col*ones(size(xvals));
                    % Plot markers for xvals and yvals using a line object
                    set(hPlot(idx,col), 'Visible', 'on',...
                        'XData', xvals,...
                        'YData', yvals,...
                        'ZData', zvals,...
                        'Color',color(idx,:))
                end
            end
        end
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
function [dTopsU dTopsC]=...
    fillProfilesUITable(hTable,dataSH,plateSize)
% all the profiles have different width - number of cuts and different
% length - max width of the rivulet=>
%=>I must discover number of cuts for each variable/picture
%=>I must rearrange profiles accordingly to place where they were taken
%
% OUTPUT variables
% dTopsU        ... unique distances of cuts from the top of the plate
% dTopsC        ... common distances of cuts from the top of the plate

% creating column names for uitable
nCuts = zeros(1,numel(dataSH));                                             %numbers of cuts throught the rivulet
dTops = cell(1,numel(dataSH));                                              %distances from the top of the plate
parfor i = 1:numel(dataSH)
    nCuts(i) = size(dataSH{i}{1},2)/2;                                      %nCuts -> nCols/2
    dTops{i} = (1:nCuts(i)) * plateSize(i,2)/(nCuts(i)+1)*1e3;
end
dTopsU = unique(cell2mat(dTops));                                           %convert cell to double and left out repeting values
tmpVar = dTops{1};
for i = 2:numel(dTops) %#ok<FORPF>
    tmpVar = intersect(tmpVar,dTops{i});                                    %common columns, need to be done by for cycle
end
dTopsC = tmpVar;clear tmpVar;
% construct Column names
for i = 1:numel(dTopsU)
    ColNames{2*i-1} = ['Cut at ' num2str(dTopsU(i),'%3.1f') ' mm|X, [m]'];
    ColNames{2*i}   = ['Cut at ' num2str(dTopsU(i),'%3.1f') ' mm|Y, [m]'];
end
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
        switch mod(i+j,3)+1                                                 %create colors for the data
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
