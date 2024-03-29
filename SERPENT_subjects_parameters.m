%% Set up global variables 

%clear all

% add required paths
addpath(pwd);
% addpath('/group/language/data/ediz.sohoglu/matlab/utilities/');
% addpath('/opt/neuromag/meg_pd_1.2/');

% define paths
rawpathstem = '/imaging/mlr/users/tc02/';
preprocessedpathstem = '/imaging/mlr/users/tc02/SERPENT_preprocessed_2021/';

% % define conditions
% conditions = {'Mismatch_4' 'Match_4' 'Mismatch_8' 'Match_8' 'Mismatch_16' 'Match_16'};
% 
% contrast_labels = {'Sum all conditions';'Match-MisMatch'; 'Clear minus Unclear'; 'Gradient difference M-MM'};
% contrast_weights = [1, 1, 1, 1, 1, 1; -1, 1, -1, 1, -1, 1; -1, -1, 0, 0, 1, 1; -1, 1, 0, 0, 1, -1];
% conditions = {'Match 3' 'Match 15' 'Mismatch 3' 'Mismatch 15' 'Written'};

cnt = 0; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C01'; 
dates{cnt} = '20180501'; 
fullid{cnt} = '26934/20180501_U-ID40637'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P01'; 
dates{cnt} = '20180502'; 
fullid{cnt} = '25602/20180502_U-ID40642'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P02'; 
dates{cnt} = '20180525'; 
fullid{cnt} = '25243/20180525_U-ID40645'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C02'; 
dates{cnt} = '20180605'; 
fullid{cnt} = '26510/20180605_U-ID41003'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C03'; 
dates{cnt} = '20180619'; 
fullid{cnt} = '26599/20180619_U-ID41125'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P03'; 
dates{cnt} = '20180621'; 
fullid{cnt} = '26269/20180621_U-ID41166'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C04'; 
dates{cnt} = '20180625'; 
fullid{cnt} = '26566/20180625_U-ID41172'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P04'; 
dates{cnt} = '20180628'; 
fullid{cnt} = '27185/20180628_U-ID41223'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C05'; 
dates{cnt} = '20180703'; 
fullid{cnt} = '26799/20180703_U-ID40969'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C06'; 
dates{cnt} = '20180717'; 
fullid{cnt} = '27261/20180717_U-ID41405'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P05'; 
dates{cnt} = '20180724'; 
fullid{cnt} = '26495/20180724_U-ID40646'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P06'; 
dates{cnt} = '20180725'; 
fullid{cnt} = '25785/20180725_U-ID41224'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_028_mp2rage_sag_p3_0.75mm_UNI_Images','Series_029_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_026_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_024_cmrr_mbep2d_3x2_1.5iso_340vols','Series_019_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_021_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0028.nii','DATA_0029.nii','DATA_0010.nii','DATA_0026.nii','DATA_0020.nii','DATA_0024.nii','DATA_0019.nii','DATA_0021.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P07'; 
dates{cnt} = '20180726'; 
fullid{cnt} = '25162/20180726_U-ID41509'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P09'; 
dates{cnt} = '20180913'; 
fullid{cnt} = '25946/20180913_U-ID41295'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_025_mp2rage_sag_p3_0.75mm_UNI_Images','Series_024_mp2rage_sag_p3_0.75mm_INV2','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_022_cmrr_mbep2d_3x2_1.5iso_340vols','Series_015_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_017_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0025.nii','DATA_0024.nii','DATA_0012.nii','DATA_0016.nii','DATA_0020.nii','DATA_0022.nii','DATA_0015.nii','DATA_0017.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P10'; 
dates{cnt} = '20180914'; 
fullid{cnt} = '27531/20180914_U-ID42024'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P11'; 
dates{cnt} = '20180924'; 
fullid{cnt} = '27212/20180924_U-ID41294'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_026_mp2rage_sag_p3_0.75mm_UNI_Images','Series_027_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0026.nii','DATA_0027.nii','DATA_0010.nii','DATA_0012.nii','DATA_0018.nii','DATA_0020.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C07'; 
dates{cnt} = '20181001'; 
fullid{cnt} = '27391/20181001_U-ID41707'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P12'; 
dates{cnt} = '20181018'; 
fullid{cnt} = '27672/20181018_U-ID42387'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P13'; 
dates{cnt} = '20181025'; 
fullid{cnt} = '25806/20181025_U-ID42218'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_023_mp2rage_sag_p3_0.75mm_UNI_Images','Series_022_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0023.nii','DATA_0022.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0020.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C08'; 
dates{cnt} = '20181102'; 
fullid{cnt} = '27392/20181102_U-ID42446'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P14'; 
dates{cnt} = '20181107'; 
fullid{cnt} = '27720/20181107_U-ID42524'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P15'; 
dates{cnt} = '20181120'; 
fullid{cnt} = '25548/20181120_U-ID42216'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P16'; 
dates{cnt} = '20181126'; 
fullid{cnt} = '27907/20181126_U-ID42866'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C09'; 
dates{cnt} = '20181126'; 
fullid{cnt} = '27000/20181126_U-ID42461'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C10'; 
dates{cnt} = '20181128'; 
fullid{cnt} = '27065/20181128_U-ID42871'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C11'; 
dates{cnt} = '20200921'; 
fullid{cnt} = '24905/20200921_U-ID49970'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P18'; 
dates{cnt} = '20201007'; 
fullid{cnt} = '31180/20201007_U-ID50160'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_008_mp2rage_sag_p3_0.75mm_UNI_Images','Series_009_mp2rage_sag_p3_0.75mm_INV2','Series_017_cmrr_mbep2d_3x2_1.5iso_340vols','Series_019_cmrr_mbep2d_3x2_1.5iso_340vols','Series_023_cmrr_mbep2d_3x2_1.5iso_340vols','Series_032_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_020_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0008.nii','DATA_0009.nii','DATA_0017.nii','DATA_0019.nii','DATA_0023.nii','DATA_0032.nii','DATA_0018.nii','DATA_0020.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C12'; 
dates{cnt} = '20201009'; 
fullid{cnt} = '31216/20201009_U-ID50227'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_024_mp2rage_sag_p3_0.75mm_UNI_Images','Series_025_mp2rage_sag_p3_0.75mm_INV2','Series_014_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_022_cmrr_mbep2d_3x2_1.5iso_340vols','Series_015_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_017_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0024.nii','DATA_0025.nii','DATA_0014.nii','DATA_0016.nii','DATA_0020.nii','DATA_0022.nii','DATA_0015.nii','DATA_0017.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C13'; 
dates{cnt} = '20201014'; 
fullid{cnt} = '31228/20201014_U-ID50274'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C15'; 
dates{cnt} = '20201019'; 
fullid{cnt} = '31231/20201019_U-ID50277'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C16'; 
dates{cnt} = '20201030'; 
fullid{cnt} = '31245/20201030_U-ID50314'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C17'; 
dates{cnt} = '20201102'; 
fullid{cnt} = '31319/20201102_U-ID50513'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C18'; 
dates{cnt} = '20201104'; 
fullid{cnt} = '24379/20201104_U-ID50454'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P20'; 
dates{cnt} = '20201109'; 
fullid{cnt} = '31366/20201109_U-ID50616'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_023_mp2rage_sag_p3_0.75mm_UNI_Images','Series_022_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0023.nii','DATA_0022.nii','DATA_0010.nii','DATA_0012.nii','DATA_0018.nii','DATA_0020.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C19'; 
dates{cnt} = '20201111'; 
fullid{cnt} = '27120/20201111_U-ID50639'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P21'; 
dates{cnt} = '20201112'; 
fullid{cnt} = '31375/20201112_U-ID50652'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C20'; 
dates{cnt} = '20201116'; 
fullid{cnt} = '31372/20201116_U-ID50641'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_024_mp2rage_sag_p3_0.75mm_UNI_Images','Series_025_mp2rage_sag_p3_0.75mm_INV2','Series_014_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_022_cmrr_mbep2d_3x2_1.5iso_340vols','Series_015_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_017_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0024.nii','DATA_0025.nii','DATA_0014.nii','DATA_0016.nii','DATA_0020.nii','DATA_0022.nii','DATA_0015.nii','DATA_0017.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C21'; 
dates{cnt} = '20201118'; 
fullid{cnt} = '31371/20201118_U-ID50640'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C22'; 
dates{cnt} = '20201119'; 
fullid{cnt} = '31301/20201119_U-ID50451'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_022_mp2rage_sag_p3_0.75mm_UNI_Images','Series_023_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_020_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0022.nii','DATA_0023.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0020.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7C23'; 
dates{cnt} = '20201125'; 
fullid{cnt} = '31303/20201125_U-ID50455'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_020_mp2rage_sag_p3_0.75mm_UNI_Images','Series_021_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0020.nii','DATA_0021.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 1; 

cnt = cnt + 1; 
subjects{cnt} = 'S7P23'; 
dates{cnt} = '20210107'; 
fullid{cnt} = '31604/20210107_U-ID51183'; 
basedir{cnt} = 'SERPENT'; 
blocksin_folders{cnt} = {'Series_021_mp2rage_sag_p3_0.75mm_UNI_Images','Series_020_mp2rage_sag_p3_0.75mm_INV2','Series_010_cmrr_mbep2d_3x2_1.5iso_340vols','Series_012_cmrr_mbep2d_3x2_1.5iso_340vols','Series_016_cmrr_mbep2d_3x2_1.5iso_340vols','Series_018_cmrr_mbep2d_3x2_1.5iso_340vols','Series_011_cmrr_mbep2d_3x2_1.5iso_340vols_SBRef','Series_013_cmrr_mbep2d_3x2_1.5iso_invPE_SBRef'}; 
blocksin{cnt} = {'DATA_0021.nii','DATA_0020.nii','DATA_0010.nii','DATA_0012.nii','DATA_0016.nii','DATA_0018.nii','DATA_0011.nii','DATA_0013.nii'}; 
blocksout{cnt} = {'structural','INV2','Run_1','Run_2','Run_3','Run_4','Pos_topup','Neg_topup'}; 
minvols(cnt) = 340; 
group(cnt) = 2; 

