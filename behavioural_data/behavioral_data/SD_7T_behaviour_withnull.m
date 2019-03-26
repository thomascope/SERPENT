function [ all_response_averages, all_rt_averages] = SD_7T_behaviour_withnull( subject, date )

all_files = ls(['*' subject '*' num2str(date) '.mat']);
%all_files = ['AFC_7T_' subject '_Run_' num2str(runnum) '_' num2str(date) '.mat'];

all_runs_resps = []; 
all_runs_rts = [];
all_runs_resp_corr = [];

load(all_files(1,:))
if exist('null_trials','var')
    
    for i = 1:size(all_files,1)
    load(all_files(i,:))
    all_runs_resps = [all_runs_resps, resp(resp~=0), null_resp(null_resp~=0)];
    resp_corr = [abs(resp(resp~=0)-2)==response_order, abs(null_resp(null_resp~=0)-2)==null_response_order];
    all_runs_resp_corr = [all_runs_resp_corr, resp_corr];
    all_runs_rts = [all_runs_rts, all_rts(all_rts~=0), all_null_rts(all_null_rts~=0)];
end

else

for i = 1:size(all_files,1)
    load(all_files(i,:))
    all_runs_resps = [all_runs_resps, resp(resp~=0)];
    resp_corr = abs(resp(resp~=0)-2)==response_order;
    all_runs_resp_corr = [all_runs_resp_corr, resp_corr];
    all_runs_rts = [all_runs_rts, all_rts(all_rts~=0)];
end

end

all_response_averages = 100*nanmean(all_runs_resp_corr);
all_rt_averages = nanmean(all_runs_rts);

figure
plot(all_runs_resp_corr)
ylabel('Correct')
xlabel('Trial Number')
ylim([0 1.1])
figure
plot(all_runs_rts)
ylabel('Reaction Time (ms)')
xlabel('Trial Number')
ylim([0 3000])

end
