function [ all_response_averages, all_rt_averages, is_reversed] = SD_7T_behaviour_withnull( subject, date )

draw_fig = 0; 

all_files = dir(['*' subject '*' num2str(date) '.mat']);
%all_files = ['AFC_7T_' subject '_Run_' num2str(runnum) '_' num2str(date) '.mat'];

all_runs_resps = [];
all_runs_rts = [];
all_runs_resp_corr = [];

load(all_files(1).name)
reversed = zeros(1,size(all_files,1));
if exist('null_trials','var')
    
    for i = 1:size(all_files,1)
        load(all_files(i).name)
        all_runs_resps = [all_runs_resps, resp(resp~=0), null_resp(null_resp~=0)];
        resp_corr = [abs(resp(resp~=0)-2)==response_order, abs(null_resp(null_resp~=0)-2)==null_response_order];
        if mean(resp_corr)<0.5 %Assume buttons reversed)
            old_resp_corr = resp_corr;
            resp_corr = [abs(resp(resp~=0)-3)==response_order, abs(null_resp(null_resp~=0)-3)==null_response_order];
            if mean(resp_corr) > mean(old_resp_corr)
                reversed(i) = 1;
            else
                resp_corr = old_resp_corr;
            end
        end
        all_runs_resp_corr = [all_runs_resp_corr, resp_corr];
        all_runs_rts = [all_runs_rts, all_rts(all_rts~=0), all_null_rts(all_null_rts~=0)];
    end
    
else
    
    for i = 1:size(all_files,1)
        load(all_files(i).name)
        all_runs_resps = [all_runs_resps, resp(resp~=0)];
        resp_corr = abs(resp(resp~=0)-2)==response_order;
        if mean(resp_corr)<0.5 %Assume buttons reversed)
            old_resp_corr = resp_corr;
            resp_corr = abs(resp(resp~=0)-3)==response_order;
            if mean(resp_corr) > mean(old_resp_corr)
                reversed(i) = 1;
            else
                resp_corr = old_resp_corr;
            end
        end
        all_runs_resp_corr = [all_runs_resp_corr, resp_corr];
        all_runs_rts = [all_runs_rts, all_rts(all_rts~=0)];
    end
    
end

all_response_averages = 100*nanmean(all_runs_resp_corr);
all_rt_averages = nanmean(all_runs_rts);

if draw_fig
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

is_reversed = round(mean(reversed));

end
