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
preprocessedpathstem = '/imaging/tc02/7T_pilot_preprocessed/';

% % define conditions
% 16M4 16M12 16MM4 16MM12 16WO 16R BP Null 6Mov
conditions = {'Match 4' 'Match 12' 'Mismatch 4' 'Mismatch 12' 'Written'};
% 
% contrast_labels = {'Sum all conditions';'Match-MisMatch'; 'Clear minus Unclear'; 'Gradient difference M-MM'};
% contrast_weights = [1, 1, 1, 1, 1, 1; -1, 1, -1, 1, -1, 1; -1, -1, 0, 0, 1, 1; -1, 1, 0, 0, 1, -1];    

% define subjects and blocks (group(cnt) = 1 for controls initial visit, group(cnt) = 2 for patients initial visit, group(cnt) = 3 for controls follow up, group(cnt) = 4 for patients follow up)
cnt = 0;

cnt = cnt + 1;
subjects{cnt} = 'KP2';
dates{cnt} = '20180208';
fullid{cnt} = '20180208_U-ID39822';
basedir{cnt} = '7T_full_paradigm_pilot_third_kp';
blocksin_folders{cnt} = {'Series_026_a_tfl_uk7t_mp2rage_matched_UNI_Images', 'Series_012_cmrr_mbep2d_3x2_sparse_SEGref_300vols', 'Series_014_cmrr_mbep2d_3x2_sparse_SEGref_300vols', 'Series_016_cmrr_mbep2d_3x2_sparse_SEGref_300vols', 'Series_018_cmrr_mbep2d_3x2_sparse_SEGref_300vols', 'Series_017_cmrr_mbep2d_3x2_sparse_SEGref_300vols_SBRef', 'Series_019_cmrr_mbep2d_3x2_sparse_SEGref_5vols_REV_SBRef'};
blocksin{cnt} = {'Mag_1_PSIR.nii', 'DATA_0012.nii', 'DATA_0014.nii', 'DATA_0016.nii', 'DATA_0018.nii', 'DATA_0017.nii', 'DATA_0019.nii'};
blocksout{cnt} = {'structural','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'};
minvols(cnt) = 213; %The minumum number of volumes in any EPI run
group(cnt) = 1;

cnt = cnt + 1;
subjects{cnt} = 'AM';
dates{cnt} = '20171215';
fullid{cnt} = '20171215_U-ID39471';
basedir{cnt} = '7T_full_paradigm_pilot_third_am';
blocksin_folders{cnt} = {'Series_011_mp2rage_sag_p3_0.75mm_UNI_Images','Series_008_cmrr_mbep2d_3x2_sparse_SEGref_300vols','Series_012_cmrr_mbep2d_3x2_sparse_SEGref_226vols','Series_014_cmrr_mbep2d_3x2_sparse_SEGref_220vols','Series_007_cmrr_mbep2d_3x2_sparse_SEGref_300vols_SBRef','Series_009_cmrr_mbep2d_3x2_sparse_SEGref_300vols_invPE_SBRef'};
blocksin{cnt} = {'DATA_0011.nii', 'DATA_0008.nii', 'DATA_0012.nii', 'DATA_0014.nii', 'DATA_0007.nii', 'DATA_0009.nii'};
blocksout{cnt} = {'structural','Run_1','Run_2','Run_3','Pos_topup','Neg_topup'};
minvols(cnt) = 220;
group(cnt) = 1;
