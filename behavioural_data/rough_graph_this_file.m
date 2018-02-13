function [ all_response_averages, all_rt_averages] = rough_graph_this_file( this_file )
load(this_file)

all_response_averages = [mean(resp(this_vocoder_channels==1&this_cue_types==1)) mean(resp(this_vocoder_channels==1&this_cue_types==2)) mean(resp(this_vocoder_channels==1&this_cue_types==3)) mean(resp(this_vocoder_channels==2&this_cue_types==1)) mean(resp(this_vocoder_channels==2&this_cue_types==2)) mean(resp(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_response_averages)
ylim([1 4])
title('Clarity Rating')
all_rt_averages = [mean(all_rts(this_vocoder_channels==1&this_cue_types==1)) mean(all_rts(this_vocoder_channels==1&this_cue_types==2)) mean(all_rts(this_vocoder_channels==1&this_cue_types==3)) mean(all_rts(this_vocoder_channels==2&this_cue_types==1)) mean(all_rts(this_vocoder_channels==2&this_cue_types==2)) mean(all_rts(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_rt_averages)
title('Mean RT')
all_rt_averages = [median(all_rts(this_vocoder_channels==1&this_cue_types==1)) median(all_rts(this_vocoder_channels==1&this_cue_types==2)) median(all_rts(this_vocoder_channels==1&this_cue_types==3)) median(all_rts(this_vocoder_channels==2&this_cue_types==1)) median(all_rts(this_vocoder_channels==2&this_cue_types==2)) median(all_rts(this_vocoder_channels==2&this_cue_types==3))]
figure
bar(all_rt_averages)
title('Median RT')

end

