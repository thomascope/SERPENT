% function results = decoding_generate_output(cfg,results,decoding_out,i_decoding,curr_decoding,data)
% 
% This function calls all decoding_transform_results for all entries in
% cfg.results.output and saves the returning outputs at results.(outname).
%
% It also handles initialization of output fields if they are not single
% numerical values.
% 
% Try to see it as a black box and ignore it, as far as possible. Look at
%
%   decoding_transform_results 
%
% instead.
%
% Kai, 2013/04/19
%
% Hist: Kai, 2020-06-17: added option to pass chance level using
%   output.output & output.chancelevel. Warning if only .chancelevel.


function results = decoding_generate_output(cfg,results,decoding_out,i_decoding,curr_decoding,data)

n_outputs = length(cfg.results.output);

% in case chance-level is not provided (which should only happen for
% parameter selection or feature selection where it doesn't really matter
chancelevel = 1/results.n_cond_per_step * 100; % chancelevel in percent    

for i_output = 1:n_outputs

    curr_output = cfg.results.output{i_output};
    outname = char(curr_output); % char necessary for classes

    % apply transformation and get result
    output = decoding_transform_results(curr_output,decoding_out,chancelevel,cfg,data);

    % add chancelevel, if we have it
    if strcmpi(outname, 'accuracy') || strcmpi(outname, 'accuracy_minus_chance') || ...
            strcmpi(outname, 'sensitivity') || strcmpi(outname, 'sensitivity_minus_chance') || ...
            strcmpi(outname, 'specificity') || strcmpi(outname, 'specificity_minus_chance') || ...
            strcmpi(outname, 'balanced_accuracy') || strcmpi(outname, 'balanced_accuracy_minus_chance') || ...
            strcmpi(outname, 'AUC') || strcmpi(outname, 'AUC_minus_chance') 
        results.(outname).chancelevel = chancelevel;
    elseif isstruct(output) && isfield(output, 'chancelevel') 
        if isfield(output, 'output') % extra field output that is then taken as output
            results.(outname).chancelevel = output.chancelevel;
            output = output.output;
        else
            warningv('decoding_generate_output:struct_with_chancelevel_but_without_output', ['decoding_generate_output:method ' outname ' returned a struct with .chancelevel, but without .output. If you want to store .chancelevel as normal field, return the remaining output as output.output']);
        end
    else
        % dont save chancelevel 
    end


    % This is a lazy initialization (Martin would call it workaround) for
    % the case in which the output has more than one element (e.g. weights
    % of classifier)
    if iscell(output) && i_decoding == 1
        results.(outname).output = cell(size(results.(outname).output));
    end

    % Lazy initialization, if a struct is returned
    % Create a struct array
    if isstruct(output) && i_decoding == 1
        results.(outname) = rmfield(results.(outname), 'output');
        results.(outname).output(curr_decoding) = output;
    end

    results.(outname).output(curr_decoding) = output;

    if cfg.results.setwise && cfg.design.n_sets > 1
        
        unique_sets = uniqueq(cfg.design.set(:));
        n_sets = cfg.design.n_sets;
        
        for i_set = 1:n_sets
            current_set = unique_sets(i_set);
            set_ind = cfg.design.set == current_set;
            
            cfg_tmp = cfg;
            % reduce design matrix to current set (essentially what cfg
            % should "see" as if there was only this one set)
            cfg_tmp.design.train = cfg.design.train(:,set_ind);
            cfg_tmp.design.test = cfg.design.test(:,set_ind);
            cfg_tmp.design.label = cfg.design.label(:,set_ind);
            cfg_tmp.design.set = cfg.design.set(:,set_ind);
            
            output = decoding_transform_results(curr_output,decoding_out(set_ind),chancelevel,cfg_tmp,data);

            % This is a lazy initialization (Martin would call it workaround) for
            % the case in which the output has more than one element (e.g. weights
            % of classifier)
            if iscell(output) && i_decoding == 1
                results.(outname).set(i_set).output = cell(size(results.(outname).output));
            end

            % Lazy initialization, if a struct is returned
            % Create a struct array
            if isstruct(output) && i_decoding == 1 && i_set == 1
                % reinit set
                results.(outname) = rmfield(results.(outname), 'set');
                results.(outname).set(i_set).output(curr_decoding) = output;
            end

            results.(outname).set(i_set).output(curr_decoding) = output;
            results.(outname).set(i_set).set_id = current_set;
        end
    end
end