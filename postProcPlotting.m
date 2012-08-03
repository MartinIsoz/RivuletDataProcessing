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
% create GUI elements
hFig    = figure('Units','Pixels','Position',PosVec,...
    'NumberTitle','off','Name','Post processing data plotting',...
    'DockControl','off',...
    'ResizeFcn',@MyResizeFcn,'Tag','MainWindow');                          %create figure window with specified size

% create listboxes and their titles
strCellGR = cell(1,numel(Availible));
parfor i = 1:numel(Availible)
    strCellGR{i} = Availible{i}.ID;
end
ListGroup  = uicontrol(hFig, 'Style','listbox',...                          %create listbox for avalible data
    'String',strCellGR,'Callback',@ListGroup_Callback,...
    'Tag','ListGroup','Max',numel(strCellGR));                               %enable multiselect in listboxes
TextGroup = uicontrol(hFig,'Style','text',...                               %create text string
    'HorizontalAlignment','left',...
    'String','Choose data group:',...
    'Tag','TextGroup');

ListData  = uicontrol(hFig, 'Style','listbox',...                           %create listbox for chosing subdata
    'Tag','ListData');                                                      %enable multiselect in listboxes
TextData = uicontrol(hFig,'Style','text',...                                %create text string
    'HorizontalAlignment','left',...
    'String','Select data:',...
    'Tag','TextData');

ListVars  = uicontrol(hFig, 'Style','listbox',...                           %create listbox for chosing variables to plot
    'Tag','ListVars');                                                      %enable multiselect in listboxes
TextVars = uicontrol(hFig,'Style','text',...                                %create text string
    'HorizontalAlignment','left',...
    'String','Select variables to plot:',...
    'Tag','TextVars');

% create pushbuttons
PushPlot = uicontrol(hFig,'Style','pushbutton','Tag','PushPlot',...
    'String','Plot Selected');
% create checkbox
CheckLink= uicontrol(hFig,'Style','checkbox','Tag','CheckLink',...
    'String','Link plot with table');
set(CheckLink,'Value',1);                                                   %check the checkbox by default
% create data table
TableData = uitable(hFig,'Tag','TableData');                                %create table for showing selected data

%% Creating callbacks

    function ListGroup_Callback(hObject,~,handles)
        selGr = get(hObject,'Value');                                       %get selected value(s)
        strCellDT = {};                                                     %create empty cell
        % automatic creation of the content of ListData
        for j = 1:numel(selGr)
            k = selGr(j);
            fNames  = fieldnames(Availible{k});                             %get fieldnames of selected structure(s)
            fNames  = fNames(strcmp(fNames,'ID') == 0);                     %get rid of ID field
            strCellDT = [strCellDT strCellGR(k) {'-------'} fNames' {' '}]; %compose k-th sublist for listbox
        end
        set(ListData,'String',strCellDT,'Max',numel(strCellGR));            %fill in list box and allow selection of all the strings
        handles.prgmcontrol.selGr = selGr;                                  %save values into handles
        guidata(hFig,handles);                                              %update handles
    end
    function ListData_Callback(hObject,~,handles)
    end
    function ListVars_Callback(hObject,~,handles)
    end
    function PushPlot_Callback(hObject,~,handles)
    end
    function CheckLink_Callback(hObject,~,handles)
    end

end

%% Auxiliary functions
function MyResizeFcn(hObject,~)
%
%   function MyResizeFcn(handles)
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
       case 'ListVars'
           ListVars = Children(i);
       case 'TextGroup'
           TextGroup = Children(i);
       case 'TextData'
           TextData = Children(i);
       case 'TextVars'
           TextVars = Children(i);
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
height1   = max([heightAv*coef 20]);                                        %height of the first listbox, min 20 pixels
height2   = max([heightAv*2*coef 40]);                                      %height of the second listbox, min 20 pixels
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
set(ListVars, 'Position',[Hpos3 Vpos3 listWidth height3]);
set(TextGroup,'Position',[Hpos1 Vpos1+height1+gapY listWidth heightText]);
set(TextData, 'Position',[Hpos2 Vpos2+height2+gapY listWidth heightText]);
set(TextVars, 'Position',[Hpos3 Vpos3+height3+gapY listWidth heightText]);
% position pushbutton and checkbox
set(PushPlot, 'Position',[Hpush Vpush pushWidth pushHeight]);
set(CheckLink,'Position',[Hpush+pushWidth+gapY Vpush...
    checkWidth pushHeight]);
% fill remaining place with axes
set(TableData,'Units','Pixels',...
    'Position',[Htble 0,...
    max([PosVec(3)-Htble 20]) max([PosVec(4) 20])]);

end