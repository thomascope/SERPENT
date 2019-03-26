function [startpulses,stimType,stimNumber,stimName] = extract_pulsenumbers_from_AFC_paradigm(fileName,runI)

%A function for outputting the values required for MVPA. 
%Stilltodo: Divide mismatches by vowel transition. 
%Sort out response trials if we want to decode these.

load(fileName)

startpulses = [imputed_pulse_numbers_at_normal_trialstart, imputed_pulse_numbers_at_writtenonly_trialstart, imputed_pulse_numbers_at_response_trialstart];

% there were 8 conditions - Match low, Match high, Mismatch low, Mismatch high, Neutral low, Neutral high, Writtenonly, Response
stimType = zeros(1,length(startpulses));

for i = 1:length(this_cue_types);
    if this_cue_types(i) == 1
        if this_vocoder_channels(i)  == 1
            stimType(i) = 1;
        elseif this_vocoder_channels(i)  == 2
            stimType(i) = 2;
        end
    elseif this_cue_types(i) == 2
        if this_vocoder_channels(i)  == 1
            stimType(i) = 3;
        elseif this_vocoder_channels(i)  == 2
            stimType(i) = 4;
        end
    elseif this_cue_types(i) == 3
        if this_vocoder_channels(i)  == 1
            stimType(i) = 5;
        elseif this_vocoder_channels(i)  == 2
            stimType(i) = 6;
        end
    end
end

stimType(i+1:i+length(imputed_pulse_numbers_at_writtenonly_trialstart)) = 7;
stimType(i+1+length(imputed_pulse_numbers_at_writtenonly_trialstart):end) = 8;

% there were 16 words 
stimNumber = this_word; %Easy for the normal trials as recorded by the delivery script

%The below will need to be corrected when I have a less stupid way of
%defining the trials
    
written_indexC = strfind(trialtype,'Written Only');
written_index = find(not(cellfun('isempty', written_indexC)));
for i = 1:length(written_index)
    j = i+(length(imputed_pulse_numbers_at_writtenonly_trialstart)*(runI-1));
    this_code = length(response_order.this_cue_types)+1-j;
    if strcmp('Match',cue_types{response_order.this_cue_types(j)}) 
        stimNumber(end+1) = response_order.this_word(this_code);
    elseif strcmp('MisMatch',cue_types{response_order.this_cue_types(j)})
        stimNumber(end+1) = response_order.this_word(this_code);
    elseif strcmp('Neutral',cue_types{response_order.this_cue_types(j)})
        stimNumber(end+1) = response_order.this_word(this_code);
    end
end

response_indexC = strfind(trialtype,'Response Trial');
response_index = find(not(cellfun('isempty', response_indexC)));
for i = 1:length(response_index)
    j = i+(length(imputed_pulse_numbers_at_writtenonly_trialstart)*(runI-1));
    if strcmp('Match',cue_types{response_order.this_cue_types(j)}) 
        stimNumber(end+1) = response_order.this_word(j);
    elseif strcmp('MisMatch',cue_types{response_order.this_cue_types(j)})
        stimNumber(end+1) = response_order.this_word(j);
    elseif strcmp('Neutral',cue_types{response_order.this_cue_types(j)})
        stimNumber(end+1) = response_order.this_word(j);
    end
end

stimName = wordlist;

end