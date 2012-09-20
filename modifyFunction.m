function EdgCoord = modifyFunction(metricdata)
%
%   EdgCoord = modifyFunction(metricdata)
%
% Function that takes found coordinates and messages about rate of finding
% succes and returns modified coordinates based on user interaction
%
% For prefered automatic estimation of edges coordinates, program takes
% proposed values (Prop. Values) which are the mean values calculated from
% rows without outliers and NaN. Otherwise, user can choose to specify
% coodrinates manual either by entering proposed values directly into the
% table or by respecifying the problematic edges graphically
%
% Rq: The code for manual selection is not very elegant, but it is doing
% what it is suppose to do...
%
% INPUT variables
% metricdata... structure obtained by previous run of the program,
%               must contain following fields:
% EdgCoord  ... matrix with estimated edges coordinates (nImages x 10)
% state
% prbMsg    ... outputs from controlFunction
% sumMsg
%
%               there also must be present specific combination of
%               following fields:
% daten     ... cell with image data
% imNames   ... if daten is not present this list of processed images
%               names is used for loading images from subsImDir
% subsImDir ... if daten is not present, images specified by imNames are
%               loaded from this directory
%
% OUTPUT variable
% EdgCoord  ... vector with estimated edges coordinates (1 x 10)
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also FINDEDGES CONTROLFUNCTION

% check if it is necessary to run the function
if isempty(metricdata.prbMsg) == 1                                          %no problem, than return
    EdgCoord = mean(metricdata.EdgCoord);                                   %assign output variable as mean of matrix columns
    return
end

% process input:
EdgCoord = metricdata.EdgCoord;
state    = metricdata.state;
prbMsg   = metricdata.prbMsg;
sumMsg   = metricdata.sumMsg;
if isfield(metricdata,'daten') == 1                                         %there are present image data into metricdata
    IMDataCell = metricdata.daten;
    DNTLoadIM  = 0;
else
    imNames    = metricdata.imNames;
    subsImDir  = metricdata.subsImDir;
    DNTLoadIM  = 1;
end

% extract variables auxiliary variables from structures
% prbMsg.coords -> [row column] of the problem
prbCoord = zeros(numel(prbMsg),2);                                          %preallocate variable for problems coordinates
parfor i = 1:numel(prbMsg)
    prbCoord(i,:) = prbMsg(i).coords;
end

% calculate mean values and std of not-NaN and not-outliers for each column
propVals = round(mean(EdgCoord));                                           %calculate mean for all values
tmpVec= unique(prbCoord(:,2));
for j = 1:numel(tmpVec)                                                     %for every column with problem
    i = tmpVec(j);
    propVals(i) =...
       round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i)))); %remove all the NaN and outliers from mean value estimation
end

% write out results of edge finding and ask user what to do
if sum(state) ~= 0                                                          %there are some problems
    options.Default = 'Accept proposed values';
    options.Interpreter = 'tex';
    strVals             = cellstr(num2str(propVals'))';                     %cell with strings of proposed edges coordinates
    stringCell= [sumMsg.string{:}...                                        %summary of found problemes
        {''}...
        {'Proposed edges coordinates:'}...                                  %proposed coordiantes
        {''}...
        {['x^M_{SC} = ' strVals{1} '   x^M_{BC} = ' strVals{4}]}...
        {''}...
        {['y^T_{SC} = ' strVals{2} '   y^T_{BC} = ' strVals{5}]}...
        {''}...
        {['y^B_{SC} = ' strVals{3} '   y^B_{BC} = ' strVals{6}]}...
        {''}...
        {['x^L_{PL}  = ' strVals{7} '   x^R_{PL}  = ' strVals{9}]}...
        {''}...
        {['y^T_{PL}  = ' strVals{8} '   y^B_{PL}  = ' strVals{10}]}...
        {''}];
    choice = questdlg(stringCell,'Edges finding summary',...
        'Accept proposed values','Show EdgCoord',options);
    switch choice
        case 'Accept proposed values'
            EdgCoord = propVals;
        case 'Show EdgCoord'
            coefVec= 7./kurtosis(EdgCoord);
            hFig = figure;                                                  %open figure window
            set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
                'Name','EdgCoord','MenuBar', 'none','NumberTitle', 'off');  %set window size +- matching the EdgeCoord needs
            openUITable(hFig,EdgCoord,prbCoord,coefVec,0);
            choice = menu('Prepare EdgCoord',...
                'Accept proposed values','Manually');                       %questdlg is prettier, but menu is not modal
            switch choice
                case 1
                    choice = 'Accept proposed values';
                case 2
                    choice = 'Manually';
            end
    end
end


% switch in dependence on user choice
% manual specification of the cuvettes edges shoud be fun :-/ (let's leave
% it out for now - cuvettes edge finding is quite solid, the mean values
% shoud be enough)
switch choice
    case 'Accept proposed values'
        EdgCoord = propVals;
    case 'Manually'
        choice  = menu('Do you want to:',...                                %open new menu, and let user choose between graphical and text input
            'Specify new values graphically',...
            'Directly modify values in table');
        if choice == 1                                                      %user wants to specify new values from images
            se      = strel('disk',12);                                     %morphological structuring element
            strVerL = 'Specify {\bf 3} times left vertical edge of the ';   %string preparation
            strVerR = 'Specify {\bf 3} times right vertical edge of the ';
            strHorT = 'Specify {\bf 3} times top horizontal edge of the ';
            strHorB = 'Specify {\bf 3} times bottom horizontal edge of the ';
            options.WindowStyle = 'modal';
            options.Interpreter = 'tex';
            for k = 1:numel(prbCoord(:,2));                                 %for all problems
                i = prbCoord(k,1);j = prbCoord(k,2);                        %save indexes into temporary variables
                if DNTLoadIM == 1                                           %if the images are not loaded, i need to get the image from directory
                    tmpIM = imread([subsImDir '/' imNames{1}]);             %load image from directory with substracted images
                else
                    tmpIM = IMDataCell{i};                                  %else i can get it from handles
                end
                switch prbMsg(k).device                                     %check the device, extreme SWITCH...
                    case 'plate'
                        tmpIM = tmpIM(:,1:2*round(end/3));                  %for the plate I need only left side of the image
                        trVec = [0 0];
                        if mod(j,7) == 0                                    %left vertical edge
                            str = [strVerL prbMsg(k).device];
                            chInd   = 1;
                        elseif mod(j,7) == 1                                %top horizontal edge
                            str = [strHorT prbMsg(k).device];
                            chInd   = 2;
                        elseif mod(j,7) == 2                                %right vertical edge
                            str = [strVerR prbMsg(k).device];
                            chInd   = 1;
                        else                                                %bottom horizontal edge
                            str = [strHorB prbMsg(k).device];
                            chInd   = 2;
                        end
                        nInput  = 3;
                    otherwise
                        if strcmp(prbMsg(k).device,'small cuvette') == 1        %choose which part of the image I want to show
                            tmpIM = tmpIM(1:round(2*end/3),round(end/2):end);   %for small cuvette I need only top right side of the image
                            trVec = [round(size(tmpIM,2)/2)-1 0];
                        else
                            tmpIM = tmpIM(round(end/3):end,round(end/2):end);   %for big cuvette I need only bottom right side of the imagee
                            trVec = [round(size(tmpIM,2)/2)-1 round(size(tmpIM,1))];
                        end
                        if mod(j,3) == 1                                        %indexes 1 or 4, mean x values of cuvettes
                            str = ['Specify both vertical edges of the '...
                                prbMsg(k).device...
                                ', both of them {\bf 3} times.'];
                            nInput = 6;                                         %need to take 6 inputs from ginput
                            chInd   = 1;                                        %I am interested in first ginput coordinate
                        elseif mod(j,3) == 2                                    %top horizontal edge
                            str = [strHorT prbMsg(k).device];
                            nInput  = 3;                                        %need to take 3 inputs from ginput
                            chInd   = 2;                                        %I am interested second ginput coordinate
                        else                                                    %bottom horiznotal edge
                            str = [strHorB prbMsg(k).device];
                            nInput  = 3;                                        %need to take 3 inputs from ginput
                            chInd   = 2;                                        %I am interested in second ginput coordinate
                        end
                end                
            % write out info about what should be specified
            msgbox(str,options);uiwait(gcf);
            % some image processing
            tmpIM   = imtophat(tmpIM,se);
            tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);        %enhance contrasts
            tmpIM   = im2bw(tmpIM,0.16);                                    %conversion to black and white
            figure;imshow(tmpIM);                                           %show image to work with
            tmpMat  = ginput(nInput);close(gcf);
            EdgCoord(i,j) = round(mean(tmpMat(:,chInd))) + trVec(chInd);
            end
            EdgCoord    = round(mean(EdgCoord));                            %take only mean values of specified coordinates
        else                                                                %user wants directly modify values
            if exist('coefVec','var') == 0                                  %if coefVec is not specified (no table was opened yet)
                coefVec= 7./kurtosis(EdgCoord);
                hFig = figure;                                              %open figure window
                set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
                    'Name','EdgCoord','MenuBar', 'none','NumberTitle', 'off');%set window size +- matching the EdgeCoord needs
            end
            EdgCoord = openUITable(hFig,EdgCoord,prbCoord,coefVec,1);
        end
end

if exist('hFig','var')                                                      %if exists, close uitable
    close(hFig)
end
end

function modData = openUITable(hFig,EdgCoord,prbCoord,coefVec,allowEdit)
%
%   function openUITable(EdgCoord,prbCoord,coefVec,allowEdit)
%
% function for opening uitable with specified parameters, highlighted
% outlietr and NaNs
%
% INPUT variables
% hFig      ... handles to figure where uitable shoud be opened
% EdgCoord  ... variable to be shown in uitable
% prbCoord  ... coordinates of NaNs and outliers in the EdgCoord
% coefVec   ... vector of coeficients used for identifying outliers
% allowEdit ... 0/1 if I want allow user to edit fields in resulting
%               uitable
%
% OUTPUT variables
% modData   ... vector with modified proposed values
%

% calculate mean values and std of not-NaN and not-outliers for each column
meanVals = round(mean(EdgCoord));                                           %calculate mean for all values
stdVals  = std(EdgCoord);
tmpVec= unique(prbCoord(:,2));
for j = 1:numel(tmpVec)                                                     %for every column with problem
    i = tmpVec(j);
    meanVals(i) =...
       round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i)))); %remove all the NaN and outliers from mean value estimation
    stdVals(i)  =...
       std(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i)));         %remove all the NaN and outliers from std. dev. estimation
end
propVals = meanVals;                                                        %values proposed as edges coordinates

% construct temporary matrix for writing
tmpMat = [EdgCoord;meanVals;stdVals;kurtosis(EdgCoord);...                  %tmpMat with mean value, std. dev., kurtosis, coefficient for f.
    coefVec;propVals];                                                      %outliers in each column and proposed values for edges coordinates
tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
for i = 1:numel(prbCoord(:,1))
    tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                        %modify format of the problematic value
        '<html><span style="color: #FF0000; font-weight: bold;">', ...
        tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
        '</span></html>');
end
tmpMat(end-4,:) = strcat(...                                                %modify format of the mean value
    '<html><span style="color: #FF00FF; font-weight: bold;">', ...
    tmpMat(end-4,:), ...
    '</span></html>');
tmpMat(end-3,:) = strcat(...                                                %modify format of the standard deviation
    '<html><span style="color: #00FFFF; font-weight: bold;">', ...
    tmpMat(end-3,:), ...
    '</span></html>');
tmpMat(end-2,:) = strcat(...                                                %modify format of the kurtosis
    '<html><span style="color: #0000FF; font-weight: bold;">', ...
    tmpMat(end-2,:), ...
    '</span></html>');
tmpMat(end-1,:) = strcat(...                                                %modify format of the used coeficient
    '<html><span style="color: #FFFF00; font-weight: bold;">', ...
    tmpMat(end-1,:), ...
    '</span></html>');
tmpMat(end,:) = strcat(...                                                  %modify format of the proposed values
    '<html><span style="color: #00FF00; font-weight: bold;">', ...
    tmpMat(end,:), ...
    '</span></html>');
colNames = {'Small cuv. xMean',...                                          %set column names
    'Small cuv. yTop', 'Small cuv. yBottom',...
    'Big cuv. xMean',...
    'Big cuv. yTop', 'Big cuv. yBottom',...
    'Plate xLeft','Plate yTop',...
    'Plate xRight','Plate yBottom'};
rowNames = 1:numel(EdgCoord(:,1));                                          %set row names
rowNames = reshape(strtrim(cellstr(num2str(rowNames(:)))), size(rowNames));
rowNames = [rowNames...
    {'Mean Value' 'Std. dev.' 'Kurtosis' 'Used coef.' 'Prop. Values'}];
if allowEdit == 1                                                           %want I let user to change columns
    ColumnEditable = true(1,numel(EdgCoord(1,:)));                          %make all columns of the table editable
else
    ColumnEditable = [];
end
hTable = uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...               %open uitable
    'RowName',rowNames,...
    'ColumnEditable',ColumnEditable,...
    'ColumnWidth','auto', ...
    'Units','Normal', 'Position',[0 0 1 1]);
if allowEdit == 1
    set(hTable,'CellEditCallback', @hTableEditCallback);                    %set cell edit callback and DeleteFcn
    choice = menu('Save values and stop editing','OK');
    if choice == 1                                                          %if user is done editing values
        modData = get(hTable,'Data');
        modData = regexp(modData(end,:),'([1-9])[\d.]\d+','match');         %'unformat' modified proposed values
        modData = cellfun(@str2double,modData);                             %convert them to double
    end
else
    modData = get(hTable,'Data');
    modData = regexp(modData(end,:),'([1-9])[\d.]\d+','match');             %'unformat' modified proposed values
    modData = cellfun(@str2double,modData,'UniformOutput',false);           %convert them to double
end
end

function hTableEditCallback(o,e)
tableData = get(o, 'Data');
if (e.Indices(1)<numel(tableData(:,1)))                                     %check if the user is not trying to something else than prop. values
    tableData{e.Indices(1), e.Indices(2)} = e.PreviousData;
    set(o, 'data', tableData);
    errordlg('You can modify only Proposed values','modal')
else
    tmpData = regexp(tableData(end,e.Indices(2)),'([1-9])[\d.]\d+','match');%unformat column of data with modified value
    tmpData = cellfun(@str2double,tmpData);                                 %convert column into doubles
    tmpData = reshape(strtrim(cellstr(num2str(tmpData(:)))),size(tmpData)); %convert results into string
    tmpData = strcat(...                                                  %modify format of the proposed values
        '<html><span style="color: #00FF00; font-weight: bold;">', ...
        tmpData, ...
        '</span></html>');
    tableData(end,e.Indices(2)) = tmpData;                                  %reconstruct data table
    set(o,'data',tableData);                                                %push data back to uitable
end
end