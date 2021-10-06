% function [out, regressor_names] = display_regressor_names(beta_loc, compress)
%
% This function gives you an overview over the possible regressor names
% that can be used as labels for a decoding analysis. This is helpful if
% you don't want to look inside the SPM.mat (e.g. with the SPM GUI) or do
% not have the regressor names created in the spm folder, yet.
%
% INPUT:
% beta_loc: The folder where the design matrix is stored as SPM.mat.
%   If beta_loc is not provided, the current folder will be used.
%   Alternatively, the matrix can also be stored in a *_SPM.mat file (e.g.
%   if you want to reduce the filesize when data is passed on to someone else).
%
% OPTIONAL:
%   compress: default 0. If compress = 1, regressors for multiple bins
%       will be summarized in one row as follows
%           yourcondition bin 1..16 (1:6)
%       instead of
%           yourcondition bin 1  (1:6)
%           yourcondition bin 2  (1:6)
%           ...
%           yourcondition bin 16 (1:6)
%
% OUT:
%   out: displayed text as cell, use char(out) to get text
%   regressor_names: Regressor names from design_from_spm.m
% 
% If you want the regressor names as output, use the function
% design_from_spm.m or design_from_afni.m

% Martin H. 2012
%
% History:
% 2016/07/07: Added AFNI compatibility
% 2017-02-05: replaced strsplit with regexp for downward compatibility

function [out, regressor_names] = display_regressor_names(beta_loc, compress)

if ~exist('beta_loc', 'var')
    beta_loc = pwd;
end

if ~exist('compress', 'var')
    compress = 0;
end

if ~ischar(beta_loc) && ~iscell(beta_loc)
    error('Input beta_loc not correctly specified. For SPM, it must be a path to where the SPM.mat is, and for AFNI a path or cell array of paths to where the BRIK files from the deconvolutions are.')
end


decoding_defaults; % use only to add path

try % this is a bit ugly, but quite efficient 
    regressor_names = design_from_spm(beta_loc,0);
catch
    try
    regressor_names = design_from_afni(beta_loc,0);
    catch
        % first check if images exist in that location
        if ischar(beta_loc), file_exists = exist(beta_loc,'file');
        else, file_exists = exist(beta_loc{1},'file'); end
        
        if file_exists
            fprintf('SPM or afni_matlab are likely not on your Matlab path. Please add the relevant software and try again!')
            error(lasterr) %#ok<LERR>
        else
            fprintf('Both SPM and AFNI failed to find beta images in location ''%s''\n',beta_loc)
            error(lasterr) %#ok<LERR>
        end
    end
end

[all_names,b] = unique(regressor_names(1,:),'first');
[ignore,bb] = sort(b); %#ok<ASGLU> % to get the original order
all_names = all_names(bb); % use index to keep the order
all_runs = unique([regressor_names{2,:}]);

n_names = length(all_names);
n_runs = length(all_runs);

all_names_char = char(all_names);

hdr = {sprintf('\nTotal number of regressors: %.0f',size(regressor_names, 2))
       sprintf('Number of different regressors: %.0f',n_names)
       sprintf('Number of runs: %.0f',n_runs)
       sprintf('Regressor names (and run numbers where regressor occurs):')};
hdr = hdr';   

for i_name = 1:n_names
    ind = strcmp(regressor_names(1,:),all_names{i_name});
    curr_runs = [regressor_names{2,ind}];
    if all(diff(curr_runs)==1)
        out{i_name} = sprintf('%s (%.0f:%.0f)',all_names_char(i_name,:),curr_runs(1),curr_runs(end));
    else
        out{i_name} = sprintf('%s (%s)',all_names_char(i_name,:),num2str(curr_runs));
    end
end

if ~compress
    % display
    out = [hdr, out];

else % compress bins
    
    % split everything at bin
    for i_out = 1:length(out)
        curr_split = regexp(out{i_out}, ' bin ','split');
        split{i_out} = curr_split;
    end
    
    % compress splits
    
    i_out_new = 0; % row counter for compressed output
    i_out = 1;
    
    while i_out <= length(split) % see COUNTER CHANGE for increase
        i_out_new = i_out_new + 1; % increase new row
        if length(split{i_out}) == 2
            % is splitted, compress entry
            currname = split{i_out}{1};
            
            % split again to get number of sessions e.g. (1:6) and startbin
            second_part = regexp(split{i_out}{2}, ' ', 'split');
            
            start_bin = str2num(second_part{1});
            last_bin = start_bin; % init
            
            % find the last one in a row called like the current one
            row_found = false;
            i_last_row = i_out; % current row as start row
            while ~row_found
                i_next_row = i_last_row + 1; % this line should be checked
                % check if next row can be parsed
                if i_next_row <= length(split) && ... % row should be there
                        length(split{i_next_row}) == 2 % row should be splittable
                    % check if next row fullfills criteria
                    row_ok = true; % init
                    row_ok = row_ok && strcmp(currname, split{i_next_row}{1}); % check name is equal
                    
                    second_part2 = regexp(split{i_next_row}{2}, ' ','split');
                    curr_bin = str2num(second_part2{1});
                    
                    row_ok = row_ok && curr_bin == last_bin + 1; % check bins are in a row
                    row_ok = row_ok && strcmp(second_part{2}, second_part2{2}); % check session string is equal
                    
                    if row_ok
                        last_bin = curr_bin;
                        i_last_row = i_next_row;
                    else
                        row_found = true;
                    end
                else
                    % row has not two parts or its larger than the last
                    % row, thus row was found
                    row_found = true;
                end
            end
            % create new entry for current row
            
            out_new{i_out_new} = [currname sprintf(' bin %i..%i ', start_bin, last_bin) second_part{2}];
            
            % CHANGING COUNTER
            i_out = i_next_row; % COUNTER CHANGE IF SPLITTABLE
        else
            % just add
            out_new{i_out_new} = split{i_out}{1};
            i_out = i_out + 1; % COUNTER CHANGE IF NOT SPLITTABLE
        end
    end
    out = [hdr, out_new];
end
display(char(out));
