function [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
%   [state prbMsg sumMsg] = controlFunction(EdgCoord)
%
% function for controling the output of findEdges function. The algorithm
% walks through the EdgCoord matrix and saves positions of the wrongly
% guessed coordinates into problemIndexes matrix. If the control is passed
% without any problems, the state variable is set to 0.
%
% Algorithm:
% - at first, the NaN values are removed.
% - than the mean value and kurtosis of each column are calculated
% - from kurtosis is defined coefficient for search for outliers in each
%   column
% - outliers are found
%
% INPUT variables
% EdgCoord  ... matrix of guessed edge coordinates, output of function
%               findEdges
%
% OUTPUT variables
% state     ... how well are defined the edges
%               [nSC oSC nBC oBC nPl oPl], where
%               nSc     ... number of NaN in small cuvettes
%               oSc     ... number of outerliers in small cuvettes
%               and so on...
%           ... the length of state variable can vary in dependence of
%               found problem from 1(scalar) up to 4 [1 2 3 4];
% prbMsg    ... structure containing indexes of rows (images)
%               where was found something odd
% sumMsg    ... summary message for the found problems
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% License: This code is published under MIT License, please do not abuse
% it.
%
% See also FINDEDGES MODIFYFUNCTION

nCol = size(EdgCoord,2);                                                    %number of columns in the input matrix (10)
k    = 1;                                                                   %auxiliary indexing variable for prbMsg
% problem counters
nSC  = 0; oSC = 0;                                                          %n* counts NaN and o* outliers
nBC  = 0; oBC = 0;
nPl  = 0; oPl = 0;
for i = 1:nCol                                                              %better to do for each column separately(remove only parts of NaN row)
    tmpVar = EdgCoord(:,i);                                                 %reduce input matrix only to i-th column
    % find NaN values in the ith column of EdgCoord matrix
    INaN = find(isnan(EdgCoord(:,i)) == 1);
    tmpVar = tmpVar(isnan(tmpVar) == 0);                                     %remove rows with NaN in them
    % calculate standard deviation of each column of EdgCoord
    coordSTD= std(tmpVar);
    coordMU = mean(tmpVar);                                                 %mean value in each column
    coordKUR= kurtosis(tmpVar);                                             %curtosis of each column (should be 3 for normally distr. data)
    nRow    = numel(tmpVar);                                                %number of elements in tmpVar after removing the NaNs
    
    % calculating the coeficient for identifying outliers, for std. data
    % distr, it should be 3 and I will decrease it for more outlier-prone
    % datasets
    coef    = 7/coordKUR;                                                   %should be 9/.. but I am expecting very narrow data

    % find outliers - values more different than coef * std. deviation
    outliers= abs(tmpVar-coordMU(ones(nRow,1),:))>...
        coef*coordSTD(ones(nRow,1),:);                                      %matrix of indexes of values more different than coef * std. dev.
    Iout    = find(outliers == 1);                                          %find position of outliers
    % translate the Iout for each found NaN
    if isempty(INaN) == 0
        for j = 1:numel(INaN)
            Iout(Iout>=INaN(j)) = Iout(Iout>=INaN(j))+1;                    %must add 1 for every left out row
        end
    end
    % write out messages for the column
    Iwr = [Iout;INaN];
    for j = 1:length(Iwr)                                                   %for all problems
        prbMsg(k).coords = [Iwr(j) i];                                      %coordinates of the problem in the EdgCoord matrix
        prbMsg(k).nImg   = Iwr(j);                                          %number of problematic image
        if isempty(find(Iwr(j) == Iout, 1)) == 1
            prbMsg(k).type   = 'NaN';
        else
            prbMsg(k).type   = 'outliers';
        end
        if i < 4
            prbMsg(k).device = 'small cuvette';                             %write the device type to the structure
            if isempty(find(Iwr(j) == Iout, 1)) == 1                        %set counter for the device
                nSC = nSC + 1;
            else
                oSC = oSC + 1;
            end
        elseif i >= 4 && i < 7
            prbMsg(k).device = 'big cuvette';
            if isempty(find(Iwr(j) == Iout, 1)) == 1
                oBC = nBC + 1;
            else
                oBC = oBC + 1;
            end
        else
            prbMsg(k).device = 'plate';
            if isempty(find(Iwr(j) == Iout, 1)) == 1
                nPl = nPl + 1;
            else
                oPl = oPl + 1;
            end
        end
        k = k+1;
    end
end

% setting up state variable
state = [nSC oSC nBC oBC nPl oPl];

% setting up summary report
sumMsg.totalPrb = nSC + nBC + nPl + oSC + oBC + oPl;                        %total number of "warnings"
sumMsg.oSC      = oSC;
sumMsg.nSc      = nSC;
sumMsg.oBC      = oBC;
sumMsg.nBC      = nBC;
sumMsg.oPl      = oPl;
sumMsg.nPl      = nPl;
if sum(state) ~= 0                                                          %write out human readable string string for user
    sumMsg.string   = {['In EdgCoord matrix from '...
        mat2str(numel(EdgCoord(:,1))) ' images, there were found at total '...
        mat2str(sumMsg.totalPrb) ' problems. Namely there were found:']...
        [mat2str(oSC) ' outer values and ' mat2str(nSC)...
        ' NaN in Small cuvettes edges estimation,']...
        [mat2str(oBC) ' outer values and ' mat2str(nBC)...
        ' NaN in Big cuvettes edges estimation and']...
        [mat2str(oPl) ' outer values and ' mat2str(nPl)...
        ' NaN in plate edges estimation.']};
else
    sumMsg.string = 'There were no problems found.';
end

% check prbMsg variable existence
if exist('prbMsg','var') == 0
    prbMsg = struct([]);
end
end