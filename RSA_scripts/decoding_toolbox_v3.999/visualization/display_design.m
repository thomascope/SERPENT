% function table = display_design(cfg)
%   or
% function table = display_design(cfg.design)
%
% Displays the design matrices (train, test & label) in a nice(r) form.
%
% For a graphical representation, see plot_design.m
%
% See also PLOT_DESIGN

% Potential improvements
%
% - Multiple blocks for long designs (e.g. after 20 steps)

function table = display_design(cfg)

%% check if input is design subfield
if ~isfield(cfg, 'design')
    if isfield(cfg, 'train') && isfield(cfg, 'test')
        warning('Seems you called display_design(cfg.design). Use display_design(cfg) if possible. File names will not be printed.')
        % save design in cfg.design for this function
        cfg.design = cfg;
    else
        error('Invalid argument for display_design(). The input should be either a cfg containing .design, or cfg.design containing .train and .test')
    end
end

% add dummy entries for files
if ~isfield(cfg, 'files')
    cfg.files.name(1:size(cfg.design.train, 1), 1) = {'.file not found'};
end

%% Check if the design is huuuugggeee - if so, just show summary
huge_number = 10000;
if numel(cfg.design.train) > huge_number && (~isfield(cfg, 'display_huge_design') || cfg.display_huge_design)
    disp(' ')
    disp(' ')
    disp(['display_design: Avoiding displaying design as it seems huge (has more than ' num2str(huge_number) ' entries)'])
    disp('Showing summary statistics instead. Set cfg.display_huge_design = true if you really want to display it')
    disp(' ')
    disp(['Design size (files x steps): ' num2str(size(cfg.design.train))])
    disp(['                     n sets: ' num2str(sum(unique(cfg.design.set)))])
    disp(['                   n labels: ' num2str(sum(unique(cfg.design.label)))])
    n_train = sum(cfg.design.train(:) > 0);
    n_test = sum(cfg.design.test(:) > 0);
    disp(['              n total train: '  num2str(n_train)])
    disp(['              n total  test: '  num2str(n_test)])
    disp(['           avg n train/step: '  num2str(n_train/size(cfg.design.train, 2))])
    disp(['           avg n  test/step: '  num2str(n_test/size(cfg.design.train, 2))])
    disp(' ')
    disp(' ')
    return
end
%% print the design in a readable form
% nrows = length(cfg.files.name);
% data
if size(cfg.files.name, 1) == 1
    % flip
    cfg.files.name = cfg.files.name';
end

% reduce file name length
fnames = cfg.files.name;
fnames_char = char(fnames);
n_str = size(fnames_char,2); % maximum string length
n_match = n_str;
for i_str = 1:n_str
    match = strncmp(fnames{1},fnames(2:end),i_str);
    if ~all(match)
        n_match = i_str-1;
        break
    end
end
filestart = fnames_char(1,1:n_match); % common file start
if length(filestart) > 15
    filerest = [repmat('...', size(fnames_char, 1), 1), fnames_char(:, n_match+1:end)]; % get not common part + initial '...'
    fnames_char = filerest;
else
	% keep fnames_char as they are (not cut)
end


% get first column (filenames + header) as string
% filename_str = char([{'files.name'}; {'---'}; cfg.files.name; {'---'}; {'design.set'}]);
filename_str = char([{'files.name'}; {'---'}; fnames_char; {'---'}; {'design.set'}]);

% set
if isfield(cfg.design, 'set')
    set_str = char({num2str(cfg.design.set)});
else
    set_str = ' ';
end

train_str = char([{'design.train'}; {''}; {num2str(cfg.design.train)}; {''}; set_str]);
test_str = char([{'design.test'}; {''}; {num2str(cfg.design.test)}; {''}; set_str]);
label_str = char([{'design.label'}; {''}; {num2str(cfg.design.label)}; {''}; set_str]);

% tabs
tabs = repmat(sprintf('\t'), size(filename_str, 1),1); % prepare tabs for hdr + data

% table
table = [filename_str, tabs, train_str, tabs, test_str, tabs, label_str];

% add file.descr if available
if isfield(cfg.files, 'descr') && ~isempty(cfg.files.descr)
    descr_str = char([{'files.descr'}; {'---'}; char(cfg.files.descr'); {'---'}; {''}]);
    table = [descr_str, tabs, table];
end

% start & endtime, if available
if isfield(cfg, 'progress') && isfield(cfg.progress, 'starttime')
    curr_text = ['Starttime: ' cfg.progress.starttime];
    if isfield(cfg, 'progress') && isfield(cfg.progress, 'endtime')
        curr_text = [curr_text ', Endtime: ' cfg.progress.endtime];
    else
        curr_text = [curr_text ', Endtime: No endtime'];
    end
else
    curr_text = 'Start & Endtime not available';
end
table = char([{table}; {curr_text}]);

% add result folder if available
try %#ok<TRYNC>
    table = char([{table}; ['cfg.results.dir: ' cfg.results.dir]]);
end

% add common part
if exist('filerest', 'var')
    table = char([{'DECODING DESIGN'}; {'Common inputfile start: '}; {['  ' filestart]}; {table}]);
else
    table = char([{'DECODING DESIGN'}; {table}]);
end


% print if not returned
if nargout < 1
    dispv(2,table)
end