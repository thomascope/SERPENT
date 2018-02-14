function tempDesign = module_get_event_times(subj_initials,testing_date,nRuns,nVolumes)


%clear all
[workingdir,file,ext] = fileparts(which('module_get_event_times.m'));
behaviour_folder = [workingdir '/behavioural_data']

addpath(genpath('/imaging/tc02/toolboxes'));

%% control parameters

nSessions=1;
nWords  = 9;  % there were 9 different vowels presented in the experiment
nTrialtypes = 8; % there were 8 conditions - Match low, Match high, Mismatch low, Mismatch high, Neutral low, Neutral high, Writtenonly, Response
tr           = 2.5;   % the EPI volumes were acquired every 3 seconds
stimdur      = 0.6;   % the audio stimuli lasted approx 0.5 seconds
stimdelay    = 1.7; % the audio stimulus was presented 2200ms after the scanner pulse
% XXX STIMDELAY NOT YET IMPLEMENTED. INSTEAD MODEL WRITTEN AND SPOKEN
% TOGETHER AS A 3 SECOND STIMULUS PRESENTED AT SCANNER PULSE
stimdur      = 2.5; % A Hack for the GLMDenoise to account for the fact that you can only specify onsets in volumes 
condition_order = {'Match low','Match high','Mismatch low','Mismatch high','Neutral low','Neutral high','Writtenonly','Response'};

% % load the subject's image ordering (the same ordering is valid for both sessions)

% pre allocate cell arrays
tempOnsets   = cell(1,nRuns);
design       = cell(1,nRuns);
tpatterns    = cell(1,nSessions);

% the idendity of the subject will be subject initials
thisSubject = subj_initials;

% prepare design matrices
tempOnsets = cell(1,nTrialtypes*nWords+2);
tempDesign = cell(1,nRuns);

for runI=1:nRuns
    
    cd(behaviour_folder)
    this_file = dir(['AFC*' subj_initials '_Run_' num2str(runI) '_' testing_date '.mat']);
    
    fileName = this_file.name;
    %read the scanning log file
 
    [startpulses,stimType,stimNumber,stimName] = extract_pulsenumbers_from_second_fullparadigm(fileName,runI,nRuns);
    
    starttime = ((startpulses-1) * tr) + stimdelay; % Remember first pulse occurs at time zero
    
    if size(stimNumber,2) ~= size(starttime,2)
        warning('Something has gone wrong in recording the stimulus types. Padding with NaNs but you MUST check your data')
        stimNumber = [stimNumber NaN(1,(size(starttime,2)-size(stimNumber,2)))];
    end
    
    for condJ = 1:nTrialtypes
        for condI=1:nWords
            tempOnsets{condI+((condJ-1)*nWords)}=starttime(stimNumber==condI & stimType==condJ);
        end
    end
    
    tempOnsets{nTrialtypes*nWords+1}=starttime(stimNumber==0 & stimType==7);
    tempOnsets{nTrialtypes*nWords+2}=starttime(stimNumber==0 & stimType==8);
    
    tempDesign{runI} = tempOnsets;
end
