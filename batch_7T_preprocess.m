% Batch script for preprocessing of pilot 7T data
% Written by TEC Feb 2018

%% Setup environment
rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
addpath /imaging/local/software/spm_cbu_svn/releases/spm12_fil_r6906
spm fmri
scriptdir = '/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/';

%% Define parameters
pilot_7T_subjects_parameters

%% Open a worker pool
if size(subjects,2) > 96
    workersrequested = 96;
    fprintf([ '\n\nUnable to ask for a worker per run; asking for 96 instead\n\n' ]);
else
    workersrequested = size(subjects,2);
end

memoryperworker = 8;
if memoryperworker*workersrequested >= 192 %I think you can't ask for more than this - it doesn't seem to work at time of testing anyway
    memoryrequired = '192'; %NB: This must be a string, not an int!!!
    fprintf([ '\n\nUnable to ask for as much RAM per worker as specified due to cluster limits, asking for 192Gb in total instead\n\n' ]);
else
    memoryrequired = num2str(memoryperworker*workersrequested);
end

try
    currentdr = pwd;
    cd('/group/language/data/thomascope/')
    workerpool = cbupool(workersrequested);
    workerpool.ResourceTemplate=['-l nodes=^N^,mem=' memoryrequired 'GB,walltime=168:00:00'];
    try
        matlabpool(workerpool)
    catch
        parpool(workerpool)
    end
    cd(currentdr)
catch
    try
        cd('/group/language/data/thomascope/')
        matlabpool 'close'
        workerpool = cbupool(workersrequested);
        workerpool.ResourceTemplate=['-l nodes=^N^,mem=' memoryrequired 'GB,walltime=168:00:00'];
        try
            matlabpool(workerpool)
        catch
            parpool(workerpool)
        end
        cd(currentdr)
    catch
        try
            cd('/group/language/data/thomascope/')
            workerpool = cbupool(workersrequested);
            try
                matlabpool(workerpool)
            catch
                parpool(workerpool)
            end
            cd(currentdr)
        catch
            cd(currentdr)
            fprintf([ '\n\nUnable to open up a cluster worker pool - opening a local cluster instead' ]);
            try
                matlabpool(12)
            catch
                parpool(12)
            end
        end
    end
end


%% Skullstrip structural
nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_skullstrip_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))} ',1']);
    inputs{2, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{3, crun} = 'structural';
    inputs{4, crun} = cellstr([preprocessedpathstem subjects{crun} '/']);
    if ~exist(inputs{4, crun}{1})
        mkdir(inputs{4, crun}{1});
    end
    inputs{5, crun} = 'structural_csf';
    inputs{6, crun} = cellstr([preprocessedpathstem subjects{crun} '/']);
end

skullstripworkedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        skullstripworkedcorrectly(crun) = 1;
    catch
        skullstripworkedcorrectly(crun) = 0;
    end
end

%% Now apply topup to distortion correct the EPI

topupworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    base_image_path = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'Pos_topup'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'Pos_topup'))}];
    reversed_image_path = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'Neg_topup'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'Neg_topup'))}];
    outpath = [preprocessedpathstem subjects{crun} '/'];
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    filestocorrect = cell(1,length(theseepis));
    for i = 1:length(theseepis)
        filestocorrect{i} = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{theseepis(i)} '/' blocksin{crun}{theseepis(i)}];
    end
    
    try
        module_topup_job(base_image_path, reversed_image_path, outpath, minvols(crun), filestocorrect)
        topupworkedcorrectly(crun) = 1;
    catch
        topupworkedcorrectly(crun) = 0;
    end
    
end