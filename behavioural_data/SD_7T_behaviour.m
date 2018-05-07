function [ all_response_averages, all_rt_averages] = SD_7T_behaviour( subject, date )

all_files = ls(['*' subject '*' num2str(date) '.mat']);
%all_files = ['AFC_7T_' subject '_Run_' num2str(runnum) '_' num2str(date) '.mat'];

all_runs_resps = []; 
all_runs_rts = [];
all_runs_resp_corr = [];
for i = size(all_files,1):-1:1
    load(all_files(i,:))
    all_runs_resps = [all_runs_resps, resp(resp~=0)];
    resp_corr = abs(resp(resp~=0)-2)==response_order;
    all_runs_resp_corr = [all_runs_resp_corr, resp_corr];
    all_runs_rts = [all_runs_rts, all_rts(all_rts~=0)];
end

all_response_averages = 100*nanmean(all_runs_resp_corr);
all_rt_averages = nanmean(all_runs_rts);

end

