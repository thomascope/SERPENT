function [startpulses,stimType,stim_type_labels] = extract_pulsenumbers_from_SD_paradigm(fileName,runI)

%A function for outputting the values required for MVPA. 
%Stilltodo: Divide mismatches by vowel transition. 
%Sort out response trials if we want to decode these.

load(fileName)

startpulses = imputed_pulse_numbers_at_normal_trialstart;

% there were 8 conditions - Match low, Match high, Mismatch low, Mismatch high, Neutral low, Neutral high, Writtenonly, Response
stimType = zeros(1,length(startpulses));

for i = 1:length(this_style);
    if this_style(i) == 1
        if this_frequency(i)  == 1
            if this_directions(i)== 1
                stimType(i) = this_category(i);
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(1*max(this_category));
            end
        elseif this_frequency(i)  == 2
            if this_directions(i)== 1
                stimType(i) = this_category(i)+(2*max(this_category));
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(3*max(this_category));
            end
            
        elseif this_frequency(i)  == 3
            if this_directions(i)== 1
                stimType(i) = this_category(i)+(4*max(this_category));
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(5*max(this_category));
            end
        end
    elseif this_style(i) == 2
        if this_frequency(i)  == 1
            if this_directions(i)== 1
                stimType(i) = this_category(i)+(6*max(this_category));
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(7*max(this_category));
            end
        elseif this_frequency(i)  == 2
            if this_directions(i)== 1
                stimType(i) = this_category(i)+(8*max(this_category));
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(9*max(this_category));
            end
            
        elseif this_frequency(i)  == 3
            if this_directions(i)== 1
                stimType(i) = this_category(i)+(10*max(this_category));
            elseif this_directions(i)== 2
                stimType(i) = this_category(i)+(11*max(this_category));
            end
        end
    end
end

stim_type_labels = allcomb(styledir, frequency_labels, direction_labels, category_labels);

if exist('imputed_pulse_numbers_at_null_trialstart','var')
    startpulses = [startpulses imputed_pulse_numbers_at_null_trialstart];
    stimType = [stimType repmat(max(stimType)+1,size(imputed_pulse_numbers_at_null_trialstart,1),size(imputed_pulse_numbers_at_null_trialstart,2))];
    null_type_labels = {'null','null','null','null'};
    %null_type_labels = repmat(null_type_labels,size(imputed_pulse_numbers_at_null_trialstart,2),1);
    stim_type_labels = [stim_type_labels;null_type_labels];
end
     
    

end