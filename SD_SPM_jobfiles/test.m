% List of open inputs
% Contrast Manager: Name - cfg_entry
% Contrast Manager: Weights vector - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'/group/language/data/thomascope/7T_SERPENT_pilot_analysis/SD_SPM_jobfiles/test_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Name - cfg_entry
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Weights vector - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
