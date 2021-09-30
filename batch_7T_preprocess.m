% Batch script for preprocessing of pilot 7T data
% Written by TEC Feb July 2021

%% Setup environment
clear all
rmpath(genpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest/'))
%addpath /imaging/local/software/spm_cbu_svn/releases/spm12_fil_r6906
% addpath /group/language/data/thomascope/spm12_fil_r6906/
% spm fmri
rmpath(genpath('/group/language/data/thomascope/spm12_fil_r6906/'))
addpath /group/language/data/thomascope/spm12_fil_r7771/ % Newedt version of cat12 - currently r1844
spm fmri

%% Define parameters
setup_file = 'SERPENT_subjects_parameters';
eval(setup_file)
tr=2.5;
scriptdir = '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/';

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
    

%% Skullstrip structural
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

%% Now reslice all the images

resliceworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3))
    filestorealign = cell(1,length(theseepis));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    for i = 1:length(theseepis)
        filestorealign{i} = spm_select('ExtFPList',outpath,['^topup_' blocksin{crun}{theseepis(i)}],1:minvols(crun));
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

if ~all(normalisesmoothworkedcorrectly)
    error('failed at normalise and smooth');
end
