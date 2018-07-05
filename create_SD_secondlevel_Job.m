function jobfile = create_SD_secondlevel_Job(preprocessedpathstem, conditionname, subjects, group)
%A function for creating a second level SPM for searchlight volumes of
% specified condition

jobfile = ['/group/language/data/thomascope/7T_SERPENT_pilot_analysis/SD_secondlevel_jobfiles/Secondlevel_' conditionname '_job.m'];
fileID = fopen(jobfile,'w');

%Set up directory for output
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.dir = {''' char(preprocessedpathstem) conditionname '_' num2str(date) '''};\n']);

%Set up scans for input
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = {\n']);
for this_subj = 1:length(subjects)
    if group(this_subj) == 1;
        fprintf(fileID,['''' preprocessedpathstem subjects{this_subj} '/searchvolumes/' conditionname '.nii,1''\n']);
    end    
end
fprintf(fileID,['};\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = {\n']);
for this_subj = 1:length(subjects)
    if group(this_subj) == 2;
        fprintf(fileID,['''' preprocessedpathstem subjects{this_subj} '/searchvolumes/' conditionname '.nii,1''\n']);
    end    
end
fprintf(fileID,['};\n']);

%Now the rest should be standard

fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.cov = struct(''c'', {}, ''cname'', {}, ''iCFI'', {}, ''iCC'', {});\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct(''files'', {}, ''iCFI'', {}, ''iCC'', {});\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.masking.em = {''''};\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;\n']);
fprintf(fileID,['matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;\n']);

fprintf(fileID,['matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep(''Factorial design specification: SPM.mat File'', substruct(''.'',''val'', ''{}'',{1}, ''.'',''val'', ''{}'',{1}, ''.'',''val'', ''{}'',{1}), substruct(''.'',''spmmat''));\n']);
fprintf(fileID,['matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;\n']);
fprintf(fileID,['matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;\n']);

fprintf(fileID,['matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep(''Model estimation: SPM.mat File'', substruct(''.'',''val'', ''{}'',{1}, ''.'',''val'', ''{}'',{1}, ''.'',''val'', ''{}'',{1}), substruct(''.'',''spmmat''));\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = ''Controls'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = ''Patients'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 1];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = ''Controls+Patients'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [1 1];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = ''Controls > Patients'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [1 -1];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = ''Patients > Controls'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [-1 1];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = ''Negative all'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [-1 -1];\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = ''none'';\n']);
fprintf(fileID,['matlabbatch{3}.spm.stats.con.delete = 0;\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep(''Contrast Manager: SPM.mat File'', substruct(''.'',''val'', ''{}'',{3}, ''.'',''val'', ''{}'',{1}, ''.'',''val'', ''{}'',{1}), substruct(''.'',''spmmat''))\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.titlestr = ''''\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.threshdesc = ''none''\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.thresh = 0.01\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.extent = 0\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.conjunction = 1\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.conspec.mask.none = 1\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.units = 1\n']);
fprintf(fileID,['matlabbatch{4}.spm.stats.results.export{1}.ps = true\n']);

