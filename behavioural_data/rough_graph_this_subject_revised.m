function [ all_response_averages, all_rt_averages] = rough_graph_this_subject_revised( subject, date )

all_files = ls(['*' subject '*' num2str(date) '.mat']);

all_runs_resps = []; 
all_runs_rts = [];
for i = size(all_files,1):-1:1
    load(all_files(i,:))
    all_runs_resps = [all_runs_resps, resp(resp~=0)];
    all_runs_rts = [all_runs_rts, all_rts(all_rts~=0)];
end

nanpadded_runs_resps = [NaN(1,(size(response_order.this_vocoder_channels,2)-size(all_runs_resps,2))) all_runs_resps]
nanpadded_runs_rts = [NaN(1,(size(response_order.this_vocoder_channels,2)-size(all_runs_rts,2))) all_runs_rts]
all_response_averages = [nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==1&response_order.this_cue_types==1)) nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==1&response_order.this_cue_types==2)) nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==1&response_order.this_cue_types==3)) nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==2&response_order.this_cue_types==1)) nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==2&response_order.this_cue_types==2)) nanmean(nanpadded_runs_resps(response_order.this_vocoder_channels==2&response_order.this_cue_types==3))]
figure
bar(all_response_averages)
ylim([1 4])
title('Clarity Rating')
set(gca,'XTickLabel',{'Match 4','Mismatch 4','Neutral 4','Match 16','Mismatch 16','Neutral 16'},'XTickLabelRotation',15)
all_rt_averages = [nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==1)) nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==2)) nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==3)) nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==1)) nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==2)) nanmean(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==3))]
figure
bar(all_rt_averages)
title('nanmean RT')
set(gca,'XTickLabel',{'Match 4','Mismatch 4','Neutral 4','Match 16','Mismatch 16','Neutral 16'},'XTickLabelRotation',15)
all_rt_averages = [nanmedian(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==1)) median(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==2)) median(nanpadded_runs_rts(response_order.this_vocoder_channels==1&response_order.this_cue_types==3)) median(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==1)) median(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==2)) median(nanpadded_runs_rts(response_order.this_vocoder_channels==2&response_order.this_cue_types==3))]
figure
bar(all_rt_averages)
title('Median RT')
set(gca,'XTickLabel',{'Match 4','Mismatch 4','Neutral 4','Match 16','Mismatch 16','Neutral 16'},'XTickLabelRotation',15)

end

