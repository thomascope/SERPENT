function []=TDTCrossnobisAnalysis_1Subj(GLMDir,downsamp_ratio)
% TDTCrossnobisAnalysis_1Subj('/imaging/mlr/users/tc02/PINFA_preprocessed_2021/P7C05/stats4_multi_3_nowritten2')

if ~exist('downsamp_ratio','var')
    downsamp_ratio = 1;
end

addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/RSA_scriptses_scripts_fMRI')
addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/RSA_scriptsdecoding_toolbox_v3.999')
addpath(genpath('/group/language/data/ediz.sohoglu/matlab/rsatoolbox'));


%% Compute searchlight crossnobis distance

% This script is a template that can be used for an encoding analysis on
% brain image data using cross-validated Mahalanobis distance. It is for
% people who have betas available from an SPM.mat (for AFNI, see
% decoding_tutorial) and want to automatically extract the relevant images
% used for calculation of the cross-validated Mahalanobis distance, as well
% as corresponding labels and decoding chunk numbers (e.g. run numbers). If
% you don't have this available, then inspect the differences between
% decoding_template and decoding_template_nobetas and adapt this template
% to use it without betas.

% Set defaults
cfg = decoding_defaults;

% Set the analysis that should be performed (default is 'searchlight')
cfg.analysis = 'searchlight';

% Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
if downsamp_ratio == 1
    cfg.results.dir = fullfile(GLMDir,'TDTcrossnobis');
else
    cfg.results.dir = fullfile(GLMDir,['TDTcrossnobis_downsamp_' num2str(downsamp_ratio)]);
end

% Set the filepath where your SPM.mat and all related betas are, e.g. 'c:\exp\glm\model_button'
beta_loc = GLMDir;

% Set the filename of your brain mask (or your ROI masks as cell matrix)
% for searchlight or wholebrain e.g. 'c:\exp\glm\model_button\mask.img' OR
% for ROI e.g. {'c:\exp\roi\roimaskleft.img', 'c:\exp\roi\roimaskright.img'}
% You can also use a mask file with multiple masks inside that are
% separated by different integer values (a "multi-mask")
cfg.files.mask = fullfile(GLMDir,'mask.nii');

% Set the label names to the regressor names which you want to use for
% your similarity analysis, e.g.
%labelnames = {'Strong+M_Set1_Item1','Strong+M_Set1_Item2','Strong+M_Set1_Item3','Strong+M_Set1_Item4','Strong+M_Set2_Item1','Strong+M_Set2_Item2','Strong+M_Set2_Item3','Strong+M_Set2_Item4','Strong+M_Set3_Item1','Strong+M_Set3_Item2','Strong+M_Set3_Item3','Strong+M_Set3_Item4','Strong+M_Set4_Item1','Strong+M_Set4_Item2','Strong+M_Set4_Item3','Strong+M_Set4_Item4','Strong+M_Set5_Item1','Strong+M_Set5_Item2','Strong+M_Set5_Item3','Strong+M_Set5_Item4','Strong+M_Set6_Item1','Strong+M_Set6_Item2','Strong+M_Set6_Item3','Strong+M_Set6_Item4','Strong+M_Set7_Item1','Strong+M_Set7_Item2','Strong+M_Set7_Item3','Strong+M_Set7_Item4','Strong+M_Set8_Item1','Strong+M_Set8_Item2','Strong+M_Set8_Item3','Strong+M_Set8_Item4','Weak+M_Set1_Item1','Weak+M_Set1_Item2','Weak+M_Set1_Item3','Weak+M_Set1_Item4','Weak+M_Set2_Item1','Weak+M_Set2_Item2','Weak+M_Set2_Item3','Weak+M_Set2_Item4','Weak+M_Set3_Item1','Weak+M_Set3_Item2','Weak+M_Set3_Item3','Weak+M_Set3_Item4','Weak+M_Set4_Item1','Weak+M_Set4_Item2','Weak+M_Set4_Item3','Weak+M_Set4_Item4','Weak+M_Set5_Item1','Weak+M_Set5_Item2','Weak+M_Set5_Item3','Weak+M_Set5_Item4','Weak+M_Set6_Item1','Weak+M_Set6_Item2','Weak+M_Set6_Item3','Weak+M_Set6_Item4','Weak+M_Set7_Item1','Weak+M_Set7_Item2','Weak+M_Set7_Item3','Weak+M_Set7_Item4','Weak+M_Set8_Item1','Weak+M_Set8_Item2','Weak+M_Set8_Item3','Weak+M_Set8_Item4','Strong+MM_Set1_Item1','Strong+MM_Set1_Item2','Strong+MM_Set1_Item3','Strong+MM_Set1_Item4','Strong+MM_Set2_Item1','Strong+MM_Set2_Item2','Strong+MM_Set2_Item3','Strong+MM_Set2_Item4','Strong+MM_Set3_Item1','Strong+MM_Set3_Item2','Strong+MM_Set3_Item3','Strong+MM_Set3_Item4','Strong+MM_Set4_Item1','Strong+MM_Set4_Item2','Strong+MM_Set4_Item3','Strong+MM_Set4_Item4','Strong+MM_Set5_Item1','Strong+MM_Set5_Item2','Strong+MM_Set5_Item3','Strong+MM_Set5_Item4','Strong+MM_Set6_Item1','Strong+MM_Set6_Item2','Strong+MM_Set6_Item3','Strong+MM_Set6_Item4','Strong+MM_Set7_Item1','Strong+MM_Set7_Item2','Strong+MM_Set7_Item3','Strong+MM_Set7_Item4','Strong+MM_Set8_Item1','Strong+MM_Set8_Item2','Strong+MM_Set8_Item3','Strong+MM_Set8_Item4','Weak+MM_Set1_Item1','Weak+MM_Set1_Item2','Weak+MM_Set1_Item3','Weak+MM_Set1_Item4','Weak+MM_Set2_Item1','Weak+MM_Set2_Item2','Weak+MM_Set2_Item3','Weak+MM_Set2_Item4','Weak+MM_Set3_Item1','Weak+MM_Set3_Item2','Weak+MM_Set3_Item3','Weak+MM_Set3_Item4','Weak+MM_Set4_Item1','Weak+MM_Set4_Item2','Weak+MM_Set4_Item3','Weak+MM_Set4_Item4','Weak+MM_Set5_Item1','Weak+MM_Set5_Item2','Weak+MM_Set5_Item3','Weak+MM_Set5_Item4','Weak+MM_Set6_Item1','Weak+MM_Set6_Item2','Weak+MM_Set6_Item3','Weak+MM_Set6_Item4','Weak+MM_Set7_Item1','Weak+MM_Set7_Item2','Weak+MM_Set7_Item3','Weak+MM_Set7_Item4','Weak+MM_Set8_Item1','Weak+MM_Set8_Item2','Weak+MM_Set8_Item3','Weak+MM_Set8_Item4','Strong+Noise_Set1_Item1','Strong+Noise_Set1_Item2','Strong+Noise_Set1_Item3','Strong+Noise_Set1_Item4','Strong+Noise_Set2_Item1','Strong+Noise_Set2_Item2','Strong+Noise_Set2_Item3','Strong+Noise_Set2_Item4','Strong+Noise_Set3_Item1','Strong+Noise_Set3_Item2','Strong+Noise_Set3_Item3','Strong+Noise_Set3_Item4','Strong+Noise_Set4_Item1','Strong+Noise_Set4_Item2','Strong+Noise_Set4_Item3','Strong+Noise_Set4_Item4','Strong+Noise_Set5_Item1','Strong+Noise_Set5_Item2','Strong+Noise_Set5_Item3','Strong+Noise_Set5_Item4','Strong+Noise_Set6_Item1','Strong+Noise_Set6_Item2','Strong+Noise_Set6_Item3','Strong+Noise_Set6_Item4','Strong+Noise_Set7_Item1','Strong+Noise_Set7_Item2','Strong+Noise_Set7_Item3','Strong+Noise_Set7_Item4','Strong+Noise_Set8_Item1','Strong+Noise_Set8_Item2','Strong+Noise_Set8_Item3','Strong+Noise_Set8_Item4','Weak+Noise_Set1_Item1','Weak+Noise_Set1_Item2','Weak+Noise_Set1_Item3','Weak+Noise_Set1_Item4','Weak+Noise_Set2_Item1','Weak+Noise_Set2_Item2','Weak+Noise_Set2_Item3','Weak+Noise_Set2_Item4','Weak+Noise_Set3_Item1','Weak+Noise_Set3_Item2','Weak+Noise_Set3_Item3','Weak+Noise_Set3_Item4','Weak+Noise_Set4_Item1','Weak+Noise_Set4_Item2','Weak+Noise_Set4_Item3','Weak+Noise_Set4_Item4','Weak+Noise_Set5_Item1','Weak+Noise_Set5_Item2','Weak+Noise_Set5_Item3','Weak+Noise_Set5_Item4','Weak+Noise_Set6_Item1','Weak+Noise_Set6_Item2','Weak+Noise_Set6_Item3','Weak+Noise_Set6_Item4','Weak+Noise_Set7_Item1','Weak+Noise_Set7_Item2','Weak+Noise_Set7_Item3','Weak+Noise_Set7_Item4','Weak+Noise_Set8_Item1','Weak+Noise_Set8_Item2','Weak+Noise_Set8_Item3','Weak+Noise_Set8_Item4','Noise+Speech_Set1_Item1','Noise+Speech_Set1_Item2','Noise+Speech_Set1_Item3','Noise+Speech_Set1_Item4','Noise+Speech_Set2_Item1','Noise+Speech_Set2_Item2','Noise+Speech_Set2_Item3','Noise+Speech_Set2_Item4','Noise+Speech_Set3_Item1','Noise+Speech_Set3_Item2','Noise+Speech_Set3_Item3','Noise+Speech_Set3_Item4','Noise+Speech_Set4_Item1','Noise+Speech_Set4_Item2','Noise+Speech_Set4_Item3','Noise+Speech_Set4_Item4','Noise+Speech_Set5_Item1','Noise+Speech_Set5_Item2','Noise+Speech_Set5_Item3','Noise+Speech_Set5_Item4','Noise+Speech_Set6_Item1','Noise+Speech_Set6_Item2','Noise+Speech_Set6_Item3','Noise+Speech_Set6_Item4','Noise+Speech_Set7_Item1','Noise+Speech_Set7_Item2','Noise+Speech_Set7_Item3','Noise+Speech_Set7_Item4','Noise+Speech_Set8_Item1','Noise+Speech_Set8_Item2','Noise+Speech_Set8_Item3','Noise+Speech_Set8_Item4'};
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

% set everything to calculate (dis)similarity estimates
cfg.decoding.software = 'distance';
cfg.decoding.method = 'classification';
cfg.decoding.train.classification.model_parameters = 'cveuclidean';

% This option averages across (dis)similarity matrices of each
% cross-validation iteration and across all cells of the lower diagonal
% (i.e. all distance comparisons). If you want the entire matrix, consider
% using 'other_average' which only averages across cross-validation
% iterations. Alternatively, you could use the output 'RSA_beta' which is
% more general purpose, but a little more complex.
cfg.results.output = 'other_average';

% These parameters carry out the multivariate noise normalization using the
% residuals
cfg.scale.method = 'cov'; % we scale by noise covariance
cfg.scale.estimation = 'separate'; % we scale all data for each run separately while iterating across searchlight spheres
cfg.scale.shrinkage = 'lw2'; % Ledoit-Wolf shrinkage retaining variances

% The crossnobis distance is identical to the cross-validated Euclidean
% distance after prewhitening (multivariate noise normalization). It has
% been shown that a good estimate for the multivariate noise is provided
% by the residuals of the first-level model, in addition with Ledoit-Wolf
% regularization. Here we calculate those residuals. If you have them
% available already, you can load them into misc.residuals using only the
% voxels from cfg.files.mask
[misc.residuals,cfg.files.residuals.chunk] = residuals_from_spm(fullfile(beta_loc,'SPM.mat'),cfg.files.mask); % this only needs to be run once and can be saved and loaded

% Set additional parameters manually if you want (see decoding.m or
% decoding_defaults.m). Below some example parameters that you might want
% to use:

cfg.searchlight.unit = 'mm';
cfg.searchlight.radius = 8; % this will yield a searchlight radius of 12mm.
cfg.searchlight.spherical = 1;
cfg.verbose = 1; % 2 = you want all information to be printed on screen, 1 = progress indicators, 0 = off

% Decide whether you want to see the searchlight/ROI/... during decoding
cfg.plot_selected_voxels = 0; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...

%% Nothing needs to be changed below for standard dissimilarity estimates using all data

% The following function extracts all beta names and corresponding run
% numbers from the SPM.mat
regressor_names = design_from_spm(beta_loc);

% Extract all information for the cfg.files structure (labels will be [1 -1] )
cfg = decoding_describe_data(cfg,labelnames,labels,regressor_names,beta_loc);

% This creates a design in which cross-validation is done between the distance estimates
cfg.design = make_design_similarity_cv(cfg);

if downsamp_ratio ~= 1
    [passed_data, misc, cfg] = decoding_load_data(cfg, misc);
    cfg.searchlight.subset = combvec(1:downsamp_ratio:passed_data.dim(1),1:downsamp_ratio:passed_data.dim(2),1:downsamp_ratio:passed_data.dim(3))';
end

% Run decoding
cfg.results.overwrite = 1;
try
    results = decoding(cfg,[],misc);
catch
    assert(~~exist([cfg.results.dir filesep 'res_other_average.mat'],'file'),'Something went wrong with the decoding - the results do not exist')
end

%% Make effect-maps (by correlating neural RDMs to model RDMs)
try
    version = 'spearman'; % how to assess accuracy of model RDMs (pearson, spearman, weighted average)
    
    if downsamp_ratio == 1
        outputDir = fullfile(GLMDir,'TDTcrossnobis',version);
    else
        outputDir = fullfile(GLMDir,['TDTcrossnobis_downsamp_' num2str(downsamp_ratio)],version);
    end
    if exist(outputDir,'dir'); rmdir(outputDir,'s'); mkdir(outputDir); else; mkdir(outputDir); end
    
    clear models
    
    basemodels.templates = zeros(15,15);
    basemodels.templates(1:16:end) = 1;
    basemodels.templates(2:48:end) = 1/3;
    basemodels.templates(3:48:end) = 1/3;
    basemodels.templates(16:48:end) = 1/3;
    basemodels.templates(18:48:end) = 1/3;
    basemodels.templates(31:48:end) = 1/3;
    basemodels.templates(32:48:end) = 1/3;
    basemodels.templates = 1-basemodels.templates;
    basemodelNames = {'templates'};
    
    load(fullfile(cfg.results.dir,'res_other_average.mat'));
    data = results.other_average.output;
    notempty_data = find(~cellfun(@isempty,results.other_average.output));
    modeltemplate = NaN(size(results.other_average.output{notempty_data(1)}));
    
    % Condition order is annoying - not conducive to easy RSA matrix formation
    %stim_type_labels = allcomb(styledir, frequency_labels, direction_labels, category_labels)
    % Rotation order is:
    % Style - photo vs line_drawing
    % Frequency - common vs moderate vs rare
    % Direction - left vs right
    % Template - dog-like vs cat-like vs horse-like vs marine vs birds
    
    styles = {'photo','line_drawings'};
    frequency = {'common','moderate','rare'};
    direction = {'left','right'};
    template = {'dog-like','cat-like','horse-like','marine','birds'};
    stim_type_table = allcomb(styles, frequency, direction, template);
    
    % First set up a global template based model - keep the others for later
    % more complex design matrices
    global_template_model = zeros(size(modeltemplate));
    for i = 1:length(labelnames)
        this_template = zeros(1,length(template));
        for j = 1:length(template)
            this_template(j) = contains(labelnames{i},template{j});
        end
        this_template_type = template{find(this_template)};
        for j = 1:length(labelnames)
            if contains(labelnames{j},this_template_type)
                global_template_model(i,j) = 1/3;
            end
        end
    end
    global_template_model(1:size(global_template_model,1)+1:end) = NaN; %Diagonal
    global_template_model = 1-global_template_model; %Dissimilarity
    modelNames{1} = 'Global_Template_Model';
    
    V = spm_vol(fullfile(GLMDir,'mask.nii'));
    mask = spm_read_vols(V);
    mask_index = results.mask_index;
    
    clear results % to free memory
    
    for m=1:length(modelNames)
        fprintf('\nComputing effect-map for model %s\n',modelNames{m});
        
        modelRDM = vectorizeRDMs(models{m})';
        effectMap = NaN(size(mask));
        for vx=1:numel(data)
            neuralRDM = vectorizeRDMs(data{vx})';
            if isempty(neuralRDM)
                continue
            end
            notempty = vx;
            if ~isempty(strfind(version,'pearson'))
                effectMap(mask_index(vx)) = fisherTransform(corr(modelRDM,neuralRDM,'type','Pearson','Rows','pairwise'));
            elseif ~isempty(strfind(version,'spearman'))
                effectMap(mask_index(vx)) = fisherTransform(corr(modelRDM,neuralRDM,'type','Spearman','Rows','pairwise'));
            elseif ~isempty(strfind(version,'average'))
                %effectMap(mask_index(vx)) = mean(neuralRDM(find(~isnan(modelRDM)),:),1);
                effectMap(mask_index(vx)) = mean(neuralRDM(find(modelRDM==1),:),1);
            end
            if ~mod(vx,100)
                disp(['Processing voxel ' num2str(vx) ' of ' num2str(numel(data))])
            end
        end
        dims = size(effectMap);
        downsamped_effectMap = effectMap(1:downsamp_ratio:dims(1),1:downsamp_ratio:dims(2),1:downsamp_ratio:dims(3));
        downsamped_V.mat = V.mat;
        downsamped_V.mat(1:3,1:3)=downsamped_V.mat(1:3,1:3)*downsamp_ratio;
        
        saveMRImage(downsamped_effectMap,fullfile(outputDir,['effect-map_' modelNames{m} '.nii']),downsamped_V.mat);
    end
catch
end
