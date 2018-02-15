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
        try
            matlabpool 'close'
        catch
            delete(gcp)
        end
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

%% Now realign the EPIs

realignworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3))
    filestorealign = cell(1,length(theseepis));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    for i = 1:length(theseepis)
        filestorealign{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
    end
    flags = struct;
    flags.fhwm = 3;
    try
    spm_realign(filestorealign,flags)
    realignworkedcorrectly(crun) = 1;
    catch
    realignworkedcorrectly(crun) = 0;
    end
end

%% Now reslice the mean image

resliceworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3))
    filestorealign = cell(1,length(theseepis));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    for i = 1:length(theseepis)
        filestorealign{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
    end
    flags = struct
    flags.which = 0;
    try
    spm_reslice(filestorealign,flags)
    resliceworkedcorrectly(crun) = 1;
    catch
    resliceworkedcorrectly(crun) = 0;
    end
end

%% Now co-register estimate, using structural as reference, mean as source and epi as others, then reslice only the mean

coregisterworkedcorrectly = zeros(1,nrun);

parfor crun = 1:nrun
    job = struct
    job.eoptions.cost_fun = 'nmi'
    job.eoptions.tol = [repmat(0.02,1,3), repmat(0.01,1,6), repmat(0.001,1,3)];
    job.eoptions.sep = [4 2];
    job.eoptions.fwhm = [7 7];
    
    outpath = [preprocessedpathstem subjects{crun} '/'];
    job.ref = {[outpath 'structural.nii,1']};
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    job.source = {[outpath 'meantopup_' blocksin{crun}{theseepis(1)} ',1']};
    
    filestocoregister = cell(1,length(theseepis));
    filestocoregister_list = [];
    for i = 1:length(theseepis)
        filestocoregister{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        filestocoregister_list = [filestocoregister_list; filestocoregister{i}]
    end
    filestocoregister = cellstr(filestocoregister_list);
    
    job.other = filestocoregister
    
    try
        spm_run_coreg(job)
        
        % Now co-register reslice the mean EPI
        P = char(job.ref{:},job.source{:});
        spm_reslice(P)
        
        coregisterworkedcorrectly(crun) = 1;
    catch
        coregisterworkedcorrectly(crun) = 0;
    end
end

%% Now normalise write for visualisation and smooth at 3 and 8
nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_normalise_smooth_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];  
    filestonormalise = cell(1,length(theseepis));
    filestonormalise_list = [];
    for i = 1:length(theseepis)
        filestonormalise{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        filestonormalise_list = [filestonormalise_list; filestonormalise{i}];
    end
    inputs{2, crun} = cellstr(filestonormalise_list);
    inputs{3, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{4, crun} = cellstr([outpath 'structural.nii,1']);
    inputs{5, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{6, crun} = cellstr([outpath 'structural.nii,1']);
end

normalisesmoothworkedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        normalisesmoothworkedcorrectly(crun) = 1;
    catch
        normalisesmoothworkedcorrectly(crun) = 0;
    end
end

%% Now do a univariate SPM analysis (currently only implemented for 3 or 4 runs)
nrun = size(subjects,2); % enter the number of runs here
jobfile = {};
jobfile{3} = {[scriptdir 'module_univariate_3runs_noneutral_job.m']};
jobfile{4} = {[scriptdir 'module_univariate_4runs_noneutral_job.m']};
inputs = cell(0, nrun);

for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];  
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_event_times(subjects{crun},dates{crun},length(theseepis),minvols(crun));
      
    inputs{1, crun} = cellstr([outpath 'stats_8']);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s8wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(8*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        inputs{(8*(sess-1))+3, crun} = cat(2, tempDesign{sess}{1:16})';
        inputs{(8*(sess-1))+4, crun} = cat(2, tempDesign{sess}{17:32})';
        inputs{(8*(sess-1))+5, crun} = cat(2, tempDesign{sess}{33:48})';
        inputs{(8*(sess-1))+6, crun} = cat(2, tempDesign{sess}{49:64})';
%         inputs{(8*(sess-1))+7, crun} = cat(2, tempDesign{sess}{65:80})';
%         inputs{(8*(sess-1))+8, crun} = cat(2, tempDesign{sess}{81:96})';
        inputs{(8*(sess-1))+7, crun} = cat(2, tempDesign{sess}{[97:112, 129]})';
        inputs{(8*(sess-1))+8, crun} = cat(2, tempDesign{sess}{[113:128, 130]})';
        inputs{(8*(sess-1))+9, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
    jobs{crun} = jobfile{length(theseepis)};
    
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs{crun}, inputs{:,crun});
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end

%% Now create a more complex SPM for future multivariate analysis (currently only implemented for 3 or 4 runs)
nrun = size(subjects,2); % enter the number of runs here
jobfile = {};
jobfile{3} = {[scriptdir 'module_univariate_3runs_complex_job.m']};
jobfile{4} = {[scriptdir 'module_univariate_4runs_complex_job.m']};
inputs = cell(0, nrun);

for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];  
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_complex_event_times(subjects{crun},dates{crun},length(theseepis),minvols(crun));
      
    inputs{1, crun} = cellstr([outpath 'stats_multi_3']);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s3wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(100*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        for cond_num = 1:80
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num})';
        end
        for cond_num = 81:96 %Response trials
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num+32})';
        end
        for cond_num = 97 %Button press
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{81})';
        end
        for cond_num = 98 %Absent sound (written only)
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{129})';
        end
        inputs{(100*(sess-1))+101, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
    jobs{crun} = jobfile{length(theseepis)};
    
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs{crun}, inputs{:,crun});
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end

%Now repeat with 8mm smoothing

for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];  
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_complex_event_times(subjects{crun},dates{crun},length(theseepis),minvols(crun));
      
    inputs{1, crun} = cellstr([outpath 'stats_multi_8']);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s8wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(100*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        for cond_num = 1:80
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num})';
        end
        for cond_num = 81:96 %Response trials
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num+32})';
        end
        for cond_num = 97 %Button press
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{81})';
        end
        for cond_num = 98 %Absent sound (written only)
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{129})';
        end
        inputs{(100*(sess-1))+101, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
    jobs{crun} = jobfile{length(theseepis)};
    
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs{crun}, inputs{:,crun});
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end

%% Now create univariate masks for later MVPA

t_thresh = 3.11; % p<0.001 uncorrected
smoothing_kernels = [3, 8];

for smoo = smoothing_kernels
for crun = 1:nrun
    spmpath = [preprocessedpathstem subjects{crun} '/stats_multi_' num2str(smoo) '/'];  
    outpath = [preprocessedpathstem subjects{crun} '/'];
    this_spm = load([spmpath 'SPM.mat']);
    writtenindex = structfind(thisSPM.SPM.xCon,'name','Normal<Written - All Sessions');
    if numel(writtenindex) ~= 1
        error('Something went wrong with finding the written mask condition')
    end
    soundindex = structfind(thisSPM.SPM.xCon,'name','Normal>silence - All Sessions');
    if numel(soundindex) ~= 1
        error('Something went wrong with finding the sound mask condition')
    end
    spm_imcalc([spmpath 'spmT_' sprintf('%04d',soundindex) '.nii'],[outpath 'mask_' num2str(smoo) '_sound_001.nii'],'i1>3.11')
    spm_imcalc([spmpath 'spmT_' sprintf('%04d',writtenindex) '.nii'],[outpath 'mask_' num2str(smoo) '_written_001.nii'],'i1>3.11')
end
end

