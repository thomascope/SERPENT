% Batch script for preprocessing of pilot 7T data
% Written by TEC Feb July 2021

%% Setup environment
clear all
global spmpath fsldir toolboxdir

rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
rmpath(genpath('/group/language/data/thomascope/spm12_fil_r6906/'))
spmpath = '/group/language/data/thomascope/spm12_fil_r7771/'; % Newest version of cat12 - currently r1844
fsldir = '/imaging/local/software/fsl/fsl64/fsl-5.0.3/fsl/'; % Needs fixing
toolboxdir = '/imaging/mlr/users/tc02/toolboxes/';
scriptdir = '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/';
freesurferpath = '/home/tc02/freesurfer/';

addpath(spmpath)
spm fmri
        
%% Define parameters
setup_file = 'SERPENT_subjects_parameters';
eval(setup_file)
tr=1.75;

%% Options to skip steps
applytopup = 1;
opennewanalysispool = 1;

%% Open a worker pool
if opennewanalysispool == 1
    if size(subjects,2) > 64
        workersrequested = 64;
        fprintf([ '\n\nUnable to ask for a worker per run; asking for 64 instead\n\n' ]);
    else
        workersrequested = size(subjects,2);
    end
    
    %Open a parallel pool
    if numel(gcp('nocreate')) == 0
        Poolinfo = cbupool(workersrequested,'--mem-per-cpu=20G --time=167:00:00 --exclude=node-h[05-08]');
        parpool(Poolinfo,Poolinfo.NumWorkers);
    end
end

%% First find INV1 scan for each participant - was not in the original lookup table as O'Brien method added later
for crun = 1:size(subjects,2)
    inv2folder = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV2'))}];
    Series_number_location = findstr(inv2folder,'Series_')+8;
    Series_number = inv2folder(Series_number_location:Series_number_location+1);
    inv1folder = strrep(inv2folder,'INV2','INV1');
    flag = 2;
    inv1folder = strrep(inv1folder,['Series_0' Series_number],['Series_0' num2str(str2num(Series_number)-flag,'%02.0f')]);
    if ~exist(inv1folder,'dir')
        flag = 1;
        inv1folder = strrep(inv2folder,'INV2','INV1');
        inv1folder = strrep(inv1folder,['Series_0' Series_number],['Series_0' num2str(str2num(Series_number)-flag,'%02.0f')]);
        if ~exist(inv1folder,'dir')
            error(['Cannot find INV1 folder in the expected location, please check'])
        end
    end
    inv1rawfile = strrep(blocksin{crun}{find(strcmp(blocksout{crun},'INV2'))},[Series_number],[num2str(str2num(Series_number)-flag,'%02.0f')]);
    if ~exist([inv1folder '/' inv1rawfile],'file')
        error(['Cannot find INV1 file in the expected location for subject ' num2str(crun) ', please check'])
    end
    inv1_split_path = strsplit(inv1folder,'/');
    if ~isempty(inv1_split_path{end})
        blocksin_folders{crun}{end+1} = inv1_split_path{end};
    else
        blocksin_folders{crun}{end+1} = inv1_split_path{end-1};
    end
    blocksin{crun}{end+1} = inv1rawfile;
    blocksout{crun}{end+1} = 'INV1';
end

%% Align images ac-pc and crop the neck
coreg_and_crop_images = 1; %Necessary, but can skip if you've done before
overwrite = 1; % If you want to re-do a step - otherwise will crash if data already exist.
flags.which = 1; % For reslicing
view_scans = 0; % Obviously doesn't work in parallel

aligncropworkedcorrectly = zeros(1,size(subjects,2));
clear this_scan
% First make an array of all the scan names
first_3 = {'structural','INV2','INV1'}; % ensure that the three structurals are first in the list for cropping
for crun = 1:size(subjects,2)
    for this_scan_number = 1:length(blocksout{crun})
        if any(strcmp(first_3,blocksout{crun}{this_scan_number}))
            rawdatafolder = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{this_scan_number}];
            scanname = blocksin{crun}{this_scan_number};
            try
                this_scan{crun}{end+1} = [rawdatafolder '/' scanname];
            catch
                this_scan{crun}{1} = [rawdatafolder '/' scanname];
            end
        end
    end
    for this_scan_number = 1:length(blocksout{crun})
        if ~any(strcmp(first_3,blocksout{crun}{this_scan_number}))
            rawdatafolder = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{this_scan_number}];
            scanname = blocksin{crun}{this_scan_number};
            this_scan{crun}{end+1} = [rawdatafolder '/' scanname];
        end
    end
end

if coreg_and_crop_images
    parfor crun = 1:size(subjects,2)
        addpath('./crop')
        try
            crop_images(this_scan{crun}',3); % Vital to do rough Talaraiching first as Freesurfer can't manage it. Only crop first 3 (structurals)
            aligncropworkedcorrectly(crun)=1;
        catch
            aligncropworkedcorrectly(crun)=0;
        end
    end
    %scanname = ['p' scanname];
end

%% Now do the regularisation and denoising, both with O'Brien and multiplicative methods
parfor crun = 1:size(subjects,2)
    addpath('./mp2rage_scripts')
    structural_p = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}];
    INV2_p = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV2'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'INV2'))}];
    INV1_p = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV1'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'INV1'))}];
    removebackgroundnoise(structural_p,INV1_p,INV2_p);
    spm_imcalc_exp(structural_p,INV2_p);
    
    % Use the Uni * INV2 image - better grey-white contrast than O'Brien image
    reference_image = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_mul_inv2.nii'];
    [~, this_reference_name, this_reference_extension] = fileparts(reference_image);
    if ~exist([preprocessedpathstem subjects{crun} '/'],'dir')
        mkdir([preprocessedpathstem subjects{crun} '/'])
    end
    copyfile(reference_image,[preprocessedpathstem subjects{crun} '/' this_reference_name this_reference_extension]);
    
    %  Or use the O'Brien image - less susceptible to bias than the Uni * INV2 image 
    reference_image = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'];
    [~, this_reference_name, this_reference_extension] = fileparts(reference_image);
    if ~exist([preprocessedpathstem subjects{crun} '/'],'dir')
        mkdir([preprocessedpathstem subjects{crun} '/'])
    end
    copyfile(reference_image,[preprocessedpathstem subjects{crun} '/' this_reference_name this_reference_extension]);
end

%% Now do CAT12 segmentation
nrun = size(subjects,2); % enter the number of runs here
jobfile = {[scriptdir 'module_cat12_segment_SDoptimised_job.m']};
inputs = cell(1, nrun);
OBrien_regularisation = 1;
if OBrien_regularisation
    %  Use the O'Brien image - less susceptible to bias than the Uni * INV2 image 
    post_fix = '_denoised.nii';
else
    % Use the Uni * INV2 image - better grey-white contrast than O'Brien image
    post_fix = '_mul_inv2.nii';
end


for crun = 1:nrun
    reference_image = [preprocessedpathstem subjects{crun} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix];
    inputs{1, crun} = cellstr(reference_image);
end

cat12segmentworkedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:size(subjects,2)
    pause(crun-1) % Offset all workers to avoid crashes
    spm('defaults','PET'); % for VBM
    spm_jobman('initcfg');
    cat12('expert')
    
    cat_get_defaults('extopts.expertgui',1);
    cat_get_defaults('output.CSF.native',1);
    cat_get_defaults('output.CSF.mod',1);
    cat_get_defaults('output.bias.native',1)
    cat_get_defaults('output.GM.warped',1)
    cat_get_defaults('output.WM.warped',1)
    cat_get_defaults('opts.biasstr',1.0); % Use 1 for initial mask creation from MP2RAGE
    
    try
        spm_jobman('run', jobs, inputs{:,crun});
        cat12segmentworkedcorrectly(crun) = 1;
    catch
        cat12segmentworkedcorrectly(crun) = 0;
    end
    
end

view_scans = 0;
allatonce = 1;
% Now optionally examine the outputs
if view_scans
    all_segmentation_checks = {};
    for crun = 1:nrun
        setenv('QT_PLUGIN_PATH','/usr/lib64/qt5/plugins') % Necessary for freeview in newer versions of Matlab
        %cmd = ['freeview -v ' char(inputs{1, crun}) ' ' preprocessedpathstem subjects{crun} '/mri/p1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix ':colormap=Heat:opacity=0.2 ' preprocessedpathstem subjects{crun} '/mri/p2p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix ':colormap=PET:opacity=0.2']
        %system(cmd)
        if allatonce
            all_segmentation_checks = [all_segmentation_checks; [preprocessedpathstem subjects{crun} '/mri/mp' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p2p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p3p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]];
        else
            spm_check_registration(char([[preprocessedpathstem subjects{crun} '/mri/mp' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p2p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]; [preprocessedpathstem subjects{crun} '/mri/p3p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]]))
        end
    end
    if allatonce
        spm_check_registration(char(all_segmentation_checks))
    end
end

%% Now run Freesurfer with the CAT12 bias corrected image masked with imfilled P1+P2+P3 (Grey+White+CSF) (i.e. skullstripped)
nrun = size(subjects,2); % enter the number of runs here
overwrite = 1; % If you want to re-do a step - otherwise will crash if data already exist.
flags.which = 1; % For spm_reslice - 1 = don't reslice the first image.
view_scans = 0; 

this_subjects_dir = [preprocessedpathstem '/freesurfer_masked/'];
setenv('SUBJECTS_DIR',this_subjects_dir);
if ~exist(this_subjects_dir)
    mkdir(this_subjects_dir);
else
    for crun = 1:nrun
        if exist([this_subjects_dir subjects{crun}])&&overwrite
        rmdir([this_subjects_dir subjects{crun}],'s')
        end
    end
    %mkdir([this_subjects_dir subjects{crun}]);
end

OBrien_regularisation = 1;
if OBrien_regularisation
    %  Use the O'Brien image - less susceptible to bias than the Uni * INV2 image 
    post_fix = '_denoised.nii';
else
    % Use the Uni * INV2 image - better grey-white contrast than O'Brien image
    post_fix = '_mul_inv2.nii';
end
freesurferworkedcorrectly = zeros(1,nrun);

thisdir = pwd;
parfor crun = 1:nrun
    try
        %First skullstrip the image
        this_scan = cellstr([preprocessedpathstem subjects{crun} '/mri/mp' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]);
        all_tissue_vols = [];
        for tissue_class = 1:3
            all_tissue_vols = [all_tissue_vols; [preprocessedpathstem subjects{crun} '/mri/p' num2str(tissue_class) 'p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]];
        end
        Vo = spm_imcalc(all_tissue_vols,[preprocessedpathstem subjects{crun} '/coreg_filled_brainmask.nii'],'imfill(i1+i2+i3>0,''holes'')');
        Vo = spm_imcalc(char([all_tissue_vols;this_scan]),[preprocessedpathstem subjects{crun} '/bias_corrected_brain.nii'],'imfill(i1+i2+i3>0,''holes'').*i4');
        cd([preprocessedpathstem subjects{crun}])
        if view_scans
            %         % Optional checks - highly recommended as this step has gone all
            %         % kinds of wrong for reasons I don't understand
            spm_check_registration(char([this_scan; all_tissue_vols; 'coreg_filled_brainmask.nii'; 'bias_corrected_brain.nii']))
            setenv('QT_PLUGIN_PATH','/usr/lib64/qt5/plugins') % Necessary for freeview in newer versions of Matlab
            %system(['freeview -v coreg_filled_skullstripped.nii'])
        end
        
        % Now run freesurfer
        setenv('RAW_DATA_FOLDER',preprocessedpathstem)
        setenv('SUBJECTS_DIR',this_subjects_dir);
        setenv('FSF_OUTPUT_FORMAT','nii');
        
        % Q. I have already skull-stripped data. Can I submit it to recon-all?
        % A: If your skull-stripped volume does not have the cerebellum, then no. If it does, then yes, however you will have to run the data a bit differently.
        % First you must run only -autorecon1 like this:
        % recon-all -autorecon1 -noskullstrip -s <subjid>
        cmd = ['recon-all -autorecon1 -noskullstrip -s ' subjects{crun} ' -hires -i ' [preprocessedpathstem subjects{crun} '/bias_corrected_brain.nii'] ' -notal-check -cw256 -bigventricles'];
        fprintf(['Submitting the following first stage command: ' cmd]);
        system(cmd);
        
        % Then you will have to make a symbolic link or copy T1.mgz to brainmask.auto.mgz and a link from brainmask.auto.mgz to brainmask.mgz. Finally, open this brainmask.mgz file and check that it looks okay (there is no skull, cerebellum is intact; use the sample subject bert that comes with your FreeSurfer installation to make sure it looks comparable). From there you can run the final stages of recon-all:
        % recon-all -autorecon2 -autorecon3 -s <subjid>
        data_dir = [this_subjects_dir subjects{crun}];
        copyfile([data_dir '/mri/T1.mgz'],[data_dir '/mri/brainmask.auto.mgz'])
        copyfile([data_dir '/mri/T1.mgz'],[data_dir '/mri/brainmask.mgz'])
        cmd = ['recon-all -autorecon2 -autorecon3 -noskullstrip -s ' subjects{crun} ' -hires -notal-check -cw256 -bigventricles'];
        fprintf(['Submitting the following second stage command: ' cmd]);
        system(cmd);
        freesurferworkedcorrectly(crun) = 1;
    catch
        freesurferworkedcorrectly(crun) = 0;
    end
    
end
cd(thisdir)

view_scans = 0;
% Now manually view outputs and decide which ones are bad
bad_subjects = {
        'S7P12'
    'S7C09'
    'S7C10'
    'S7P20'
    }; %After first Freesurfer run. Failures.
if view_scans
    if isempty(bad_subjects)
        for crun = 1:nrun
            setenv('QT_PLUGIN_PATH','/usr/lib64/qt5/plugins') % Necessary for freeview in newer versions of Matlab
            cmd = ['freeview -v ' this_subjects_dir subjects{crun} '/mri/T1.mgz ' this_subjects_dir subjects{crun} '/mri/wm.mgz ' this_subjects_dir subjects{crun} '/mri/brainmask.mgz ' this_subjects_dir subjects{crun} '/mri/aseg.mgz:colormap=lut:opacity=0.2 -f ' this_subjects_dir subjects{crun} '/surf/lh.white:edgecolor=blue ' this_subjects_dir subjects{crun} '/surf/lh.pial:edgecolor=red ' this_subjects_dir subjects{crun} '/surf/rh.white:edgecolor=blue ' this_subjects_dir subjects{crun} '/surf/rh.pial:edgecolor=red'];
            system(cmd)
            isgood(crun) = input('Does this subject look good? y or n.');
        end
        bad_subjects = subjects(isgood=='n')';
    end
end

% For bad subjects, the most common reason for failure was inclusion of the
% skull in the CSF compartment of the CAT12 mask. Therefore try again
% giving Freesurfer the raw image and allowing it to segment itself.

for this_bad = 1:length(bad_subjects)
    crun_cells = strfind(subjects,bad_subjects{this_bad});
    crun = find(not(cellfun('isempty',crun_cells)));
    assert(strcmp(bad_subjects{this_bad},subjects{crun}),['Error in comparing subject strings ' bad_subjects{this_bad} ' and ' subjects{crun}]);
    
    if exist([this_subjects_dir subjects{crun}])&&overwrite
        rmdir([this_subjects_dir subjects{crun}],'s')
    end
end
parfor this_bad = 1:length(bad_subjects)
    try
        crun_cells = strfind(subjects,bad_subjects{this_bad});
        crun = find(not(cellfun('isempty',crun_cells)));
        assert(strcmp(bad_subjects{this_bad},subjects{crun}),['Error in comparing subject strings ' bad_subjects{this_bad} ' and ' subjects{crun}]);
        
        this_scan = cellstr([preprocessedpathstem bad_subjects{this_bad} '/mri/mp' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) post_fix]);
        fprintf(['Redoing bad subject: ' subjects{crun} '\n']);
        cmd = ['recon-all -all -s ' subjects{crun} ' -hires -i ' this_scan{1} ' -notal-check -cw256 -bigventricles'];
        fprintf(['Submitting the following command: ' cmd '\n']);
        system(cmd);
    end
end
    

%% Segment and skullstrip structural using SPM12 with both Uni and INV2 images
nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_skullstrip_INV2_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))} ',1']);
    inputs{2, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV2'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'INV2'))}]);
    inputs{3, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
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

%% Now realign the EPIs

realignworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    base_image_path = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'Pos_topup'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'Pos_topup'))}];
    reversed_image_path = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'Neg_topup'))} '/' blocksin{crun}{find(strcmp(blocksout{crun},'Neg_topup'))}];
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    filestorealign = cell(1,length(theseepis));
    for i = 1:length(theseepis)
        inpath = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{theseepis(i)} '/'];
        filestorealign{i} = spm_select('ExtFPList',inpath,['^' blocksin{crun}{theseepis(i)}],1:minvols(crun));
    end
    filestorealign{i+1} = base_image_path
    filestorealign{i+2} = reversed_image_path
    
    flags = struct;
    flags.fhwm = 3;
    flags.interp = 5; % Improve quality by using 5th degree B-spline interpolation
    try
        spm_realign(filestorealign,flags)
        realignworkedcorrectly(crun) = 1;
    catch
        realignworkedcorrectly(crun) = 0;
    end
    for i = 1:length(theseepis) %Now move movement parameters
        inpath = [rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{theseepis(i)} '/'];
        outpath = [preprocessedpathstem subjects{crun} '/'];
        copyfile([inpath 'rp_' blocksin{crun}{theseepis(i)}(1:end-4) '.txt'],[outpath 'rp_' blocksin{crun}{theseepis(i)}(1:end-4) '.txt'])
    end
end

if ~all(realignworkedcorrectly)
    error('failed at realign');
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

if ~all(coregisterworkedcorrectly)
    error('failed at coregister');
end

%% Now reslice all the images
backup_old = 1;
resliceworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3))
    filestorealign = cell(1,length(theseepis));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    for i = 1:length(theseepis)
        filestorealign{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        if backup_old == 1
            copyfile([outpath 'rtopup_' blocksin{crun}{theseepis(i)}],[outpath 'old_rtopup_' blocksin{crun}{theseepis(i)}]);
        end
    end        
    flags = struct
    flags.which = 2;
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

%% Now smooth the realigned, undistorted, resliced native space functionals at 3 and 8
nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_smooth_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    filestosmooth = cell(1,length(theseepis));
    filestosmooth_list = [];
    for i = 1:length(theseepis)
        filestosmooth{i} = spm_select('ExtFPList',outpath,['^rtopup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        filestosmooth_list = [filestosmooth_list; filestosmooth{i}];
    end
    inputs{1, crun} = cellstr(filestosmooth_list); % Needs to be twice, once for each smoothing kernel
    inputs{2, crun} = cellstr(filestosmooth_list);
end

smoothworkedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        smoothworkedcorrectly(crun) = 1;
    catch
        smoothworkedcorrectly(crun) = 0;
    end
end

if ~all(smoothworkedcorrectly)
    error('failed at native space smooth');
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
    inputs{1, crun} = cellstr([outpath 'mri/y_p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii']);
    
    
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
    inputs{3, crun} = cellstr([outpath 'mri/y_p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii']);
    inputs{4, crun} = cellstr([outpath 'structural.nii,1']);
    % % First is for SPM segment, second for CAT12
    %inputs{5, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/y_' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{5, crun} = cellstr([outpath 'mri/y_p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii']);
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

if ~all(normalisesmoothworkedcorrectly)
    error('failed at normalise and smooth');
end

%% Now check outputs
%First native space
for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    middle_epi = minvols(crun)/2;
    native_epi_paths = {};
    for i = 1:length(theseepis)
        native_epi_paths = [native_epi_paths; outpath 's3rtopup_' blocksin{crun}{theseepis(i)} ',' num2str(middle_epi)];
    end
    spm_check_registration(char([outpath 'structural.nii'; outpath 'mri/p1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'; outpath 'mri/p2p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'; outpath 'mri/p3p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'; native_epi_paths]))
    pause
end

%Then template space
for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    middle_epi = minvols(crun)/2;
    native_epi_paths = {};
    for i = 1:length(theseepis)
        native_epi_paths = [native_epi_paths; outpath 's3wtopup_' blocksin{crun}{theseepis(i)} ',' num2str(middle_epi)];
    end
    spm_check_registration(char([outpath 'wstructural.nii'; outpath 'mri/wp1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'; outpath 'mri/wp2p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'; native_epi_paths]))
    pause
end

% Checked, looks good except for the known problem of CAT12 putting skull
% into CSF, preventing accurate TIV determination so...

%% Now run SamSEG to get TIV estimates.
nrun = size(subjects,2); % enter the number of runs here
inputs = cell(2, nrun);

this_subjects_dir = [preprocessedpathstem 'samseg_tiv/'];
setenv('SUBJECTS_DIR',this_subjects_dir);
if ~exist(this_subjects_dir)
    mkdir(this_subjects_dir);
end
for crun = 1:nrun
    inputs{1, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    inputs{2, crun} = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'INV2'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'INV2'))}]);
end
    
parfor crun = 1:nrun
    outdir=[this_subjects_dir subjects{crun} '/samseg2']
    cmd = ['run_samseg --input ' char(inputs{1, crun}) ' ' char(inputs{2, crun}) ' --output ' outdir]
    system(cmd)
end
samseg_tiv = [];
for crun = 1:nrun
    tiv_file=[this_subjects_dir subjects{crun} '/samseg2/sbtiv.stats'];
    fid = fopen(tiv_file, 'rt');
    TextAsCells = textscan(fid, '%s', 'Delimiter', ',');
    fclose(fid);
    mask = find(~cellfun(@isempty, strfind(TextAsCells{1}, 'Measure Intra-Cranial')));
    samseg_tiv(crun) = str2num(TextAsCells{1}{mask+1});
end
save([preprocessedpathstem 'samseg_tivs'],'samseg_tiv');
csvwrite([preprocessedpathstem 'samseg_tivs.csv'],samseg_tiv);

%% Now run a VBM analysis based on either the spm or cat12 segmentations
nrun = size(subjects,2); % enter the number of runs here
age_lookup = readtable('SERPENT_Only_Included.csv');
load([preprocessedpathstem 'samseg_tivs'],'samseg_tiv');
assert(length(samseg_tiv)==nrun,'Number of subjects and TIV values does not match, aborting')
visual_check = 0;
group1_mrilist = {}; %NB: Patient MRIs, so note group number swaps
group1_ages = [];
group1_tivs = [];
group1_sexes = [];
group2_mrilist = {};
group2_ages = [];
group2_tivs = [];
group2_sexes = [];
this_scan = {};
this_segmented = {};
segmented = 1;
spm_segment = 0;
cat12_segment = 1;
clear group1_covariates group2_covariates

for crun = 1:nrun
    this_age = age_lookup.Age(strcmp(age_lookup.x_SubjectID,subjects{crun}));
    this_sex = strcmp(age_lookup.Sex(strcmp(age_lookup.x_SubjectID,subjects{crun})),'M');
    %Define covariates
    Age_column = find(strcmp(age_lookup.Properties.VariableNames,'Age'));
    covariate_struct = table2struct(age_lookup(strcmp(age_lookup.x_SubjectID,subjects{crun}),Age_column:length(age_lookup.Properties.VariableNames)));
    this_scan(crun) = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
    %this_scan(crun) = cellstr([preprocessedpathstem subjects{crun} '/structural.nii']);
    if segmented
        if spm_segment
            this_segmented(crun) = cellstr([rawpathstem basedir{crun} '/' fullid{crun} '/' blocksin_folders{crun}{find(strcmp(blocksout{crun},'structural'))} '/c1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}]);
        elseif cat12_segment
            outpath = [preprocessedpathstem subjects{crun} '/'];
            this_segmented(crun) = cellstr([outpath 'mri/mwp1p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii']);
        end
    end
    if group(crun) == 1 % Controls
        if ~segmented
            group2_mrilist(end+1) = this_scan(crun);
        else
            group2_mrilist(end+1) = this_segmented(crun);
        end
        group2_ages(end+1) = this_age;
        group2_tivs(end+1) = samseg_tiv(crun);
        if exist('group2_covariates','var')
            group2_covariates(end+1) = covariate_struct;
        else
            group2_covariates = covariate_struct;
        end
        group2_sexes(end+1) = this_sex;
    elseif group(crun) == 2 % Patients
        if ~segmented
            group1_mrilist(end+1) = this_scan(crun);
        else
            group1_mrilist(end+1) = this_segmented(crun);
        end
        group1_ages(end+1) = this_age;
        group1_tivs(end+1) = samseg_tiv(crun);
        if exist('group1_covariates','var')
            group1_covariates(end+1) = covariate_struct;
        else
            group1_covariates = covariate_struct;
        end
        group1_sexes(end+1) = this_sex;
    end
end
if visual_check
    if segmented
        spm_check_registration(this_segmented{:})
    else
        spm_check_registration(this_scan{:}) % Optional visual check of your input images (don't need to be aligned or anything, just to see they're all structurals and exist)
    end
end

%NB: Only implemented so far for cat12 segmented images - other image types
%will need extra steps, see https://github.com/thomascope/7T_pilot_analysis/blob/master/module_vbm_job.m
% if spm_segment
% % Make a DARTEL template based on a matched number of control and patient images
% npatients = sum(group==2);
% ncontrols = sum(group==1);
% core_number = min(npatients,ncontrols);
% 
% core_imagepaths = [group1_mrilist; group2_mrilist(1:length(group1_mrilist))
% 
% XXX this section not yet complete, because we have moved to cat12
% segmentation

% Now smooth all scans
group1_mrilist = group1_mrilist';
group2_mrilist = group2_mrilist';
mrilist = [group1_mrilist; group2_mrilist];

jobfile = {[scriptdir 'module_smooth_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    inputs{1, crun} = cellstr(mrilist{crun}); % Needs to be twice, once for each smoothing kernel
    inputs{2, crun} = cellstr(mrilist{crun});
end

structuralsmoothworkedcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        structuralsmoothworkedcorrectly(crun) = 1;
    catch
        structuralsmoothworkedcorrectly(crun) = 0;
    end
end

if ~all(structuralsmoothworkedcorrectly)
    error('failed at segmented structural smooth');
end

% Now do group stats with TIV and age file as covariates in the ANOVA
nrun = 1;
all_smooth = [3,8];
parfor smooth_number = 1:2
    this_smooth = all_smooth(smooth_number)
    jobfile = {[scriptdir '/vbm_scripts/VBM_batch_factorial_TIV_age.m']};
    jobs = repmat(jobfile, 1, nrun);
    inputs = cell(6, nrun);
    stats_folder = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/factorial_full_group_vbm_TIVnormalised_agecovaried_unsmoothedmask']};
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    
    inputs{1, 1} = stats_folder;
    
    for crun = 1:nrun
        inputs{2, crun} = cell(length(group1_mrilist),1);
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
        end
        inputs{3, crun} = cell(length(group2_mrilist),1);
        for i = 1:length(group2_mrilist)
            if segmented
                if spm_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group2{i}{end}]);
                elseif cat12_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group2{i}{end}]);
                end
            else
                inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group2{i}{end}]);
            end
        end
    end
    
    inputs{4, 1} = [group1_tivs'; group2_tivs'];
    inputs{5, 1} = [group1_ages'; group2_ages'];
    if cat12_segment
        inputs{6, 1} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
    else
        inputs{6, 1} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
    end
    
    if ~exist(char(inputs{6, 1}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    if visual_check
        all_input_images = [inputs{2};inputs{3}];
        spm_check_registration(all_input_images{:})
        input('Press any key to continue')
    end
    spm('defaults', 'PET');
    spm_jobman('run', jobs, inputs{:});
    
    inputs = cell(1, nrun);
    inputs{1, 1} =  {[char(stats_folder) '/SPM.mat']};
    
    jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
    jobs = repmat(jobfile, 1, nrun);
    
    spm_jobman('run', jobs, inputs{:});
    
    jobfile = {[scriptdir '/vbm_scripts/VBM_batch_contrast.m']};
    jobs = repmat(jobfile, 1, nrun);
    
    spm_jobman('run', jobs, inputs{:});
    
    jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
    jobs = repmat(jobfile, 1, nrun);
    
    spm_jobman('run', jobs, inputs{:});
end

% Now do covariate stats with behavioural regressors, and age+TIV
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
    this_smooth = all_smooth(smooth_number);
    inputs = cell(6, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist),nrun);
       
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/covariate_analysis/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist),1);
        inputs{3, crun} = [group1_tivs'];
        inputs{4, crun} = [group1_ages'];
        inputs{5, crun} = NaN(length(group1_mrilist),1);
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{5, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        if cat12_segment
            inputs{6, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{6, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{6, 1}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue 
        end
        
        try
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_ungrouped_covariate_TIV_age.m']};
        jobs = repmat(jobfile, 1, nrun);
        spm('defaults', 'PET');
        
        these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
        these_inputs{1,1} = inputs{1,crun};
        for i = 2:size(inputs,1)-1
            these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
        end
        these_inputs{i+1,1} = inputs{end,crun};
        spm_jobman('run', jobs{crun}, these_inputs{:,1});
        
        new_inputs = cell(1, nrun);
        new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_ungrouped_contrast.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end

% Now do covariate stats with behavioural regressors, and age+TIV+sex
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
    this_smooth = all_smooth(smooth_number);
    inputs = cell(7, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist),nrun);
       
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/covariate_analysis_withsex/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist),1);
        inputs{3, crun} = [group1_tivs'];
        inputs{4, crun} = [group1_ages'];
        inputs{5, crun} = NaN(length(group1_mrilist),1);
        inputs{6, crun} = [group1_sexes'];
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{5, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        if cat12_segment
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{7, 1}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue 
        end
        
        try
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_ungrouped_covariate_TIV_age_sex.m']};
        jobs = repmat(jobfile, 1, nrun);
        spm('defaults', 'PET');
        
        these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
        these_inputs{1,1} = inputs{1,crun};
        for i = 2:size(inputs,1)-1
            these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
        end
        these_inputs{i+1,1} = inputs{end,crun};
        spm_jobman('run', jobs{crun}, these_inputs{:,1});
        
        new_inputs = cell(1, nrun);
        new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_ungrouped_contrast.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end

% Now repeat covariate stats with controls too - behavioural regressors, and age+TIV
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
    this_smooth = all_smooth(smooth_number);
    inputs = cell(6, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist)+length(group2_mrilist),nrun);
       
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/covariate_analysis_withcontrols/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};       
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist)+length(group2_mrilist),1);
        inputs{3, crun} = [group1_tivs';group2_tivs'];
        inputs{4, crun} = [group1_ages';group2_ages'];
        inputs{5, crun} = [NaN(length(group1_mrilist),1);NaN(length(group1_mrilist),1)];
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{5, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        for i = 1:length(group2_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group2{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group2{i}{end}]);
                end
            else
                inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group2{i}{end}]);
            end
            inputs{5, crun}(i+length(group1_mrilist)) = eval(['group2_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i+length(group1_mrilist)))
                covariate_nans(i+length(group1_mrilist), crun) = 1;
            end
        end
        if cat12_segment
            inputs{6, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{6, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{6, 1}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue 
        end
        
        try
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_ungrouped_covariate_TIV_age.m']};
        jobs = repmat(jobfile, 1, nrun);
        spm('defaults', 'PET');
        
        these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
        these_inputs{1,1} = inputs{1,crun};
        for i = 2:size(inputs,1)-1
            these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
        end
        these_inputs{i+1,1} = inputs{end,crun};
        spm_jobman('run', jobs{crun}, these_inputs{:,1});
        
        new_inputs = cell(1, nrun);
        new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_ungrouped_contrast.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end

% Now repeat covariate stats with controls too - behavioural regressors, and age+TIV+sex
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
      this_smooth = all_smooth(smooth_number);
    inputs = cell(6, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist)+length(group2_mrilist),nrun);
       
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/covariate_analysis_withcontrols_withsex/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};       
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist)+length(group2_mrilist),1);
        inputs{3, crun} = [group1_tivs';group2_tivs'];
        inputs{4, crun} = [group1_ages';group2_ages'];
        inputs{5, crun} = [NaN(length(group1_mrilist),1);NaN(length(group1_mrilist),1)];
        inputs{6, crun} = [group1_sexes';group2_sexes'];
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{5, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        for i = 1:length(group2_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group2{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group2{i}{end}]);
                end
            else
                inputs{2,crun}(i+length(group1_mrilist)) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group2{i}{end}]);
            end
            inputs{5, crun}(i+length(group1_mrilist)) = eval(['group2_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{5, crun}(i+length(group1_mrilist)))
                covariate_nans(i+length(group1_mrilist), crun) = 1;
            end
        end
        if cat12_segment
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{7, 1}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue 
        end
        
        try
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_ungrouped_covariate_TIV_age_sex.m']};
        jobs = repmat(jobfile, 1, nrun);
        spm('defaults', 'PET');
        
        these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
        these_inputs{1,1} = inputs{1,crun};
        for i = 2:size(inputs,1)-1
            these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
        end
        these_inputs{i+1,1} = inputs{end,crun};
        spm_jobman('run', jobs{crun}, these_inputs{:,1});
        
        new_inputs = cell(1, nrun);
        new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_ungrouped_contrast.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end

% Now repeat covariate stats with group as a factor - behavioural regressors, and age+TIV
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
    this_smooth = all_smooth(smooth_number);
    inputs = cell(7, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist)+length(group2_mrilist),nrun);
    
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/grouped_covariate_analysis/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist),1);
        inputs{3, crun} = cell(length(group2_mrilist),1);
        inputs{4, crun} = [group1_tivs';group2_tivs'];
        inputs{5, crun} = [group1_ages';group2_ages'];
        inputs{6, crun} = [NaN(length(group1_mrilist),1);NaN(length(group1_mrilist),1)];
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{6, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{6, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        for i = 1:length(group2_mrilist)
            if segmented
                if spm_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group2{i}{end}]);
                elseif cat12_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group2{i}{end}]);
                end
            else
                inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group2{i}{end}]);
            end
            inputs{6, crun}(i+length(group1_mrilist)) = eval(['group2_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{6, crun}(i+length(group1_mrilist)))
                covariate_nans(i+length(group1_mrilist), crun) = 1;
            end
        end
        if cat12_segment
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{7, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{7, crun}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue
        end
        
        try
            jobfile = {[scriptdir '/vbm_scripts/VBM_batch_grouped_covariate_TIV_age.m']};
            jobs = repmat(jobfile, 1, nrun);
            spm('defaults', 'PET');
            
            these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
            these_inputs{1,1} = inputs{1,crun};
            these_inputs{2,1} = inputs{2,crun}(isnan(covariate_nans(1:length(group1_mrilist),crun)));
            these_inputs{3,1} = inputs{3,crun}(isnan(covariate_nans(length(group1_mrilist)+1:end,crun)));
            for i = 4:size(inputs,1)-1
                these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
            end
            these_inputs{i+1,1} = inputs{end,crun};
            spm_jobman('run', jobs{crun}, these_inputs{:,1});
            
            new_inputs = cell(1, nrun);
            new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
            
            jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
            jobs = repmat(jobfile, 1, nrun);
            
            spm_jobman('run', jobs{crun}, new_inputs{:,crun});
            
            jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_grouped_contrast.m']};
            jobs = repmat(jobfile, 1, nrun);
            
            spm_jobman('run', jobs{crun}, new_inputs{:,crun});
            
            jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
            jobs = repmat(jobfile, 1, nrun);
            
            spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end

% Now repeat covariate stats with group as a factor - behavioural regressors, and age+TIV+sex
nrun = length(fieldnames(group1_covariates(1)))-1;
all_smooth = [3,8];
for smooth_number = 1:2
    this_smooth = all_smooth(smooth_number);
    inputs = cell(8, nrun);
    split_stem_group2 = regexp(group2_mrilist, '/', 'split');
    split_stem_group1 = regexp(group1_mrilist, '/', 'split');
    covariate_nans = NaN(length(group1_mrilist)+length(group2_mrilist),nrun);
       
    for crun = 1:nrun
        stats_folder{crun} = {[preprocessedpathstem filesep 'VBM_stats_' num2str(this_smooth) '/grouped_covariate_analysis_withsex/' char(age_lookup.Properties.VariableNames(crun+Age_column))]};
        inputs{1, crun} = stats_folder{crun};
        inputs{2, crun} = cell(length(group1_mrilist),1);
        inputs{3, crun} = cell(length(group2_mrilist),1);
        inputs{4, crun} = [group1_tivs';group2_tivs'];
        inputs{5, crun} = [group1_ages';group2_ages'];
        inputs{6, crun} = [NaN(length(group1_mrilist),1);NaN(length(group1_mrilist),1)];
        inputs{7, crun} = [group1_sexes';group2_sexes'];
        for i = 1:length(group1_mrilist)
            if segmented
                if spm_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group1{i}{end}]);
                elseif cat12_segment
                    inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group1{i}{end}]);
                end
            else
                inputs{2,crun}(i) = cellstr(['/' fullfile(split_stem_group1{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group1{i}{end}]);
            end
            inputs{6, crun}(i) = eval(['group1_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{6, crun}(i))
                covariate_nans(i, crun) = 1;
            end
        end
        for i = 1:length(group2_mrilist)
            if segmented
                if spm_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mw' split_stem_group2{i}{end}]);
                elseif cat12_segment
                    inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) split_stem_group2{i}{end}]);
                end
            else
                inputs{3,crun}(i) = cellstr(['/' fullfile(split_stem_group2{i}{1:end-1}) '/s' num2str(this_smooth) 'mwc1' split_stem_group2{i}{end}]);
            end
            inputs{6, crun}(i+length(group1_mrilist)) = eval(['group2_covariates(i).' char(age_lookup.Properties.VariableNames(crun+Age_column))]);
            if isnan(inputs{6, crun}(i+length(group1_mrilist)))
                covariate_nans(i+length(group1_mrilist), crun) = 1;
            end
        end
        if cat12_segment
            inputs{8, crun} = {[scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']};
        else
            inputs{8, crun} = {[scriptdir 'control_majority_unsmoothed_mask_c1_thr0.05_cons0.8.img']};
        end
        
    end
    
    if ~exist(char(inputs{8, crun}),'file')
        maskfilenames = {};
        for i = 1:length(group2_mrilist)
            if segmented
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}(3:end)];
            else
                maskfilenames{i} = ['/' fullfile(split_stem_group2{i}{1:end-1}) '/w' split_stem_group2{i}{end}];
            end
        end
        if cat12_segment
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_p1'], char(maskfilenames))
        else
            make_majority_mask([0.2 0.1 0.05 0.001], 0.8, ['control_majority_unsmoothed_mask_c1'], char(maskfilenames))
        end
    end
    
    parfor crun = 1:nrun
        if all(covariate_nans(:,crun)==1)
            continue 
        end
        
        try
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_grouped_covariate_TIV_age_sex.m']};
        jobs = repmat(jobfile, 1, nrun);
        spm('defaults', 'PET');
        
        these_inputs = cell(size(inputs,1),1); % Exclude NaN covariates
        these_inputs{1,1} = inputs{1,crun};
        these_inputs{2,1} = inputs{2,crun}(isnan(covariate_nans(1:length(group1_mrilist),crun)));
        these_inputs{3,1} = inputs{3,crun}(isnan(covariate_nans(length(group1_mrilist)+1:end,crun)));
        for i = 4:size(inputs,1)-1
            these_inputs{i,1} = inputs{i,crun}(isnan(covariate_nans(:,crun)));
        end
        these_inputs{i+1,1} = inputs{end,crun};
        spm_jobman('run', jobs{crun}, these_inputs{:,1});
        
        new_inputs = cell(1, nrun);
        new_inputs{1, crun} =  {[char(stats_folder{crun}) '/SPM.mat']};
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_estimate.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_covariate_grouped_contrast.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        
        jobfile = {[scriptdir '/vbm_scripts/VBM_batch_results.m']};
        jobs = repmat(jobfile, 1, nrun);
        
        spm_jobman('run', jobs{crun}, new_inputs{:,crun});
        catch
        end
    end
end


%% Now do fMRI SPM Univariate analysis in template space
nrun = size(subjects,2); % enter the number of runs here
for this_smooth = [3,8];
    % Do a univariate SPM analysis at a smoothing level set by the this_smooth flag
    disp('SPM univariate analysis')
    
    inputs = cell(0, nrun);
    
    starttime={};
    stimType={};
    stim_type_labels={};
    for crun = 1:nrun
        theseepis = find(strncmp(blocksout{crun},'Run',3));
        outpath = [preprocessedpathstem subjects{crun} '/'];
        filestoanalyse = cell(1,length(theseepis));
        
        [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD_cluster(subjects{crun},dates{crun},length(theseepis),minvols(crun));
        
        inputs{1, crun} = cellstr([outpath 'stats_mask0.3_' num2str(this_smooth) '_multi_reversedbuttons']);
        for sess = 1:length(theseepis)
            filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s' num2str(this_smooth) 'wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
            inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
            this_rp_file = dir([outpath 'rp*' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
            inputs{(2*(sess-1))+3, crun} = cellstr([outpath this_rp_file.name]);
        end
        %inputs{end+1, crun} = cellstr([outpath 'binarised_native_structural_mask.nii,1']); % Don't mask at first level
    end
    
    SPMworkedcorrectly = zeros(1,nrun);
    parfor crun = 1:nrun
        for i = 1:length(subjects)
            this_dir = pwd;
            cd([scriptdir 'behavioural_data'])
            [~,~, reversed_buttons] = SD_7T_behaviour_withnull( subjects{crun}, dates{crun} ); % Need to check button presses are recorded correctly
            cd(this_dir)
        end
        jobfile = create_SD_SPM_Job(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun},reversed_buttons);
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
        error(['failed at SPM ' num2str(this_smooth) 'mm']);
    end
    
end

%% Now create a univariate second level SPM with Age as a covariate - one per condition of interest
for this_smooth = [3,8];
    exclude_bad = 0; % I have now excluded only the relevant EPI sequences above.
    bad_scans = {
        };
    
    age_lookup = readtable('SERPENT_Only_Included.csv');
    all_conditions = {
        'con_0005.nii','Photos > Line';
        'con_0010.nii','Photos < Line';
        'con_0015.nii','Left > Right';
        'con_0020.nii','Left < Right';
        'con_0025.nii','Common > Rare';
        'con_0030.nii','Common < Rare';
        'con_0035.nii','Left Button';
        'con_0040.nii','Right Button'
        'con_0045.nii','All Pictures'
        'con_0050.nii','Negative All Pictures'
        };
    expected_sessions = 4;
    
    visual_check = 0;
    nrun = size(all_conditions,1); % enter the number of runs here
    %jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
    
    this_scan = {};
    this_t_scan = {};
    firstlevel_folder = ['stats_mask0.3_' num2str(this_smooth) '_multi_reversedbuttons'];
    
    jobfile = {[scriptdir 'module_secondlevel_job.m']};
    jobs = repmat(jobfile, 1, nrun);
    inputs = cell(4, nrun);
    
    for this_condition = 1:nrun
        group1_firstlevel_mrilist = {}; %NB: Patient MRIs, so here group 2 (sorry)
        group1_firstlevel_ages = [];
        group2_firstlevel_mrilist = {};
        group2_firstlevel_ages = [];
        
        if exclude_bad
            inputs{1, this_condition} = cellstr([preprocessedpathstem firstlevel_folder '_nobad' filesep all_conditions{this_condition,2}]);
        else
            inputs{1, this_condition} = cellstr([preprocessedpathstem firstlevel_folder filesep all_conditions{this_condition,2}]);
        end
        for crun = 1:size(subjects,2)
            if exclude_bad
                if any(strcmp(bad_scans,subjects{crun}))
                    continue
                end
            end
            this_age = age_lookup.Age(strcmp(age_lookup.x_SubjectID,subjects{crun}));
            this_spm_temp = load([preprocessedpathstem subjects{crun} filesep firstlevel_folder filesep 'SPM.mat']);
            if length(this_spm_temp.SPM.Sess)~=expected_sessions
                disp([subjects{crun} ' has ' num2str(length(this_spm_temp.SPM.Sess)) ' sessions when ' num2str(expected_sessions) ' expected. Check this is what you want'])
                con_num = str2num(all_conditions{this_condition,1}(5:8));
                new_con_num = (con_num/(expected_sessions+1))*(length(this_spm_temp.SPM.Sess)+1);
                disp(['Replacing contrast ' num2str(con_num,'%04.f') ' with ' num2str(new_con_num,'%04.f')])
                new_contrast_name = strrep(all_conditions{this_condition,1},num2str(con_num,'%04.f'),num2str(new_con_num,'%04.f'));
                this_scan(crun) = cellstr([preprocessedpathstem subjects{crun} filesep firstlevel_folder filesep new_contrast_name]);
                this_t_scan(crun) = cellstr([preprocessedpathstem subjects{crun} filesep firstlevel_folder filesep strrep(new_contrast_name,'con','spmT')]);
            else
                this_scan(crun) = cellstr([preprocessedpathstem subjects{crun} filesep firstlevel_folder filesep all_conditions{this_condition,1}]);
                this_t_scan(crun) = cellstr([preprocessedpathstem subjects{crun} filesep firstlevel_folder filesep strrep(all_conditions{this_condition,1},'con','spmT')]);
            end
            if group(crun) == 1 % Controls
                group2_firstlevel_mrilist(end+1) = this_scan(crun);
                group2_firstlevel_ages(end+1) = this_age;
            elseif group(crun) == 2 % Patients
                group1_firstlevel_mrilist(end+1) = this_scan(crun);
                group1_firstlevel_ages(end+1) = this_age;
            end
        end
        inputs{2, this_condition} = group1_firstlevel_mrilist';
        inputs{3, this_condition} = group2_firstlevel_mrilist';
        inputs{4, this_condition} = [group1_firstlevel_ages';group2_firstlevel_ages'];
        if visual_check
            spm_check_registration(this_t_scan{~cellfun(@isempty,this_t_scan)}) % Optional visual check of your input images (don't need to be aligned or anything, just to see they're all t-maps and exist)
            input('Press any key to proceed to second level with these scans')
        end
    end
    
    secondlevelworkedcorrectly = zeros(1,nrun);
    parfor crun = 1:nrun
        spm('defaults', 'fMRI');
        spm_jobman('initcfg')
        try
            spm_jobman('run', jobs{crun}, inputs{:,crun});
            secondlevelworkedcorrectly(crun) = 1;
        catch
            secondlevelworkedcorrectly(crun) = 0;
        end
    end
end

%% Now repeat SPM Univariate analysis in native space
nrun = size(subjects,2); % enter the number of runs here
for this_smooth = [3,8];
    % Do a univariate SPM analysis at a smoothing level set by the this_smooth flag
    disp('SPM univariate analysis')
    
    inputs = cell(0, nrun);
    
    starttime={};
    stimType={};
    stim_type_labels={};
    for crun = 1:nrun
        theseepis = find(strncmp(blocksout{crun},'Run',3));
        outpath = [preprocessedpathstem subjects{crun} '/'];
        filestoanalyse = cell(1,length(theseepis));
        
        [starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},run_params{crun}] = module_get_event_times_SD_cluster(subjects{crun},dates{crun},length(theseepis),minvols(crun));
        
        inputs{1, crun} = cellstr([outpath 'stats_native_mask0.3_' num2str(this_smooth) '_coreg_reversedbuttons']);
        for sess = 1:length(theseepis)
            filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s' num2str(this_smooth) 'rtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
            inputs{(2*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
            this_rp_file = dir([outpath 'rp*' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
            inputs{(2*(sess-1))+3, crun} = cellstr([outpath this_rp_file.name]);
        end
        %inputs{end+1, crun} = cellstr([outpath 'binarised_native_structural_mask.nii,1']); % Don't mask at first level
    end
    
    SPMworkedcorrectly = zeros(1,nrun);
    parfor crun = 1:nrun
        for i = 1:length(subjects)
            this_dir = pwd;
            cd([scriptdir 'behavioural_data'])
            [~,~, reversed_buttons_native] = SD_7T_behaviour_withnull( subjects{crun}, dates{crun} ); % Need to check button presses are recorded correctly
            cd(this_dir)
        end
        jobfile = create_SD_SPM_Job(subjects{crun},dates{crun},starttime{crun},stimType{crun},stim_type_labels{crun},buttonpressed{crun},buttonpresstime{crun},inputs(:,crun),run_params{crun},reversed_buttons_native);
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
        error(['failed at SPM ' num2str(this_smooth) 'mm']);
    end
    
end

%% Now run the cross validated Mahalanobis distance and RSM on each subject on the whole brain downsampled at 2 (quick)
nrun = size(subjects,2); % enter the number of runs here
mahalanobisworkedcorrectly = zeros(1,nrun);
downsamp_ratio = 2; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons'];
    try
        TDTCrossnobisAnalysis_1Subj(GLMDir,downsamp_ratio)
        mahalanobisworkedcorrectly(crun) = 1;
    catch
        mahalanobisworkedcorrectly(crun) = 0;
    end
end

%% Or run the cross validated Mahalanobis distance and RSM on each subject on the whole brain not downsampled, but in parallel over voxels (slow, and produces around 12Gb output data per subject, but more powerful statistics) - the bigger the worker pool the better.
run_not_downsampled = 1; % NB: MAKES HUGE FILES!
if run_not_downsampled
    nrun = size(subjects,2); % enter the number of runs here
    mahalanobisparallelworkedcorrectly = zeros(1,nrun);
    for crun = 1:nrun
        if numel(gcp('nocreate')) == 0 % If parallel pool crashes, this should allow the loop to simply resume at the next subject
            Poolinfo = cbupool(60,'--mem-per-cpu=10G --time=167:00:00');
            parpool(Poolinfo,Poolinfo.NumWorkers);
        end
        addpath(genpath('./RSA_scripts'))
        GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons'];
        try
            TDTCrossnobisAnalysis_parallelsearch(GLMDir)
            mahalanobisparallelworkedcorrectly(crun) = 1;
        catch
            mahalanobisparallelworkedcorrectly(crun) = 0;
        end
    end
    if opennewanalysispool == 1
        delete(gcp)
        if size(subjects,2) > 64
            workersrequested = 64;
            fprintf([ '\n\nUnable to ask for a worker per run; asking for 64 instead\n\n' ]);
        else
            workersrequested = size(subjects,2);
        end
        Poolinfo = cbupool(workersrequested,'--mem-per-cpu=14G --time=167:00:00');
        parpool(Poolinfo,Poolinfo.NumWorkers);
    end
end

%% Do an RSA analysis
nrun = size(subjects,2); % enter the number of runs here
RSAnobisworkedcorrectly = zeros(1,nrun);
downsamp_ratio = 1; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons'];
    try
        module_make_effect_maps(GLMDir,downsamp_ratio,subjects{crun})
        RSAnobisworkedcorrectly(crun) = 1;
    catch
        RSAnobisworkedcorrectly(crun) = 0;
    end
end

%% Now normalise the native space RSA maps into template space with CAT12 deformation fields calculated earlier
nrun = size(subjects,2); % enter the number of runs here
native2templateworkedcorrectly = zeros(1,nrun);
downsamp_ratio = 1; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons'];
    outpath = [preprocessedpathstem subjects{crun} '/'];
    try
        module_nativemap_2_template(GLMDir,downsamp_ratio,outpath)
        native2templateworkedcorrectly(crun) = 1;
    catch
        native2templateworkedcorrectly(crun) = 0;
    end
end

% %% Now check this normalisation - looking at the results seems to have failed in parietal lobe
% template = '/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/S7C01/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis/spearman/wnativeSpaceMask_templates within photo_right.nii';
% all_masks = {};
% for i = 1:length(subjects)
% all_masks{i} = strrep(template,'S7C01',subjects{i});
% end
% spm_check_registration(char(all_masks'))
% 
% %It was S7P01! Very shifted. Examining raw images, seems to be a problem
% %with co-registration of s3rtopup image - offset.
% %S7P16 also looks less than ideal - lots of non-brain in mask, pushing occipital lobe in



%% Now do a second level analysis on the searchlights
crun = 1;
age_lookup = readtable('SERPENT_Only_Included.csv');
downsamp_ratio = 1; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
rmpath([scriptdir '/RSA_scripts/es_scripts_fMRI']) %Stops SPM getting defaults for second level if on path

GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
outpath = [preprocessedpathstem '/stats_native_mask0.3_3_coreg_reversedbuttons/searchlight/downsamp_' num2str(downsamp_ratio) filesep 'second_level']; %Results directory

searchlighthighressecondlevel = []; % Sampling at 1mm isotropic - preferable for REML
searchlighthighressecondlevel = module_searchlight_secondlevel_hires(GLMDir,subjects,group,age_lookup,outpath,downsamp_ratio);

%% Repeat excluding subjects with poor quality data
subjects_noP16 = subjects;
subjects_noP16(strcmp(subjects_noP16,'S7P16')) = [];

crun = 1;
age_lookup = readtable('SERPENT_Only_Included.csv');
downsamp_ratio = 1; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
rmpath([scriptdir '/RSA_scripts/es_scripts_fMRI']) %Stops SPM getting defaults for second level if on path

GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
outpath = [preprocessedpathstem '/stats_native_mask0.3_3_coreg_reversedbuttons/searchlight/downsamp_' num2str(downsamp_ratio) filesep 'second_level_noP16']; %Results directory

searchlighthighressecondlevel = []; % Sampling at 1mm isotropic - preferable for REML
searchlighthighressecondlevel = module_searchlight_secondlevel_hires(GLMDir,subjects_noP16,group,age_lookup,outpath,downsamp_ratio);

%% Now do ROI analysis
% First separate out probablistic map into components: Wang, Liang, et al. "Probabilistic maps of visual topography in human cortex." Cerebral cortex 25.10 (2015): 3911-3931.
% 01 - V1v	    
% 02 - V1d	   
% 03 - V2v	   
% 04 - V2d	   
% 05 - V3v	    
% 06 - V3d	    
% 07 - hV4	  
% 08 - VO1	    
% 09 - VO2	
make_atlas_rois = 0; %Already done
if make_atlas_rois
    for this_roi = 1:9
    spm_imcalc('./Regions_of_Interest/maxprob_vol_lh.nii',['./Regions_of_Interest/lh_roi_' num2str(this_roi) '.nii'],['i1==' num2str(this_roi)])
    spm_imcalc('./Regions_of_Interest/maxprob_vol_rh.nii',['./Regions_of_Interest/rh_roi_' num2str(this_roi) '.nii'],['i1==' num2str(this_roi)])
    end
end


% Now create a vector along the ventral stream, using Engell's Face-Scene
% contrast: Engell A.D. and McCarthy G. (2013). fMRI activation by face and biological motion perception: Comparison of response maps and creation of probabilistic atlases. NeuroImage, 74, 140-151.
face_map_info = spm_vol('./Regions_of_Interest/ASAP_maps/facescene_pmap_N124_stat3.nii');
face_map = spm_read_vols(face_map_info); % This is the Face-Scene contrast for 124 young healthy people, expressed as percent significant in each voxel

%Find peak location on each side (Right and left FFA)
left_half = face_map;
left_half(1:floor(size(face_map,1)/2),:,:) = 0; %NB: x-direction negative indexed here
right_half = face_map;
right_half(ceil((size(face_map,1))/2):end,:,:) = 0;
[~,idx_r] = max(right_half(:));
[~,idx_l] = max(left_half(:));
all_interpolated_MNI_locations = {};
for start_idx = [idx_r, idx_l]
    %Work forwards and backwards from those points to make a tensor;
    [r,c,p] = ind2sub(size(face_map),start_idx);
    MNI_x = [face_map_info.mat(1,4)+(r*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(c*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(p*face_map_info.mat(3,3))];
    
    %Work forwards and backwards from that point to make a tensor;
    y_start = MNI_x(2);
    %First go backwards
    last_location = [r,c,p];
    these_negative_locations = [];
    these_negative_MNI_locations = [];
    for this_y = (c-1):-1:(c-50)
        this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
            these_negative_locations = [these_negative_locations; last_location];
            last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
            these_negative_MNI_locations = [these_negative_MNI_locations; last_MNI_location];
        else % Less than 10% of subjects have face preference - end of tensor
            break
        end
    end
    
    %Then go forwards
    last_location = [r,c,p];
    these_positive_locations = [];
    these_positive_MNI_locations = [];
    for this_y = (c+1):1:(c+50)
        this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
            these_positive_locations = [these_positive_locations; last_location];
            last_MNI_location = (face_map_info.mat*[last_location 1]')';
            last_MNI_location = last_MNI_location(1:3);
            %last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
            these_positive_MNI_locations = [these_positive_MNI_locations; last_MNI_location];
        else % Less than 10% of subjects have face preference - end of tensor
            break
        end
    end
    
    %Then create tensor
    these_locations = [flipud(these_negative_locations); [r,c,p]; these_positive_locations];
    these_MNI_locations = [flipud(these_negative_MNI_locations); MNI_x; these_positive_MNI_locations];
    % Interpolate from 2mm to 1mm resolution
    these_interpolated_MNI_locations = [];
    for this_y_loc = 1:size(these_MNI_locations,1)-1
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(this_y_loc,:)];
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; mean(these_MNI_locations(this_y_loc:this_y_loc+1,:),1)];
    end
    these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(end,:)];
    all_interpolated_MNI_locations{end+1} = these_interpolated_MNI_locations;
end

% Write these tensors for visualisation
example_volume_info = spm_vol('photo_line_template_noself.nii'); %An example multivariate contrast 
example_volume = spm_read_vols(example_volume_info); %An example multivariate contrast 
tensors_to_write = zeros(size(example_volume));
for this_tensor = 1:length(all_interpolated_MNI_locations)
    for this_location = 1:length(all_interpolated_MNI_locations{this_tensor})
        these_voxel_coordinates = [all_interpolated_MNI_locations{this_tensor}(this_location,:),1]*(inv(example_volume_info.mat))';
        try
            tensors_to_write(these_voxel_coordinates(1),these_voxel_coordinates(2),these_voxel_coordinates(3)) = 1;
        end
    end
end
tensor_volume_info = example_volume_info;
tensor_volume_info.descrip = 'Tensors for multivariate analysis';
tensor_volume_info.fname = 'face-scene tensors.nii';
spm_write_vol(tensor_volume_info,tensors_to_write)

save('all_interpolated_MNI_locations','all_interpolated_MNI_locations')

%% Calculate tSNR maps
nrun = size(subjects,2); % enter the number of runs here
inputs = cell(2, nrun);

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    filestosmooth = cell(1,length(theseepis));
    filestosmooth_list = [];
    for i = 1:length(theseepis)
        filestosmooth{i} = spm_select('ExtFPList',outpath,['^rtopup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
        filestosmooth_list = [filestosmooth_list; filestosmooth{i}];
    end
    inputs{1, crun} = cellstr(filestosmooth_list); 
end

parfor crun = 1:nrun
    calc_tsnr(inputs{1, crun})
end

nrun = size(subjects,2); % enter the number of runs here
%jobfile = {'/group/language/data/thomascope/vespa/SPM12version/Standalone preprocessing pipeline/tc_source/batch_forwardmodel_job_noheadpoints.m'};
jobfile = {[scriptdir 'module_normalise_job.m']};
inputs = cell(2, nrun);

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    
    inputs{1, crun} = cellstr([outpath 'mri/y_p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii']);
    inputs{2, crun} = cellstr([outpath 'tsnr.nii']);
    
end

normalisetsnrcorrectly = zeros(1,nrun);
jobs = repmat(jobfile, 1, 1);

parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs, inputs{:,crun});
        normalisetsnrcorrectly(crun) = 1;
    catch
        normalisetsnrcorrectly(crun) = 0;
    end
end

normalised_tsnr_maps = {};
control_normalised_tsnr_maps = {};
patient_normalised_tsnr_maps = {};

for crun = 1:nrun
    outpath = [preprocessedpathstem subjects{crun} '/'];
    normalised_tsnr_maps{crun} = [outpath 'wtsnr.nii'];
    if group(crun)==1
        control_normalised_tsnr_maps{end+1} = [outpath 'wtsnr.nii'];
    elseif group(crun)==2
        patient_normalised_tsnr_maps{end+1} = [outpath 'wtsnr.nii'];
    end
end

these_maps = spm_vol(char(normalised_tsnr_maps));
spm_imcalc(these_maps,'mean_tSNR_map.nii','mean(X)',{1 0 0})
spm_imcalc(char([cellstr('mean_tSNR_map.nii'); scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']),'masked_mean_tSNR_map.nii','i1.*(i2>0.05)')

these_maps = spm_vol(char(control_normalised_tsnr_maps));
spm_imcalc(these_maps,'mean_control_tSNR_map.nii','mean(X)',{1 0 0})
spm_imcalc(char([cellstr('mean_control_tSNR_map.nii'); scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']),'masked_mean_control_tSNR_map.nii','i1.*(i2>0.05)')

these_maps = spm_vol(char(patient_normalised_tsnr_maps));
spm_imcalc(these_maps,'mean_patient_tSNR_map.nii','mean(X)',{1 0 0})
spm_imcalc(char([cellstr('mean_patient_tSNR_map.nii'); scriptdir 'control_majority_unsmoothed_mask_p1_thr0.05_cons0.8.img']),'masked_mean_patient_tSNR_map.nii','i1.*(i2>0.05)')

%% Assess behavioural performance
for i = 1:length(subjects)
    this_dir = pwd;
    cd([scriptdir 'behavioural_data'])
    [ all_response_averages(i), all_rt_averages(i), all_reversed(i)] = SD_7T_behaviour_withnull( subjects{i}, dates{i} );
    cd(this_dir)
end