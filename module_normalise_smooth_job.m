%-----------------------------------------------------------------------
% Job saved on 14-Feb-2018 16:05:14 by cfg_util (rev $Rev: 6942 $)
% spm SPM - SPM12 (7219)
%-----------------------------------------------------------------------
matlabbatch{1}.spm.spatial.normalise.write.subj.def = '<UNDEFINED>';
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = '<UNDEFINED>';
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1.5 1.5 1.5];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
matlabbatch{2}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{2}.spm.spatial.smooth.fwhm = [3 3 3];
matlabbatch{2}.spm.spatial.smooth.dtype = 0;
matlabbatch{2}.spm.spatial.smooth.im = 0;
matlabbatch{2}.spm.spatial.smooth.prefix = 's3';
matlabbatch{3}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{3}.spm.spatial.smooth.fwhm = [8 8 8];
matlabbatch{3}.spm.spatial.smooth.dtype = 0;
matlabbatch{3}.spm.spatial.smooth.im = 0;
matlabbatch{3}.spm.spatial.smooth.prefix = 's8';
matlabbatch{4}.spm.spatial.normalise.write.subj.def = '<UNDEFINED>';
matlabbatch{4}.spm.spatial.normalise.write.subj.resample = '<UNDEFINED>';
matlabbatch{4}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{4}.spm.spatial.normalise.write.woptions.vox = [1.4 1.4 1.4];
matlabbatch{4}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{4}.spm.spatial.normalise.write.woptions.prefix = 'w';
matlabbatch{5}.spm.spatial.normalise.write.subj.def = '<UNDEFINED>';
matlabbatch{5}.spm.spatial.normalise.write.subj.resample = '<UNDEFINED>';
matlabbatch{5}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{5}.spm.spatial.normalise.write.woptions.vox = [1.4 1.4 1.4];
matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 0;
matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = 'mask_';
