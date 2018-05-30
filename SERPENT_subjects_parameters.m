%% Set up global variables

%clear all

% make sure EEG modality of SPM software is selected
%spm('EEG');
%spm

% add required paths
addpath(pwd);
% addpath('/group/language/data/ediz.sohoglu/matlab/utilities/');
% addpath('/opt/neuromag/meg_pd_1.2/');

% define paths
rawpathstem = '/imaging/tc02/';
preprocessedpathstem = '/imaging/tc02/SERPENT_preprocessed/';

% % define conditions
% conditions = {'Mismatch_4' 'Match_4' 'Mismatch_8' 'Match_8' 'Mismatch_16' 'Match_16'};
% 
% contrast_labels = {'Sum all conditions';'Match-MisMatch'; 'Clear minus Unclear'; 'Gradient difference M-MM'};
% contrast_weights = [1, 1, 1, 1, 1, 1; -1, 1, -1, 1, -1, 1; -1, -1, 0, 0, 1, 1; -1, 1, 0, 0, 1, -1];    

% define subjects and blocks (group(cnt) = 1 for controls initial visit, group(cnt) = 2 for patients initial visit, group(cnt) = 3 for controls follow up, group(cnt) = 4 for patients follow up)
cnt = 0;

% cnt = cnt + 1;
% subjects{cnt} = 'S7C01';
% dates{cnt} = '20180501';
% fullid{cnt} = '26934/20180501_U-ID40637';
% basedir{cnt} = 'SERPENT';
% blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'};
% blocksin{cnt} = {'DATA_0020.nii', 'DATA_0021.nii', 'DATA_0010.nii', 'DATA_0012.nii', 'DATA_0016.nii', 'DATA_0018.nii', 'DATA_0011.nii','DATA_0013.nii'};
% blocksout{cnt} = {'structural', 'INV2', 'Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
% minvols(cnt) = 340;
% group(cnt) = 1;
% 
% cnt = cnt + 1;
% subjects{cnt} = 'S7P01';
% dates{cnt} = '20180502';
% fullid{cnt} = '25602/20180502_U-ID40642';
% basedir{cnt} = 'SERPENT';
% blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'};
% blocksin{cnt} = {'DATA_0020.nii', 'DATA_0021.nii', 'DATA_0010.nii', 'DATA_0012.nii', 'DATA_0016.nii', 'DATA_0018.nii', 'DATA_0011.nii','DATA_0013.nii'};
% blocksout{cnt} = {'structural', 'INV2', 'Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
% minvols(cnt) = 340;
% group(cnt) = 2;

cnt = cnt + 1;
subjects{cnt} = 'S7P02';
dates{cnt} = '20180525';
fullid{cnt} = '25243/20180525_U-ID40645/';
basedir{cnt} = 'SERPENT';
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'};
blocksin{cnt} = {'DATA_0020.nii', 'DATA_0021.nii', 'DATA_0010.nii', 'DATA_0012.nii', 'DATA_0016.nii', 'DATA_0018.nii', 'DATA_0011.nii','DATA_0013.nii'};
blocksout{cnt} = {'structural', 'INV2', 'Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
minvols(cnt) = 340;
group(cnt) = 2;