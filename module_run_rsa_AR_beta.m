function [avgRDM, stats_p_r] = module_run_rsa_AR_beta(crun,cond_num,mask_name,condition,aro)

pilot_7T_subjects_parameters

data_path = [preprocessedpathstem subjects{crun} '/stats3_multi_AR' num2str(aro) '/'];
mask_path = [preprocessedpathstem subjects{crun} '/' mask_name];
sess_files = dir([data_path '/*Sess*SD*']); %Should be one SD image per session
num_sess = size(sess_files,1);
beta_files = dir([data_path '/Cbeta_0*']);
num_betas = (size(beta_files,1)-num_sess)/num_sess; %Should be one regressor per session at the end

betapattern_numbers = zeros(num_sess,16);
for i = 1:num_sess    
    betapattern_numbers(i,:) = [1:16]+((16*(cond_num-1))+(num_betas*(i-1)));
end
[avgRDM, stats_p_r] = module_rsa_beta_job(betapattern_numbers,mask_path,data_path,cond_num,condition,num_sess);

save(['./RSA_results/RSA_results_beta_subj' num2str(crun) '_' condition '_mask_' mask_name(1:end-4) '_AR' num2str(aro)],'avgRDM','stats_p_r')

