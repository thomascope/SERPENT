matlabbatch{1}.spm.stats.factorial_design.dir = {'/imaging/tc02/SERPENT_preprocessed/Category_within_modality_subsamp3_29-Jun-2018'};
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = {
'/imaging/tc02/SERPENT_preprocessed/S7C01/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7C02/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7C03/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7C04/searchvolumes/Category_within_modality_subsamp3.nii,1'
};
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = {
'/imaging/tc02/SERPENT_preprocessed/S7P01/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7P02/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7P03/searchvolumes/Category_within_modality_subsamp3.nii,1'
'/imaging/tc02/SERPENT_preprocessed/S7P04/searchvolumes/Category_within_modality_subsamp3.nii,1'
};
matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Controls';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Patients';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 1];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'Controls+Patients';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [1 1];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'Controls > Patients';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [1 -1];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'Patients > Controls';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [-1 1];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'Negative all';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [-1 -1];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;
matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'))
matlabbatch{4}.spm.stats.results.conspec.titlestr = ''
matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf
matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none'
matlabbatch{4}.spm.stats.results.conspec.thresh = 0.01
matlabbatch{4}.spm.stats.results.conspec.extent = 0
matlabbatch{4}.spm.stats.results.conspec.conjunction = 1
matlabbatch{4}.spm.stats.results.conspec.mask.none = 1
matlabbatch{4}.spm.stats.results.units = 1
matlabbatch{4}.spm.stats.results.export{1}.ps = true
