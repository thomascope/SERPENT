% List of open inputs
nrun = 1; % enter the number of runs here
jobfile = {'/lustre/scratch/wbic-beta/tec31/7T_preprocessing_scripts/am_structural_skullstrip_batch_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(0, nrun);
for crun = 1:nrun
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
