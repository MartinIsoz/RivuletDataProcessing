function postProcPlotting(Availible)
%
%   function postProcPlotting(Availible)
%
% function for plotting calculated data (just for basic data overview).
% there is automatically created simple gui that offers user to plot
% selected data. In comparison with "Quick outputs overview" from the main
% gui, there are only few additional plotting possibilities
% 
% INPUT variables
% Availible   ... cell of structures obtained from rivuletProcessing.m
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         09. 08. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also RIVULETEXPDATAPROCESSING SHOWPROCDATA

% --- Disabling useless warnings
%#ok<*DEFNU> - GUI cannot see what functions will be used by user


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
    'Tag','ListGroup','Max',numel(strCellGR));                              %#ok<*NASGU> %enable multiselect in listboxes
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
    'String','Plot Selected','Callback',@PushPlot_Callback,...
    'Enable','off');                                                        %at first disable this button
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
        % disable plot button until the data are selected
        set(PushPlot,'Enable','off');
        set(CheckLink,'Enable','on');                                       %CheckLink may be disabled by chosing profiles, enable it here
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
        selDT     = get(hObject,'Value');                                   %get selected value(s)
        if numel(selDT) == 1 && comp == 0                                   %check for length of the selection for strcmp
            if strcmp(strCellDT{selDT},'Profiles') == 1                     %actualize listbox selection to show compatible data
                strCellNDT = strCellDT(strcmp(strCellDT,'Profiles')==1);    %reduce only to profiles
                % at the moment, this plot are not linkable with table
                set(CheckLink,'Enable','off');
                % update appdata
                appdata.prgmcontrol.comp = 1;                               %store info about choosing compatible data
                appdata.prgmcontrol.shTable = 'Profiles';                   %store info about choosed data
                guidata(hObject,appdata);
            elseif strcmp(strCellDT{selDT},'IFACorr') == 1
                strCellNDT = strCellDT(strcmp(strCellDT,'IFACorr')==1);     %reduce only to interfacial area correlation data
                % update appdata
                appdata.prgmcontrol.comp = 1;                               %store info about choosing compatible data
                appdata.prgmcontrol.shTable = 'IFACorr';                    %store info about choosed data
                guidata(hObject,appdata);
            else
                strCellNDT = strCellDT(strcmp(strCellDT,'Profiles') == 0&...%get rid of profiles and IFACorr
                    strcmp(strCellDT,'IFACorr') == 0);
                % update appdata
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
        if comp == 1                                                        %this case occurs if there are only compatible data present in lstbx
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
                        set(PushPlot,'Enable','on');                        %the data are plotable now
                        % initialize fields needed by PushPlot
                        selGR = appdata.prgmcontrol.selGR;
                        appdata.prgmcontrol.selMS    = selGR;               %initialization of the next selected indexes (needed for PushPlot)
                        appdata.prgmcontrol.GR       =...
                            cellstr(num2str(numel(selGR),1));               %needed for making legend strings
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
        % enable PushPlot button
        set(PushPlot,'Enable','on');                                        %data are plottable now
        % update and fill appdata
        appdata.prgmcontrol.GR = GR;                                        %save indexes of selected data into groups into appdata
        appdata.prgmcontrol.selMS = selMS;                                  %save real indexes of selected
        guidata(hFig,appdata);                                              %update appdata
    end
    function PushPlot_Callback(hObject,~,~)
        % extract program controls
        shTable = appdata.prgmcontrol.shTable;
        selGR   = appdata.prgmcontrol.selGR;                                %selected data groups
        selDT   = appdata.prgmcontrol.selDT;                                %selected data in groups
        selMS   = appdata.prgmcontrol.selMS;                                %indexes of selected data
        GR      = appdata.prgmcontrol.GR;                                   %indexes of the data into groups
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
        k           = 1;l = 1;                                              %auxiliary indexes
        for j = 1:numel(selMS)
            if l > numel(GR{k})                                             %distinct to which groups are the data appartening
                k = k+1;
                l = 1;
            else
                l = l+1;
            end
            tmpVar = regexp(Availible{selGR(k)}.ID,'_','split');            %cut the string between '_'
            tmpVar = tmpVar(1:3);                                           %take only usefull data (liquid type, gas vol.flow and plt. incl. an.)
            tmpVar{1} = ['Liq. tp.: ' tmpVar{1}];                           %liquid type
            tmpVar{2} = ['F = ' tmpVar{2} ' Pa^{0.5}'];                     %f-factor
            tmpVar{3} = ['\alpha = ' tmpVar{3} '\circ{}'];                  %plate inclination angle
            rdblCellStr{j} = [tmpVar{1} 10 ...
                tmpVar{2} 10 ...
                tmpVar{3}] ;                                                %append string to legend
        end
        switch shTable
            case 'Profiles'
                set(hPlFig,'Name','Mean prof. in cuts');                    %set name of the plot
                if get(CheckLink,'Value') == 1
                    set(TableData,'CellSelectionCallback',...
                        @hTableProfilesSelectionCallback);
                end
                % extract variable from appdata
                dTopsU= appdata.metricdata.dTopsU;
                dTopsC= appdata.metricdata.dTopsC;
                % create net of subplots
                nSubPl= numel(dTopsC);                                      %number of sublots is number of common columns
                % set up colors
                color  = distinguishable_colors(numel(selMS));              %create matrix of distinguishable colors
                % fill in the subplots
                mod2    = mod(nSubPl,2);                                    %modulo after dividing by 2 (number of empty spaces in second row)
                if mod2 ~= 0                                                %if there is left space in the second row
                    totWidth = 1;                                           %it will be used for legend
                else                                                        %otherwise,
                    totWidth= 0.8;                                          %use only 0.8 of hor space, leave the rest for legend
                end
                widthPl = totWidth/(ceil(nSubPl/2));                        %width of 1 plot
                heightPl= 0.5;                                              %height of 1 plot, 2 rows
                l       = -1;                                               %auxiliary indexe for horizontal ax. placing
                spV     = 0.5;                                              %space from the bottom of the figure
                for j = 1:nSubPl
                    if j == ceil(nSubPl/2)+1;                               %end of the first row
                        l  =  0;
                        spV=  0;
                    else
                        l = l+1;
                    end
                    hPlAxes(j) = axes('OuterPosition',...
                        [l*widthPl spV widthPl heightPl]);
                    hold(hPlAxes(j),'on');                                  %set the plot to hold
                    hTtl = title(hPlAxes(j),...
                        ['Cut at ' mat2str(dTopsC(j)) ' mm']);
                    set(hTtl,'FontSize',13,'FontWeight','bold')             %modify title properties
                    xlabel(hPlAxes(j),'plate width coordinate, [m]');
                    ylabel(hPlAxes(j),'rivulet height, [m]');
                    % select data to plot
                    indPlt = find(dTopsU==dTopsC(j));                       %find index of the same distance
                    indPlt = [2*indPlt-1 2*indPlt];                         %there are 2*numel(dTopsU) columns
                    tmpVar = Data(:,indPlt);                                %reduce data
                    tmpVar = reshape(tmpVar(tmpVar~=0),[],size(tmpVar,2));  %strip off 0
                    brks   = [1 find(diff(tmpVar(:,1))<0)'+1 numel(tmpVar(:,1))];%new group starts
                    for k  = 1:numel(brks)-1
                        plot(hPlAxes(j),tmpVar(brks(k):brks(k+1)-1,1),...
                            tmpVar(brks(k):brks(k+1)-1,2),'Color',color(k,:),...
                            'LineWidth',2)
                        xlim(hPlAxes(j),[0 plateSize(1)]);                  %width of the plate is the x-coordinate
                    end
                end
                % create legend, I need to help myself with little hack
                % using ghost figure
                lgStr = cell(1,numel(selMS));
                parfor j = 1:numel(selMS)                                   %create legend for each chosen picture
                    lgStr{j} = ['Sel. ' num2str(j) 10 rdblCellStr{j}];
                end
                if mod2 ~= 0                                                %if there is left space, use it for legend
                    hGhostAx = axes('OuterPosition',...                     %create ghost axes
                        [(l+1)*widthPl spV widthPl heightPl],...
                        'Visible','off','Units','Normal');
                else                                                        %otherwise use saved space
                    hGhostAx = axes('OuterPosition',...
                        [totWidth 0 1-totWidth 1],...
                        'Visible','off');
                end
                hold(hGhostAx,'on');
                for j  = 1:numel(brks)-1
                    plot(hGhostAx,tmpVar(brks(j):brks(j+1)-1,1),...
                        tmpVar(brks(j):brks(j+1)-1,2),'Color',color(j,:),...
                        'Visible','off','LineWidth',2);                     %invisible plots in invisible axes
                end
                legend(hGhostAx,lgStr',...
                    'OuterPosition',get(hGhostAx,'Position'));              %create legend for ghost axes
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
                    'gas F-Factor'],...
                    'Units','Normal',...
                    'Callback',@PopUpXAxsCorr_Callback,...
                    'Position',[0.3 0.01 0.4 0.08],'Value',1);              %create popup menu for choosing x axes
                brks = [1 find(diff(Data(:,4))<0)'+1 numel(Data(:,4))+1];   %indexes of new data starts (diff in dimless fl. rate < 0)
                hold(hPlAxes,'on');
                color = distinguishable_colors(numel(brks)-1);              %allocate matrix for used colors and fill it with colors
                for j = 1:numel(brks)-1
                    % prepare data (calculate mean values and std() )
                    tmpVar = Data(brks(j):brks(j+1)-1,[4 end]);             %resave current part of data as tmpVar
                    uniqueFlR= unique(tmpVar(:,1));                         %unique dimensionless flow rates
                    meanIFArea=zeros(numel(uniqueFlR),1);                   %preallocate variables
                    stdDevIFA= meanIFArea;
                    for k = 1:numel(uniqueFlR)
                        meanIFArea(k) = mean(tmpVar(...                     %select data with the one flow rate
                            uniqueFlR(k) == tmpVar(:,1),2));                %calculate mean IF area for unique flow rates
                        stdDevIFA(k)  = std(tmpVar(...                      %select data with the one flow rate
                            uniqueFlR(k) == tmpVar(:,1),2));                %calculate standard deviation of these values
                    end
                    hPlot(j,1) = plot(hPlAxes,tmpVar(:,1),tmpVar(:,2),'^'); %plot measured values
                    hPlot(j,2) = errorbar(hPlAxes,uniqueFlR,meanIFArea,...  %plot mean IF areas with errorbars
                        stdDevIFA,'^-');
                    set(hPlot(j,:),'Color',color(j,:),'MarkerFaceColor',... %set up colors
                        color(j,:));
                end
                set(hPlot(:,1),'Visible','off');                            %make everything except mean values invisible
                hTtl = title(hPlAxes,['Interfacial area as fun. of '...
                    'dimensionless liq. flow rate']);
                set(hTtl,'FontSize',13,'FontWeight','bold')                 %modify title properties
                xlabel(hPlAxes,'dimensionless flow rate, [-]');
                ylabel(hPlAxes,'interfacial area of the rivulet, [m^2]');
                set(hPlot,'MarkerSize',7);
                % create leged entries (ID strings of data groups)
                hLegend = legend(hPlot(:,1),rdblCellStr,'Location','Best',...
                    'Interpreter','tex');
                % save handles into appdata
                appdata.handles.hPlFig = hPlFig;
                appdata.handles.hPlAxes= hPlAxes;
                appdata.handles.hPlot  = hPlot;
                % save breakpoints into appdata
                appdata.metricdata.brks= brks;
                % save legend cell of strings
                appdata.metricdata.rdblCellStr = rdblCellStr;
                % save colors of lines into appdata
                appdata.metricdata.color=color;
                guidata(hFig,appdata);                                      %update application data
            case 'Other'
                switch selDT                                                %switch selected data
                    case 1                                                  %switch figure title and labels
                        ttlStr = ['Mean speed of liquid as function'...
                            ' of distance from the top of the plate'];
                        ylbStr = 'Speed, [m/s]';
                    case 2
                        ttlStr = ['Rivulet width as function'...
                            ' of distance from the top of the plate'];
                        ylbStr = 'Width, [m]';
                    case 3
                        ttlStr = ['Rivulet height as function'...
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
                brks = [1 find(diff(Data(:,end))<0)'+1 numel(Data(:,end))+1];%indexes of new data starts (diff in distances from top < 0)
                % create leged entries (ID strings of data groups)
                legendCellStr = {};
                flRates       = Data(:,8);                                  %get present dimless flow rates
                flRates       = flRates(flRates~=0);                        %get rid of zeros
                color = distinguishable_colors(numel(brks)-1);              %allocate matrix for used colors and fill in with colors
                hold(hPlAxes,'on');
                hPlot = zeros(numel(brks)-1,size(Data,2)-3);                %allocate space for the variable hPlot
                for j = 1:numel(brks)-1                                     %for all selected dimless flow rates
                    legendCellStr{j} =...
                        ['M = ' num2str(flRates(j),'%3.1f') 10 ...          %compose a legend entry
                        rdblCellStr{j}];
                    hPlot(j,1:end-1) = plot(hPlAxes,...
                        Data(brks(j):brks(j+1)-1,end),...                   %plot datagroup - measurements
                        Data(brks(j):brks(j+1)-1,[1:end-5 end-3]),'^');     %skip the mean values
                    hPlot(j,end) = errorbar(hPlAxes,...                     %plot mean values with errorbars setted up by std()
                        Data(brks(j):brks(j+1)-1,end),...                   %x-axis, distances from the plate top (nCuts,1)
                        Data(brks(j):brks(j+1)-1,end-4),...                 %y-axis, mean values (nCuts,1)
                        Data(brks(j):brks(j+1)-1,end-3),'^-');              %errorbars, 2xstd, standard deviations (nCuts,1)
                    set(hPlot(j,:),'Color',color(j,:),...                   %color the plot
                        'MarkerFaceColor',color(j,:));                      %fill the marker faces with the same color
                    set(hPlot(j,1:end-1),'Visible','off');                  %hide everything except mean values
                end
                hLegend = legend(hPlot(:,1),legendCellStr,...               %set up legend, number of groups == number of columns
                    'Location','EastOutside',...
                    'Interpreter','tex');
                % modifying the plot
                set(hPlot,'MarkerSize',7);
                xlabel(hPlAxes,'Distance from the top of the plate, [m]');  %set xlabel (common to all)
                xlim(hPlAxes,[0 max(plateSize(:,2))])                       %set xLim as the biggest plate length
                ylabel(hPlAxes,ylbStr);                                     %set y label
                hTtl = title(hPlAxes,ttlStr);                               %set title of the figure
                set(hTtl,'FontSize',13,'FontWeight','bold')                 %modify title properties
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
        lgstr   = appdata.metricdata.rdblCellStr;                           %cell of strings to be displayed in legend
        % extract metricdata
        brks    = appdata.metricdata.brks;
        color   = appdata.metricdata.color;
        Data    = get(hPlFig,'UserData');                                   %get data from the table
        contents= cellstr(get(hObject,'String'));
        xAxes   = contents{get(hObject,'Value')};                           %get selected value from popmenu
        switch xAxes
            case 'Dimensionless liquid flow rate'
                indX = 4;                                                   %column index of x-data in table
                ttlStr = ['Interfacial area as fun. of '...
                    'dimensionless liq. flow rate'];
                xlblStr= 'dimensionless liq. flow rate, [-]';
            case 'gas F-Factor'
                indX = 6;                                                   %column index of x-data in table
                ttlStr = ['Interfacial area as fun. of '...
                    'gas F-Factor'];
                xlblStr= 'F-Factor, [Pa^{0.5}]';
        end
        cla(hPlAxes);                                                       %clear axes for the new plot
        hold(hPlAxes,'on');
        for j = 1:numel(brks)-1
            % prepare data (calculate mean values and std() )
            tmpVar = Data(brks(j):brks(j+1)-1,[indX end]);                     %resave current part of data as tmpVar
            uniqueFlR= unique(tmpVar(:,1));                                 %unique dimensionless flow rates
            meanIFArea=zeros(numel(uniqueFlR),1);                           %preallocate variables
            stdDevIFA= meanIFArea;
            for k = 1:numel(uniqueFlR)
                meanIFArea(k) = mean(tmpVar(...                             %select data with the one flow rate
                    uniqueFlR(k) == tmpVar(:,1),2));                        %calculate mean IF area for unique flow rates
                stdDevIFA(k)  = std(tmpVar(...                              %select data with the one flow rate
                    uniqueFlR(k) == tmpVar(:,1),2));                        %calculate standard deviation of these values
            end
            hPlot(j,1) = plot(hPlAxes,tmpVar(:,1),tmpVar(:,2),'^');         %plot measured values
            hPlot(j,2) = errorbar(hPlAxes,uniqueFlR,meanIFArea,...          %plot mean IF areas with errorbars
                stdDevIFA,'^-');
            set(hPlot(j,:),'Color',color(j,:),'MarkerFaceColor',...         %set up colors
                color(j,:));
        end
        set(hPlot(:,1),'Visible','off');                                    %make everything except mean values invisible
        title(hPlAxes,ttlStr,'FontSize',13,'FontWeight','bold');
        xlabel(hPlAxes,xlblStr);
        ylabel(hPlAxes,'interfacial area of the rivulet, [m^2]');
        set(hPlot,'MarkerSize',7);
        hLegend = legend(hPlot(:,1),lgstr,'Location','Best');
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
    function hTableProfilesSelectionCallback(~,~)
    end                        %not used at the time
    function hTableIFACorrSelectionCallback(hTable,eventdata)               %function for table selection callback of the IFACorr
        %extract handles from appdata
        appdata = guidata(hFig);
        %extract handles
        hPlot   = appdata.handles.hPlot;                                    %handles for plotted lines
        % extract values from appdata
        brks    = appdata.metricdata.brks;                                  %indexes of starts of new datasets
        color   = appdata.metricdata.color;                                 %used colors
        % hPlot are handles to lines
        set(hPlot(:,1), 'Visible', 'off')                                   %set everything except mean values invisible
        
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
        hPlAxes = appdata.handles.hPlAxes;                                  %handles for axes
        % extract values from appdata
        brks    = appdata.metricdata.brks;                                  %index of new group starts
        color   = appdata.metricdata.color;                                 %used colors
        % hPlot are handles to lines
        set(hPlot(:,1:end-1), 'Visible', 'off')                             %turn invisible everything except the lines with mean values
        
        % Get the list of currently selected table cells
        sel = eventdata.Indices;                                            %Get selection indices (row, col)
        % Noncontiguous selections are ok
        selcols = unique(sel(:,2));                                         %Get all selected data col IDs
        selrows = unique(sel(:,1));                                         %Get all selected data row IDs
        table = get(hTable,'UserData');                                     %Get copy of uitable data
        
        if max(selcols) > numel(table(1,:)) - 6                             %if user wants to plot anything else than measurements
            errordlg({'You can add to plot only different measuremets'...
                'Please select different columns'})
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
                    set(hPlot(idx,col), 'Visible', 'on',...                 %make markers visible
                        'XData', xvals,...                                  %set up data
                        'YData', yvals,...
                        'ZData', zvals,...
                        'Color',color(idx,:));                              %set colors according to legend
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
rgb     = distinguishable_colors(cellfun(@numel,dataSH));                   %create matrix of distinguishable colors for each group
parfor i = 1:size(rgb,1)                                                    %convert these colors into html
    tmpHex    = dec2hex(round(255*rgb(i,:)));
    html(i,:) = [tmpHex(1,:) tmpHex(2,:) tmpHex(3,:)];
end
l     = 1;                                                                  %auxiliary indexing variable for indexing colors
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
            html(l,:) '; font-weight: normal;">'], ...
            tmpMat(k), ...
            '</span></html>');
        end
        DataClr= [DataClr;tmpMat];
        l      = l+1;                                                       %increase color selector
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
        'F-Factor,|[Pa^0.5]','Riv. surface|area, [m2]'};
% creating data matrix to show
Data    = [];
DataClr = [];
rgb     = distinguishable_colors(numel(dataSH));                            %create matrix of distinguishable colors for each group
parfor i = 1:size(rgb,1)                                                    %convert these colors into html
    tmpHex    = dec2hex(round(255*rgb(i,:)));
    html(i,:) = [tmpHex(1,:) tmpHex(2,:) tmpHex(3,:)];
end
for i = 1:numel(dataSH) %#ok<FORPF>
    % adding i-th dataset to data matrix to show
    Data = [Data;dataSH{i}];
    % coloring data matrix - each dataset has its own color
    tmpMat = reshape(strtrim(cellstr(num2str(dataSH{i}(:)))),...
        size(dataSH{i}));                                                   %convert data to cell of strings
    for j = 1:numel(tmpMat)
        tmpMat(j) = strcat(...                                              %modify format of the problematic value
            ['<html><span style="color: #' ...
            html(i,:) '; font-weight: normal;">'], ...
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
    'Dimensionless|flow rate, [-]' 'F-Factor,|[m3/s]',...
    'Distance from|plate top, [m]'}];
% prepare data to be shown
Data    = [];
DataClr = [];
rgb     = distinguishable_colors(cellfun(@numel,dataSH));                   %create matrix of distinguishable colors for each group
parfor i = 1:size(rgb,1)                                                    %convert these colors into html
    tmpHex    = dec2hex(round(255*rgb(i,:)));
    html(i,:) = [tmpHex(1,:) tmpHex(2,:) tmpHex(3,:)];
end
l     = 1;                                                                  %auxiliary indexing variable for indexing colors
for i = 1:numel(dataSH) 
    nZeros = max(numMS) - numMS(i);                                         %number of zeros is difference between maximal and actual n of measur.
    for j = 1:numel(dataSH{i})
        tmpMat = [dataSH{i}{j}(:,1:numMS(i)) ...                            %current data + added zero columns
            zeros(nCuts(i),nZeros) dataSH{i}{j}(:,numMS(i)+1:end)];
        Data = [Data;tmpMat];                                               %add current data to Data
        tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))),...
            size(tmpMat));                                                  %convert data to cell of strings
        for k = 1:numel(tmpMat)
            tmpMat(k) = strcat(...                                          %modify format of the problematic value
                ['<html><span style="color: #' ...
                html(l,:) '; font-weight: normal;">'], ...
                tmpMat(k), ...
                '</span></html>');
        end
        DataClr = [DataClr;tmpMat];
        l = l+1;                                                            %increase color counter
    end
end
set(hTable,'ColumnName',ColNames,'Data',DataClr,'ColumnWidth',{100},...
    'UserData',Data);
    
end

%% Distinguishable colors - downloaded function
function colors = distinguishable_colors(n_colors,bg,func)
% DISTINGUISHABLE_COLORS: pick colors that are maximally perceptually distinct
%
% When plotting a set of lines, you may want to distinguish them by color.
% By default, Matlab chooses a small set of colors and cycles among them,
% and so if you have more than a few lines there will be confusion about
% which line is which. To fix this problem, one would want to be able to
% pick a much larger set of distinct colors, where the number of colors
% equals or exceeds the number of lines you want to plot. Because our
% ability to distinguish among colors has limits, one should choose these
% colors to be "maximally perceptually distinguishable."
%
% This function generates a set of colors which are distinguishable
% by reference to the "Lab" color space, which more closely matches
% human color perception than RGB. Given an initial large list of possible
% colors, it iteratively chooses the entry in the list that is farthest (in
% Lab space) from all previously-chosen entries. While this "greedy"
% algorithm does not yield a global maximum, it is simple and efficient.
% Moreover, the sequence of colors is consistent no matter how many you
% request, which facilitates the users' ability to learn the color order
% and avoids major changes in the appearance of plots when adding or
% removing lines.
%
% Syntax:
%   colors = distinguishable_colors(n_colors)
% Specify the number of colors you want as a scalar, n_colors. This will
% generate an n_colors-by-3 matrix, each row representing an RGB
% color triple. If you don't precisely know how many you will need in
% advance, there is no harm (other than execution time) in specifying
% slightly more than you think you will need.
%
%   colors = distinguishable_colors(n_colors,bg)
% This syntax allows you to specify the background color, to make sure that
% your colors are also distinguishable from the background. Default value
% is white. bg may be specified as an RGB triple or as one of the standard
% "ColorSpec" strings. You can even specify multiple colors:
%     bg = {'w','k'}
% or
%     bg = [1 1 1; 0 0 0]
% will only produce colors that are distinguishable from both white and
% black.
%
%   colors = distinguishable_colors(n_colors,bg,rgb2labfunc)
% By default, distinguishable_colors uses the image processing toolbox's
% color conversion functions makecform and applycform. Alternatively, you
% can supply your own color conversion function.
%
% Example:
%   c = distinguishable_colors(25);
%   figure
%   image(reshape(c,[1 size(c)]))
%
% Example using the file exchange's 'colorspace':
%   func = @(x) colorspace('RGB->Lab',x);
%   c = distinguishable_colors(25,'w',func);

% Copyright 2010-2011 by Timothy E. Holy

% Parse the inputs
if (nargin < 2)
    bg = [1 1 1];  % default white background
else
    if iscell(bg)
        % User specified a list of colors as a cell aray
        bgc = bg;
        for i = 1:length(bgc) %#ok<FORPF>
            bgc{i} = parsecolor(bgc{i});
        end
        bg = cat(1,bgc{:});
    else
        % User specified a numeric array of colors (n-by-3)
        bg = parsecolor(bg);
    end
end

% Generate a sizable number of RGB triples. This represents our space of
% possible choices. By starting in RGB space, we ensure that all of the
% colors can be generated by the monitor.
n_grid = 30;  % number of grid divisions along each axis in RGB space
x = linspace(0,1,n_grid);
[R,G,B] = ndgrid(x,x,x);
rgb = [R(:) G(:) B(:)];
if (n_colors > size(rgb,1)/3)
    error('You can''t readily distinguish that many colors');
end

% Convert to Lab color space, which more closely represents human
% perception
if (nargin > 2)
    lab = func(rgb);
    bglab = func(bg);
else
    C = makecform('srgb2lab');
    lab = applycform(rgb,C);
    bglab = applycform(bg,C);
end

% If the user specified multiple background colors, compute distances
% from the candidate colors to the background colors
mindist2 = inf(size(rgb,1),1);
for i = 1:size(bglab,1)-1 %#ok<FORPF>
    dX = bsxfun(@minus,lab,bglab(i,:)); % displacement all colors from bg
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
end

% Iteratively pick the color that maximizes the distance to the nearest
% already-picked color
colors = zeros(n_colors,3);
lastlab = bglab(end,:);   % initialize by making the "previous" color equal to background
for i = 1:n_colors
    dX = bsxfun(@minus,lab,lastlab); % displacement of last from all colors on list
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
    [~,index] = max(mindist2);  % find the entry farthest from all previously-chosen colors
    colors(i,:) = rgb(index,:);  % save for output
    lastlab = lab(index,:);  % prepare for next iteration
end
end

function c = parsecolor(s)
if ischar(s)
    c = colorstr2rgb(s);
elseif isnumeric(s) && size(s,2) == 3
    c = s;
else
    error('MATLAB:InvalidColorSpec','Color specification cannot be parsed.');
end
end

function c = colorstr2rgb(c)
% Convert a color string to an RGB value.
% This is cribbed from Matlab's whitebg function.
% Why don't they make this a stand-alone function?
rgbspec = [1 0 0;0 1 0;0 0 1;1 1 1;0 1 1;1 0 1;1 1 0;0 0 0];
cspec = 'rgbwcmyk';
k = find(cspec==c(1));
if isempty(k)
    error('MATLAB:InvalidColorString','Unknown color string.');
end
if k~=3 || length(c)==1,
    c = rgbspec(k,:);
elseif length(c)>2,
    if strcmpi(c(1:3),'bla')
        c = [0 0 0];
    elseif strcmpi(c(1:3),'blu')
        c = [0 0 1];
    else
        error('MATLAB:UnknownColorString', 'Unknown color string.');
    end
end
end