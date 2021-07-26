function outfile = spm_imcalc_exp(im1,im2)
%%spm_imcalc_exp(im1,im2)
%Multiply two images together. There is no rescaling to 4096.
spm('Defaults','pet');
spm_jobman('initcfg');

[apath,afile,anext]=fileparts(im1);

outfile=fullfile(apath,strcat(afile,'_mul_inv2',anext));

%-----------------------------------------------------------------------
% Job saved on 14-Jul-2021 20:58:28 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.imcalc.input = {
                                        im1
                                        im2
                                        };
matlabbatch{1}.spm.util.imcalc.output = outfile;
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*i2';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 0;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm_jobman('run',matlabbatch);

disp(['Finished ' outfile '.']) 