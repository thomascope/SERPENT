% List of open inputs
% CAT12: Segmentation: Volumes - cfg_files
% CAT12: Segmentation: Volumes - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/group/language/data/thomascope/7T_SERPENT_pilot_analysis/scratch_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % CAT12: Segmentation: Volumes - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % CAT12: Segmentation: Volumes - cfg_files
end
spm('defaults', 'PET');
spm_jobman('run', jobs, inputs{:});
