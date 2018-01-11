function CorrectSubjectIDs
%CORRECTSUBJECTIDS Summary of this function goes here
%   Detailed explanation goes here


idPath = '\\root\projects\CLSA-ChineseClassroom\subjectIDs.xlsx';

dataPath = '\\root\projects\CLSA-ChineseClassroom\DaysimeterData\cropped\2018-01-10_1502.mat';

tb = readtable(idPath);

db = load(dataPath);

objArray = db.objArray;


for iObj = 1:numel(objArray)
    idx = objArray(iObj).SerialNumber == tb.DaysimeterSerialNumber;
    objArray(iObj).ID = num2str(tb.AssignedDaysimeterNumber(idx));
end

% Sort by subject and session
tmpSessions = vertcat(objArray(:).Session);
tmpTable = table({objArray(:).ID}',{tmpSessions(:).Name}','VariableNames',{'ID','Session'});
[~, idxSort] = sortrows(tmpTable,{'ID','Session'});
objArray = objArray(idxSort);

save(dataPath, 'objArray')
end

