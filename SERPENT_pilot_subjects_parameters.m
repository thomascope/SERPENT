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
preprocessedpathstem = '/imaging/tc02/SERPENT_pilot_preprocessed/';

% % define conditions
% conditions = {'Mismatch_4' 'Match_4' 'Mismatch_8' 'Match_8' 'Mismatch_16' 'Match_16'};
% 
% contrast_labels = {'Sum all conditions';'Match-MisMatch'; 'Clear minus Unclear'; 'Gradient difference M-MM'};
% contrast_weights = [1, 1, 1, 1, 1, 1; -1, 1, -1, 1, -1, 1; -1, -1, 0, 0, 1, 1; -1, 1, 0, 0, 1, -1];    

% define subjects and blocks (group(cnt) = 1 for controls initial visit, group(cnt) = 2 for patients initial visit, group(cnt) = 3 for controls follow up, group(cnt) = 4 for patients follow up)
cnt = 0;

% cnt = cnt + 1;
% subjects{cnt} = 'RBJ';
% dates{cnt} = '20180410';
% fullid{cnt} = '25723/20180410_U-ID40390';
% basedir{cnt} = '7T_SERPENT_PILOT_RBJ';
% blocksin_folders{cnt} = {'Series_008_mp2rage_sag_p3_0.75mm_UNI_Images','Series_009_mp2rage_sag_p3_0.75mm_INV2','Series_013_cmrr_mbep2d_3x2_TR1.5s_390vols','Series_017_cmrr_mbep2d_3x2_TR1.5s_390vols','Series_021_cmrr_mbep2d_3x2_TR1.5s_380vols','Series_023_cmrr_mbep2d_3x2_TR1.5s_380vols','Series_016_cmrr_mbep2d_3x2_TR1.5s_390vols_SBRef','Series_018_cmrr_mbep2d_3x2_TR1.5s_InvPE_SBRef'};
% blocksin{cnt} = {'DATA_0008.nii', 'DATA_0009.nii', 'DATA_0013.nii', 'DATA_0017.nii', 'DATA_0021.nii', 'DATA_0023.nii', 'DATA_0016.nii','DATA_0018.nii'};
% blocksout{cnt} = {'structural', 'INV2', 'Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
% minvols(cnt) = 380;
% group(cnt) = 1;

cnt = cnt + 1;
subjects{cnt} = 'WAC';
dates{cnt} = '20180417';
fullid{cnt} = '16213/20180417_U-ID40472';
basedir{cnt} = '7T_SERPENT_PILOT_WAC';
blocksin_folders{cnt} = {'Series_028_mp2rage_sag_p3_0.75mm_UNI_Images','Series_029_mp2rage_sag_p3_0.75mm_INV2','Series_018_cmrr_mbep2d_3x2_1.5iso_380vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_024_cmrr_mbep2d_3x2_1.5iso_340vols','Series_026_cmrr_mbep2d_3x2_1.5iso_340vols','Series_019_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_021_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'};
blocksin{cnt} = {'DATA_0028.nii', 'DATA_0029.nii', 'DATA_0018.nii', 'DATA_0020.nii', 'DATA_0024.nii', 'DATA_0026.nii', 'DATA_0019.nii','DATA_0021.nii'};
blocksout{cnt} = {'structural', 'INV2', 'Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
minvols(cnt) = 340;
group(cnt) = 1;

