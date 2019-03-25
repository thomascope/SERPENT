% Batch script for preprocessing of pilot 7T data
% Written by TEC Feb 2018

%% Setup environment
clear all
rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
%addpath /imaging/local/software/spm_cbu_svn/releases/spm12_fil_r6906
addpath /group/language/data/thomascope/spm12_fil_r6906/
spm fmri
scriptdir = '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/';

%% Define parameters
setup_file = 'SERPENT_subjects_parameters';
eval(setup_file)

%% Options to skip steps
applytopup = 1;
opennewanalysispool = 0;
secondlevel = 0;

%% Open a worker pool
if opennewanalysispool == 1
    if size(subjects,2) > 96
        workersrequested = 96;
        fprintf([ '\n\nUnable to ask for a worker per run; asking for 96 instead\n\n' ]);
    else
        workersrequested = size(subjects,2);
    end
    
    memoryperworker = 16;
    if memoryperworker*workersrequested >= 768 %I think you can't ask for more than this - it doesn't seem to work at time of testing anyway
        memoryrequired = '768'; %NB: This must be a string, not an int!!!
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
end

%% Skullstrip structural
nrun = size(subjects,2); % enter the number of runs here

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

if ~all(skullstripworkedcorrectly)
    error('failed at skullstrip');
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
    if ~all(topupworkedcorrectly)
        error('failed at topup');
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

if ~all(realignworkedcorrectly)
    error('failed at realign');
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

if ~all(resliceworkedcorrectly)
    error('failed at reslice');
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

if ~all(cat12workedcorrectly)
    error('failed at cat12');
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
    job.ref = {[outpath 'structural_csf.nii,1']};
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

if ~all(coregisterworkedcorrectly)
    error('failed at coregister');
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
    inputs{4, crun} = cellstr([outpath 'structural_csf.nii,1']);
    % % First is for SPM segment, second for CAT12
    %inputs{5, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{5, crun} = cellstr([outpath 'mri/y_structural_csf.nii']);
    inputs{6, crun} = cellstr([outpath 'structural_csf.nii,1']);
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

if ~all(normalisesmoothworkedcorrectly)
    error('failed at normalise and smooth');
end


%% Now do a univariate SPM analysis at 8mm
nrun = size(subjects,2); % enter the number of runs here
inputs = cell(0, nrun);

starttime={};
stimType={};
stim_type_labels={};
for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    filestoanalyse = cell(1,length(theseepis));
    
    [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD(subjects{crun},dates{crun},length(theseepis),minvols(crun));
    
    inputs{1, crun} = cellstr([outpath 'stats_mask0.4_8_multi']);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s8wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        inputs{(2*(sess-1))+3, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
     
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    jobfile = create_SD_SPM_Job(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun});
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobfile);
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end

if ~all(SPMworkedcorrectly)
    error('failed at SPM 8mm');
end

%% Now repeat univariate SPM analysis at 3mm
nrun = size(subjects,2); % enter the number of runs here
inputs = cell(0, nrun);

starttime={};
stimType={};
stim_type_labels={};
for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    filestoanalyse = cell(1,length(theseepis));
    
    [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD(subjects{crun},dates{crun},length(theseepis),minvols(crun));
    
    inputs{1, crun} = cellstr([outpath 'stats_mask0.4_3_multi']);
    for sess = 1:length(theseepis)
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s3wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        inputs{(2*(sess-1))+3, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
     
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    jobfile = create_SD_SPM_Job(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun});
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobfile);
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end

if ~all(SPMworkedcorrectly)
    error('failed at SPM 3mm');
end

% %% Now do another univariate SPM analysis at 8mm without the button press
% nrun = size(subjects,2); % enter the number of runs here
% inputs = cell(0, nrun);
% 
% starttime={};
% stimType={};
% stim_type_labels={};
% for crun = 1:nrun
%     theseepis = find(strncmp(blocksout{crun},'Run',3));
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     filestoanalyse = cell(1,length(theseepis));
%     
%     [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD(subjects{crun},dates{crun},length(theseepis),minvols(crun));
%     
%     inputs{1, crun} = cellstr([outpath 'stats_mask0.4_8_nobutton_multi']);
%     for sess = 1:length(theseepis)
%         filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s8wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
%         inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
%         inputs{(2*(sess-1))+3, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
%     end
%      
% end
% 
% SPMworkedcorrectly = zeros(1,nrun);
% parfor crun = 1:nrun
%     jobfile = create_SD_SPM_Job_nobutton(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun});
%     spm('defaults', 'fMRI');
%     spm_jobman('initcfg')
%     try
%         spm_jobman('run', jobfile);
%         SPMworkedcorrectly(crun) = 1;
%     catch
%         SPMworkedcorrectly(crun) = 0;
%     end
% end
% 
% %% Now repeat univariate SPM analysis at 3mm without the button press
% nrun = size(subjects,2); % enter the number of runs here
% inputs = cell(0, nrun);
% 
% starttime={};
% stimType={};
% stim_type_labels={};
% for crun = 1:nrun
%     theseepis = find(strncmp(blocksout{crun},'Run',3));
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     filestoanalyse = cell(1,length(theseepis));
%     
%     [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD(subjects{crun},dates{crun},length(theseepis),minvols(crun));
%     
%     inputs{1, crun} = cellstr([outpath 'stats_mask0.4_3_nobutton_multi']);
%     for sess = 1:length(theseepis)
%         filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s3wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
%         inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
%         inputs{(2*(sess-1))+3, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
%     end
%      
% end
% 
% SPMworkedcorrectly = zeros(1,nrun);
% parfor crun = 1:nrun
%     jobfile = create_SD_SPM_Job_nobutton(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun});
%     spm('defaults', 'fMRI');
%     spm_jobman('initcfg')
%     try
%         spm_jobman('run', jobfile);
%         SPMworkedcorrectly(crun) = 1;
%     catch
%         SPMworkedcorrectly(crun) = 0;
%     end
% end

%% Now do whole brain searchlight analysis with a larger parpool
if opennewanalysispool == 1
    %Re-open Parpool with larger worker pool
    currentdr = pwd;
    cd('/group/language/data/thomascope/')
    try
        matlabpool 'close'
    catch
        delete(gcp)
    end
    workerpool = cbupool(42);
    workerpool.ResourceTemplate=['-l nodes=^N^,mem=192GB,walltime=168:00:00'];
    try
        matlabpool(workerpool)
    catch
        parpool(workerpool,workerpool.NumWorkers)
    end
    cd(currentdr)
end

nrun = size(subjects,2);

for crun = 1:nrun % Don't paralellise here as it is more efficient to do so by voxel
    this_subject = subjects{crun};
    outpath = [preprocessedpathstem this_subject];
    spmpath = [outpath '/stats_mask0.4_3_multi'];
    subsamp_fac = 3; % Set a subsampling factor here - less than 3 will crash the workers with a full 7T volume due to memory
    half_one = [1:30]; % Photos vs line drawings
    crosscon{1} = {half_one, setdiff(1:60,half_one)};
    half_one = [1:5, 11:15, 21:25, 31:35, 41:45, 51:55]; % Left facing vs right facing
    crosscon{2} = {half_one, setdiff(1:60,half_one)};
    
    crosscon_collapsed{1} = {[1:3:15], [3:3:15]}; % Train on rare animals, test on common and vice-versa.
    
    [all_disvols{crun} searchlight_locations{crun} all_testRDMs{crun} all_disvols_cross{crun} all_disvols_collapsed{crun} all_disvols_cross_collapsed{crun}] = module_compare_behaviour_brain(this_subject,spmpath,outpath,subsamp_fac,crosscon,crosscon_collapsed);
    vol_data{crun} = spm_vol(fullfile(outpath,'wstructural_csf.nii'));
end

%% Set up test RDMs - XXX WORK IN PROGRESS
res = {};
for crun = 1:nrun
    thisRDM = all_testRDMs{crun};
    test_rdm_1 = repmat(thisRDM,4,4);
    onerdm = ones(size(thisRDM));
    test_rdm_2 = [thisRDM,onerdm,onerdm,onerdm;onerdm,thisRDM,onerdm,onerdm;onerdm,onerdm,thisRDM,onerdm;onerdm,onerdm,onerdm,thisRDM];
    triplet = ones(3,3);
    triplet = triplet-eye(3);
    triplet = triplet / 2;
    categoryRDM = [triplet, ones(3), ones(3), ones(3), ones(3); ones(3), triplet, ones(3), ones(3), ones(3); ones(3), ones(3), triplet, ones(3), ones(3); ones(3), ones(3), ones(3), triplet, ones(3); ones(3), ones(3), ones(3), ones(3), triplet,];
    test_rdm_3 = repmat(categoryRDM,4,4);
    test_rdm_4 = [categoryRDM,onerdm,onerdm,onerdm;onerdm,categoryRDM,onerdm,onerdm;onerdm,onerdm,categoryRDM,onerdm;onerdm,onerdm,onerdm,categoryRDM];
    
    predictors(1).name = 'Tiled_judgments';
    predictors(1).RDM = test_rdm_1;
    predictors(2).name = 'Isolated_judgments';
    predictors(2).RDM = test_rdm_2;
    predictors(3).name = 'Category_differentiation';
    predictors(3).RDM = test_rdm_3;
    predictors(4).name = 'Category_within_modality';
    predictors(4).RDM = test_rdm_4;
    
    [res{crun}] = roidata_rsa(all_disvols{crun},predictors);
       
end

% Now write volumes of searchlight similarities
%sfactor = 1000;
for crun = 1:nrun
    this_vol_data = struct;
    this_vol_data.dim = vol_data{crun}.dim;
    this_vol_data.dt = vol_data{crun}.dt;
    this_vol_data.dt(1) = spm_type('float32');
    this_vol_data.pinfo = vol_data{crun}.pinfo;
    this_vol_data.pinfo(1)=1;
    this_vol_data.mat = vol_data{crun}.mat;
    this_vol_data.mat(1:3,1:3) = this_vol_data.mat(1:3,1:3)*subsamp_fac;
    this_vol_data.dim = floor(vol_data{crun}.dim/subsamp_fac);
    these_locs = searchlight_locations{crun}/subsamp_fac;
    
    this_subject = subjects{crun};
    search_outpath = [preprocessedpathstem this_subject '/searchvolumes'];
    if ~exist(search_outpath,'dir')
        mkdir(search_outpath)
    end
    
    nans_data = nan(this_vol_data.dim);
    zeros_data = zeros(this_vol_data.dim);
    
    for i = 1:length(predictors)
        this_vol_data.fname = [search_outpath '/' predictors(i).name '_subsamp' num2str(subsamp_fac) '.nii'];
        this_data = nans_data;
        for j = 1:size(these_locs,2)
            this_data(these_locs(1,j),these_locs(2,j),these_locs(3,j)) = res{crun}.r(i,j);
        end
        header = spm_create_vol(this_vol_data);
        spm_write_vol(header,this_data)
    end
    
end

%Set up test RDMs for crosscon data - XXX WORK IN PROGRESS
res = {};
for crun = 1:nrun
    for this_cross = 1:numel(crosscon)
    thisRDM = all_testRDMs{crun};
    test_rdm_1 = repmat(thisRDM,2,2);
    onerdm = ones(size(thisRDM));
    test_rdm_2 = [thisRDM,onerdm;onerdm,thisRDM];
    triplet = ones(3,3);
    triplet = triplet-eye(3);
    triplet = triplet / 2;
    categoryRDM = [triplet, ones(3), ones(3), ones(3), ones(3); ones(3), triplet, ones(3), ones(3), ones(3); ones(3), ones(3), triplet, ones(3), ones(3); ones(3), ones(3), ones(3), triplet, ones(3); ones(3), ones(3), ones(3), ones(3), triplet,];
    test_rdm_3 = repmat(categoryRDM,2,2);
    test_rdm_4 = [categoryRDM,onerdm;onerdm,categoryRDM];
    
    predictors(1).name = 'Tiled_judgments';
    predictors(1).RDM = test_rdm_1;
    predictors(2).name = 'Isolated_judgments';
    predictors(2).RDM = test_rdm_2;
    predictors(3).name = 'Category_differentiation';
    predictors(3).RDM = test_rdm_3;
    predictors(4).name = 'Category_within_modality';
    predictors(4).RDM = test_rdm_4;
    
    [res{crun}{this_cross}] = roidata_rsa(all_disvols_cross{crun}{this_cross},predictors);

    end
end


% Now write volumes of searchlight similarities on crosscon data
%sfactor = 1000;
for crun = 1:nrun
    for this_cross = 1:numel(crosscon)
        this_vol_data = struct;
        this_vol_data.dim = vol_data{crun}.dim;
        this_vol_data.dt = vol_data{crun}.dt;
        this_vol_data.dt(1) = spm_type('float32');
        this_vol_data.pinfo = vol_data{crun}.pinfo;
        this_vol_data.pinfo(1)=1;
        this_vol_data.mat = vol_data{crun}.mat;
        this_vol_data.mat(1:3,1:3) = this_vol_data.mat(1:3,1:3)*subsamp_fac;
        this_vol_data.dim = floor(vol_data{crun}.dim/subsamp_fac);
        these_locs = searchlight_locations{crun}/subsamp_fac;
        
        this_subject = subjects{crun};
        search_outpath = [preprocessedpathstem this_subject '/searchvolumes'];
        
        nans_data = nan(this_vol_data.dim);
        zeros_data = zeros(this_vol_data.dim);
        
        for i = 1:length(predictors)
            this_vol_data.fname = [search_outpath '/' predictors(i).name '_cross' num2str(this_cross) '_subsamp' num2str(subsamp_fac) '.nii'];
            this_data = nans_data;
            for j = 1:size(these_locs,2)
                this_data(these_locs(1,j),these_locs(2,j),these_locs(3,j)) = res{crun}{this_cross}.r(i,j);
            end
            header = spm_create_vol(this_vol_data);
            spm_write_vol(header,this_data)
        end
    end
end

%Set up test RDMs for collapsed data - XXX WORK IN PROGRESS
res = {};
for crun = 1:nrun
    for this_collapse = 1:numel(all_disvols_collapsed{1})
        if this_collapse == 3 %The case where both are collapsed and we have a 15 element matrix
            thisRDM = all_testRDMs{crun};
            test_rdm_1 = repmat(thisRDM,1,1);
            onerdm = ones(size(thisRDM));
            test_rdm_2 = thisRDM; %NB: This is the same as test_rdm_1 but keep it here for consistency with other collapses
            triplet = ones(3,3);
            triplet = triplet-eye(3);
            triplet = triplet / 2;
            categoryRDM = [triplet, ones(3), ones(3), ones(3), ones(3); ones(3), triplet, ones(3), ones(3), ones(3); ones(3), ones(3), triplet, ones(3), ones(3); ones(3), ones(3), ones(3), triplet, ones(3); ones(3), ones(3), ones(3), ones(3), triplet,];
            test_rdm_3 = repmat(categoryRDM,1,1);
            test_rdm_4 = [categoryRDM]; %again only included for consistent numbering
            
            predictors(1).name = 'Tiled_judgments';
            predictors(1).RDM = test_rdm_1;
            predictors(2).name = 'Isolated_judgments';
            predictors(2).RDM = test_rdm_2;
            predictors(3).name = 'Category_differentiation';
            predictors(3).RDM = test_rdm_3;
            predictors(4).name = 'Category_within_modality';
            predictors(4).RDM = test_rdm_4;
            
            [res{crun}{this_collapse}] = roidata_rsa(all_disvols_collapsed{crun}{this_collapse},predictors);
        else %The case where one is collapsed and we have a 30 element matrix
            
            thisRDM = all_testRDMs{crun};
            test_rdm_1 = repmat(thisRDM,2,2);
            onerdm = ones(size(thisRDM));
            test_rdm_2 = [thisRDM,onerdm;onerdm,thisRDM];
            triplet = ones(3,3);
            triplet = triplet-eye(3);
            triplet = triplet / 2;
            categoryRDM = [triplet, ones(3), ones(3), ones(3), ones(3); ones(3), triplet, ones(3), ones(3), ones(3); ones(3), ones(3), triplet, ones(3), ones(3); ones(3), ones(3), ones(3), triplet, ones(3); ones(3), ones(3), ones(3), ones(3), triplet,];
            test_rdm_3 = repmat(categoryRDM,2,2);
            test_rdm_4 = [categoryRDM,onerdm;onerdm,categoryRDM];
            
            predictors(1).name = 'Tiled_judgments';
            predictors(1).RDM = test_rdm_1;
            predictors(2).name = 'Isolated_judgments';
            predictors(2).RDM = test_rdm_2;
            predictors(3).name = 'Category_differentiation';
            predictors(3).RDM = test_rdm_3;
            predictors(4).name = 'Category_within_modality';
            predictors(4).RDM = test_rdm_4;
            
            [res{crun}{this_collapse}] = roidata_rsa(all_disvols_collapsed{crun}{this_collapse},predictors);
        end
    end
end


% Now write volumes of searchlight similarities on collapsed data
%sfactor = 1000;
for crun = 1:nrun
    for this_collapse = 1:numel(all_disvols_collapsed{1})
        this_vol_data = struct;
        this_vol_data.dim = vol_data{crun}.dim;
        this_vol_data.dt = vol_data{crun}.dt;
        this_vol_data.dt(1) = spm_type('float32');
        this_vol_data.pinfo = vol_data{crun}.pinfo;
        this_vol_data.pinfo(1)=1;
        this_vol_data.mat = vol_data{crun}.mat;
        this_vol_data.mat(1:3,1:3) = this_vol_data.mat(1:3,1:3)*subsamp_fac;
        this_vol_data.dim = floor(vol_data{crun}.dim/subsamp_fac);
        these_locs = searchlight_locations{crun}/subsamp_fac;
        
        this_subject = subjects{crun};
        search_outpath = [preprocessedpathstem this_subject '/searchvolumes'];
        
        nans_data = nan(this_vol_data.dim);
        zeros_data = zeros(this_vol_data.dim);
        
        for i = 1:length(predictors)
            this_vol_data.fname = [search_outpath '/' predictors(i).name '_collapse' num2str(this_collapse) '_subsamp' num2str(subsamp_fac) '.nii'];
            this_data = nans_data;
            for j = 1:size(these_locs,2)
                this_data(these_locs(1,j),these_locs(2,j),these_locs(3,j)) = res{crun}{this_collapse}.r(i,j);
            end
            header = spm_create_vol(this_vol_data);
            spm_write_vol(header,this_data)
        end
    end
end

%% Now do second level analysis
if secondlevel == 1
    % First whole data anlysis
    secondlevelworkedcorrectly = zeros(1,length(predictors));
    parfor crun = 1:length(predictors)
        conditionname = [predictors(crun).name '_subsamp' num2str(subsamp_fac)];
        jobfile = create_SD_secondlevel_Job(preprocessedpathstem, conditionname, subjects, group)
        spm('defaults', 'fMRI');
        spm_jobman('initcfg')
        try
            spm_jobman('run', jobfile);
            secondlevelworkedcorrectly(crun) = 1;
        catch
            secondlevelworkedcorrectly(crun) = 0;
        end
        
    end
    
    if ~all(secondlevelworkedcorrectly)
        error('failed at whole data secondlevel');
    end
    
    % Then do crosscon analysis
    all_combs = combvec(1:numel(crosscon), 1:length(predictors));
    secondlevelworkedcorrectly = zeros(1,size(all_combs,2));
    parfor this_comb = 1:size(all_combs,2)
        this_cross = all_combs(1,this_comb)
        crun = all_combs(2,this_comb)
        conditionname = [predictors(crun).name '_cross' num2str(this_cross) '_subsamp' num2str(subsamp_fac)];
        jobfile = create_SD_secondlevel_Job(preprocessedpathstem, conditionname, subjects, group)
        spm('defaults', 'fMRI');
        spm_jobman('initcfg')
        try
            spm_jobman('run', jobfile);
            secondlevelworkedcorrectly(this_comb) = 1;
        catch
            secondlevelworkedcorrectly(this_comb) = 0;
        end
    end
    
    if ~all(secondlevelworkedcorrectly)
        error('failed at crosscon secondlevel');
    end
    
    % Then do collapsed analysis
    all_combs = combvec(1:numel(all_disvols_collapsed{1}), 1:length(predictors));
    secondlevelworkedcorrectly = zeros(1,size(all_combs,2));
    parfor this_comb = 1:size(all_combs,2)
        this_collapse = all_combs(1,this_comb)
        crun = all_combs(2,this_comb)
        conditionname = [predictors(crun).name '_collapse' num2str(this_collapse) '_subsamp' num2str(subsamp_fac)];
        jobfile = create_SD_secondlevel_Job(preprocessedpathstem, conditionname, subjects, group)
        spm('defaults', 'fMRI');
        spm_jobman('initcfg')
        try
            spm_jobman('run', jobfile);
            secondlevelworkedcorrectly(this_comb) = 1;
        catch
            secondlevelworkedcorrectly(this_comb) = 0;
        end
    end
    
    if ~all(secondlevelworkedcorrectly)
        error('failed at collapsed secondlevel');
    end
    
        
end

% 
% %Finally check the collapsed crosstrained data for identity decoding. XXX
% %NEED TO DISCUSS THIS WITH JOHAN TO FIND OUT BEST METHOD
% res = {};
% for crun = 1:nrun
%               
%             thisRDM = ones(5,5) - eye(5);
%             test_rdm_1 = repmat(thisRDM,2,2);
%             onerdm = ones(size(thisRDM));
%             test_rdm_2 = [thisRDM,onerdm;onerdm,thisRDM];
%             triplet = ones(3,3);
%             triplet = triplet-eye(3);
%             triplet = triplet / 2;
%             categoryRDM = [triplet, ones(3), ones(3), ones(3), ones(3); ones(3), triplet, ones(3), ones(3), ones(3); ones(3), ones(3), triplet, ones(3), ones(3); ones(3), ones(3), ones(3), triplet, ones(3); ones(3), ones(3), ones(3), ones(3), triplet,];
%             test_rdm_3 = repmat(categoryRDM,2,2);
%             test_rdm_4 = [categoryRDM,onerdm;onerdm,categoryRDM];
%             
%             predictors(1).name = 'Tiled_judgments';
%             predictors(1).RDM = test_rdm_1;
%             predictors(2).name = 'Isolated_judgments';
%             predictors(2).RDM = test_rdm_2;
%             predictors(3).name = 'Category_differentiation';
%             predictors(3).RDM = test_rdm_3;
%             predictors(4).name = 'Category_within_modality';
%             predictors(4).RDM = test_rdm_4;
%             
%             [res{crun}{this_collapse}] = roidata_rsa(all_disvols_collapsed{crun}{this_collapse},predictors);
%         end
%     end
% end
% 
% 
% % Now write volumes of searchlight similarities on collapsed data
% sfactor = 1000;
% for crun = 1:nrun
%     for this_collapse = 1:numel(crosscon)
%         this_vol_data = struct;
%         this_vol_data.dim = vol_data{crun}.dim;
%         this_vol_data.dt = vol_data{crun}.dt;
%         this_vol_data.pinfo = vol_data{crun}.pinfo;
%         this_vol_data.pinfo(1)=1;
%         this_vol_data.mat = vol_data{crun}.mat;
%         this_vol_data.mat(1:3,1:3) = this_vol_data.mat(1:3,1:3)*subsamp_fac;
%         this_vol_data.dim = floor(vol_data{crun}.dim/subsamp_fac);
%         these_locs = searchlight_locations{crun}/subsamp_fac;
%         
%         this_subject = subjects{crun};
%         search_outpath = [preprocessedpathstem this_subject '/searchvolumes'];
%         
%         nans_data = nan(this_vol_data.dim);
%         zeros_data = zeros(this_vol_data.dim);
%         
%         for i = 1:length(predictors)
%             this_vol_data.fname = [search_outpath '/' predictors(i).name '_collapse' num2str(this_collapse) '_subsamp' num2str(subsamp_fac) '.nii'];
%             this_data = nans_data;
%             for j = 1:size(these_locs,2)
%                 this_data(these_locs(1,j),these_locs(2,j),these_locs(3,j)) = res{crun}{this_collapse}.r(i,j);
%             end
%             spm_write_vol(this_vol_data,this_data*sfactor)
%         end
%     end
% end



% %% Now create univariate masks for later MVPA
% 
% t_thresh = 3.11; % p<0.001 uncorrected
% smoothing_kernels = [3, 8];
% 
% for smoo = smoothing_kernels
%     for crun = 1:nrun
%         spmpath = [preprocessedpathstem subjects{crun} '/stats_mask0.4_' num2str(smoo) '_multi/'];
%         outpath = [preprocessedpathstem subjects{crun} '/'];
%         thisSPM = load([spmpath 'SPM.mat']);
%         writtenindex = structfind(thisSPM.SPM.xCon,'name','Normal<Written - All Sessions');
%         if numel(writtenindex) ~= 1
%             error('Something went wrong with finding the written mask condition')
%         end
%         soundindex = structfind(thisSPM.SPM.xCon,'name','Normal>silence - All Sessions');
%         if numel(soundindex) ~= 1
%             error('Something went wrong with finding the sound mask condition')
%         end
%         spm_imcalc([spmpath 'spmT_' sprintf('%04d',soundindex) '.nii'],[outpath 'mask_' num2str(smoo) '_sound_001.nii'],'i1>3.11')
%         spm_imcalc([spmpath 'spmT_' sprintf('%04d',writtenindex) '.nii'],[outpath 'mask_' num2str(smoo) '_written_001.nii'],'i1>3.11')
%     end
% end
% 
% %% Now create anatomical masks for later MVPA
% nrun = size(subjects,2); % enter the number of runs here
% 
% % First create masks
% search_labels = {
%     'Left STG'
%     'Left PT'
%     'Left PrG'
%     'Left FO'
%     'Left TrIFG'
%     };
% 
% for crun = 1:nrun
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     currentdir = pwd;
%     cd(outpath)
%     xA=spm_atlas('load','Neuromorphometrics');
%     for i = 1:size(xA.labels,2)
%         all_labels{i} = xA.labels(i).name;
%     end
%     
%     S = cell(1,length(search_labels));
%     for i = 1:length(search_labels)
%         S{i} = find(strncmp(all_labels,search_labels{i},size(search_labels{i},2)));
%     end
%     
%     for i = 1:size(S,2)
%         fname=strcat(strrep(search_labels{i}, ' ', '_'),'.nii');
%         VM=spm_atlas('mask',xA,xA.labels(S{i}).name);
%         VM.fname=fname;
%         spm_write_vol(VM,spm_read_vols(VM));
%     end
%     
%     fname='atlas_all.nii';
%     VM=spm_atlas('mask',xA,all_labels);
%     VM.fname=fname;
%     spm_write_vol(VM,spm_read_vols(VM));
%     
%     cd(currentdir)
%     
% end
% 
% maskcoregisterworkedcorrectly = zeros(1,nrun);
% 
% parfor crun = 1:nrun
%     job = struct
%     job.eoptions.cost_fun = 'nmi'
%     job.eoptions.tol = [repmat(0.02,1,3), repmat(0.01,1,6), repmat(0.001,1,3)];
%     job.eoptions.sep = [4 2];
%     job.eoptions.fwhm = [7 7];
%     
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     job.ref = {[outpath 'wstructural_csf.nii']};
%     theseepis = find(strncmp(blocksout{crun},'Run',3));
%     job.source = {[outpath 'atlas_all.nii']};
%     
%     filestocoregister = cell(1,length(theseepis));
%     filestocoregister_list = [];
%     for i = 1:length(search_labels)
%         filestocoregister{i} = strcat(outpath,strrep(search_labels{i}, ' ', '_'),'.nii');
%         filestocoregister_list = strvcat(filestocoregister_list, filestocoregister{i});
%     end
%     filestocoregister = cellstr(filestocoregister_list);
%     
%     job.other = filestocoregister
%     
%     try
%         spm_run_coreg(job)
%         
%         P = char(job.ref{:},job.source{:},job.other{:});
%         %inflate the ROIs a bit to account for smaller brains than template
%         for thisone=3:size(P,1)
%             dilate_image_spm(P(thisone,:),5)
% %             spm_imcalc(P(thisone,:), P(thisone,:), 'i1*10');
% %             spm_smooth(P(thisone,:),P(thisone,:),10);
% %             spm_imcalc(P(thisone,:),P(thisone,:),'i1>1');
%         end
%         flags=struct;
%         flags.interp = 0;
%         spm_reslice(P,flags)
%         
%         
%         maskcoregisterworkedcorrectly(crun) = 1;
%     catch
%         maskcoregisterworkedcorrectly(crun) = 0;
%     end
% end
% 
% %% Now create anatomical masks for later MVPA with fat Neuromorphometrics
% nrun = size(subjects,2); % enter the number of runs here
% 
% % First create masks
% search_labels = {
%     'Left Superior Temporal Gyrus'
%     'Left Angular Gyrus'
%     'Left Precentral Gyrus'
%     'Left Frontal Operculum'
%     'Left Inferior Frontal Angular Gyrus'
%     'Right Superior Temporal Gyrus'
%     'Right Angular Gyrus'
%     'Right Precentral Gyrus'
%     'Right Frontal Operculum'
%     'Right Inferior Frontal Angular Gyrus'
%     'Left Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
%     'Right Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
%     };
% 
% 
% cat_install_atlases
% 
% for crun = 1:nrun
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     currentdir = pwd;
%     cd(outpath)
%     xA=spm_atlas('load','dartel_neuromorphometrics');
%     for i = 1:size(xA.labels,2)
%         all_labels{i} = xA.labels(i).name;
%     end
%     
%     S = cell(1,length(search_labels));
%     for i = 1:length(search_labels)
%         S{i} = find(strcmp(all_labels,search_labels{i}));
%     end
%     
%     for i = 1:size(S,2)
%         fname=strcat(strrep(search_labels{i}, ' ', '_'),'.nii');
%         VM=spm_atlas('mask',xA,xA.labels(S{i}).name);
%         VM.fname=fname;
%         spm_write_vol(VM,spm_read_vols(VM));
%     end
%     
%     fname='atlas_all.nii';
%     VM=spm_atlas('mask',xA,all_labels);
%     VM.fname=fname;
%     spm_write_vol(VM,spm_read_vols(VM));
%     
%     cd(currentdir)
%     
% end
% 
% maskcoregisterworkedcorrectly = zeros(1,nrun);
% 
% parfor crun = 1:nrun
%     job = struct
%     job.eoptions.cost_fun = 'nmi'
%     job.eoptions.tol = [repmat(0.02,1,3), repmat(0.01,1,6), repmat(0.001,1,3)];
%     job.eoptions.sep = [4 2];
%     job.eoptions.fwhm = [7 7];
%     
%     outpath = [preprocessedpathstem subjects{crun} '/'];
%     job.ref = {[outpath 'wstructural_csf.nii']};
%     theseepis = find(strncmp(blocksout{crun},'Run',3));
%     job.source = {[outpath 'atlas_all.nii']};
%     
%     filestocoregister = cell(1,length(theseepis));
%     filestocoregister_list = [];
%     for i = 1:length(search_labels)
%         filestocoregister{i} = strcat(outpath,strrep(search_labels{i}, ' ', '_'),'.nii');
%         filestocoregister_list = strvcat(filestocoregister_list, filestocoregister{i});
%     end
%     filestocoregister = cellstr(filestocoregister_list);
%     
%     job.other = filestocoregister
%     
%     try
%         %spm_run_coreg(job)
%         
%         P = char(job.ref{:},job.source{:},job.other{:});
% %         %inflate the ROIs a bit to account for smaller brains than template
% %         for thisone=3:size(P,1)
% %             dilate_image_spm(P(thisone,:),5)
% % %             spm_imcalc(P(thisone,:), P(thisone,:), 'i1*10');
% % %             spm_smooth(P(thisone,:),P(thisone,:),10);
% % %             spm_imcalc(P(thisone,:),P(thisone,:),'i1>1');
% %         end
%         flags=struct;
%         flags.interp = 0;
%         spm_reslice(P,flags)
%         
%         
%         maskcoregisterworkedcorrectly(crun) = 1;
%     catch
%         maskcoregisterworkedcorrectly(crun) = 0;
%     end
% end
% 
% % %% Now begin the MVPA proper! RSA within the mask first
% % nrun = size(subjects,2); % enter the number of runs here
% % data_smoo = 3; %Smoothing on MVPA data
% % mask_smoo = 3; %Smoothing on MVPA mask
% % mask_cond = {'sound' 'written'};
% % % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% % 
% % avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% % stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% % 
% % for crun = 1:nrun
% %     
% %     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
% %     
% %     for mask_cond_num = 1:length(mask_cond)
% %         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
% %         for cond_num = 1:length(conditions)
% %             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
% %             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
% %         end
% %     end
% % end
% % all_avgRDM{1} = avgRDM;
% % all_stats{1} = stats_p_r;
% % 
% % data_smoo = 3; %Smoothing on MVPA data
% % mask_smoo = 8; %Smoothing on MVPA mask
% % mask_cond = {'sound' 'written'};
% % % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% % 
% % avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% % stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% % 
% % for crun = 1:nrun
% %     
% %     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
% %     
% %     for mask_cond_num = 1:length(mask_cond)
% %         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
% %         for cond_num = 1:length(conditions)
% %             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
% %             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
% %         end
% %     end
% % end
% % all_avgRDM{2} = avgRDM;
% % all_stats{2} = stats_p_r;
% % 
% % 
% % data_smoo = 8; %Smoothing on MVPA data
% % mask_smoo = 8; %Smoothing on MVPA mask
% % mask_cond = {'sound' 'written'};
% % % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% % 
% % avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% % stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% % 
% % for crun = 1:nrun
% %     
% %     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
% %     
% %     for mask_cond_num = 1:length(mask_cond)
% %         mask_path = [preprocessedpathstem subjects{crun} '/mask_' num2str(mask_smoo) '_' mask_cond{mask_cond_num} '_001.nii'];
% %         for cond_num = 1:length(conditions)
% %             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
% %             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
% %         end
% %     end
% % end
% % all_avgRDM{3} = avgRDM;
% % all_stats{3} = stats_p_r;
% % 
% % data_smoo = 3; %Smoothing on MVPA data
% % %mask_cond = {'rLeft_STG.nii' 'rLeft_PrG.nii' 'rLeft_FO.nii'};
% % mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
% %     'rLeft_Angular_Gyrus.nii'
% %     'rLeft_Precentral_Gyrus.nii'
% %     'rLeft_Frontal_Operculum.nii'
% %     'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
% %     };
% % % 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
% % 
% % avgRDM = cell(size(subjects,2),length(mask_cond),length(conditions));
% % stats_p_r = cell(size(subjects,2),length(mask_cond),length(conditions));
% % 
% % for crun = 1:nrun
% %     
% %     data_path = [preprocessedpathstem subjects{crun} '/stats2_multi_' num2str(data_smoo) '/'];
% %     
% %     for mask_cond_num = 1:length(mask_cond)
% %         mask_path = [preprocessedpathstem subjects{crun} '/' mask_cond{mask_cond_num}];
% %         for cond_num = 1:length(conditions)
% %             tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
% %             [avgRDM{crun,mask_cond_num,cond_num}, stats_p_r{crun,mask_cond_num,cond_num}] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,conditions{cond_num});
% %         end
% %     end
% % end
% % all_avgRDM{4} = avgRDM;
% % all_stats{4} = stats_p_r;
% 
% % %% Try again with parallelisation of different AR model orders
% % addpath(genpath('/imaging/tc02/toolboxes')); %Where is the RSA toolbox?
% % 
% % %data_smoo = 3; %Smoothing on MVPA data
% % all_aros = [1 3 6 12];
% % mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
% %     'rLeft_Angular_Gyrus.nii'
% %     'rLeft_Precentral_Gyrus.nii'
% %     'rLeft_Frontal_Operculum.nii'
% %     'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
% %     'rRight_Superior_Temporal_Gyrus.nii'
% %     'rRight_Angular_Gyrus.nii'
% %     'rRight_Precentral_Gyrus.nii'
% %     'rRight_Frontal_Operculum.nii'
% %     'rRight_Inferior_Frontal_Angular_Gyrus.nii'
% %     'rLeft_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
% %     'rRight_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
% %     };
% % mask_short_cond = {'lSTG'
% %     'lAG'
% %     'lPrG'
% %     'lFO'
% %     'lIFG'
% %     'rSTG'
% %     'rAG'
% %     'rPrG'
% %     'rFO'
% %     'rIFG'
% %     'lXXX'
% %     'rXXX'};
% % all_combs = combvec(1:size(subjects,2),1:length(mask_cond),1:length(conditions),1:length(all_aros))';
% % pat_aro_combs = combvec(1:size(subjects,2),1:length(all_aros))';
% % 
% % %type = 't-pat'; % Run based on the t-patterns
% % type = 'beta'; % Run based on the beta-patterns
% % 
% % switch type
% %     case 'beta'
% % %First denan the beta images
% % for thisone = 1:size(pat_aro_combs,1)
% %     crun = pat_aro_combs(thisone,1);
% % aro = all_aros(pat_aro_combs(thisone,2));
% % data_path = [preprocessedpathstem subjects{crun} '/stats3_multi_AR' num2str(aro) '/'];
% % beta_files = dir([data_path '/Cbeta_0*']);
% % 
% % parfor i = 1:size(beta_files,1)
% % module_fslmaths_job([data_path 'Cbeta_' sprintf('%04d',i) '.nii'],'-nan',[data_path 'Cbeta_denan_' sprintf('%04d',i) '.nii']); %Account for the fact that spm_read_vols crashes with nan
% % end
% % end
% % end
% % 
% % parfor thisone = 1:size(all_combs,1)
% %     crun = all_combs(thisone,1);
% %     mask_cond_num = all_combs(thisone,2);
% %     cond_num = all_combs(thisone,3);
% %     aro = all_aros(all_combs(thisone,4));
% %     switch type
% %         case 't-pat'
% %             module_run_rsa_AR(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},aro) % Run based on the t-patterns
% %         case 'beta'
% %             module_run_rsa_AR_beta(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},aro) %Run based on the beta patterns
% %     end
% %     %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},data_smoo)
% %     %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},['Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo)],data_smoo)
% %     
% % end
% % 
% % for crun = 1:size(subjects,2)
% %     for mask_cond_num = 1:length(mask_cond)
% %         for cond_num = 1:length(conditions)
% %             for aro = 1:length(all_aros)
% %                 mask_name = mask_cond{mask_cond_num};
% %                 mask_short_name = mask_short_cond{mask_cond_num};
% %                 switch type
% %                     case 't-pat'
% %                         thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_AR' num2str(all_aros(aro))],'avgRDM','stats_p_r');
% %                     case 'beta'
% %                         thesedata = load(['./RSA_results/RSA_results_beta_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_AR' num2str(all_aros(aro))],'avgRDM','stats_p_r');
% %                 end
% %                 %thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' 'Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo) '_mask_' mask_name(1:end-4) '_smooth_' num2str(data_smoo)],'avgRDM','stats_p_r');
% %                 avgRDM{crun,mask_cond_num,cond_num,aro} = thesedata.avgRDM;
% %                 this_cond_name = strrep(avgRDM{crun,mask_cond_num,cond_num,aro}.name,'Mismatch ','MM');
% %                 this_cond_name = strrep(this_cond_name,'Match ','M');
% %                 this_cond_name = strrep(this_cond_name,'RDM across sessions | condition ','');
% %                 avgRDM{crun,mask_cond_num,cond_num,aro}.name = ['S' num2str(crun) this_cond_name '_' mask_short_name '_AR' num2str(all_aros(aro))];
% %                 stats_p_r{crun,mask_cond_num,cond_num,aro} = thesedata.stats_p_r;
% %             end
% %         end
% %     end
% % end
% % 
% % userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
% % userOptions.nBootstrap=100; % XXX CHange to 10000 when code finalised
% % 
% % judgmentRDM.RDM = zeros(16,16);
% % judgmentRDM.RDM(1:17:end) = 1;
% % judgmentRDM.RDM(2:68:end) = 1/3;
% % judgmentRDM.RDM(3:68:end) = 1/3;
% % judgmentRDM.RDM(4:68:end) = 1/3;
% % judgmentRDM.RDM(17:68:end) = 1/3;
% % judgmentRDM.RDM(19:68:end) = 1/3;
% % judgmentRDM.RDM(20:68:end) = 1/3;
% % judgmentRDM.RDM(33:68:end) = 1/3;
% % judgmentRDM.RDM(34:68:end) = 1/3;
% % judgmentRDM.RDM(36:68:end) = 1/3;
% % judgmentRDM.RDM(49:68:end) = 1/3;
% % judgmentRDM.RDM(50:68:end) = 1/3;
% % judgmentRDM.RDM(51:68:end) = 1/3;
% % 
% % judgmentRDM.RDM = 1-judgmentRDM.RDM;
% % judgmentRDM.name = 'vowels only';
% % 
% % base_figureindex = 250;
% % userOptions.figureIndex = [260, 360];
% % 
% % for crun = 1:size(subjects,2)
% %     for aro = 1:length(all_aros)
% % userOptions.figureIndex = [base_figureindex+10*crun+aro, base_figureindex+200+10*crun+aro];
% %         
% % subj_stats_p_r{crun,aro}=compareRefRDM2candRDMs(judgmentRDM, avgRDM(crun,:,:,aro), userOptions);
% % 
% % 
% %     end
% % end
% 
% %% Analyse by condition and brain region
% addpath(genpath('/imaging/tc02/toolboxes')); %Where is the RSA toolbox?
% 
% if opennewanalysispool == 1
%     %Re-open Parpool with larger worker pool
%     
%     cd('/group/language/data/thomascope/')
%     try
%         matlabpool 'close'
%     catch
%         delete(gcp)
%     end
%     workerpool = cbupool(42);
%     workerpool.ResourceTemplate=['-l nodes=^N^,mem=192GB,walltime=168:00:00'];
%     try
%         matlabpool(workerpool)
%     catch
%         parpool(workerpool,workerpool.NumWorkers)
%     end
%     cd(currentdr)
% end
% 
% all_smos = 3; %Smoothing on MVPA data
% 
% mask_cond = {'rLeft_Superior_Temporal_Gyrus.nii'
%     'rLeft_Angular_Gyrus.nii'
%     'rLeft_Precentral_Gyrus.nii'
%     'rLeft_Frontal_Operculum.nii'
%     'rLeft_Inferior_Frontal_Angular_Gyrus.nii'
%     'rRight_Superior_Temporal_Gyrus.nii'
%     'rRight_Angular_Gyrus.nii'
%     'rRight_Precentral_Gyrus.nii'
%     'rRight_Frontal_Operculum.nii'
%     'rRight_Inferior_Frontal_Angular_Gyrus.nii'
%     'rLeft_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
%     'rRight_Cerebellar_Lobule_Cerebellar_Vermal_Lobules_VI-VII.nii'
%     };
% mask_short_cond = {'lSTG'
%     'lAG'
%     'lPrG'
%     'lFO'
%     'lIFG'
%     'rSTG'
%     'rAG'
%     'rPrG'
%     'rFO'
%     'rIFG'
%     'lXXX'
%     'rXXX'};
% all_combs = combvec(1:size(subjects,2),1:length(mask_cond),1:length(conditions),1:length(all_smos))';
% pat_smo_combs = combvec(1:size(subjects,2),1:length(all_smos))';
% 
% type = 't-pat'; % Run based on the t-patterns
% %type = 'beta'; % Run based on the beta-patterns
% 
% switch type
%     case 'beta'
% %First denan the beta images
% for thisone = 1:size(pat_smo_combs,1)
%     crun = pat_smo_combs(thisone,1);
% smo = all_smos(pat_smo_combs(thisone,2));
% data_path = [preprocessedpathstem subjects{crun} '/stats_multi_' num2str(smo) '_nowritten/'];
% beta_files = dir([data_path '/Cbeta_0*']);
% 
% parfor i = 1:size(beta_files,1)
% module_fslmaths_job([data_path 'Cbeta_' sprintf('%04d',i) '.nii'],'-nan',[data_path 'Cbeta_denan_' sprintf('%04d',i) '.nii']); %Account for the fact that spm_read_vols crashes with nan
% end
% end
% end
% 
% parfor thisone = 1:size(all_combs,1)
%     crun = all_combs(thisone,1);
%     mask_cond_num = all_combs(thisone,2);
%     cond_num = all_combs(thisone,3);
%     smo = all_smos(all_combs(thisone,4));
%     switch type
%         case 't-pat'
%             module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},smo) % Run based on the t-patterns
%         case 'beta'
%             module_run_rsa_beta(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},smo) %Run based on the beta patterns
%     end
%     %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},conditions{cond_num},data_smoo)
%     %module_run_rsa(crun,cond_num,mask_cond{mask_cond_num},['Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo)],data_smoo)
%     
% end
% 
% for crun = 1:size(subjects,2)
%     for mask_cond_num = 1:length(mask_cond)
%         for cond_num = 1:length(conditions)
%             for smo = 1:length(all_smos)
%                 mask_name = mask_cond{mask_cond_num};
%                 mask_short_name = mask_short_cond{mask_cond_num};
%                 switch type
%                     case 't-pat'
%                         thesedata = load(['./RSA_results/RSA_results_nowritten2_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_smooth_' num2str(all_smos(smo))],'avgRDM','stats_p_r');
%                     case 'beta'
%                         thesedata = load(['./RSA_results/RSA_results_beta_nowritten2_subj' num2str(crun) '_' conditions{cond_num} '_mask_' mask_name(1:end-4) '_smooth_' num2str(all_smos(smo))],'avgRDM','stats_p_r');
%                 end
%                 %thesedata = load(['./RSA_results/RSA_results_subj' num2str(crun) '_' 'Subj_' num2str(crun) '_mask_' mask_cond{mask_cond_num} '_cond_' conditions{cond_num} '_smo_' num2str(data_smoo) '_mask_' mask_name(1:end-4) '_smooth_' num2str(data_smoo)],'avgRDM','stats_p_r');
%                 avgRDM{crun,mask_cond_num,cond_num,smo} = thesedata.avgRDM;
%                 this_cond_name = strrep(avgRDM{crun,mask_cond_num,cond_num,smo}.name,'Mismatch ','MM');
%                 this_cond_name = strrep(this_cond_name,'Match ','M');
%                 this_cond_name = strrep(this_cond_name,'RDM across sessions | condition ','');
%                 avgRDM{crun,mask_cond_num,cond_num,smo}.name = ['S' num2str(crun) this_cond_name '_' mask_short_name '_sm' num2str(all_smos(smo))];
%                 stats_p_r{crun,mask_cond_num,cond_num,smo} = thesedata.stats_p_r;
%             end
%         end
%     end
% end
% 
% userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
% userOptions.nBootstrap=100; % XXX CHange to 10000 when code finalised
% 
% judgmentRDM.RDM = zeros(16,16);
% judgmentRDM.RDM(1:17:end) = 1;
% judgmentRDM.RDM(2:68:end) = 1/3;
% judgmentRDM.RDM(3:68:end) = 1/3;
% judgmentRDM.RDM(4:68:end) = 1/3;
% judgmentRDM.RDM(17:68:end) = 1/3;
% judgmentRDM.RDM(19:68:end) = 1/3;
% judgmentRDM.RDM(20:68:end) = 1/3;
% judgmentRDM.RDM(33:68:end) = 1/3;
% judgmentRDM.RDM(34:68:end) = 1/3;
% judgmentRDM.RDM(36:68:end) = 1/3;
% judgmentRDM.RDM(49:68:end) = 1/3;
% judgmentRDM.RDM(50:68:end) = 1/3;
% judgmentRDM.RDM(51:68:end) = 1/3;
% 
% judgmentRDM.RDM = 1-judgmentRDM.RDM;
% judgmentRDM.name = 'vowels only';
% 
% base_figureindex = 250;
% userOptions.figureIndex = [260, 360];
% 
% for crun = 1:size(subjects,2)
%     for smo = 1:length(all_smos)
% userOptions.figureIndex = [base_figureindex+10*crun+smo, base_figureindex+200+10*crun+smo];
%         
% subj_stats_p_r{crun,smo}=compareRefRDM2candRDMs(judgmentRDM, avgRDM(crun,:,:,smo), userOptions);
% 
% 
%     end
% end

%% End of script - be a good citizen
try
    matlabpool 'close'
catch
    delete(gcp)
end
