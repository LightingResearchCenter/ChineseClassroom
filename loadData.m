function data = loadData(projectDir)
%LOADDATA Summary of this function goes here
%   Detailed explanation goes here

% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
d12packDir      = fullfile(githubDir,'d12pack');
addpath(d12packDir);

ls = dir([projectDir,filesep,'*.mat']);
if ~isempty(ls)
    [~,idxMostRecent] = max(vertcat(ls.datenum));
    dataName = ls(idxMostRecent).name;
    dataPath = fullfile(projectDir,dataName);
    
    d = load(dataPath);
    
    data = d.objArray;
else
    data = [];
end

end

