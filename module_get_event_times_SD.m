function [starttime,stimType,stim_type_labels,buttonpressed,buttonpresstime] = module_get_event_times_SD(subj_initials,testing_date,nRuns,nVolumes)


%clear all
[workingdir,~,~] = fileparts(which('module_get_event_times.m'));
behaviour_folder = [workingdir '/behavioural_data'];

addpath(genpath('/imaging/tc02/toolboxes'));

%% control parameters

stimdelay    = 0;   % the visual stimulus was presented at the same time as the scanner pulse

% % load the subject's image ordering (the same ordering is valid for both sessions)


for runI=1:nRuns
    
    cd(behaviour_folder)
    this_file = dir(['SD*' subj_initials '_Run_' num2str(runI) '_' testing_date '.mat']);
    run_params = load(this_file.name);
    tr = run_params.TR;
    
    cd(workingdir)
    
    fileName = this_file.name;
    %read the scanning log file
 
    [startpulses{runI},stimType{runI},stim_type_labels{runI}] = extract_pulsenumbers_from_SD_paradigm([behaviour_folder '/' fileName],runI);
    
    starttime{runI} = ((startpulses{runI}-1) * tr) + stimdelay; % Remember first pulse occurs at time zero
    buttonpressed{runI} = run_params.resp;
    buttonpresstime{runI} = ((startpulses{runI}-1) * tr) + stimdelay + (run_params.all_rts/1000);

end
