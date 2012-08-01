function EdgCoord = modifyFunction(metricdata)
%
%   EdgCoord = modifyFunction(metricdata)
%
% Function that takes found coordinates and messages about rate of finding
% succes and returns modified coordinates base on user interaction
%
% For prefered automatic estimation, the outliers and NaN are replaced by
% mean values of found coordinates. Otherwise, the user can choose to find
% the problematic edges manually and then, is asked to specify 3 different
% points on each border from which is estimated the mean coordinate
%
% Rq: The code for manual selection is not very elegant, but it is doing
% what it is suppose to do...
%
% INPUT variables
% metricdata... structure obtained by previous run of the program,
%               must contain following fields:
% EdgCoord  ... matrix with estimated edge coordinates
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

% check if it is necessary to run the function
if isempty(metricdata.prbMsg) == 1                                          %no problem, than return
    EdgCoord = metricdata.EdgCoord;                                         %assign output variable
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

% write out results of edge finding and ask user what to do
if sum(state) ~= 0                                                          %there are some problems
    options.Default = 'From mean values';
    options.Interpreter = 'tex';
    stringCell= [sumMsg.string{:} {'Do you want to modify these edges:'}];
    choice = myQst('autstr',stringCell);
    if strcmp(choice,'Show EdgCoord') == 1                                  %user wants to show the EdgeCoord matrix
        coefVec= 7./kurtosis(EdgCoord);
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
            'Name','EdgCoord','MenuBar', 'none','NumberTitle', 'off');      %set window size +- matching the EdgeCoord needs
        openUITable(hFig,EdgCoord,prbCoord,coefVec,0);
        choice = menu('Modify selected values',...
            'From mean values','Manually','Don`t modify');                  %questdlg is prettier, but menu is not modal
        switch choice
            case 1
                choice = 'From mean values';
            case 2
                choice = 'Manually';
            case 3
                choice = 'Don`t modify';
        end
    end
else
    msgbox('Edges of the plate and cuvettes were found','modal');
    uiwait(gcf);
    choice = 'Don`t modify';
end

% switch in dependence on user choice
% manual specification of the cuvettes edges shoud be fun :-/ (let's leave
% it out for now - cuvettes edge finding is quite solid, the mean values
% shoud be enough)
switch choice
    case 'From mean values'
        tmpVec= unique(prbCoord(:,2));
        for j = 1:numel(tmpVec)                                             %for every column with problem
            i = tmpVec(j);
            EdgCoord(prbCoord(prbCoord(:,2) == i),i) =...                   %all values with specified column index
                round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i))));%replace all outliers and NaN with mean values of the rest
        end
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
                    tmpIM = imread([subsImDir imNames{1}]);                 %load image from directory with substracted images
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
        else                                                                %user wants directly modify values
            if exist('coefVec','var') == 0                                  %if coefVec is not specified (no table was opened yet)
                coefVec= 7./kurtosis(EdgCoord);
                hFig = figure;                                              %open figure window
                set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
                    'Name','EdgCoord','MenuBar', 'none','NumberTitle', 'off');%set window size +- matching the EdgeCoord needs
            end
            EdgCoord = openUITable(hFig,EdgCoord,prbCoord,coefVec,1);
        end
    case 'Don`t modify'
end

% see if hFig is opened and if it is, actualize it
if exist('hFig','var') == 1
    openUITable(hFig,EdgCoord,prbCoord,coefVec,0);
end
hMBox = msgbox('Press Enter to continue','modal');uiwait(hMBox);            %notify user about end of the program
if exist('hFig','var')                                                      %if exists, close uitable
    close(hFig)
end
end

function modData = openUITable(hFig,EdgCoord,prbCoord,coefVec,allowEdit)
%
%   function openUITable(EdgCoord,prbCoord,coefVec,allowEdit)
%
% function for opening uitable with specified parameters and highlighted
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
%

% calculate mean values of not-NaN and not-outliers for each column
meanVals = round(mean(EdgCoord));                                           %calculate mean for all values
tmpVec= unique(prbCoord(:,2));
for j = 1:numel(tmpVec)                                                     %for every column with problem
    i = tmpVec(j);
    meanVals(i) =...
       round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i)))); %remove all the NaN and outliers from mean value estimation
end

% construct temporary matrix for writing
tmpMat = [EdgCoord;meanVals;kurtosis(EdgCoord);...                          %tmpMat with mean value, kurtosis and used coefficient for finding
    coefVec];                                                               %outliers in each column
tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
for i = 1:numel(prbCoord(:,1))
    tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                        %modify format of the problematic value
        '<html><span style="color: #FF0000; font-weight: bold;">', ...
        tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
        '</span></html>');
end
tmpMat(end-2,:) = strcat(...                                                %modify format of the mean value
    '<html><span style="color: #FF00FF; font-weight: bold;">', ...
    tmpMat(end-2,:), ...
    '</span></html>');
tmpMat(end-1,:) = strcat(...                                                %modify format of the kurtosis
    '<html><span style="color: #0000FF; font-weight: bold;">', ...
    tmpMat(end-1,:), ...
    '</span></html>');
tmpMat(end,:) = strcat(...                                                  %modify format of the used coeficient
    '<html><span style="color: #FFFF00; font-weight: bold;">', ...
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
rowNames = [rowNames {'Mean Value' 'Kurtosis' 'Used coef.'}];
if allowEdit == 1                                                           %want I let user to change columns
    ColumnEditable = zeros(1,numel(EdgCoord(1,:)));
    ColumnEditable(unique(prbCoord(:,2))) = 1;                              %make columns with NaNs and outliers editable
    ColumnEditable = logical(ColumnEditable);
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
        modData = regexp(modData,'([1-9])[\d.]\d+','match');                %'unformat' these values
        modData = cellfun(@str2double,modData);                             %convert them to double
        modData = modData(1:end-2,:);                                       %strip off automatically generated values
    end
end
end

function hTableEditCallback(o,e)
tableData = get(o, 'Data');
if (e.Indices(1) > numel(tableData(:,1))-3)                                 %check if the user is not trying to modify automatically gen. data
    tableData{e.Indices(1), e.Indices(2)} = e.PreviousData;
    set(o, 'data', tableData);
    errordlg('Do not modify automatically generated values','modal')
else
    tmpData = regexp(tableData(:,e.Indices(2)),'([1-9])[\d.]\d+','match');  %unformat column of data with modified value
    tmpData = cellfun(@str2double,tmpData);                                 %convert column into doubles
    tmpData = [round(mean(tmpData(1:end-2)));                               %update automatically modified values
               kurtosis(tmpData(1:end-2))];
    tmpData = reshape(strtrim(cellstr(num2str(tmpData(:)))),size(tmpData)); %convert results into string
    tmpData(1) = strcat(...                                                 %modify format of automatically modified data
        '<html><span style="color: #FF00FF; font-weight: bold;">', ...
        tmpData(1), ...
        '</span></html>');
    tmpData(2) = strcat(...
        '<html><span style="color: #0000FF; font-weight: bold;">', ...
        tmpData(2), ...
        '</span></html>');
    tableData(end-2:end-1,e.Indices(2)) = tmpData;                          %reconstruct data table
    set(o,'data',tableData);                                                %push data back to uitable
end
end