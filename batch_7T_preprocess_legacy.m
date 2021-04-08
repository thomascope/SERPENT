% Batch script for preprocessing of pilot 7T data
% Written by TEC Feb 2018

%% Setup environment
rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
%addpath /imaging/local/software/spm_cbu_svn/releases/spm12_fil_r6906
addpath /group/language/data/thomascope/spm12_fil_r6906/
spm fmri
scriptdir = '/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/';

%% Define parameters
pilot_7T_subjects_parameters

%% Options to skip steps
applytopup = 0;

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
        parpool(workerpool,workerpool.NumWorkers)
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
            parpool(workerpool,workerpool.NumWorkers)
        end
        cd(currentdr)
    catch
        try
            cd('/group/language/data/thomascope/')
            workerpool = cbupool(workersrequested);
            try
                matlabpool(workerpool)
            catch
                parpool(workerpool,workerpool.NumWorkers)
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
jobfile = {[scriptdir 'module_skullstrip_INV2_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))} ',1']);
    inputs{2, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV2'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'INV2'))}]);
    inputs{3, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{4, crun} = 'structural';
    inputs{5, crun} = cellstr([preprocessedpathstem subjects{crun} '/']);
    if ~exist(inputs{5, crun}{1})
        mkdir(inputs{5, crun}{1});
    end
    inputs{6, crun} = 'structural_csf';
    inputs{7, crun} = cellstr([preprocessedpathstem subjects{crun} '/']);
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

if applytopup == 1
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

%% Now do cat12 normalisation of the structural to create deformation fields (works better than SPM segment deformation fields, which sometimes produce too-small brains)

nrun = size(subjects,2); % enter the number of runs here
jobfile = {'/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/module_cat12_normalise_job.m'};
inputs = cell(1, nrun);
for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    inputs{1, crun} = cellstr([outpath 'structural_csf.nii']);
end

cat12workedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        cat12workedcorrectly(crun) = 1;
    catch
        cat12workedcorrectly(crun) = 0;
    end
end


%% Now normalise write for visualisation and smooth at 3 and 8
nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_normalise_smooth_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    
    % % First is for SPM segment, second for CAT12
    %inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{1, crun} = cellstr([outpath 'mri/y_structural_csf.nii']);
    
    
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    filestonormalise = cell(1,length(theseepis));
    filestonormalise_list = [];
    for i = 1:length(theseepis)
        filestonormalise{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        filestonormalise_list = [filestonormalise_list; filestonormalise{i}];
    end
    inputs{2, crun} = cellstr(filestonormalise_list);
    % % First is for SPM segment, second for CAT12
    %inputs{3, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{3, crun} = cellstr([outpath 'mri/y_structural_csf.nii']);
    inputs{4, crun} = cellstr([outpath 'structural.nii,1']);
    % % First is for SPM segment, second for CAT12
    %inputs{5, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{5, crun} = cellstr([outpath 'mri/y_structural_csf.nii']);
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
    
    inputs{1, crun} = cellstr([outpath 'stats2_8']);
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
    
    inputs{1, crun} = cellstr([outpath 'stats2_multi_3']);
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
    
    inputs{1, crun} = cellstr([outpath 'stats2_multi_8']);
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

%% Now create a more complex SPM with variable levels of AR whitening, with word omissions specified

jobfile = {};
jobfile{3} = {[scriptdir 'module_univariate_3runs_complex_AR_job.m']};
jobfile{4} = {[scriptdir 'module_univariate_4runs_complex_AR_job.m']};

all_aros = [1 3 6 12]; %Autoregressive model order
nrun = size(subjects,2)*length(all_aros); % enter the number of runs here
inputs = cell(0, size(subjects,2),length(all_aros));
for this_aro = 1:length(all_aros);
for crun = 1:size(subjects,2)
    aro = all_aros(this_aro);
    
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_complex_event_times(subjects{crun},dates{crun},length(theseepis),minvols(crun));
    
    inputs{1, crun, this_aro} = cellstr([outpath 'stats3_multi_AR' num2str(aro)]);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s3wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(100*(sess-1))+2, crun, this_aro} = cellstr(filestoanalyse{sess});
        for cond_num = 1:80
            inputs{(100*(sess-1))+2+cond_num, crun, this_aro} = cat(2, tempDesign{sess}{cond_num})';
        end
        for cond_num = 81:96 %Response trials
            inputs{(100*(sess-1))+2+cond_num, crun, this_aro} = cat(2, tempDesign{sess}{cond_num+32})';
        end
        for cond_num = 97 %Button press
            inputs{(100*(sess-1))+2+cond_num, crun, this_aro} = cat(2, tempDesign{sess}{81})';
        end
        for cond_num = 98 %Absent sound (written only)
            inputs{(100*(sess-1))+2+cond_num, crun, this_aro} = cat(2, tempDesign{sess}{129})';
        end
        inputs{(100*(sess-1))+101, crun, this_aro} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
    %inputs{(100*(sess-1))+102, crun, this_aro} = 'AR(1)';
    inputs{(100*(sess-1))+102, crun, this_aro} = aro;
    jobs{crun} = jobfile{length(theseepis)};
    
end
end


try
    matlabpool 'close'
catch
    delete(gcp)
end


workersrequested = 24;
workerpool = cbupool(workersrequested);
workerpool.ResourceTemplate=['-l nodes=^N^,mem=768GB,walltime=168:00:00'];
try
    matlabpool(workerpool)
catch
    parpool(workerpool,workerpool.NumWorkers)
end
        
all_combs = combvec(1:size(subjects,2),1:length(all_aros))';
SPMworkedcorrectly = zeros(1,size(all_combs,1));
for thisone = 1:size(all_combs,1)
    crun = all_combs(thisone,1);
    this_aro = all_combs(thisone,2);
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs{crun}, inputs{:,crun, this_aro});
        SPMworkedcorrectly(thisone) = 1;
    catch
        SPMworkedcorrectly(thisone) = 0;
    end
end

%% Now create a ReML SPM without modelling the written word separately for future multivariate analysis (currently only implemented for 3 or 4 runs)
nrun = size(subjects,2); % enter the number of runs here
jobfile = {};
jobfile{3} = {[scriptdir 'module_univariate_3runs_complex_job.m']};
jobfile{4} = {[scriptdir 'module_univariate_4runs_complex_job.m']};
inputs = cell(0, nrun);

for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_complex_event_times_nowritten(subjects{crun},dates{crun},length(theseepis),minvols(crun));
    
    inputs{1, crun} = cellstr([outpath 'stats_multi_3_nowritten2']);
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


%% Now create univariate masks for later MVPA

t_thresh = 3.11; % p<0.001 uncorrected
smoothing_kernels = [3, 8];

for smoo = smoothing_kernels
    for crun = 1:nrun
        spmpath = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(smoo) '/'];
        outpath = [preprocessedpathstem subjects{crun} '/'];
        thisSPM = load([spmpath 'SPM.mat']);
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

%% Now create anatomical masks for later MVPA
nrun = size(subjects,2); % enter the number of runs here

% First create masks
search_labels = {
    'Left STG'
    'Left PT'
    'Left PrG'
    'Left FO'
    'Left TrIFG'
    };

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    currentdir = pwd;
    cd(outpath)
    xA=spm_atlas('load','Neuromorphometrics');
    for i = 1:size(xA.labels,2)
        all_labels{i} = xA.labels(i).name;
    end
    
    S = cell(1,length(search_labels));
    for i = 1:length(search_labels)
        S{i} = find(strncmp(all_labels,search_labels{i},size(search_labels{i},2)));
    end
    
    for i = 1:size(S,2)
        fname=strcat(strrep(search_labels{i}, ' ', '_'),'.nii');
        VM=spm_atlas('mask',xA,xA.labels(S{i}).name);
        VM.fname=fname;
        spm_write_vol(VM,spm_read_vols(VM));
    end
    
    fname='atlas_all.nii';
    VM=spm_atlas('mask',xA,all_labels);
    VM.fname=fname;
    spm_write_vol(VM,spm_read_vols(VM));
    
    cd(currentdir)
    
end

maskcoregisterworkedcorrectly = zeros(1,nrun);

parfor crun = 1:nrun
    job = struct
    job.eoptions.cost_fun = 'nmi'
    job.eoptions.tol = [repmat(0.02,1,3), repmat(0.01,1,6), repmat(0.001,1,3)];
    job.eoptions.sep = [4 2];
    job.eoptions.fwhm = [7 7];
    
    outpath = [preprocessedpathstem subjects{crun} '/'];
    job.ref = {[outpath 'wstructural.nii']};
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    job.source = {[outpath 'atlas_all.nii']};
    
    filestocoregister = cell(1,length(theseepis));
    filestocoregister_list = [];
    for i = 1:length(search_labels)
        filestocoregister{i} = strcat(outpath,strrep(search_labels{i}, ' ', '_'),'.nii');
        filestocoregister_list = strvcat(filestocoregister_list, filestocoregister{i});
    end
    filestocoregister = cellstr(filestocoregister_list);
    
    job.other = filestocoregister
    
    try
        spm_run_coreg(job)
        
        P = char(job.ref{:},job.source{:},job.other{:});
        %inflate the ROIs a bit to account for smaller brains than template
        for thisone=3:size(P,1)
            dilate_image_spm(P(thisone,:),5)
%             spm_imcalc(P(thisone,:), P(thisone,:), 'i1*10');
%             spm_smooth(P(thisone,:),P(thisone,:),10);
%             spm_imcalc(P(thisone,:),P(thisone,:),'i1>1');
        end
        flags=struct;
        flags.interp = 0;
        spm_reslice(P,flags)
        
        
        maskcoregisterworkedcorrectly(crun) = 1;
    catch
        maskcoregisterworkedcorrectly(crun) = 0;
    end
end

%% Now create anatomical masks for later MVPA with fat Neuromorphometrics
nrun = size(subjects,2); % enter the number of runs here

% First create masks
search_labels = {
    'Left Superior Temporal Gyrus'
    'Left Angular Gyrus'
    'Left Precentral Gyrus'
    'Left Frontal Operculum'
    'Left Inferior Frontal Angular Gyrus'
    'Right Superior Temporal Gyrus'
    'Right Angular Gyrus'
    'Right Precentral Gyrus'
    'Right Frontal Operculum'
    'Right Inferior Frontal Angular Gyrus'
    'Left Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
    'Right Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
    };


cat_install_atlases

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    currentdir = pwd;
    cd(outpath)
    xA=spm_atlas('load','dartel_neuromorphometrics');
    for i = 1:size(xA.labels,2)
        all_labels{i} = xA.labels(i).name;
    end
    
    S = cell(1,length(search_labels));
    for i = 1:length(search_labels)
        S{i} = find(strcmp(all_labels,search_labels{i}));
    end
    
    for i = 1:size(S,2)
        fname=strcat(strrep(search_labels{i}, ' ', '_'),'.nii');
        VM=spm_atlas('mask',xA,xA.labels(S{i}).name);
        VM.fname=fname;
        spm_write_vol(VM,spm_read_vols(VM));
    end
    
    fname='atlas_all.nii';
    VM=spm_atlas('mask',xA,all_labels);
    VM.fname=fname;
    spm_write_vol(VM,spm_read_vols(VM));
    
    cd(currentdir)
    
end

maskcoregisterworkedcorrectly = zeros(1,nrun);

parfor crun = 1:nrun
    job = struct
    job.eoptions.cost_fun = 'nmi'
    job.eoptions.tol = [repmat(0.02,1,3), repmat(0.01,1,6), repmat(0.001,1,3)];
    job.eoptions.sep = [4 2];
    job.eoptions.fwhm = [7 7];
    
    outpath = [preprocessedpathstem subjects{crun} '/'];
    job.ref = {[outpath 'wstructural.nii']};
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    job.source = {[outpath 'atlas_all.nii']};
    
    filestocoregister = cell(1,length(theseepis));
    filestocoregister_list = [];
    for i = 1:length(search_labels)
        filestocoregister{i} = strcat(outpath,strrep(search_labels{i}, ' ', '_'),'.nii');
        filestocoregister_list = strvcat(filestocoregister_list, filestocoregister{i});
    end
    filestocoregister = cellstr(filestocoregister_list);
    
    job.other = filestocoregister
    
    try
        %spm_run_coreg(job)
        
        P = char(job.ref{:},job.source{:},job.other{:});
%         %inflate the ROIs a bit to account for smaller brains than template
%         for thisone=3:size(P,1)
%             dilate_image_spm(P(thisone,:),5)
% %             spm_imcalc(P(thisone,:), P(thisone,:), 'i1*10');
% %             spm_smooth(P(thisone,:),P(thisone,:),10);
% %             spm_imcalc(P(thisone,:),P(thisone,:),'i1>1');
%         end
        flags=struct;
        flags.interp = 0;
        spm_reslice(P,flags)
        
        
        maskcoregisterworkedcorrectly(crun) = 1;
    catch
        maskcoregisterworkedcorrectly(crun) = 0;
    end
end

% %% Now begin the MVPA proper! RSA within the mask first
% nrun = size(subjects,2); % enter the number of runs here
% data_smoo = 3; %Smoothing on MVPA data
% mask_smoo = 3; %Smoothing on MVPA mask
% mask_cond = {'sound' 'written'};
% % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% 
% avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% 
% for crun = 1:nrun
%     
%     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
%     
%     for mask_cond_num = 1:length(mask_cond)
%         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
%         for cond_num = 1:length(conditions)
%             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
%             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
%         end
%     end
% end
% all_avgRDM{1} = avgRDM;
% all_stats{1} = stats_p_r;
% 
% data_smoo = 3; %Smoothing on MVPA data
% mask_smoo = 8; %Smoothing on MVPA mask
% mask_cond = {'sound' 'written'};
% % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% 
% avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% 
% for crun = 1:nrun
%     
%     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
%     
%     for mask_cond_num = 1:length(mask_cond)
%         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
%         for cond_num = 1:length(conditions)
%             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
%             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
%         end
%     end
% end
% all_avgRDM{2} = avgRDM;
% all_stats{2} = stats_p_r;
% 
% 
% data_smoo = 8; %Smoothing on MVPA data
% mask_smoo = 8; %Smoothing on MVPA mask
% mask_cond = {'sound' 'written'};
% % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% 
% avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% 
% for crun = 1:nrun
%     
%     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
%     
%     for mask_cond_num = 1:length(mask_cond)
%         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
%         for cond_num = 1:length(conditions)
%             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
%             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
%         end
%     end
% end
% all_avgRDM{3} = avgRDM;
% all_stats{3} = stats_p_r;
% 
% data_smoo = 3; %Smoothing on MVPA data
% %mask_cond = {'rLeft_STG.nii' 'rLeft_PrG.nii' 'rLeft_FO.nii'};
% mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
%     'rLeft_Angular_Gyrus.nii'
%     'rLeft_Precentral_Gyrus.nii'
%     'rLeft_Frontal_Operculum.nii'
%     'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
%     };
% % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% 
% avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% 
% for crun = 1:nrun
%     
%     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
%     
%     for mask_cond_num = 1:length(mask_cond)
%         mask_path = [preprocessedpathstem subjects{crun} '/' mask_cond{mask_cond_num}];
%         for cond_num = 1:length(conditions)
%             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
%             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
%         end
%     end
% end
% all_avgRDM{4} = avgRDM;
% all_stats{4} = stats_p_r;

%% Try again with parallelisation of different AR model orders
addpath(genpath('/imaging/mlr/users/tc02/toolboxes')); %Where is the RSA toolbox?

%data_smoo = 3; %Smoothing on MVPA data
all_aros = [1 3 6 12];
mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
    'rLeft_Angular_Gyrus.nii'
    'rLeft_Precentral_Gyrus.nii'
    'rLeft_Frontal_Operculum.nii'
    'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
    'rRight_Superior_Temporal_Gyrus.nii'
    'rRight_Angular_Gyrus.nii'
    'rRight_Precentral_Gyrus.nii'
    'rRight_Frontal_Operculum.nii'
    'rRight_Inferior_Frontal_Angular_Gyrus.nii'
    'rLeft_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
    'rRight_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
    };
mask_short_cond = {'lSTG'
    'lAG'
    'lPrG'
    'lFO'
    'lIFG'
    'rSTG'
    'rAG'
    'rPrG'
    'rFO'
    'rIFG'
    'lXXX'
    'rXXX'};
all_combs = combvec(1:size(subjects,2),1:length(mask_cond),1:length(conditions),1:length(all_aros))';
pat_aro_combs = combvec(1:size(subjects,2),1:length(all_aros))';

%type = 't-pat'; % Run based on the t-patterns
type = 'beta'; % Run based on the beta-patterns

switch type
    case 'beta'
%First denan the beta images
for thisone = 1:size(pat_aro_combs,1)
    crun = pat_aro_combs(thisone,1);
aro = all_aros(pat_aro_combs(thisone,2));
data_path = [preprocessedpathstem subjects{crun} '/stats3_multi_AR' num2str(aro) '/'];
beta_files = dir([data_path '/Cbeta_0*']);

parfor i = 1:size(beta_files,1)
module_fslmaths_job([data_path 'Cbeta_' sprintf('%04d',i) '.nii'],'-nan',[data_path 'Cbeta_denan_' sprintf('%04d',i) '.nii']); %Account for the fact that spm_read_vols crashes with nan
end
end
end

parfor thisone = 1:size(all_combs,1)
    crun = all_combs(thisone,1);
    mask_cond_num = all_combs(thisone,2);
    cond_num = all_combs(thisone,3);
    aro = all_aros(all_combs(thisone,4));
    switch type
        case 't-pat'
            module_run_rsa_AR(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},aro) % Run based on the t-patterns
        case 'beta'
            module_run_rsa_AR_beta(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},aro) %Run based on the beta patterns
    end
    %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},data_smoo)
    %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},['Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo)],data_smoo)
    
end

for crun = 1:size(subjects,2)
    for mask_cond_num = 1:length(mask_cond)
        for cond_num = 1:length(conditions)
            for aro = 1:length(all_aros)
                mask_name = mask_cond{mask_cond_num};
                mask_short_name = mask_short_cond{mask_cond_num};
                switch type
                    case 't-pat'
                        thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_AR' num2str(all_aros(aro))],'avgRDM','stats_p_r');
                    case 'beta'
                        thesedata = load(['./RSA_results/RSA_results_beta_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_AR' num2str(all_aros(aro))],'avgRDM','stats_p_r');
                end
                %thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' 'Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo) '_mask_' mask_name(1:end-4) '_smooth_' num2str(data_smoo)],'avgRDM','stats_p_r');
                avgRDM{crun,mask_cond_num,cond_num,aro} = thesedata.avgRDM;
                this_cond_name = strrep(avgRDM{crun,mask_cond_num,cond_num,aro}.name,'Mismatch ','MM');
                this_cond_name = strrep(this_cond_name,'Match ','M');
                this_cond_name = strrep(this_cond_name,'RDM across sessions | condition ','');
                avgRDM{crun,mask_cond_num,cond_num,aro}.name = ['S' num2str(crun) this_cond_name '_' mask_short_name '_AR' num2str(all_aros(aro))];
                stats_p_r{crun,mask_cond_num,cond_num,aro} = thesedata.stats_p_r;
            end
        end
    end
end

userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
userOptions.nBootstrap=100; % XXX CHange to 10000 when code finalised

judgmentRDM.RDM = zeros(16,16);
judgmentRDM.RDM(1:17:end) = 1;
judgmentRDM.RDM(2:68:end) = 1/3;
judgmentRDM.RDM(3:68:end) = 1/3;
judgmentRDM.RDM(4:68:end) = 1/3;
judgmentRDM.RDM(17:68:end) = 1/3;
judgmentRDM.RDM(19:68:end) = 1/3;
judgmentRDM.RDM(20:68:end) = 1/3;
judgmentRDM.RDM(33:68:end) = 1/3;
judgmentRDM.RDM(34:68:end) = 1/3;
judgmentRDM.RDM(36:68:end) = 1/3;
judgmentRDM.RDM(49:68:end) = 1/3;
judgmentRDM.RDM(50:68:end) = 1/3;
judgmentRDM.RDM(51:68:end) = 1/3;

judgmentRDM.RDM = 1-judgmentRDM.RDM;
judgmentRDM.name = 'vowels only';

base_figureindex = 250;
userOptions.figureIndex = [260, 360];

for crun = 1:size(subjects,2)
    for aro = 1:length(all_aros)
userOptions.figureIndex = [base_figureindex+10*crun+aro, base_figureindex+200+10*crun+aro];
        
subj_stats_p_r{crun,aro}=compareRefRDM2candRDMs(judgmentRDM, avgRDM(crun,:,:,aro), userOptions);


    end
end

%% Analyse by condition and brain region
addpath(genpath('/imaging/mlr/users/tc02/toolboxes')); %Where is the RSA toolbox?

all_smos = 3; %Smoothing on MVPA data

mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
    'rLeft_Angular_Gyrus.nii'
    'rLeft_Precentral_Gyrus.nii'
    'rLeft_Frontal_Operculum.nii'
    'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
    'rRight_Superior_Temporal_Gyrus.nii'
    'rRight_Angular_Gyrus.nii'
    'rRight_Precentral_Gyrus.nii'
    'rRight_Frontal_Operculum.nii'
    'rRight_Inferior_Frontal_Angular_Gyrus.nii'
    'rLeft_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
    'rRight_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
    };
mask_short_cond = {'lSTG'
    'lAG'
    'lPrG'
    'lFO'
    'lIFG'
    'rSTG'
    'rAG'
    'rPrG'
    'rFO'
    'rIFG'
    'lXXX'
    'rXXX'};
all_combs = combvec(1:size(subjects,2),1:length(mask_cond),1:length(conditions),1:length(all_smos))';
pat_smo_combs = combvec(1:size(subjects,2),1:length(all_smos))';

type = 't-pat'; % Run based on the t-patterns
%type = 'beta'; % Run based on the beta-patterns

switch type
    case 'beta'
%First denan the beta images
for thisone = 1:size(pat_smo_combs,1)
    crun = pat_smo_combs(thisone,1);
smo = all_smos(pat_smo_combs(thisone,2));
data_path = [preprocessedpathstem subjects{crun} '/stats_multi_' num2str(smo) '_nowritten/'];
beta_files = dir([data_path '/Cbeta_0*']);

parfor i = 1:size(beta_files,1)
module_fslmaths_job([data_path 'Cbeta_' sprintf('%04d',i) '.nii'],'-nan',[data_path 'Cbeta_denan_' sprintf('%04d',i) '.nii']); %Account for the fact that spm_read_vols crashes with nan
end
end
end

parfor thisone = 1:size(all_combs,1)
    crun = all_combs(thisone,1);
    mask_cond_num = all_combs(thisone,2);
    cond_num = all_combs(thisone,3);
    smo = all_smos(all_combs(thisone,4));
    switch type
        case 't-pat'
            c(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},smo) % Run based on the t-patterns
        case 'beta'
            module_run_rsa_beta(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},smo) %Run based on the beta patterns
    end
    %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},data_smoo)
    %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},['Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo)],data_smoo)
    
end

for crun = 1:size(subjects,2)
    for mask_cond_num = 1:length(mask_cond)
        for cond_num = 1:length(conditions)
            for smo = 1:length(all_smos)
                mask_name = mask_cond{mask_cond_num};
                mask_short_name = mask_short_cond{mask_cond_num};
                switch type
                    case 't-pat'
                        thesedata = load(['./RSA_results/RSA_results_nowritten2_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_smooth_' num2str(all_smos(smo))],'avgRDM','stats_p_r');
                    case 'beta'
                        thesedata = load(['./RSA_results/RSA_results_beta_nowritten2_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_smooth_' num2str(all_smos(smo))],'avgRDM','stats_p_r');
                end
                %thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' 'Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo) '_mask_' mask_name(1:end-4) '_smooth_' num2str(data_smoo)],'avgRDM','stats_p_r');
                avgRDM{crun,mask_cond_num,cond_num,smo} = thesedata.avgRDM;
                this_cond_name = strrep(avgRDM{crun,mask_cond_num,cond_num,smo}.name,'Mismatch ','MM');
                this_cond_name = strrep(this_cond_name,'Match ','M');
                this_cond_name = strrep(this_cond_name,'RDM across sessions | condition ','');
                avgRDM{crun,mask_cond_num,cond_num,smo}.name = ['S' num2str(crun) this_cond_name '_' mask_short_name '_sm' num2str(all_smos(smo))];
                stats_p_r{crun,mask_cond_num,cond_num,smo} = thesedata.stats_p_r;
            end
        end
    end
end

userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
userOptions.nBootstrap=100; % XXX CHange to 10000 when code finalised

judgmentRDM.RDM = zeros(16,16);
judgmentRDM.RDM(1:17:end) = 1;
judgmentRDM.RDM(2:68:end) = 1/3;
judgmentRDM.RDM(3:68:end) = 1/3;
judgmentRDM.RDM(4:68:end) = 1/3;
judgmentRDM.RDM(17:68:end) = 1/3;
judgmentRDM.RDM(19:68:end) = 1/3;
judgmentRDM.RDM(20:68:end) = 1/3;
judgmentRDM.RDM(33:68:end) = 1/3;
judgmentRDM.RDM(34:68:end) = 1/3;
judgmentRDM.RDM(36:68:end) = 1/3;
judgmentRDM.RDM(49:68:end) = 1/3;
judgmentRDM.RDM(50:68:end) = 1/3;
judgmentRDM.RDM(51:68:end) = 1/3;

judgmentRDM.RDM = 1-judgmentRDM.RDM;
judgmentRDM.name = 'vowels only';

base_figureindex = 250;
userOptions.figureIndex = [260, 360];

for crun = 1:size(subjects,2)
    for smo = 1:length(all_smos)
userOptions.figureIndex = [base_figureindex+10*crun+smo, base_figureindex+200+10*crun+smo];
        
subj_stats_p_r{crun,smo}=compareRefRDM2candRDMs(judgmentRDM, avgRDM(crun,:,:,smo), userOptions);


    end
end
