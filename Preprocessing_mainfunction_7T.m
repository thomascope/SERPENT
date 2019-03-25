function Preprocessing_mainfunction_7T(step,prevStep,p,pathstem,maxfilteredpathstem,subjects,subjcnt,dates,blocksin,blocksout,rawpathstem,badeeg,badmeg,runtodo)
% A mainfunction for preprocessing 7T MRI data
% Designed to run in a modular fashion and in parallel - i.e. pass this
% function a single step and single subject
% for example:
% 

%% Work out which file we're looking to work on now
switch prevStep
    % Here you specify the filenames that you search for after each step.
    case 'maxfilter'
        prevStep = '*ssst.fif';
        S.outfilestem = [pathstem subjects];
        if ~exist(S.outfilestem,'dir')
            mkdir(S.outfilestem);
        end
        pathstem = maxfilteredpathstem;
    case 'convert'
        prevStep = 'run*.mat';
    case 'ICA_artifacts'
        prevStep = 'Mrun*.mat';
    case 'ICA_artifacts_copy'
        prevStep = 'Mrun*.mat';
    case 'downsample'
        prevStep = 'd*Mrun*.mat';
    case 'epoch'
        prevStep = 'e*Mrun*.mat';
    case 'merge'
        prevStep = 'c*Mrun*.mat';
    case 'subtractevoked'
        prevStep = 'ev*Mrun*.mat';
    case 'rereference'
        prevStep = 'M*Mrun*.mat';
    case 'TF_power'
        prevStep = 'tf*Mrun*.mat';
    case 'TF_phase'
        prevStep = 'tph*Mrun*.mat';
    case 'TF_rescale'
        prevStep = 'r*Mrun*.mat';
    case 'filter'
        prevStep = 'fb*Mrun*.mat';
    case 'secondfilter'
        prevStep = 'ffb*Mrun*.mat';
    case 'baseline'
        prevStep = 'b*Mrun*.mat';
    case 'average'
        prevStep = 'm*Mrun*.mat';
    case 'quickaverage'
        prevStep = 'quick/m*Mrun*.mat';
    case 'weight'
        prevStep = 'w*Mrun*.mat';
    case 'combineplanar'
        prevStep = 'p*Mrun*.mat';
    case 'artefact'
        prevStep = 'a*Mrun*.mat';
    case 'blink'
        prevStep = 'clean*Mrun*.mat';
    case 'image'
        prevStep = 'trial*Mrun*.img';
    case 'smooth'
        prevStep = 'sm*Mrun*.img';
    case 'firstlevel'
        prevStep = 't*Mrun*.img';
        
end

%% Set up environment
switch p.clusterid
    case 'CBU'
        rawpathstem = '/imaging/tc02/';
        preprocessedpathstem = '/imaging/tc02/SERPENT_preprocessed/';
        rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
        %addpath /imaging/local/software/spm_cbu_svn/releases/spm12_fil_r6906
        addpath /group/language/data/thomascope/spm12_fil_r6906/
        spm fmri
        scriptdir = '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/';
        
    case 'HPC'
        rawpathstem = '/rds/user/tec31/hpc-work/SERPENT/rawdata/';
        preprocessedpathstem = '/rds/user/tec31/hpc-work/SERPENT/preprocessed/';
        addpath /home/tec31/spm12_fil_r6906/spm12_fil_r6906
        spm fmri
        scriptdir = '/rds/user/tec31/hpc-work/SERPENT';
end

%% Now do the requested step
switch step
    
    case 'skullstrip'
        nrun = size(subjects,2); % enter the number of runs here - should be 1 if submitted in parallel, but retain the functionality to bundle subjects
        
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
        
        for crun = 1:nrun
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
        
    case 'topup'
        nrun = size(subjects,2); % enter the number of runs here - should be 1 if submitted in parallel, but retain the functionality to bundle subjects
        topupworkedcorrectly = zeros(1,nrun);
        for crun = 1:nrun
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