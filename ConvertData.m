function varargout = ConvertData

clear
clc

addpath('C:\Users\jonesg5\Documents\GitHub\d12pack')
addpath('C:\Users\jonesg5\Documents\GitHub\circadian')

rootDir = '\\root\projects';
calPath = fullfile(rootDir,'DaysimeterAndDimesimeterReferenceFiles',...
    'recalibration2016','calibration_log.csv');

projectDir = '\\ROOT\projects\CLSA-ChineseClassroom\DaysimeterData';
croppedDir = fullfile(projectDir,'cropped');
dataDir    = fullfile(projectDir,'original');

timestamp = datestr(now,'yyyy-mm-dd_HHMM');
dbName  = [timestamp,'.mat'];
dbPath  = fullfile(projectDir,'converted',dbName);

previousData = loadData(croppedDir);
if ~isempty(previousData)
    previousSubjects = {previousData.ID}';
    previousSessionsTemp = vertcat(previousData.Session);
    previousSessions = {previousSessionsTemp.Name}';
else
    previousSubjects = {''};
    previousSessions = {''};
end

sessionLs = dir(fullfile(dataDir,'week*'));
cdfPaths = {};
sessionNames = {};

for iSession = 1:numel(sessionLs)
    thisSession = sessionLs(iSession).name;
    thisSessionPath = fullfile(sessionLs(iSession).folder,thisSession);
    cdfLs    = dir(fullfile(thisSessionPath,'*.cdf'));
    cdfPaths = vertcat(cdfPaths,fullfile(thisSessionPath,{cdfLs.name}'));
    tempSessionNames = repmat({thisSession},size(cdfLs));
    sessionNames = vertcat(sessionNames, tempSessionNames);
end

datalogPaths = regexprep(cdfPaths,'\.cdf','-DATA.txt');
loginfoPaths = regexprep(cdfPaths,'\.cdf','-LOG.txt');

nFile = numel(cdfPaths);


riseTime = duration(24+6, 10, 0);
bedTime  = duration(  21, 50, 0);

% Convert files to objects
ii = 1;
for iFile = 1:nFile
    obj = d12pack.HumanData;
    
    obj.CalibrationPath = calPath;
    obj.RatioMethod     = 'normal';
    obj.TimeZoneLaunch	= 'Asia/Hong_Kong';
    obj.TimeZoneDeploy	= 'Asia/Hong_Kong';
    
    % Set session of coppied objects
    obj.Session = struct('Name',sessionNames{iFile});
    
    % Import the original data
    obj.log_info = obj.readloginfo(loginfoPaths{iFile});
    obj.data_log = obj.readdatalog(datalogPaths{iFile});
    
    % Create observation mask
    switch obj.Session.Name
        case 'week0'
            startDate = datetime(2017, 11, 13,  6, 10, 0, 'TimeZone', obj.TimeZoneLaunch);
            stopDate  = datetime(2017, 11, 19, 21, 50, 0, 'TimeZone', obj.TimeZoneLaunch);
        case 'week2'
            startDate = datetime(2017, 11, 27,  6, 10, 0, 'TimeZone', obj.TimeZoneLaunch);
            stopDate  = datetime(2017, 12,  3, 21, 50, 0, 'TimeZone', obj.TimeZoneLaunch);
        case 'week5'
            startDate = datetime(2017, 12, 19,  6, 10, 0, 'TimeZone', obj.TimeZoneLaunch);
            stopDate  = datetime(2017, 12, 29, 21, 50, 0, 'TimeZone', obj.TimeZoneLaunch);
        case 'week8'
            startDate = datetime(2018,  1,  8,  6, 10, 0, 'TimeZone', obj.TimeZoneLaunch);
            stopDate  = datetime(2018,  1, 14, 21, 50, 0, 'TimeZone', obj.TimeZoneLaunch);
        case 'week9'
            startDate = datetime(2018,  1, 15,  6, 10, 0, 'TimeZone', obj.TimeZoneLaunch);
            stopDate  = datetime(2018,  1, 21, 21, 50, 0, 'TimeZone', obj.TimeZoneLaunch);
        otherwise
            error('unknown session name')
    end
    
    obj.Observation = obj.Time >= startDate & obj.Time <= stopDate;
    
    % Create bed log
    theseDates = unique(dateshift(obj.Time(obj.Observation),'Start','day'));
    theseBeds  = theseDates + bedTime;
    theseRises = theseDates + riseTime;
    
    idxBefore = theseBeds < min(obj.Time) | theseRises < min(obj.Time);
    idxAfter  = theseBeds > max(obj.Time) | theseRises > max(obj.Time);
    idxOut    = idxBefore | idxAfter;
    
    theseBeds(idxOut)  = [];
    theseRises(idxOut) = [];
    
    obj.BedLog = d12pack.BedLogData(theseBeds, theseRises);
    
    % Read CDF data
    try
    cdfData = daysimeter12.readcdf(cdfPaths{iFile});
    catch err
        display(err)
    end
    
    % Add ID
    obj.ID = cdfData.GlobalAttributes.subjectID;
    
    if ~any(ismember(obj.ID, previousSubjects) & ismember(obj.Session.Name, previousSessions))
        % Add object to array of objects
        objArray(ii,1)   = obj;
        
        ii = ii + 1;
    end
end


% Combine new data with any previous data
if ~isempty(previousData)
    objArray = vertcat(previousData, objArray);
end

% Sort by subject and session
tmpSessions = vertcat(objArray(:).Session);
tmpTable = table({objArray(:).ID}',{tmpSessions(:).Name}','VariableNames',{'ID','Session'});
[~, idxSort] = sortrows(tmpTable,{'ID','Session'});
objArray = objArray(idxSort);

% Save converted data to file
save(dbPath,'objArray');

if nargout > 0
    varargout{1} = objArray;
end

end