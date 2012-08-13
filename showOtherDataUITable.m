function showOtherDataUITable(data,NameStr,type,plots,plateSize)
%
% simple function for showing data selected in quick outputs overview
% in uitable. it was exported from the main code because of possibility of
% using nested functions
%
% INPUT variables
% data  ... data to be shown
% NameStr.. name for the opened figure
% type  ... type to decide if it is descriptive output or correlation to be
%           shown 0 ... correlation, 1 ... description
% plots ... 0/1, if user want the data to be plotable
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         09. 08. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also RIVULETEXPDATAPROCESSING

hFig = figure;                                                              %open figure window
set(hFig,'NumberTitle', 'off');

if type == 0
    if plots == 0
        set(hFig,'Units','Pixels','Position',[10 30 700 750],...            %correlations are in long columns
            'Name',NameStr);
    else
        set(hFig,'Units','Pixels','Position',[10 30 1100 700],...           %for plots use bigger part of the screen
            'Name',NameStr);
    end
    ColNames = {'Surface tension,|[N/m]',...                                %set up ColNames for correlation data
        'Density,|[kg/m3]','Viscosity,|[Pa s]',...
        'Dimensionless,|flow rate, [-]','Plate incl.|angle,[deg]',...
        'F-Factor,|[Pa^0.5]','Riv. surface|area, [m2]'};
else
    if plots == 0
        set(hFig,'Units','Pixels','Position',[10 30 950 200],...             %for description, there are more columns than rows
            'Name',NameStr);
    else
        set(hFig,'Units','Pixels','Position',[10 30 1100 700],...           %for plots use bigger part of the screen
            'Name',NameStr);
    end
    ColNames = 1:numel(data(1,1:end-6));                                    %last six columns are auxiliary variables to be named
    ColNames = reshape(strtrim(cellstr(num2str(ColNames(:)))), size(ColNames));
    ColNames = [ColNames {'' 'Mean|value' 'Standard|deviation'...
        'Dimensionless|flow rate, [-]' 'F-Factor,|[Pa^0.5]',...
        'Distance from|plate top, [m]'}];
end
% set up table position vector
if plots == 0
    tablePosVec = [0 0 1 1];
elseif plots == 1 && type == 0                                              %plots with correlation data
    tablePosVec = [0.025 0.025 0.450 0.950];                                %take left side of figure for uitable
    axesPosVec  = [0.475 0.025 0.500 0.950];                                %and right side for axes
elseif plots == 1 && type == 1;                                             %plots with descriptive data
    tablePosVec = [0.025 0.750 0.950 0.225];                                %top side for uitable
    axesPosVec  = [0.025 0.025 0.950 0.725];                                %and bottom for axes
end
hTable = uitable(hFig,'Data',data,...
    'ColumnWidth',{90}, ...
    'ColumnName',ColNames,...
    'Units','Normal', 'Position',tablePosVec);
if plots == 1
    % create axes in space set up by axesPosVec
    hAxes = axes('OuterPosition',axesPosVec);                               %create axes in left space
    if type == 0
        hPlot1 = plot(hAxes,data(:,4),data(:,end),'ro');                     %plot all data as red circles
        hold on
        uniqueFlowRates  = unique(data(:,4));                               %get all unique dimensionless flow rates
        meanIFArea       = zeros(1,numel(uniqueFlowRates));                 %preallocate variable for mean values
        for i = 1:numel(uniqueFlowRates)
            meanIFArea(i) = mean(data(uniqueFlowRates(i) == data(:,4),end));%calculate mean IF area for unique flow rate
        end
        hPlot2 = plot(hAxes,uniqueFlowRates,meanIFArea,'g','LineWidth',2);   %add trend line to the graph
        title(['\bf Interfacial area as fun. of '...
            'dimensionless flow rate'],'FontSize',13);
        xlabel('dimensionless flow rate, [-]');
        ylabel('interfacial area of the rivulet, [m^2]');
        set(hPlot1,'MarkerSize',10,'MarkerFaceColor','y');
        legend(hPlot2,'Mean values - Trend line')
    else
        % Create an invisible marker plot of the data and save handles
        % to the lineseries objects; use this to simulate data brushing.
        hmkrs = plot(hAxes,data(:,end),data(:,1:end-3), ...
            'Marker', 'o',...
            'MarkerFaceColor', 'y',...
            'HandleVisibility', 'off',...
            'Visible', 'off');
        xlabel('distance from the top of the plate, [m]');
        xlim([0 plateSize(2)]);                                             %set limits of x-axes
        ylabel('output data values');
        title('\bf Output data','FontSize',13)
        set(hTable,'CellSelectionCallback',@hTableSelectionCallback,...     %set CellSelectionCallback for the table
            'ToolTipString','Select columns to plot them');                 %set tooltip for the table
    end 
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
        xvals = data(xvals,end);                                            %select x-values from data table - distance from the top of the plate
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

end