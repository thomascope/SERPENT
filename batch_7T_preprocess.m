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

% NB: Note S7P14 frontal atrophy - examine whether outlier

%% Now create a vector along the ventral stream, using Engell's Face-Scene
% % contrast: Engell A.D. and McCarthy G. (2013). fMRI activation by face and biological motion perception: Comparison of response maps and creation of probabilistic atlases. NeuroImage, 74, 140-151.
% face_map_info = spm_vol('./Regions_of_Interest/ASAP_maps/facescene_pmap_N124_stat3.nii');
% face_map = spm_read_vols(face_map_info); % This is the Face-Scene contrast for 124 young healthy people, expressed as percent significant in each voxel
% 
% %Find peak location on each side (Right and left FFA)
% left_half = face_map;
% left_half(1:floor(size(face_map,1)/2),:,:) = 0; %NB: x-direction negative indexed here
% right_half = face_map;
% right_half(ceil((size(face_map,1))/2):end,:,:) = 0;
% [~,idx_r] = max(right_half(:));
% [~,idx_l] = max(left_half(:));
% all_interpolated_MNI_locations = {};
% for start_idx = [idx_r, idx_l]
%     %Work forwards and backwards from those points to make a tensor;
%     [r,c,p] = ind2sub(size(face_map),start_idx);
%     MNI_x = [face_map_info.mat(1,4)+(r*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(c*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(p*face_map_info.mat(3,3))];
%     
%     %Work forwards and backwards from that point to make a tensor;
%     y_start = MNI_x(2);
%     %First go backwards
%     last_location = [r,c,p];
%     these_negative_locations = [];
%     these_negative_MNI_locations = [];
%     for this_y = (c-1):-1:(c-50)
%         this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
%         [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
%         if mxv>0.1 % More than 10% of subjects have face preference here
%             [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
%             last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
%             these_negative_locations = [these_negative_locations; last_location];
%             last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
%             these_negative_MNI_locations = [these_negative_MNI_locations; last_MNI_location];
%         else % Less than 10% of subjects have face preference - end of tensor
%             break
%         end
%     end
%     
%     %Then go forwards
%     last_location = [r,c,p];
%     these_positive_locations = [];
%     these_positive_MNI_locations = [];
%     for this_y = (c+1):1:(c+50)
%         this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
%         [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
%         if mxv>0.1 % More than 10% of subjects have face preference here
%             [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
%             last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
%             these_positive_locations = [these_positive_locations; last_location];
%             last_MNI_location = (face_map_info.mat*[last_location 1]')';
%             last_MNI_location = last_MNI_location(1:3);
%             %last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
%             these_positive_MNI_locations = [these_positive_MNI_locations; last_MNI_location];
%         else % Less than 10% of subjects have face preference - end of tensor
%             break
%         end
%     end
%     
%     %Then create tensor
%     these_locations = [flipud(these_negative_locations); [r,c,p]; these_positive_locations];
%     these_MNI_locations = [flipud(these_negative_MNI_locations); MNI_x; these_positive_MNI_locations];
%     % Interpolate from 2mm to 1mm resolution
%     these_interpolated_MNI_locations = [];
%     for this_y_loc = 1:size(these_MNI_locations,1)-1
%         these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(this_y_loc,:)];
%         these_interpolated_MNI_locations = [these_interpolated_MNI_locations; mean(these_MNI_locations(this_y_loc:this_y_loc+1,:),1)];
%     end
%     these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(end,:)];
%     all_interpolated_MNI_locations{end+1} = these_interpolated_MNI_locations;
% end
% 
% % Write these tensors for visualisation
% example_volume_info = spm_vol('photo_line_template_noself.nii'); %An example multivariate contrast 
% example_volume = spm_read_vols(example_volume_info); %An example multivariate contrast 
% tensors_to_write = zeros(size(example_volume));
% for this_tensor = 1:length(all_interpolated_MNI_locations)
%     for this_location = 1:length(all_interpolated_MNI_locations{this_tensor})
%         these_voxel_coordinates = [all_interpolated_MNI_locations{this_tensor}(this_location,:),1]*(inv(example_volume_info.mat))';
%         try
%             tensors_to_write(these_voxel_coordinates(1),these_voxel_coordinates(2),these_voxel_coordinates(3)) = 1;
%         end
%     end
% end
% tensor_volume_info = example_volume_info;
% tensor_volume_info.descrip = 'Tensors for multivariate analysis';
% tensor_volume_info.fname = 'face-scene tensors.nii';
% spm_write_vol(tensor_volume_info,tensors_to_write)

save('all_interpolated_facescene_MNI_locations','all_interpolated_MNI_locations')

% Now try defining tensors based on our own Pictures - Null contrast
%seeds = [32.0 -44.0 -20.0; -35.0 -44.0 -23.0]; %Most anterior voxels of the ventral stream, manually located.
seeds = [43 -52.0 -13.0; 50 -68 -1]; %Most significant FFA voxels in the ventral stream, manually located.

picture_map_info = spm_vol('./Regions_of_Interest/Pictures-null-cluster.nii');
picture_map = spm_read_vols(picture_map_info); % This is the Face-Scene contrast for 124 young healthy people, expressed as percent significant in each voxel

all_interpolated_MNI_locations = {};
for this_seed = 1:size(seeds,1)
    %Work forwards and backwards from those points to make a tensor;
    seeds_voxelspace = round([seeds(this_seed,:),1]*(inv(picture_map_info.mat))');
    r = seeds_voxelspace(1,1);
    c = seeds_voxelspace(1,2);
    p = seeds_voxelspace(1,3);
    MNI_x = [picture_map_info.mat(1,4)+(r*picture_map_info.mat(1,1)), picture_map_info.mat(2,4)+(c*picture_map_info.mat(2,2)), picture_map_info.mat(3,4)+(p*picture_map_info.mat(3,3))];
    
    %Work forwards and backwards from that point to make a tensor;
    y_start = MNI_x(2);
    %First go backwards
    last_location = [r,c,p];
    these_negative_locations = [];
    these_negative_MNI_locations = [];
    for this_y = (c-1):-1:(c-50)
        this_plane = picture_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
            these_negative_locations = [these_negative_locations; last_location];
            last_MNI_location = [picture_map_info.mat(1,4)+(last_location(1)*picture_map_info.mat(1,1)), picture_map_info.mat(2,4)+(last_location(2)*picture_map_info.mat(2,2)), picture_map_info.mat(3,4)+(last_location(3)*picture_map_info.mat(3,3))];
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
        this_plane = picture_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)+r_temp-6,this_y,last_location(3)+p_temp-6];
            these_positive_locations = [these_positive_locations; last_location];
            last_MNI_location = (picture_map_info.mat*[last_location 1]')';
            last_MNI_location = last_MNI_location(1:3);
            %last_MNI_location = [picture_map_info.mat(1,4)+(last_location(1)*picture_map_info.mat(1,1)), picture_map_info.mat(2,4)+(last_location(2)*picture_map_info.mat(2,2)), picture_map_info.mat(3,4)+(last_location(3)*picture_map_info.mat(3,3))];
            these_positive_MNI_locations = [these_positive_MNI_locations; last_MNI_location];
        else % Less than 10% of subjects have face preference - end of tensor
            break
        end
    end
    
    %Then create tensor
    these_locations = [flipud(these_negative_locations); [r,c,p]; these_positive_locations];
    these_MNI_locations = [flipud(these_negative_MNI_locations); MNI_x; these_positive_MNI_locations];
    % Interpolate from 1.5mm to 0.5mm resolution
    these_interpolated_MNI_locations = [];
    for this_y_loc = 1:size(these_MNI_locations,1)-1
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(this_y_loc,:)];
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; mean([these_MNI_locations(this_y_loc,:);these_MNI_locations(this_y_loc:this_y_loc+1,:)],1)];
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; mean([these_MNI_locations(this_y_loc+1,:);these_MNI_locations(this_y_loc:this_y_loc+1,:)],1)];
    end
    these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(end,:)];
    % Now downsample to 1mm resolution
    these_interpolated_MNI_locations = these_interpolated_MNI_locations(1:2:end,:);
    all_interpolated_MNI_locations{end+1} = these_interpolated_MNI_locations;
end

% Write these tensors for visualisation
example_volume_info = spm_vol('photo_line_template_noself.nii'); %An example multivariate contrast 
example_volume = spm_read_vols(example_volume_info); %An example multivariate contrast 
tensors_to_write = zeros(size(example_volume));
for this_tensor = 1:length(all_interpolated_MNI_locations)
    for this_location = 1:length(all_interpolated_MNI_locations{this_tensor})
        these_voxel_coordinates = round([all_interpolated_MNI_locations{this_tensor}(this_location,:),1]*(inv(example_volume_info.mat))');
        try
            tensors_to_write(these_voxel_coordinates(1),these_voxel_coordinates(2),these_voxel_coordinates(3)) = 1;
        end
    end
end
tensor_volume_info = example_volume_info;
tensor_volume_info.descrip = 'Tensors for multivariate analysis';
tensor_volume_info.fname = 'Picture-null tensors.nii';
spm_write_vol(tensor_volume_info,tensors_to_write)

save('all_interpolated_picturenull_MNI_locations','all_interpolated_MNI_locations')

%% Now do ROI analysis - First create ROIS
make_atlas_rois = 0; %Already done
if make_atlas_rois
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
    for this_roi = 1:9
        spm_imcalc('./Regions_of_Interest/maxprob_vol_lh.nii',['./Regions_of_Interest/lh_roi_' num2str(this_roi) '.nii'],['i1==' num2str(this_roi)])
        spm_imcalc('./Regions_of_Interest/maxprob_vol_rh.nii',['./Regions_of_Interest/rh_roi_' num2str(this_roi) '.nii'],['i1==' num2str(this_roi)])
    end
    
    % Now better, more recent map: Rosenke, Mona, et al. "A probabilistic functional atlas of human occipito-temporal visual cortex." Cerebral Cortex 31.1 (2021): 603-619.
    region_key= {
        'lh_mFus_faces'
        'lh_pFus_faces'
        'lh_IOG_faces'
        'lh_OTS_bodies'
        'lh_ITG_bodies'
        'lh_MTG_bodies'
        'lh_LOS_bodies'
        'lh_pOTS_characters'
        'lh_IOS_haracters'
        'lh_CoS_places'
        'lh_hMT_motion'
        'lh_v1d_retinotopic'
        'lh_v2d_retinotopic'
        'lh_v3d_retinotopic'
        'lh_v1v_retinotopic'
        'lh_v2v_retinotopic'
        'lh_v3v_retinotopic'
        'rh_mFus_faces'
        'rh_pFus_faces'
        'rh_IOG_faces'
        'rh_OTS_bodies'
        'rh_ITG_bodies'
        'rh_MTG_bodies'
        'rh_LOS_bodies'
        'rh_CoS_places'
        'rh_TOS_places'
        'rh_hMT_motion'
        'rh_v1d_retinotopic'
        'rh_v2d_retinotopic'
        'rh_v3d_retinotopic'
        'rh_v1v_retinotopic'
        'rh_v2v_retinotopic'
        'rh_v3v_retinotopic'
        }
    for this_roi = 1:length(region_key)
        spm_imcalc('./Regions_of_Interest/visfAtlas_MNI152_volume.nii',['./Regions_of_Interest/Rosenke_' region_key{this_roi} '.nii'],['i1==' num2str(this_roi)]) %NB: Not zero based indexing in the atlas, despite what it implies in the XML
    end
     
    %Now parcellate Glasser (2016). A multi-modal parcellation of human cerebral cortex. Nature, 1-11.
    Glasser_regions = readtable('./Regions_of_Interest/HCP-MMP1_UniqueRegionList.csv');
    for this_roi = 1:height(Glasser_regions)
        spm_imcalc('./Regions_of_Interest/HCP-MMP_1mm.nii',['./Regions_of_Interest/Glasser_ ' num2str(Glasser_regions.regionID(this_roi)) '_' Glasser_regions.x_regionName{this_roi} '.nii'],['i1==' num2str(Glasser_regions.regionID(this_roi))])
    end
    
end

%% Now normalise the template space masks into native space

images2normalise = {};

for this_roi = 1:9
    images2normalise{end+1} = ['./Regions_of_Interest/lh_roi_' num2str(this_roi) '.nii'];
    images2normalise{end+1} = ['./Regions_of_Interest/rh_roi_' num2str(this_roi) '.nii'];
end

images2normalise{end+1} = ['./Regions_of_Interest/lh_template_noself_crossmod.nii'];
images2normalise{end+1} = ['./Regions_of_Interest/rh_template_noself_crossmod.nii'];

region_key= {
        'lh_mFus_faces'
        'lh_pFus_faces'
        'lh_IOG_faces'
        'lh_OTS_bodies'
        'lh_ITG_bodies'
        'lh_MTG_bodies'
        'lh_LOS_bodies'
        'lh_pOTS_characters'
        'lh_IOS_haracters'
        'lh_CoS_places'
        'lh_hMT_motion'
        'lh_v1d_retinotopic'
        'lh_v2d_retinotopic'
        'lh_v3d_retinotopic'
        'lh_v1v_retinotopic'
        'lh_v2v_retinotopic'
        'lh_v3v_retinotopic'
        'rh_mFus_faces'
        'rh_pFus_faces'
        'rh_IOG_faces'
        'rh_OTS_bodies'
        'rh_ITG_bodies'
        'rh_MTG_bodies'
        'rh_LOS_bodies'
        'rh_CoS_places'
        'rh_TOS_places'
        'rh_hMT_motion'
        'rh_v1d_retinotopic'
        'rh_v2d_retinotopic'
        'rh_v3d_retinotopic'
        'rh_v1v_retinotopic'
        'rh_v2v_retinotopic'
        'rh_v3v_retinotopic'
        };
    
    for this_roi = 1:length(region_key)
        images2normalise{end+1} = ['./Regions_of_Interest/Rosenke_' region_key{this_roi} '.nii'];
    end

% search_labels = {
%     'Left STG'
%     'Left PT'
%     'Left PrG'
%     'Left FO'
%     'Left TrIFG'
%     };

% xA=spm_atlas('load','Neuromorphometrics');

% search_labels = {
%     %     'Left Superior Temporal Gyrus'
%     %     'Left Angular Gyrus'
%     %     'Left Precentral Gyrus'
%     %     'Left Frontal Operculum'
%     %     'Left Inferior Frontal Angular Gyrus'
%     %     'Right Superior Temporal Gyrus'
%     %     'Right Angular Gyrus'
%     %     'Right Precentral Gyrus'
%     %     'Right Frontal Operculum'
%     %     'Right Inferior Frontal Angular Gyrus'
%     %     'Left Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
%     %     'Right Cerebellar Lobule Cerebellar Vermal Lobules VI-VII'
%     };

% cat_install_atlases
% xA=spm_atlas('load','dartel_neuromorphometrics');
% for i = 1:size(xA.labels,2)
%     all_labels{i} = xA.labels(i).name;
% end

% S = cell(1,length(search_labels));
% for i = 1:length(search_labels)
%     S{i} = find(strncmp(all_labels,search_labels{i},size(search_labels{i},2)));
% end
% if ~exist('./atlas_Neuromorphometrics/','dir')
%     mkdir('./atlas_Neuromorphometrics/');
% end
% for i = 1:size(S,2)
%     fname=strcat(strrep(search_labels{i}, ' ', '_'),'.nii');
%     VM=spm_atlas('mask',xA,xA.labels(S{i}).name);
%     VM.fname=['./atlas_Neuromorphometrics/' fname];
%     spm_write_vol(VM,spm_read_vols(VM));
%     images2normalise{end+1} = [pwd '/atlas_Neuromorphometrics/' fname];
% end

nrun = size(subjects,2); % enter the number of runs here
template2nativeworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    outpath = [preprocessedpathstem subjects{crun} '/'];
    reslice_template = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/mask.nii']; %Template for reslicing
    inverse_deformation_path = ['mri/iy_p' blocksin{crun}{find(strcmp(blocksout{crun},'structural'))}(1:end-4) '_denoised.nii'];
    try
        module_template_2_nativemap(images2normalise,outpath,1,reslice_template,inverse_deformation_path);
        template2nativeworkedcorrectly(crun) = 1;
    catch
        template2nativeworkedcorrectly(crun) = 0;
    end
end

%% Analyse by condition and brain region
addpath(genpath('/imaging/mlr/users/tc02/toolboxes')); %Where is the RSA toolbox?

masks = {};

for this_roi = 1:9
    masks{end+1} = ['rwlh_roi_' num2str(this_roi)];
    masks{end+1} = ['rwrh_roi_' num2str(this_roi)];
end

masks{end+1} = ['rwlh_template_noself_crossmod'];
masks{end+1} = ['rwrh_template_noself_crossmod'];

region_key= {
        'lh_mFus_faces'
        'lh_pFus_faces'
        'lh_IOG_faces'
        'lh_OTS_bodies'
        'lh_ITG_bodies'
        'lh_MTG_bodies'
        'lh_LOS_bodies'
        'lh_pOTS_characters'
        'lh_IOS_haracters'
        'lh_CoS_places'
        'lh_hMT_motion'
        'lh_v1d_retinotopic'
        'lh_v2d_retinotopic'
        'lh_v3d_retinotopic'
        'lh_v1v_retinotopic'
        'lh_v2v_retinotopic'
        'lh_v3v_retinotopic'
        'rh_mFus_faces'
        'rh_pFus_faces'
        'rh_IOG_faces'
        'rh_OTS_bodies'
        'rh_ITG_bodies'
        'rh_MTG_bodies'
        'rh_LOS_bodies'
        'rh_CoS_places'
        'rh_TOS_places'
        'rh_hMT_motion'
        'rh_v1d_retinotopic'
        'rh_v2d_retinotopic'
        'rh_v3d_retinotopic'
        'rh_v1v_retinotopic'
        'rh_v2v_retinotopic'
        'rh_v3v_retinotopic'
        };
    
    for this_roi = 1:length(region_key)
        masks{end+1} = ['rwRosenke_' region_key{this_roi}];
    end

GLMDir = [preprocessedpathstem subjects{1} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
% temp = load([GLMDir filesep 'SPM.mat']);
% labelnames = {};
% for i = 1:length(temp.SPM.Sess(1).U)
%     if ~strncmp(temp.SPM.Sess(1).U(i).name,{'photo','line'},4)
%         continue
%     else
%         labelnames(end+1) = temp.SPM.Sess(1).U(i).name;
%     end
% end
% labels = 1:length(labelnames);
% labelnames_denumbered = {};
% for i = 1:length(labelnames)
%     labelnames_denumbered{i} = labelnames{i}(isletter(labelnames{i})|isspace(labelnames{i}));
% end
% conditionnames = unique(labelnames_denumbered,'stable');
% clear temp labelnames_denumbered labelnames

nrun = size(subjects,2); % enter the number of runs here
mahalanobisroiworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Where is the SPM model?
    mask_dir = [preprocessedpathstem subjects{crun}]; %Where are the native space ROI masks?
    try
        TDTCrossnobisAnalysis_roi(GLMDir,mask_dir,masks);
        mahalanobisroiworkedcorrectly(crun) = 1;
    catch
        mahalanobisroiworkedcorrectly(crun) = 0;
    end
end


%% Now do RSA on ROI data
nrun = size(subjects,2); % enter the number of runs here
RSAroiworkedcorrectly = zeros(1,nrun);
partialRSAroiworkedcorrectly = zeros(1,nrun);
masks = {};

for this_roi = 1:9
    masks{end+1} = ['rwlh_roi_' num2str(this_roi)];
    masks{end+1} = ['rwrh_roi_' num2str(this_roi)];
end

masks{end+1} = ['rwlh_template_noself_crossmod'];
masks{end+1} = ['rwrh_template_noself_crossmod'];

region_key= {
    'lh_mFus_faces'
    'lh_pFus_faces'
    'lh_IOG_faces'
    'lh_OTS_bodies'
    'lh_ITG_bodies'
    'lh_MTG_bodies'
    'lh_LOS_bodies'
    'lh_pOTS_characters'
    'lh_IOS_haracters'
    'lh_CoS_places'
    'lh_hMT_motion'
    'lh_v1d_retinotopic'
    'lh_v2d_retinotopic'
    'lh_v3d_retinotopic'
    'lh_v1v_retinotopic'
    'lh_v2v_retinotopic'
    'lh_v3v_retinotopic'
    'rh_mFus_faces'
    'rh_pFus_faces'
    'rh_IOG_faces'
    'rh_OTS_bodies'
    'rh_ITG_bodies'
    'rh_MTG_bodies'
    'rh_LOS_bodies'
    'rh_CoS_places'
    'rh_TOS_places'
    'rh_hMT_motion'
    'rh_v1d_retinotopic'
    'rh_v2d_retinotopic'
    'rh_v3d_retinotopic'
    'rh_v1v_retinotopic'
    'rh_v2v_retinotopic'
    'rh_v3v_retinotopic'
    };

for this_roi = 1:length(region_key)
    masks{end+1} = ['rwRosenke_' region_key{this_roi}];
end


parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Where is the SPM model?
    try
        module_roi_RSA(GLMDir,masks,subjects{crun})
        RSAroiworkedcorrectly(crun) = 1;
    catch
        RSAroiworkedcorrectly(crun) = 0;
    end
end
matrices_to_partial = {'Global V1_ds','Global GIST correlation'};
parfor crun = 1:nrun
    addpath(genpath('./RSA_scripts'))
    GLMDir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Where is the SPM model?
    try
        module_partial_roi_RSA(GLMDir,masks,subjects{crun},matrices_to_partial)
        partialRSAroiworkedcorrectly(crun) = 1;
    catch
        partialRSAroiworkedcorrectly(crun) = 0;
    end
end

%% Now visualise ROI results and do basic stats
GLMDir = [preprocessedpathstem subjects{1} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
outdir = ['./ROI_figures/stats_native_mask0.3_3_coreg_reversedbuttons'];
mkdir(outdir)
temp = load([GLMDir filesep 'SPM.mat']);

labelnames = {};
for i = 1:length(temp.SPM.Sess(1).U)
    if ~strncmp(temp.SPM.Sess(1).U(i).name,{'photo','line'},4)
        continue
    else
        labelnames(end+1) = temp.SPM.Sess(1).U(i).name;
    end
end
labels = 1:length(labelnames);

% Add covariates of interest XXX - Add in anterior temporal thickness
age_lookup = readtable('SERPENT_Only_Included.csv');
for crun = 1:length(subjects)
this_age(crun) = age_lookup.Age(strcmp(age_lookup.x_SubjectID,subjects{crun}));
end
covariates = [this_age'];
%covariates = [this_age',nanmean(all_sigma_pred)'];
%covariate_names = horzcat('Age','Prior_Precision',all_roi_thicknesses.Properties.VariableNames);
covariate_names = horzcat({'Age'});

%Now build model space for testing

clear this_model_name mask_names

this_model_name{1} = {
    'Photo to Line V1_ds'
    'Photo to Line GIST correlation'
    'Photo to Line templates_noself'
    'Photo to Line visible_dissimilarity_noself'
    'Photo to Line knowledge_dissimilarity_noself'
    'Photo to Line judgment_noself'
    'Photo to Line l_sa_noself'
    'Photo to Line l_s_a_noself'
    'Photo to Line lsm_ll_sa_noself'
    'Photo to Line decoding'
    };

this_model_name{2} = {
    'Global V1_ds'
    'Global GIST correlation'
    'Global templates_noself'
    'Global visible_dissimilarity_noself'
    'Global knowledge_dissimilarity_noself'
    'Global judgment_noself'
    'Global l_sa_noself'
    'Global l_s_a_noself'
    'Global lsm_ll_sa_noself'
    'Global decoding'
    };

this_model_name{3} = {
    'All V1_ds'
    'All GIST correlation'
    'All templates_noself'
    'All visible_dissimilarity_noself'
    'All knowledge_dissimilarity_noself'
    'All judgment_noself'
    'All l_sa_noself'
    'All l_s_a_noself'
    'All lsm_ll_sa_noself'
    'All decoding'
    };


mask_names = {};

mask_names{1} = {};
for this_roi = 1:9
    mask_names{1}{end+1} = ['rwlh_roi_' num2str(this_roi)];
    mask_names{1}{end+1} = ['rwrh_roi_' num2str(this_roi)];
end

mask_names{2} = {};
mask_names{2}{end+1} = ['rwlh_template_noself_crossmod'];
mask_names{2}{end+1} = ['rwrh_template_noself_crossmod'];

nrun = size(subjects,2); % enter the number of runs here
% First load in the similarities
RSA_ROI_data_exist = zeros(1,nrun);
all_data = [];

all_rho = [];
all_corr_ps = [];
all_corrected_rho = [];
all_corrected_corr_ps = [];

% First plot model sets by brain region (i.e. one model set per brain region)

for j = 1:length(this_model_name)
    for k = 1:length(mask_names)
        for i = 1:length(mask_names{k})
            all_data = [];
            all_corrected_data = [];
            for crun = 1:nrun
                %ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/RSA/spearman']; %Where are the results>
                ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/' mask_names{k}{i} '/RSA/spearman'];
                if ~exist(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j}{1} '.mat']),'file')
                    ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI' mask_names{k}{i} '/RSA/spearman']; % Stupid coding error earlier in analysis led to misnamed directories
                end
                for m = 1:length(this_model_name{j})
                    try
                        temp_data = load(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j}{m} '.mat']));
                        all_data(m,:,crun) = temp_data.roi_effect; %Create a matrix of condition by ROI by subject
                        RSA_ROI_data_exist(crun) = 1;
                    catch
                        warning(['No data for ' subjects{crun} ' probably because of SPM dropout, ignoring them'])
                        %error
                        RSA_ROI_data_exist(crun) = 0;
                        continue
                    end
                end
            end
            roi_names = temp_data.roi_names;
            clear temp_data
            disp(['Excluding subjects ' num2str(find(RSA_ROI_data_exist==0)) ' belonging to groups ' num2str(group(RSA_ROI_data_exist==0)) ' maybe check them'])
            all_data(:,:,RSA_ROI_data_exist==0) = NaN;
            all_corrected_data(:,:,group==1) = es_removeBetween_rotated(all_data(:,:,group==1),[3,1,2]); %Subjects, conditions, measures columns = 3,1,2 here
            all_corrected_data(:,:,group==2) = es_removeBetween_rotated(all_data(:,:,group==2),[3,1,2]); %Subjects, conditions, measures columns = 3,1,2 here
            
            
            this_ROI = find(strcmp(mask_names{k}{i},roi_names));
            %Test covariates
            for m = 1:length(this_model_name{j})
                [all_rho(j,k,i,m,:),all_corr_ps(j,k,i,m,:)] = corr(covariates,squeeze(all_data(m,this_ROI,:)),'rows','pairwise');
                for this_corr = 1:size(all_corr_ps,5);
                    if all_corr_ps(j,k,i,m,this_corr) < 0.05
                        disp(['Exploratory correlation in ' mask_names{k}{i}(3:end) ' ' this_model_name{j}{m} ' for ' covariate_names{this_corr}])
                    end
                end
            end
            
            
            figure
            set(gcf,'Position',[100 100 1600 800]);
            set(gcf, 'PaperPositionMode', 'auto');
            hold on
            errorbar([1:length(this_model_name{j})]-0.1,nanmean(squeeze(all_data(:,this_ROI,group==1&RSA_ROI_data_exist)),2),nanstd(squeeze(all_data(:,this_ROI,group==1&RSA_ROI_data_exist))')/sqrt(sum(group==1&RSA_ROI_data_exist)),'kx')
            errorbar([1:length(this_model_name{j})]+0.1,nanmean(squeeze(all_data(:,this_ROI,group==2&RSA_ROI_data_exist)),2),nanstd(squeeze(all_data(:,this_ROI,group==2&RSA_ROI_data_exist))')/sqrt(sum(group==2&RSA_ROI_data_exist)),'rx')
%                         for m = 1:length(this_model_name{j})
%                             scatter(repmat(m-0.1,1,size(squeeze(all_data(:,this_ROI,group==1&RSA_ROI_data_exist)),2)),squeeze(all_data(m,this_ROI,group==1&RSA_ROI_data_exist))','k')
%                             scatter(repmat(m+0.1,1,size(squeeze(all_data(:,this_ROI,group==2&RSA_ROI_data_exist)),2)),squeeze(all_data(m,this_ROI,group==2&RSA_ROI_data_exist))','r')
%                         end
            xlim([0 length(this_model_name{j})+1])
            set(gca,'xtick',[1:length(this_model_name{j})],'xticklabels',this_model_name{j},'XTickLabelRotation',45,'TickLabelInterpreter','none')
            plot([0 length(this_model_name{j})+1],[0,0],'k--')
            title([mask_names{k}{i}(3:end) ' RSA'],'Interpreter','none')
            if verLessThan('matlab', '9.2')
                legend('Controls','Patients','location','southeast')
            else
                legend('Controls','Patients','location','southeast','AutoUpdate','off')
            end
            [h,p] = ttest(squeeze(all_data(:,this_ROI,logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
            end
            [h,p] = ttest(squeeze(all_data(:,this_ROI,group==1&logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
            end
            [h,p] = ttest(squeeze(all_data(:,this_ROI,group==2&logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
            end
            
            [h,p] = ttest2(squeeze(all_data(:,this_ROI,group==1&logical(RSA_ROI_data_exist)))',squeeze(all_data(:,this_ROI,group==2&logical(RSA_ROI_data_exist)))');
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
            end
            for m = 1:length(this_model_name{j})
                for this_corr = 1:size(all_corr_ps,5);
                    if all_corr_ps(j,k,i,m,this_corr) < 0.05
                        text(m, these_y_lims(2)-(this_corr*diff(these_y_lims/100)),covariate_names{this_corr},'Interpreter','None')
                    end
                end
            end
            drawnow
            saveas(gcf,[outdir filesep mask_names{k}{i}(3:end) '_Model_set_' num2str(j) '.png'])
            saveas(gcf,[outdir filesep mask_names{k}{i}(3:end) '_Model_set_' num2str(j) '.pdf'])
            
            for m = 1:length(this_model_name{j})
                [all_corrected_rho(j,k,i,m,:),all_corrected_corr_ps(j,k,i,m,:)] = corr(covariates,squeeze(all_data(m,this_ROI,:)),'rows','pairwise');
                for this_corr = 1:size(all_corr_ps,5);
                    if all_corr_ps(j,k,i,m,this_corr) < 0.05
                        disp(['Exploratory corrected correlation in ' mask_names{k}{i}(3:end) ' ' this_model_name{j}{m} ' for ' covariate_names{this_corr}])
                    end
                end
            end
            
            figure
            set(gcf,'Position',[100 100 1600 800]);
            set(gcf, 'PaperPositionMode', 'auto');
            hold on
            errorbar([1:length(this_model_name{j})]-0.1,nanmean(squeeze(all_corrected_data(:,this_ROI,group==1&RSA_ROI_data_exist)),2),nanstd(squeeze(all_corrected_data(:,this_ROI,group==1&RSA_ROI_data_exist))')/sqrt(sum(group==1&RSA_ROI_data_exist)),'kx')
            errorbar([1:length(this_model_name{j})]+0.1,nanmean(squeeze(all_corrected_data(:,this_ROI,group==2&RSA_ROI_data_exist)),2),nanstd(squeeze(all_corrected_data(:,this_ROI,group==2&RSA_ROI_data_exist))')/sqrt(sum(group==2&RSA_ROI_data_exist)),'rx')
%                                     for m = 1:length(this_model_name{j})
%                             scatter(repmat(m-0.1,1,size(squeeze(all_corrected_data(:,this_ROI,group==1&RSA_ROI_data_exist)),2)),squeeze(all_corrected_data(m,this_ROI,group==1&RSA_ROI_data_exist))','k')
%                             scatter(repmat(m+0.1,1,size(squeeze(all_corrected_data(:,this_ROI,group==2&RSA_ROI_data_exist)),2)),squeeze(all_corrected_data(m,this_ROI,group==2&RSA_ROI_data_exist))','r')
%                         end
            xlim([0 length(this_model_name{j})+1])
            set(gca,'xtick',[1:length(this_model_name{j})],'xticklabels',this_model_name{j},'XTickLabelRotation',45,'TickLabelInterpreter','none')
            plot([0 length(this_model_name{j})+1],[0,0],'k--')
            title(['Corrected ' mask_names{k}{i}(3:end) ' RSA'],'Interpreter','none')
            if verLessThan('matlab', '9.2')
                legend('Controls','Patients','location','southeast')
            else
                legend('Controls','Patients','location','southeast','AutoUpdate','off')
            end
            [h,p] = ttest(squeeze(all_corrected_data(:,this_ROI,logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
            end
            [h,p] = ttest(squeeze(all_corrected_data(:,this_ROI,group==1&logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
            end
            [h,p] = ttest(squeeze(all_corrected_data(:,this_ROI,group==2&logical(RSA_ROI_data_exist)))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
            end
            
            [h,p] = ttest2(squeeze(all_corrected_data(:,this_ROI,group==1&logical(RSA_ROI_data_exist)))',squeeze(all_corrected_data(:,this_ROI,group==2&logical(RSA_ROI_data_exist)))');
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
            end
            for m = 1:length(this_model_name{j})
                for this_corr = 1:size(all_corrected_corr_ps,5);
                    if all_corrected_corr_ps(j,k,i,m,this_corr) < 0.05
                        text(m, these_y_lims(2)-(this_corr*diff(these_y_lims/100)),covariate_names{this_corr},'Interpreter','None')
                    end
                end
            end
            drawnow
            saveas(gcf,[outdir filesep 'Corrected_' mask_names{k}{i}(3:end) '_Model_set_' num2str(j) '.png'])
            saveas(gcf,[outdir filesep 'Corrected_' mask_names{k}{i}(3:end) '_Model_set_' num2str(j) '.pdf'])
            
        end
        close all
    end
end

%% Now reverse, and plot a model over many brain regions of interest
GLMDir = [preprocessedpathstem subjects{1} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
outdir = ['./ROI_figures/stats_native_mask0.3_3_coreg_reversedbuttons'];
mkdir(outdir)
temp = load([GLMDir filesep 'SPM.mat']);

labelnames = {};
for i = 1:length(temp.SPM.Sess(1).U)
    if ~strncmp(temp.SPM.Sess(1).U(i).name,{'photo','line'},4)
        continue
    else
        labelnames(end+1) = temp.SPM.Sess(1).U(i).name;
    end
end
labels = 1:length(labelnames);

% % Add covariates of interest XXX - Add in anterior temporal thickness
% age_lookup = readtable('SERPENT_Only_Included.csv');
% for crun = 1:length(subjects)
% this_age(crun) = age_lookup.Age(strcmp(age_lookup.x_SubjectID,subjects{crun}));
% end
% covariates = [this_age'];
% %covariates = [this_age',nanmean(all_sigma_pred)'];
% %covariate_names = horzcat('Age','Prior_Precision',all_roi_thicknesses.Properties.VariableNames);
% covariate_names = horzcat({'Age'});

%Now build model space for testing

clear this_model_name mask_names

this_model_name = {
    'Photo to Line V1_ds'
    'Photo to Line GIST correlation'
    'Photo to Line templates_noself'
    'Photo to Line visible_dissimilarity_noself'
    'Photo to Line knowledge_dissimilarity_noself'
    'Photo to Line judgment_noself'
    'Photo to Line l_sa_noself'
    'Photo to Line l_s_a_noself'
    'Photo to Line lsm_ll_sa_noself'
    'Photo to Line decoding'
    'Global V1_ds'
    'Global GIST correlation'
    'Global templates_noself'
    'Global visible_dissimilarity_noself'
    'Global knowledge_dissimilarity_noself'
    'Global judgment_noself'
    'Global l_sa_noself'
    'Global l_s_a_noself'
    'Global lsm_ll_sa_noself'
    'Global decoding'
    'All V1_ds'
    'All GIST correlation'
    'All templates_noself'
    'All visible_dissimilarity_noself'
    'All knowledge_dissimilarity_noself'
    'All judgment_noself'
    'All l_sa_noself'
    'All l_s_a_noself'
    'All lsm_ll_sa_noself'
    'All decoding'
    'Photo to Line CNN_1_pp_corr_noself'
    'Photo to Line CNN_2_pp_corr_noself'
    'Photo to Line CNN_3_pp_corr_noself'
    'Photo to Line CNN_4_pp_corr_noself'
    'Photo to Line CNN_5_pp_corr_noself'
    'Photo to Line CNN_6_pp_corr_noself'
    'Photo to Line CNN_7_pp_corr_noself'
    'Photo to Line CNN_8_pp_corr_noself'
    'Left to Right V1_ds'
    'Left to Right GIST correlation'
    'Left to Right templates_noself'
    'Left to Right visible_dissimilarity_noself'
    'Left to Right knowledge_dissimilarity_noself'
    'Left to Right judgment_noself'
    'Left to Right l_sa_noself'
    'Left to Right l_s_a_noself'
    'Left to Right lsm_ll_sa_noself'
    'Left to Right decoding'
    'Left to Right CNN_1_pp_corr_noself'
    'Left to Right CNN_2_pp_corr_noself'
    'Left to Right CNN_3_pp_corr_noself'
    'Left to Right CNN_4_pp_corr_noself'
    'Left to Right CNN_5_pp_corr_noself'
    'Left to Right CNN_6_pp_corr_noself'
    'Left to Right CNN_7_pp_corr_noself'
    'Left to Right CNN_8_pp_corr_noself'
    };


mask_names = {};

region_key= {
    'lh_v1d_retinotopic'
    'lh_v2d_retinotopic'
    'lh_v3d_retinotopic'
    'lh_v1v_retinotopic'
    'lh_v2v_retinotopic'
    'lh_v3v_retinotopic'
    'lh_hMT_motion'
    'lh_CoS_places'
    'lh_IOS_haracters'
    'lh_pOTS_characters'
    'lh_LOS_bodies'
    'lh_MTG_bodies'
    'lh_ITG_bodies'
    'lh_OTS_bodies'
    'lh_IOG_faces'
    'lh_pFus_faces'
    'lh_mFus_faces'
    'rh_v1d_retinotopic'
    'rh_v2d_retinotopic'
    'rh_v3d_retinotopic'
    'rh_v1v_retinotopic'
    'rh_v2v_retinotopic'
    'rh_v3v_retinotopic'
    'rh_hMT_motion'
    'rh_TOS_places'
    'rh_CoS_places'
    'rh_LOS_bodies'
    'rh_MTG_bodies'
    'rh_ITG_bodies'
    'rh_OTS_bodies'
    'rh_IOG_faces'
    'rh_pFus_faces'
    'rh_mFus_faces'
    };
    
    for this_roi = 1:ceil(length(region_key)/2) %Note 1 more LH than RH ROI so ceil rather than expected floor
        mask_names{end+1} = ['rwRosenke_' region_key{this_roi}];
    end

mask_names{end+1} = ['rwlh_template_noself_crossmod'];

    for this_roi = ceil(length(region_key)/2)+1:length(region_key)
        mask_names{end+1} = ['rwRosenke_' region_key{this_roi}];
    end
mask_names{end+1} = ['rwrh_template_noself_crossmod'];

nrun = size(subjects,2); % enter the number of runs here
% First load in the similarities
RSA_ROI_data_exist = zeros(length(this_model_name),length(mask_names),nrun);
all_data = [];

all_rho = [];
all_corr_ps = [];
all_corrected_rho = [];
all_corrected_corr_ps = [];

for j = 1:length(this_model_name)
    all_data = [];
    all_corrected_data = [];
    for k = 1:length(mask_names)
        for crun = 1:nrun
            %ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/RSA/spearman']; %Where are the results>
            ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/' mask_names{k} '/RSA/spearman'];
            if ~exist(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} '.mat']),'file')
                ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI' mask_names{k} '/RSA/spearman']; % Stupid coding error earlier in analysis led to misnamed directories
            end
            try
                temp_data = load(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} '.mat']));
                all_data(j,k,crun) = temp_data.roi_effect; %Create a matrix of condition by ROI by subject
                RSA_ROI_data_exist(j,k,crun) = 1;
            catch
                warning(['No data for ' subjects{crun} ' probably because of SPM dropout, ignoring them'])
                %error
                RSA_ROI_data_exist(j,k,crun) = 0;
                all_data(j,k,crun) = NaN;
                continue
            end
        end
        roi_names = temp_data.roi_names;
        disp(['Excluding subjects ' num2str(find(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' belonging to groups ' num2str(group(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' maybe check them'])
    end
    all_corrected_data(j,:,group==1) = es_removeBetween_rotated(all_data(j,:,group==1),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
    all_corrected_data(j,:,group==2) = es_removeBetween_rotated(all_data(j,:,group==2),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
    
    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    hold on
    errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
    errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
    %                         for m = 1:length(mask_names)
    %                             scatter(repmat(m-0.1,1,size(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
    %                             scatter(repmat(m+0.1,1,size(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
    %                         end
    xlim([0 length(mask_names)+1])
    set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
    plot([0 length(mask_names)+1],[0,0],'k--')
    title([this_model_name{j} ' RSA'],'Interpreter','none')
    if verLessThan('matlab', '9.2')
        legend('Controls','Patients','location','southeast')
    else
        legend('Controls','Patients','location','southeast','AutoUpdate','off')
    end
    [h,p] = ttest(squeeze(all_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
    end
    [h,p] = ttest(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
    end
    [h,p] = ttest(squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
    end
    
    [h,p] = ttest2(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
    end
    
    drawnow
    saveas(gcf,[outdir filesep this_model_name{j} '_by_region.png'])
    saveas(gcf,[outdir filesep this_model_name{j} '_by_region.pdf'])
        
    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    hold on
    errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
    errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
    %                                     for m = 1:length(mask_names)
    %                             scatter(repmat(m-0.1,1,size(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
    %                             scatter(repmat(m+0.1,1,size(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
    %                         end
    xlim([0 length(mask_names)+1])
    set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
    plot([0 length(mask_names)+1],[0,0],'k--')
    title(['Corrected ' this_model_name{j} ' RSA'],'Interpreter','none')
    if verLessThan('matlab', '9.2')
        legend('Controls','Patients','location','southeast')
    else
        legend('Controls','Patients','location','southeast','AutoUpdate','off')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
    end
    
    [h,p] = ttest2(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
    end

    drawnow
    saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} '_by_region.png'])
    saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} '_by_region.pdf'])
    
end
close all


% Now repeat with partialled correlations
matrices_to_partial = {'Global V1_ds','Global GIST correlation'};
partial_matrices = [];
for this_partial = 1:length(matrices_to_partial)
    IndexC = strcmp(this_model_name,matrices_to_partial(this_partial));
    partial_matrices = [partial_matrices find(IndexC==1)];
end

for j = 1:length(this_model_name)
    all_data = [];
    all_corrected_data = [];
    
    for these_partial_numbers = 1:length(partial_matrices)
        all_partial_combinations = nchoosek(partial_matrices,these_partial_numbers);
        for this_partial = 1:size(all_partial_combinations,1)
            number_partialled_out = size(all_partial_combinations,2);
            partial_name = [];
            for this_partial_matrix = 1:number_partialled_out
                partial_name = [partial_name '+' this_model_name{all_partial_combinations(this_partial,this_partial_matrix)}];
            end
            partial_name = ['_partialling_' partial_name(2:end)];
            
            for k = 1:length(mask_names)
                for crun = 1:nrun
                    %ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/RSA/spearman']; %Where are the results>
                    ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/' mask_names{k} '/RSA/spearman'];
                    if ~exist(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} partial_name '.mat']),'file')
                        ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI' mask_names{k} '/RSA/spearman']; % Stupid coding error earlier in analysis led to misnamed directories
                    end
                    try
                        temp_data = load(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} partial_name '.mat']));
                        all_data(j,k,crun) = temp_data.roi_effect; %Create a matrix of condition by ROI by subject
                        RSA_ROI_data_exist(j,k,crun) = 1;
                    catch
                        warning(['No data for ' subjects{crun} ' probably because of SPM dropout, ignoring them'])
                        %error
                        RSA_ROI_data_exist(j,k,crun) = 0;
                        all_data(j,k,crun) = NaN;
                        continue
                    end
                end
                roi_names = temp_data.roi_names;
                disp(['Excluding subjects ' num2str(find(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' belonging to groups ' num2str(group(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' maybe check them'])
            end
            all_corrected_data(j,:,group==1) = es_removeBetween_rotated(all_data(j,:,group==1),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
            all_corrected_data(j,:,group==2) = es_removeBetween_rotated(all_data(j,:,group==2),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
            
            figure
            set(gcf,'Position',[100 100 1600 800]);
            set(gcf, 'PaperPositionMode', 'auto');
            hold on
            errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
            errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
            %                         for m = 1:length(mask_names)
            %                             scatter(repmat(m-0.1,1,size(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
            %                             scatter(repmat(m+0.1,1,size(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
            %                         end
            xlim([0 length(mask_names)+1])
            set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
            plot([0 length(mask_names)+1],[0,0],'k--')
            title([this_model_name{j} partial_name ' RSA'],'Interpreter','none')
            if verLessThan('matlab', '9.2')
                legend('Controls','Patients','location','southeast')
            else
                legend('Controls','Patients','location','southeast','AutoUpdate','off')
            end
            [h,p] = ttest(squeeze(all_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
            end
            [h,p] = ttest(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
            end
            [h,p] = ttest(squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
            end
            
            [h,p] = ttest2(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
            end
            
            drawnow
            saveas(gcf,[outdir filesep this_model_name{j} partial_name '_by_region.png'])
            saveas(gcf,[outdir filesep this_model_name{j} partial_name '_by_region.pdf'])
            
            figure
            set(gcf,'Position',[100 100 1600 800]);
            set(gcf, 'PaperPositionMode', 'auto');
            hold on
            errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
            errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
            %                                     for m = 1:length(mask_names)
            %                             scatter(repmat(m-0.1,1,size(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
            %                             scatter(repmat(m+0.1,1,size(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
            %                         end
            xlim([0 length(mask_names)+1])
            set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
            plot([0 length(mask_names)+1],[0,0],'k--')
            title(['Corrected ' this_model_name{j} partial_name ' RSA'],'Interpreter','none')
            if verLessThan('matlab', '9.2')
                legend('Controls','Patients','location','southeast')
            else
                legend('Controls','Patients','location','southeast','AutoUpdate','off')
            end
            [h,p] = ttest(squeeze(all_corrected_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
            end
            [h,p] = ttest(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
            end
            [h,p] = ttest(squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            these_y_lims = ylim;
            if sum(h)~=0
                plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
            end
            
            [h,p] = ttest2(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
            if sum(h)~=0
                plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
            end
            
            drawnow
            saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} partial_name '_by_region.png'])
            saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} partial_name '_by_region.pdf'])
            
        end
        close all
    end
end


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

%% Now plot along tensors

downsamp_ratio = 1; %Downsampling in each dimension, must be an integer, 2 is 8 times faster than 1 (2 cubed).
outpath = [preprocessedpathstem '/stats_native_mask0.3_3_coreg_reversedbuttons/searchlight/downsamp_' num2str(downsamp_ratio) filesep 'second_level'];
radius = 5; %Tolerance on the tensor - find maximum voxel within X mm

this_model_name{1} = {
    'Photo to Line templates_noself_hires'
    'Photo to Line lsm_ll_sa_noself_hires'
    };

this_model_name{2} = {
    'All GIST Euclidean_hires'
    'All CNN_2_pp_corr_noself_hires'
    'All CNN_3_pp_corr_noself_hires'
    'All CNN_4_pp_corr_noself_hires'
    'All CNN_5_pp_corr_noself_hires'
    'All CNN_6_pp_corr_noself_hires'
    'All CNN_7_pp_corr_noself_hires'
    };

these_tensors = load('all_interpolated_picturenull_MNI_locations');
these_tensors = these_tensors.all_interpolated_MNI_locations;
for this_model_set =1:length(this_model_name)
    module_plot_these_tensors_radius(this_model_name{this_model_set},these_tensors,outpath,group,subjects,radius)
    module_plot_these_tensors(this_model_name{this_model_set},these_tensors,outpath,group,subjects)
end

%% Assess behavioural performance
for i = 1:length(subjects)
    this_dir = pwd;
    cd([scriptdir 'behavioural_data'])
    [ all_response_averages(i), all_rt_averages(i), all_reversed(i)] = SD_7T_behaviour_withnull( subjects{i}, dates{i} );
    cd(this_dir)
end