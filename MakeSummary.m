function MakeSummary
%MAKE Summary of this function goes here
%   Detailed explanation goes here

timestamp = datestr(now,'yyyy-mm-dd_HHMM');

addpath('C:\Users\jonesg5\Documents\GitHub\d12pack');

projectDir = '\\root\projects\CLSA-ChineseClassroom\DaysimeterData';

ls = dir(fullfile(projectDir,'cropped','*.mat'));
[~,idxMostRecent] = max(vertcat(ls.datenum));
dataName = ls(idxMostRecent).name;
dataPath = fullfile(ls(idxMostRecent).folder,ls(idxMostRecent).name);

load(dataPath)

n = numel(objArray);
C = cell(n,1);
N = NaN(n,1);
varNames = {'subject','session','phasor_magnitude','phasor_angle','interdaily_stability','intradaily_variability','mean_waking_activity_index','mean_waking_circadian_stimulus','geometric_mean_waking_photopic_illuminance'};
T = table(C,C,N,N,N,N,N,N,N,'VariableNames',varNames);

for iObj = 1:n
    thisObj = objArray(iObj);
    
    if ~ischar(thisObj.ID)
        thisObj.ID = num2str(thisObj.ID);
    end
    
    T.subject{iObj,1} = thisObj.ID;
    T.session{iObj,1} = thisObj.Session.Name;
    
    if any(thisObj.Compliance)
        if ~isnan(thisObj.Phasor.Vector)
        T.phasor_magnitude(iObj,1) = thisObj.Phasor.Magnitude;
        T.phasor_angle(iObj,1) = thisObj.Phasor.Angle.hours;
        else
            T.phasor_magnitude(iObj,1) = NaN;
            T.phasor_angle(iObj,1) = NaN;
        end
        
        T.interdaily_stability(iObj,1) = thisObj.InterdailyStability;
        T.intradaily_variability(iObj,1) = thisObj.IntradailyVariability;
        
        T.mean_waking_activity_index(iObj,1) = thisObj.MeanWakingActivityIndex;
        T.mean_waking_circadian_stimulus(iObj,1) = thisObj.MeanWakingCircadianStimulus;
        T.geometric_mean_waking_photopic_illuminance(iObj,1) = thisObj.GeometricMeanWakingIlluminance;
    end
end

excelPath = fullfile(projectDir,'tables',['summary_',timestamp,'.xlsx']);
writetable(T,excelPath);
winopen(excelPath)
end

