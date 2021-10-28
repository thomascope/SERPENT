%Display all thresholded maps of interest (i.e. in this folder), scaled to
%their data range.

addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/Visualisation/ojwoodford-export_fig-216b30e')
clear cfg
cfg.plots = [1:2];
%cfg.plots = [1];
cfg.symmetricity = 'symmetrical'; % Works well for jet, but not hot or cool
% cfg.normalise = 1;
% cfg.threshold = [5 40];
cfg.inflate = 10;
cfg.normalise = 0;
% cfg.rendfile = './lh.inflated1.surf.gii';
% cfg.rendfile = './BrainMesh_ICBM152.lh.gii'; % Different overlay brains

cfg.threshold = [3.32 7]; %p<0.001 unc

%cfg.sampling_distance = 3; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images

univariate_folder = '/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/stats_mask0.3_8_multi_reversedbuttons';
all_subfolders = dir(univariate_folder);

for i = 3:length(all_subfolders) %ignore . and ..
    jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0005.nii'],'jet',cfg)
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
        jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0001.nii'],'jet',cfg)
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_controls'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
        jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0002.nii'],'jet',cfg)
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_patients'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
            jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0003.nii'],'jet',cfg)
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_con-pat'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
                jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0004.nii'],'jet',cfg)
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_pat-con'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
end

cfg.sampling_distance = 3; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images

univariate_folder = '/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/stats_mask0.3_8_multi_reversedbuttons';
all_subfolders = dir(univariate_folder);

for i = 3:length(all_subfolders) %ignore . and ..
    jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0005.nii'],'jet',cfg)
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
        jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0001.nii'],'jet',cfg)
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_controls'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
        jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0002.nii'],'jet',cfg)
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_patients'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
            jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0003.nii'],'jet',cfg)
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_con-pat'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
                jp_spm8_surfacerender2_version_tc([univariate_folder filesep all_subfolders(i).name filesep 'spmT_0004.nii'],'jet',cfg)
    savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_both_' num2str(cfg.sampling_distance) 'voxelsampling'];
    %savepath = ['./rendered_images/' all_subfolders(i).name '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_pat-con'];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
end

cfg = rmfield(cfg,'sampling_distance');
cfg.threshold = [3.32 14];
jp_spm8_surfacerender2_version_tc(['/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/VBM_stats_8/factorial_full_group_vbm_TIVnormalised_agecovaried_unsmoothedmask/spmT_0002.nii'],'jet',cfg)
savepath = ['./rendered_images/VBM_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_con-pat'];
eval(['export_fig ' savepath '.png -transparent'])
close all

covariates_of_interest = {'ACE_R','DigitSpanBackwards','PyramidsPalmTrees_52','DigitSpanForwards','Raven_sMatrices','DigitSpanTotal','TotalAnimals_60','MMSE'};
analyses_of_interest = {'covariate_analysis','covariate_analysis_withcontrols','grouped_covariate_analysis'};
cfg.threshold = [3.32 7];

for i = 1:length(covariates_of_interest)
    for j = 1:length(analyses_of_interest)
        folder_of_interest = ['/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/VBM_stats_8/' analyses_of_interest{j} filesep covariates_of_interest{i}]
        jp_spm8_surfacerender2_version_tc([folder_of_interest filesep 'spmT_0001.nii'],'jet',cfg)
        savepath = ['./rendered_images/' analyses_of_interest{j} '_' covariates_of_interest{i} '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f') '_con-pat'];
        eval(['export_fig ' savepath '.png -transparent'])
        close all
    end
end

cfg.sampling_distance = 3;
cfg.threshold = [3.32 14];
jp_spm8_surfacerender2_version_tc(['/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/VBM_stats_8/factorial_full_group_vbm_TIVnormalised_agecovaried_unsmoothedmask/spmT_0002.nii'],'jet',cfg)
savepath = ['./rendered_images/VBM_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f')  '_' num2str(cfg.sampling_distance) '_con-pat'];
eval(['export_fig ' savepath '.png -transparent'])
close all

covariates_of_interest = {'ACE_R','DigitSpanBackwards','PyramidsPalmTrees_52','DigitSpanForwards','Raven_sMatrices','DigitSpanTotal','TotalAnimals_60','MMSE'};
analyses_of_interest = {'covariate_analysis','covariate_analysis_withcontrols','grouped_covariate_analysis'};
cfg.threshold = [3.32 7];

for i = 1:length(covariates_of_interest)
    for j = 1:length(analyses_of_interest)
        folder_of_interest = ['/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/VBM_stats_8/' analyses_of_interest{j} filesep covariates_of_interest{i}]
        jp_spm8_surfacerender2_version_tc([folder_of_interest filesep 'spmT_0001.nii'],'jet',cfg)
        savepath = ['./rendered_images/' analyses_of_interest{j} '_' covariates_of_interest{i} '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f')  '_' num2str(cfg.sampling_distance) '_con-pat'];
        eval(['export_fig ' savepath '.png -transparent'])
        close all
    end
end


%now plot tSNR maps

tSNR_maps = {
    '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/mean_control_tSNR_map.nii'
    '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/mean_patient_tSNR_map.nii'
    '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/mean_tSNR_map.nii'
    };
groups = {
    'Control'
    'Patient'
    'Overall'
   };
for i = 1:3
    this_scan_data = spm_read_vols(spm_vol(tSNR_maps{i}));
    upper_range(i) = max(max(max(this_scan_data)));
end
cfg.sampling_distance = 3;        
cfg.threshold = [0 max(upper_range)];
for i = 1:3
    jp_spm8_surfacerender2_version_tc(tSNR_maps{i},'jet',cfg)
    savepath = ['./rendered_images/SNR_' groups{i} '_' num2str(cfg.threshold(1),'%.2f') '_' num2str(cfg.threshold(2),'%.2f')  '_' num2str(cfg.sampling_distance)];
    eval(['export_fig ' savepath '.png -transparent'])
    close all
end



all_scans = dir('./multivariate_segments/*.nii');

for sampling_distance = [3];
    cfg.sampling_distance = sampling_distance; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images
    for i = 1:length(all_scans)
        
        this_scan_data = spm_read_vols(spm_vol(['./multivariate/' all_scans(i).name]));
         upper_range = max(max(max(this_scan_data)));
%         lower_range = min(min(min(abs(this_scan_data))));
upper_range = 9.84 % For matching shared segment scales
lower_range = 0; % data already thresholded
        
        % spm_smooth(all_scans(i).name,['s5x_' all_scans(i).name],[5 0 0])
        % this_smoothed_scan_data = spm_read_vols(spm_vol(['s5x_' all_scans(i).name]));
        % upper_range_smooth = max(max(max(this_scan_data)));
        % lower_range_smooth = min(min(min(abs(this_scan_data))));
        
        %cfg.threshold = [3.3748 6.5]; %p=0.001
        cfg.threshold = [lower_range upper_range]; %scaled to data
        % cfg.threshold = [lower_range_smooth upper_range_smooth]; %scaled to data
        
        jp_spm8_surfacerender2_version_tc(['./multivariate_segments/' all_scans(i).name],'jet',cfg)
        
        savepath = ['./rendered_images/' all_scans(i).name(1:end-4) '_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
        savepath = strrep(savepath,'>','-');
        %eval(['export_fig ' savepath '.png -transparent -m2'])
        eval(['export_fig ' savepath '.png -transparent'])
        close all
    end
end

all_scans = dir('./multivariate_predictions/*.nii');

for sampling_distance = [3];
    cfg.sampling_distance = sampling_distance; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images
    for i = 1:length(all_scans)
        
        this_scan_data = spm_read_vols(spm_vol(['./multivariate_predictions/' all_scans(i).name]));
         upper_range = max(max(max(this_scan_data)));
%         lower_range = min(min(min(abs(this_scan_data))));
upper_range = 5.97; % For matching prediction scales
lower_range = 0; % data already thresholded
        
        % spm_smooth(all_scans(i).name,['s5x_' all_scans(i).name],[5 0 0])
        % this_smoothed_scan_data = spm_read_vols(spm_vol(['s5x_' all_scans(i).name]));
        % upper_range_smooth = max(max(max(this_scan_data)));
        % lower_range_smooth = min(min(min(abs(this_scan_data))));
        
        %cfg.threshold = [3.3748 6.5]; %p=0.001
        cfg.threshold = [lower_range upper_range]; %scaled to data
        % cfg.threshold = [lower_range_smooth upper_range_smooth]; %scaled to data
        
        jp_spm8_surfacerender2_version_tc(['./multivariate_predictions/' all_scans(i).name],'jet',cfg)
        
        savepath = ['./rendered_images/' all_scans(i).name(1:end-4) '_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
        savepath = strrep(savepath,'>','-');
        %eval(['export_fig ' savepath '.png -transparent -m2'])
        eval(['export_fig ' savepath '.png -transparent'])
        close all
    end
end

all_scans = dir('./physio_physio/*.nii');

for sampling_distance = [3];
    cfg.sampling_distance = sampling_distance; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images
    for i = 1:length(all_scans)
        
        this_scan_data = spm_read_vols(spm_vol(['./physio_physio/' all_scans(i).name]));
         upper_range = max(max(max(this_scan_data)));
%         lower_range = min(min(min(abs(this_scan_data))));
upper_range = 9.17; % For matching prediction scales
lower_range = 0; % data already thresholded
        
        % spm_smooth(all_scans(i).name,['s5x_' all_scans(i).name],[5 0 0])
        % this_smoothed_scan_data = spm_read_vols(spm_vol(['s5x_' all_scans(i).name]));
        % upper_range_smooth = max(max(max(this_scan_data)));
        % lower_range_smooth = min(min(min(abs(this_scan_data))));
        
        %cfg.threshold = [3.3748 6.5]; %p=0.001
        cfg.threshold = [lower_range upper_range]; %scaled to data
        % cfg.threshold = [lower_range_smooth upper_range_smooth]; %scaled to data
        
        jp_spm8_surfacerender2_version_tc(['./physio_physio/' all_scans(i).name],'jet',cfg)
        
        savepath = ['./rendered_images/' all_scans(i).name(1:end-4) '_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
        savepath = strrep(savepath,'>','-');
        %eval(['export_fig ' savepath '.png -transparent -m2'])
        eval(['export_fig ' savepath '.png -transparent'])
        close all
    end
end


% Now plot PPI with ROIs in blue

for sampling_distance = [3];
    cfg.sampling_distance = sampling_distance; % tc modification - When mesh is lower resolution than overlay image this can be problematic, now displays largest value within a Euclidean distance specified in number of voxels. Can be slow for high resolution images
    cfg.overwrite = 1;
    upper_range = 9.17; % For matching prediction scales
    lower_range = 0; % data already thresholded
    
    cfg.threshold = [lower_range upper_range];
    cfg.threshold2 = [0 1]; %Binary ROI
    jp_spm8_surfacerender2_version_tc(['./ROI_scans/PPI-PrG-STG-noseed.nii'],'jet',cfg,['./ROI_scans/Left_Precentral_Univariate_Interaction_combined.nii'],repmat([0 0 0.5],256,1))
    
    savepath = ['./rendered_images/PPI-PrG-STG-noseed_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = strrep(savepath,'>','-');
    %eval(['export_fig ' savepath '.png -transparent -m2'])
    eval(['export_fig ' savepath '.png -transparent'])
    close all
    
    jp_spm8_surfacerender2_version_tc(['./physio_physio/PPI-Precentral-STG-Cluster.nii'],'jet',cfg,['./ROI_scans/Left_Precentral_Univariate_Interaction_combined.nii'],repmat([0 0 0.5],256,1))
    
    savepath = ['./rendered_images/PPI-PrG-STG-noseed_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = strrep(savepath,'>','-');
    %eval(['export_fig ' savepath '.png -transparent -m2'])
    eval(['export_fig ' savepath '.png -transparent'])
    close all
    
    jp_spm8_surfacerender2_version_tc(['./physio_physio/PPI-STG-Precentral-cluster.nii'],'jet',cfg,['./ROI_scans/Left_STG_Univariate3mm_15>3.nii'],repmat([0 0 0.5],256,1))
    
    savepath = ['./rendered_images/PPI-STG-PrG-noseed_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = strrep(savepath,'>','-');
    %eval(['export_fig ' savepath '.png -transparent -m2'])
    eval(['export_fig ' savepath '.png -transparent'])
    close all
    
    spm_imcalc(char({'./ROI_scans/Left_STG_Univariate3mm_15>3.nii';'./ROI_scans/Left_Precentral_Univariate_Interaction_combined.nii'}),['./ROI_scans/PrG+STG.nii'],['i1>0|i2>0'])
    jp_spm8_surfacerender2_version_tc(['./physio_physio/PPI-PrecentralxSTG-Negative-Cluster.nii'],'jet',cfg,['./ROI_scans/PrG+STG.nii'],repmat([0 0 0.5],256,1))
    
    savepath = ['./rendered_images/PPI-Interaction-noseed_' num2str(lower_range,'%.2f') '_' num2str(upper_range,'%.2f') '_' num2str(cfg.sampling_distance) 'voxelsampling'];
    savepath = strrep(savepath,'>','-');
    %eval(['export_fig ' savepath '.png -transparent -m2'])
    eval(['export_fig ' savepath '.png -transparent'])
    close all
        
    cfg.overwrite = 0;
end

% 
% %Now create ROI figures for illustration
% im1 = './ROI_scans/Left_STG_Univariate3mm_15>3.nii';
% im2 = './ROI_scans/Left_Precentral_Univariate_Interaction_combined.nii';
% cfg.threshold = [0 1];
% 
% jp_spm8_surfacerender2_version_tc(im1,'jet',cfg,im2,'cool')
