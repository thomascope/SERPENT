% List of open inputs
% fMRI model specification: Directory - cfg_files
% fMRI model specification: Scans - cfg_files
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Multiple regressors - cfg_files
% fMRI model specification: Scans - cfg_files
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Multiple regressors - cfg_files
% fMRI model specification: Scans - cfg_files
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Multiple regressors - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/module_univariate_3runs_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(31, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Directory - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Scans - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{4, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{5, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{6, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{7, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{8, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{9, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{10, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{11, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Multiple regressors - cfg_files
    inputs{12, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Scans - cfg_files
    inputs{13, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{14, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{15, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{16, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{17, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{18, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{19, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{20, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{21, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Multiple regressors - cfg_files
    inputs{22, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Scans - cfg_files
    inputs{23, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{24, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{25, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{26, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{27, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{28, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{29, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{30, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{31, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Multiple regressors - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
