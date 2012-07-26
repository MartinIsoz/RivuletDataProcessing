function EdgCoord = modifyFunction(EdgCoord,IMdataCell,state,prbMsg,sumMsg)
%
%   EdgCoord = modifyFunction(EdgCoord,daten,state,prbMsg,sumMsg)
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
% EdgCoord  ... matrix with estimated edge coordinates
% IMdataCell... cell with image data
% state
% prbMsg    ... outputs from controlFunction
% sumMsg

%check if it is necessary to run the function
if isempty(prbMsg) == 1                                                     %no problem, than return
    return
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
        tmpMat = [EdgCoord;round(mean(EdgCoord));kurtosis(EdgCoord);...     %tmpMat with mean value, kurtosis and used coefficient for finding
            coefVec];                                                       %outliers in each column
        tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
        for i = 1:numel(prbCoord(:,1))
            tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                %modify format of the problematic value
                '<html><span style="color: #FF0000; font-weight: bold;">', ...
                tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
                '</span></html>');
        end
        tmpMat(end-2,:) = strcat(...                                        %modify format of the mean value
                '<html><span style="color: #FF00FF; font-weight: bold;">', ...
                tmpMat(end-2,:), ...
                '</span></html>');
        tmpMat(end-1,:) = strcat(...                                        %modify format of the kurtosis
                '<html><span style="color: #0000FF; font-weight: bold;">', ...
                tmpMat(end-1,:), ...
                '</span></html>');
        tmpMat(end,:) = strcat(...                                          %modify format of the used coeficient
                '<html><span style="color: #FFFF00; font-weight: bold;">', ...
                tmpMat(end,:), ...
                '</span></html>');
        colNames = {'Small cuv. xMean',...                                  %set column names
            'Small cuv. yTop', 'Small cuv. yBottom',...
            'Big cuv. xMean',...
            'Big cuv. yTop', 'Big cuv. yBottom',...
            'Plate xLeft','Plate yTop',...
            'Plate xRight','Plate yBottom'};
        rowNames = 1:numel(EdgCoord(:,1));                                  %set row names
        rowNames = reshape(strtrim(cellstr(num2str(rowNames(:)))), size(rowNames));
        rowNames = [rowNames {'Mean Value' 'Kurtosis' 'Used coef.'}];
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
            'Name','EdgCoord');               %set window size +- matching the EdgeCoord needs
        uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...                %open uitable
            'RowName',rowNames,...
            'ColumnEditable',false,...
            'ColumnWidth','auto', ...
            'Units','Normal', 'Position',[0 0 1 1]);                        %open EdgeCoord in uitable
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
            save_to_base(1);
            EdgCoord(prbCoord(prbCoord(:,2) == i),i) =...                   %all values with specified column index
                round(mean(removerows(EdgCoord(:,i),prbCoord(prbCoord(:,2) == i))));%replace all outliers and NaN with mean values of the rest
        end
    case 'Manually'
        se      = strel('disk',12);                                         %morphological structuring element
        strVerL = 'Specify {\bf 3} times left vertical edge of the ';       %string preparation
        strVerR = 'Specify {\bf 3} times right vertical edge of the ';
        strHorT = 'Specify {\bf 3} times top horizontal edge of the ';
        strHorB = 'Specify {\bf 3} times bottom horizontal edge of the ';
        options.WindowStyle = 'modal';
        options.Interpreter = 'tex';
        for k = 1:numel(prbCoord(:,2));                                     %for all problems
            i = prbCoord(k,1);j = prbCoord(k,2);                            %save indexes into temporary variables
            switch prbMsg(k).device                                         %check the device, extreme SWITCH...
                case 'plate'
                    tmpIM = IMdataCell{i}(:,1:2*round(end/3));              %for the plate I need only left side of the image
                    trVec = [0 0];
                    if mod(j,7) == 0                                        %left vertical edge
                        str = [strVerL prbMsg(k).device];
                        chInd   = 1;
                    elseif mod(j,7) == 1                                    %top horizontal edge
                        str = [strHorT prbMsg(k).device];
                        chInd   = 2;
                    elseif mod(j,7) == 2                                    %right vertical edge
                        str = [strVerR prbMsg(k).device];
                        chInd   = 1;
                    else                                                    %bottom horizontal edge
                        str = [strHorB prbMsg(k).device];
                        chInd   = 2;
                    end
                    nInput  = 3;
                otherwise
                    if strcmp(prbMsg(k).device,'small cuvette') == 1        %choose which part of the image I want to show
                        tmpIM = IMdataCell{i}(1:round(2*end/3),round(end/2):end);%for small cuvette I need only top right side of the image
                        trVec = [round(size(IMdataCell{i},2)/2)-1 0];
                    else
                        tmpIM = IMdataCell{i}(round(end/3):end,round(end/2):end);%for big cuvette I need only bottom right side of the imagee
                        trVec = [round(size(IMdataCell{i},2)/2)-1 round(size(IMdataCell{i},1))];
                    end
                    if mod(j,3) == 1                                        %indexes 1 or 4, mean x values of cuvettes
                        str = ['Specify both vertical edges of the '...
                            prbMsg(k).device ', both of them {\bf 3} times.'];
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
    case 'Don`t modify'
end

% see if hFig is opened and if it is, actualize it
if exist('hFig','var') == 1
    tmpMat = [EdgCoord;round(mean(EdgCoord));kurtosis(EdgCoord);coefVec];
    tmpMat = reshape(strtrim(cellstr(num2str(tmpMat(:)))), size(tmpMat));
    for i = 1:numel(prbCoord(:,1))
        tmpMat(prbCoord(i,1),prbCoord(i,2)) = strcat(...                    %modify format of the problematic value
            '<html><span style="color: #FF0000; font-weight: bold;">', ...
            tmpMat(prbCoord(i,1),prbCoord(i,2)), ...
            '</span></html>');
    end
    tmpMat(end-2,:) = strcat(...                                            %modify format of the mean value
        '<html><span style="color: #FF00FF; font-weight: bold;">', ...
        tmpMat(end-2,:), ...
        '</span></html>');
    tmpMat(end-1,:) = strcat(...                                            %modify format of the kurtosis
        '<html><span style="color: #0000FF; font-weight: bold;">', ...
        tmpMat(end-1,:), ...
        '</span></html>');
    tmpMat(end,:) = strcat(...                                              %modify format of the used coeficient
        '<html><span style="color: #FFFF00; font-weight: bold;">', ...
        tmpMat(end,:), ...
        '</span></html>');
    colNames = {'Small cuv. xMean',...                                      %set column names
        'Small cuv. yTop', 'Small cuv. yBottom',...
        'Big cuv. xMean',...
        'Big cuv. yTop', 'Big cuv. yBottom',...
        'Plate xLeft','Plate yTop',...
        'Plate xRight','Plate yBottom'};
    rowNames = 1:numel(EdgCoord(:,1));                                      %set row names
    rowNames = reshape(strtrim(cellstr(num2str(rowNames(:)))), size(rowNames));
    rowNames = [rowNames {'Mean Value' 'Kurtosis' 'Used coef.'}];
    uitable(hFig,'Data',tmpMat,'ColumnName',colNames,...                    %open uitable
        'RowName',rowNames,...
        'ColumnEditable',false,...
        'ColumnWidth','auto', ...
        'Units','Normal', 'Position',[0 0 1 1]);                            %open EdgeCoord in uitable
end
hMBox = msgbox('Press Enter to continue','modal');uiwait(hMBox);            %notify user about end of the program
if exist('hFig','var')                                                      %if exists, close uitable
    close(hFig)
end
end