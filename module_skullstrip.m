% List of open inputs
% Segment: Volumes - cfg_files
% Named File Selector: File Set - cfg_files
% Image Calculator: Output Filename - cfg_entry
% Image Calculator: Output Directory - cfg_files
% Image Calculator: Output Filename - cfg_entry
% Image Calculator: Output Directory - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/module_skullstrip_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(6, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Segment: Volumes - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Named File Selector: File Set - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Output Filename - cfg_entry
    inputs{4, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Output Directory - cfg_files
    inputs{5, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Output Filename - cfg_entry
    inputs{6, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Output Directory - cfg_files
end
spm('defaults', 'EEG');
spm_jobman('run', jobs, inputs{:});
