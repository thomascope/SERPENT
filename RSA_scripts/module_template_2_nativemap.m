function images_warped = module_template_2_nativemap(images,StrDir,ismasks,reslice_template,inverse_deformation_path)
% Normalise masks or other images to native space
% Specify 0 for normal images, or 1 for masks (needs to be re-thresholded and binarised)

addpath('/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/RSA_scripts/es_scripts_fMRI')
addpath('/group/language/data/thomascope/7T_full_paradigm_pilot_analysis_scripts/RSA_scripts/decoding_toolbox_v3.999')
addpath(genpath('/group/language/data/ediz.sohoglu/matlab/rsatoolbox'));

% Copy template space mask to subject directory
for i=1:length(images)
    [base_stem, image_name, image_extension] = fileparts(images{i});
    images_copied{i} = fullfile(StrDir,[image_name image_extension]);
    copyfile(images{i},images_copied{i});
end

% Normalize
if size(images_copied,1)==1&&size(images_copied,2)>1
    images_copied = images_copied'; %Assume row rather than column
end
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = images_copied;
matlabbatch{1}.spm.spatial.normalise.write.subj.def =  cellstr([StrDir inverse_deformation_path]);

spm_jobman('initcfg')
spm_jobman('run', matlabbatch);

% Reslice into functional space

if exist('reslice_template','var')
    flags.interp = 7; %Best quality
    flags.which = 1; % Don't reslice the template image
    flags.mean = 0; %Don't output the mean
    flags.mask = 0; %Don't implicitly mask the images
    for i=1:length(images_copied)
        [base_stem, image_name, image_extension] = fileparts(images_copied{i});
        images_warped{i} = fullfile(StrDir,['w' image_name image_extension]);
        spm_reslice({reslice_template;images_warped{i}},flags)
        images_resliced{i} = fullfile(StrDir,['rw' image_name image_extension]);
    end
    
    % Re-binarise mask data % Not actually needed, as not resliced.
    if ismasks

        mask_threshold = .05;
        for i=1:length(images_warped)
            % Binarise normalised mask
            V = spm_vol(images_resliced{i});
            fname_mask = V.fname;
            Y_mask = spm_read_vols(V);
            Y_mask(Y_mask<mask_threshold) = 0;
            Y_mask(isnan(Y_mask)) = 0;
            Y_mask(Y_mask>=mask_threshold) = 1;
            saveMRImage(Y_mask,fname_mask,V.mat);
        end
    end
     % spm_check_registration(char(images_resliced'),[StrDir,'structural_csf.nii']) %For debugging check
end