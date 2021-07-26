function make_cat12_segments(uni,inv1,inv2)
% make_cat12_segments.m
% Create segments for VBM and bias correccted Denosied image

do_crop=1;
do_robust=0; %Use modified O'Brien or simpler multiplicative method

try
  spm quit;
%   clear all;
  
  spm_rmpath;
end

addpath /rds/project/rds-k1PgZFWfeZY/applications/spm/spm12_7771/
clear global;

addpath '/rds/project/rds-k1PgZFWfeZY/applications/spm/spm_tools';
addpath '/rds/project/rds-k1PgZFWfeZY/applications/spm/spm_tools/crop';
addpath '/rds/project/rds-k1PgZFWfeZY/applications/spm/spm_tools/mp2rage_scripts';

pout={uni;inv1;inv2};

%% ac-pc all images
if do_crop
    pout=crop_images({uni;inv1;inv2}, 3);
end

if do_robust
    cat12in=removebackgroundnoise(pout{1},pout{2},pout{3});
else
    cat12in=spm_imcalc_exp(pout{1},pout{3});
end

cat12_segment_v1742(cat12in);
