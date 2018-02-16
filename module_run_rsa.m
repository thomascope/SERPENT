function [avgRDM, stats_p_r] = module_run_rsa(crun,cond_num,mask_name,condition,data_smoo)

pilot_7T_subjects_parameters

data_path = [preprocessedpathstem subjects{crun} '/stats_multi_' num2str(data_smoo) '/'];
mask_path = [preprocessedpathstem subjects{crun} '/' mask_name];
tpattern_numbers = 9+[1:16]+(16*(cond_num-1));
[avgRDM, stats_p_r] = module_rsa_job(tpattern_numbers,mask_path,data_path,cond_num,condition);

save(['./RSA_results/RSA_results_subj' num2str(crun) '_' condition '_mask_' mask_name(1:end-4) '_smooth_' num2str(data_smoo)],'avgRDM','stats_p_r')

