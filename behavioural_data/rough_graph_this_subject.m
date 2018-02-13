function [ all_response_averages, all_rt_averages] = rough_graph_this_subject( subject, date )

all_files = ls(['*' subject '*' num2str(date) '.mat'])

all_runs_resps =[]; 
all_runs_rts = [];
for i = size(all_files,1):-1:1
    load(all_files(i,:))
    all_runs_resps = [all_runs_resps, resp(resp~=0)];
    all_runs_rts = [all_runs_rts, all_rts(all_rts~=0)];
end

all_response_averages = [nanmean(all_runs_resps(this_vocoder_channels==1&this_cue_types==1)) nanmean(all_runs_resps(this_vocoder_channels==1&this_cue_types==2)) nanmean(all_runs_resps(this_vocoder_channels==1&this_cue_types==3)) nanmean(all_runs_resps(this_vocoder_channels==2&this_cue_types==1)) nanmean(all_runs_resps(this_vocoder_channels==2&this_cue_types==2)) nanmean(all_runs_resps(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_response_averages)
ylim([1 4])
title('Clarity Rating')
all_rt_averages = [nanmean(all_runs_rts(this_vocoder_channels==1&this_cue_types==1)) nanmean(all_runs_rts(this_vocoder_channels==1&this_cue_types==2)) nanmean(all_runs_rts(this_vocoder_channels==1&this_cue_types==3)) nanmean(all_runs_rts(this_vocoder_channels==2&this_cue_types==1)) nanmean(all_runs_rts(this_vocoder_channels==2&this_cue_types==2)) nanmean(all_runs_rts(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_rt_averages)
title('nanmean RT')
all_rt_averages = [nanmedian(all_runs_rts(this_vocoder_channels==1&this_cue_types==1)) median(all_runs_rts(this_vocoder_channels==1&this_cue_types==2)) median(all_runs_rts(this_vocoder_channels==1&this_cue_types==3)) median(all_runs_rts(this_vocoder_channels==2&this_cue_types==1)) median(all_runs_rts(this_vocoder_channels==2&this_cue_types==2)) median(all_runs_rts(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_rt_averages)
title('Median RT')

end

