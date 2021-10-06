% function decoding_write_results(cfg,results)
%
% This is a subfunction of The Decoding Toolbox that saves previously
% processed data to a prespecified target location. For example, it can be
% used to write brain images in a searchlight analysis or write a mat-file
% for ROI analyses, containing a structure with fields for each ROI.
% The function can also be run separately to save previously processed data.
%
% PARAMETERS
%   cfg.result.write: = 0: don't write results
%                     = 1: write mat + img file for SL + ROI
%                     = 2: write only mat file for SL + ROI
%
%   cfg.results.overwrite = 0: don't overwrite files (also see comment below)
%                         = 1: overwrite results 
%
% Remark: if cfg.results.overwrite = 0 and if result files with the same
% name exist, the result files (.hdr & .img, .nii, or .HEAD & .BRIK) will
% be copied. However this is very unlikely to occur, because decoding.m
% checks whether the result files exist already when it is starts, and
% aborts operation already then if the result files should not be
% overwritten. Copying will only occur in the unlikely event that result
% files with the same name are created between this initial check in
% decoding.m and when they should be saved here.
%
% See also DECODING

% by Martin Hebart and Kai Goergen
%
% HISTORY
% KAI: 2020/03/24: Displaying name of warning file.
% MARTIN: 2016/07/05: Added compatibility with AFNI
% KAI: 2016/03/11: Added check that new datainfo.mat agress with
%   results_hdr.mat when writing image.
% KAI: 2015/12/11: switched coding cfg.result.write to more intuitive 
%       behaviour, now cfg.result.write = 1 writes both, mat+img, and
%       write = 2 writes mat only.
% MARTIN: 2015/19/09: now writing cfg > 2GB with -v7.3 flag
% MARTIN: 2015/07/07: introduced possibility to write file format .nii
% MARTIN: 2015/07/06: introduced possibility to write ROIs using a multi-mask
% MARTIN: 2014/06/16: now writing results > 2GB with -v7.3 flag
% MARTIN: 2014/09/01: now returning results as .mat file as a default
% MARTIN: 2013/06/16: removed input mask_index (should anyway be contained
%   in results struct), restructured ROI and wholebrain writing section
% KAI, 2011/08/16
%   Added copying of result files if result files exist and
%   cfg.results.overwrite = 1
%

function decoding_write_results(cfg,results)

global reports

% Unpack results
mask_index = results.mask_index;

% Save warning messages
if ~isempty(reports) % if any warnings were present
    fdir = cfg.results.dir;
    fname = fullfile(fdir,sprintf('%s_warnings.mat',cfg.results.filestart));
    save(fname,'reports');
    dispv(1,['Warnings occurred during execution. Saving warnings to ', fname],'display')
end

n_outputs = length(cfg.results.output);

% Check if we are dealing with permutation results
if isfield(cfg.design,'function') && isfield(cfg.design.function,'permutation')
    isperm = 1;
else
    isperm = 0;
end

% Save cfg
if ~isperm
    cfg_fname = [cfg.results.filestart '_cfg.mat'];
else
    cfg_fname = [cfg.results.filestart '_cfg_perm.mat'];
end
cfg_fpath = fullfile(cfg.results.dir,cfg_fname);

% remove figure handle before saving cfg (otherwise cfg files also contain
% the full figure in newer matlab-versions, because these are objects...)
org_cfg = cfg; % keep for restoring
cfg.fighandles = [];
% save cfg
saveflag = checkvarsize(cfg);
save(cfg_fpath, 'cfg', saveflag);
% restore cfg fig handles
cfg = org_cfg; 
clear org_cfg;

% Get roi names and number of rois from masks and unpack mask_index_each
if strcmpi(cfg.analysis,'roi')
    
    % if mask files have been provided and there was no multi-mask
    if isfield(cfg,'files') && isfield(cfg.files,'mask') && length(cfg.files.mask) == numel(results.mask_index_each)
        for i_mask = 1:length(cfg.files.mask)
            % use file names of masks
            [dummy1,roi_names{i_mask},dummy2] = fileparts(cfg.files.mask{i_mask}); %#ok<ASGLU,*AGROW>
            if length(roi_names{i_mask})>=5 && any(strcmp(roi_names{i_mask}(end-4:end),{'+tlrc','+orig','+acpc'}))
                roi_names{i_mask}(end-4:end) = [];
            end
        end
    else
        % check if a multi-mask had been used and has been passed as a file
        if isfield(cfg,'files') && isfield(cfg.files,'mask') && length(cfg.files.mask) == 1 && length(cfg.files.mask) ~= numel(results.mask_index_each)
            dispv(1,'ROIs numbered by entries in multi-mask (excluding 0 and NaN).')
            mask_hdr = read_header(cfg.software,cfg.files.mask{1});
            mask_vol = read_image(cfg.software,mask_hdr);
            mask_num = unique(mask_vol(:));
            mask_num(isnan(mask_num)|mask_num==0) = []; % remove 0 and NaN
            for i_mask = 1:length(mask_num)
                roi_names{i_mask} = sprintf('roi%05d',mask_num(i_mask));
            end
        else
            dispv(1,'ROIs numbered from 1 to n_rois.')
            for i_mask = 1:numel(results.mask_index_each)
                roi_names{i_mask} = sprintf('roi%05d',i_mask);
            end
        end
    end
    results.roi_names = roi_names;
    n_rois = length(roi_names);
    
    mask_index_each = results.mask_index_each;
end

% Do same for wholebrain, so we can use the same code for both
if strcmpi(cfg.analysis,'wholebrain')
    roi_names = {'wholebrain'};
    n_rois = 1;
    mask_index_each = {results.mask_index};
end

%% WRITE SEARCHLIGHT RESULTS AS IMAGE
% exception: do not write any when permutations were executed (otherwise we
% overwrite the original results and write e.g. 1000 images!)
if cfg.results.write == 1 && strcmpi(cfg.analysis,'searchlight') && ~isperm
    
    try
        resultsvol_hdr = read_header(cfg.software,cfg.files.name{1}); % choose canonical hdr from first classification image
        resultsvol_hdr = resultsvol_hdr(1); % in case we are dealing with a 4D volume
        % check that rotation matrices agree
        if isfield(cfg.datainfo, 'mat')
            if isfield(resultsvol_hdr, 'mat')
                mat_diff = abs(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:));
                tolerance = 32*eps(max(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:)));
                if any(mat_diff > tolerance) % like isequal, but allows for rounding errors
                    warningv('decoding_write_results:rotation_matrices_different', 'Rotation & translation matrix of image in file \n %s \n is different from rotation & translation matrix in cfg.\n The .mat entry defines rotation & translation of the image.\n That both differ means that at least one of both has been rotated.\n Please use reslicing (e.g. from SPM) to have all images in the same position.', resultsvol_hdr.fname)
                    warningv('decoding_write_results:rotation_matrices_differentTODO', 'TODO: This should be fixed')
                end
            end
        end
        fallback = 0; % if results cannot be written as .img, save as mat
    catch %#ok<CTCH>
        fallback = 1;
    end
    
    for i_output = 1:n_outputs
        
        % write searchlight results as img-file only if the output allows it
        if fallback, continue, end
        
        outputname = cfg.results.output{i_output};
        
        if ~isnumeric(results.(outputname).output)
            % try to see if there is zero or one cell array per searchlight
            if all(cellfun(@numel,results.(outputname).output) <= 1)
                % convert
                n_maskvox = size(results.(outputname).output,1);
                c = cfg.results.backgroundvalue * ones(n_maskvox,1);
                n_searchlight = n_maskvox;
                try
                    decoding_subindex = results.decoding_subindex;
                catch
                    decoding_subindex = 1:n_searchlight;
                end
                
                c(decoding_subindex) = [results.(outputname).output{:}];
                % reassign
                results.(outputname).output = c;
                
            else
                warning('DECODING_WRITE_RESULTS:no_writing_possible',...
                    'Result %s cannot be written to an image, because the format is not numeric and thus assumes there are several entries per voxel. Writing only as .mat file.',outputname)
                continue
            end
        end
        
        % Save overall results and save to returning variable
        [trash1,trash2,suffix,ext] = tdt_fileparts(cfg.files.name{1});
        ext = regexp(ext,',','split'); ext = ext{1}; % in case we have a 4D nifti
        fname = sprintf('%s%s%s',cfg.results.resultsname{i_output},suffix,ext);
        resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
        resultsvol_hdr.descrip = sprintf('%s decoding map',outputname);
        resultsvol = cfg.results.backgroundvalue * ones(resultsvol_hdr.dim(1:3)); % prepare results volume with background value (default: 0)
        resultsvol(mask_index) = results.(outputname).output;
        
        if exist(resultsvol_hdr.fname,'file')
            if cfg.results.overwrite
                % simply overwrite the file
                warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Overwriting it (because cfg.results.overwrite = 1)',resultsvol_hdr.fname)
            else
                % dont overwrite file, copy it
                [old_results_path, old_results_file, dummy_fext] = fileparts(resultsvol_hdr.fname);
                old_fname = fullfile(old_results_path, old_results_file);
                backup_fname = fullfile(old_results_path, [old_results_file, '_old_before_', datestr(now, 'yyyymmddTHHMMSS')]);
                warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Copying old files %s to %s (because cfg.results.overwrite = 0)',resultsvol_hdr.fname, old_fname, backup_fname);
                
                for fext = {'.hdr', '.img', '.nii', '.BRIK', '.HEAD'}
                    source = [old_fname, fext{1}];
                    if ~exist(source,'file'), continue, end
                    target = [backup_fname, fext{1}];
                    dispv(1, 'Copying %s to %s', source, target)
                    ignore = copyfile(source, target); %#ok<*NASGU> % output needed for linux bug
                end
            end
        end
        
        dispv(1,'Saving %s results to %s', cfg.decoding.method, resultsvol_hdr.fname)
        
        write_image(cfg.software,resultsvol_hdr,resultsvol);
        
        results.(outputname).(outputname).fname = resultsvol_hdr.fname;
        
        % Save set results (i.e.: should each set be saved separately?)
        if cfg.results.setwise && cfg.design.n_sets > 1
            n_sets = length(results.(outputname).set);
            for i_set = 1:n_sets
                fname = sprintf('%s_set%04i%s', cfg.results.resultsname{i_output}, results.(outputname).set(i_set).set_id, ext);
                resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
                resultsvol_hdr.descrip = sprintf('%s decoding map of set %i',outputname,i_set);
                resultsvol_set = cfg.results.backgroundvalue * ones(resultsvol_hdr.dim(1:3)); % prepare results volume
                resultsvol_set(mask_index) = results.(outputname).set(i_set).output;
                dispv(2,'Saving results for set %i to %s', i_set, resultsvol_hdr.fname)
                write_image(cfg.software,resultsvol_hdr,resultsvol_set);
                results.(outputname).set(i_set).fname = resultsvol_hdr.fname;
            end
        end
    end
end

%% WRITE ROI OR WHOLEBRAIN RESULTS AS .IMG IF REQUESTED
% exception: do not write any when permutations were executed (otherwise we
% overwrite the original results and write e.g. 1000 images!)

if cfg.results.write == 1 && (strcmpi(cfg.analysis,'roi') || strcmpi(cfg.analysis,'wholebrain')) && ~isperm
    
    % if we are not dealing with a multi-mask, save all ROI results separately
    if ~exist('mask_num','var')
        
    for i_roi = 1:n_rois % loop over ROIs and write results separately
        
        try
            resultsvol_hdr = read_header(cfg.software,cfg.files.name{1}); % choose canonical hdr from first classification image
            % check that rotation matrices agree
            if isfield(cfg.datainfo, 'mat')
                if isfield(resultsvol_hdr, 'mat')
                    mat_diff = abs(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:));
                    tolerance = 32*eps(max(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:)));
                    if any(mat_diff > tolerance) % like isequal, but allows for rounding errors
                        warningv('decoding_write_results:rotation_matrices_different', 'Rotation & translation matrix of image in file \n %s \n is different from rotation & translation matrix in cfg.\n The .mat entry defines rotation & translation of the image.\n That both differ means that at least one of both has been rotated.\n Please use reslicing (e.g. from SPM) to have all images in the same position.', resultsvol_hdr.fname)
                        warningv('decoding_write_results:rotation_matrices_differentTODO', 'TODO: This should be fixed')
                    end
                end
            end
            fallback = 0; % if results cannot be written as .img, save as mat
        catch %#ok<CTCH>
            fallback = 1;
        end
        
        for i_output = 1:n_outputs
 
            % write roi/wholebrain results as img-file only if the output allows it
            if fallback, continue, end
            
            outputname = cfg.results.output{i_output};
            
            % Save overall results and save to returning variable
            [trash1,trash2,suffix,ext] = tdt_fileparts(cfg.files.name{1});
            ext = regexp(ext,',','split'); ext = ext{1}; % in case we have a 4D nifti
            fname = sprintf('%s_%s%s%s',cfg.results.resultsname{i_output},roi_names{i_roi},suffix,ext);
            resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
            resultsvol_hdr.descrip = sprintf('%s decoding map on ROI %s',outputname,roi_names{i_roi});
            curr_output = results.(outputname).output(i_roi);
            
            [resultsvol,continueflag] = assign_output(cfg,resultsvol_hdr,curr_output,mask_index_each,i_roi);
            if continueflag == 1,
                str = sprintf('Results for output %s and roi ''%s'' cannot be written, because the format is wrong (e.g. leave-one-run-out with more than one output per run).',outputname,roi_names{i_roi});
                warning('DECODING_WRITE_RESULTS:cannot_write',str) %#ok<SPWRN>
            end
            
            if ~continueflag
                
                % Check if file exists
                if exist(resultsvol_hdr.fname,'file')
                    if cfg.results.overwrite
                        % simply overwrite the file
                        warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Overwriting it (because cfg.results.overwrite = 1)',resultsvol_hdr.fname)
                    else
                        % dont overwrite file, copy it
                        [old_results_path, old_results_file, dummy_fext] = fileparts(resultsvol_hdr.fname);
                        old_fname = fullfile(old_results_path, old_results_file);
                        backup_fname = fullfile(old_results_path, [old_results_file, '_old_before_', datestr(now, 'yyyymmddTHHMMSS')]);
                        warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Copying old files %s to %s (because cfg.results.overwrite = 0)',resultsvol_hdr.fname, old_fname, backup_fname);
                        
                        for fext = {'.hdr', '.img', '.nii'}
                            source = [old_fname, fext{1}];
                            if ~exist(source,'file'), continue, end
                            target = [backup_fname, fext{1}];
                            dispv(1, 'Copying %s to %s', source, target)
                            ignore = copyfile(source, target); % output needed for linux bug
                        end
                    end
                end
                
                dispv(1,'Saving %s results to %s', cfg.decoding.method, resultsvol_hdr.fname)
                
                write_image(cfg.software,resultsvol_hdr,resultsvol);
                
                results.(outputname).(outputname).fname = resultsvol_hdr.fname;
                
            end
            
            % Save set results (i.e.: should each set be saved separately?)
            if cfg.results.setwise && cfg.design.n_sets > 1
                n_sets = length(results.(outputname).set);
                for i_set = 1:n_sets
                    fname = sprintf('%s_set%04i_%s%s', cfg.results.resultsname{i_output}, results.(outputname).set(i_set).set_id,roi_names{i_roi}, ext);
                    resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
                    resultsvol_hdr.descrip = sprintf('%s decoding map of set %i',outputname,i_set);
                    curr_output = results.(outputname).set(i_set).output(i_roi);
                    [resultsvol_set,continueflag] = assign_output(cfg,resultsvol_hdr,curr_output,mask_index_each,i_roi);
                    
                    if continueflag == 1,
                        str = sprintf('Results for output %s, roi ''%s'' and set %i cannot be written, because the format is wrong (e.g. leave-one-run-out with more than one output per run).',outputname,roi_names{i_roi},i_set);
                        warning('DECODING_WRITE_RESULTS:cannot_write',str) %#ok<SPWRN>
                        continue
                    end
                                        
                    dispv(2,'Saving results for set %i to %s', i_set, resultsvol_hdr.fname)
                    write_image(cfg.software,resultsvol_hdr,resultsvol_set);
                    results.(outputname).set(i_set).fname = resultsvol_hdr.fname;
                end
            end
        end
    end
    
    % if we are dealing with a multi-mask, combine all ROI results together
    else
    
    
        
        try
            resultsvol_hdr = read_header(cfg.software,cfg.files.name{1}); % choose canonical hdr from first classification image
            % check that rotation matrices agree
            if isfield(cfg.datainfo, 'mat')
                if isfield(resultsvol_hdr, 'mat')
                    mat_diff = abs(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:));
                    tolerance = 32*eps(max(cfg.datainfo.mat(:)-resultsvol_hdr.mat(:)));
                    if any(mat_diff > tolerance) % like isequal, but allows for rounding errors
                        warningv('decoding_write_results:rotation_matrices_different', 'Rotation & translation matrix of image in file \n %s \n is different from rotation & translation matrix in cfg.\n The .mat entry defines rotation & translation of the image.\n That both differ means that at least one of both has been rotated.\n Please use reslicing (e.g. from SPM) to have all images in the same position.', resultsvol_hdr.fname)
                        warningv('decoding_write_results:rotation_matrices_differentTODO', 'TODO: This should be fixed')
                    end
                end
            end
            fallback = 0; % if results cannot be written as .img, save as mat
        catch %#ok<CTCH>
            fallback = 1;
        end
        
        for i_output = 1:n_outputs
            
            % write roi/wholebrain results as img-file only if the output allows it
            if fallback, continue, end
            
            outputname = cfg.results.output{i_output};
            
            % Save overall results and save to returning variable
            [trash1,trash2,suffix,ext] = tdt_fileparts(cfg.files.name{1});
            ext = regexp(ext,',','split'); ext = ext{1}; % in case we have a 4D nifti
            fname = sprintf('%s_multiroi%s%s',cfg.results.resultsname{i_output},suffix,ext);
            resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
            resultsvol_hdr.descrip = sprintf('%s decoding map on all ROIs (multi-ROI)',outputname);
            curr_output = results.(outputname).output;
            
            resultsvol = cfg.results.backgroundvalue * ones(resultsvol_hdr.dim(1:3)); % prepare results volume
            for i_roi = 1:n_rois
                [curr_resultsvol,continueflag] = assign_output(cfg,resultsvol_hdr,curr_output(i_roi),mask_index_each,i_roi);
                % combine
                resultsvol(mask_index_each{i_roi}) = curr_resultsvol(mask_index_each{i_roi});
            end
            
            if continueflag == 1,
                str = sprintf('Results for output %s and roi ''%s'' cannot be written, because the format is wrong (e.g. leave-one-run-out with more than one output per run).',outputname,roi_names{i_roi});
                warning('DECODING_WRITE_RESULTS:cannot_write',str) %#ok<SPWRN>
            end
            
            
            if ~continueflag
                
                % Check if file exists
                if exist(resultsvol_hdr.fname,'file')
                    if cfg.results.overwrite
                        % simply overwrite the file
                        warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Overwriting it (because cfg.results.overwrite = 1)',resultsvol_hdr.fname)
                    else
                        % dont overwrite file, copy it
                        [old_results_path, old_results_file, dummy_fext] = fileparts(resultsvol_hdr.fname);
                        old_fname = fullfile(old_results_path, old_results_file);
                        backup_fname = fullfile(old_results_path, [old_results_file, '_old_before_', datestr(now, 'yyyymmddTHHMMSS')]);
                        warning('decoding_write_results:overwrite_results', 'Resultfile %s already existed. Copying old files %s to %s (because cfg.results.overwrite = 0)',resultsvol_hdr.fname, old_fname, backup_fname);
                        
                        for fext = {'.hdr', '.img', '.nii'}
                            source = [old_fname, fext{1}];
                            if ~exist(source,'file'), continue, end
                            target = [backup_fname, fext{1}];
                            dispv(1, 'Copying %s to %s', source, target)
                            ignore = copyfile(source, target); % output needed for linux bug
                        end
                    end
                end
                
                dispv(1,'Saving %s results to %s', cfg.decoding.method, resultsvol_hdr.fname)
                
                write_image(cfg.software,resultsvol_hdr,resultsvol);
                
                results.(outputname).(outputname).fname = resultsvol_hdr.fname;
                
            end
            
            % Save set results (i.e.: should each set be saved separately?)
            if cfg.results.setwise && cfg.design.n_sets > 1
                n_sets = length(results.(outputname).set);
                for i_set = 1:n_sets
                    fname = sprintf('%s_set%04i_multiroi%s', cfg.results.resultsname{i_output}, results.(outputname).set(i_set).set_id, ext);
                    resultsvol_hdr.fname = fullfile(cfg.results.dir,fname);
                    resultsvol_hdr.descrip = sprintf('%s decoding map of set %i',outputname,i_set);
                    curr_output = results.(outputname).set(i_set).output;
                    
                    resultsvol_set = cfg.results.backgroundvalue * ones(resultsvol_hdr.dim(1:3)); % prepare results volume
                    for i_roi = 1:n_rois
                        [curr_resultsvol_set,continueflag] = assign_output(cfg,resultsvol_hdr,curr_output(i_roi),mask_index_each,i_roi);
                        % combine
                        resultsvol_set(mask_index_each{i_roi}) = curr_resultsvol_set(mask_index_each{i_roi});
                    end
                    
                    if continueflag == 1,
                        str = sprintf('Results for output %s, roi ''%s'' and set %i cannot be written, because the format is wrong (e.g. leave-one-run-out with more than one output per run).',outputname,roi_names{i_roi},i_set);
                        warning('DECODING_WRITE_RESULTS:cannot_write',str) %#ok<SPWRN>
                        continue
                    end
                    
                    dispv(2,'Saving results for set %i to %s', i_set, resultsvol_hdr.fname)
                    write_image(cfg.software,resultsvol_hdr,resultsvol_set);
                    results.(outputname).set(i_set).fname = resultsvol_hdr.fname;
                end % for i_set
            end % if setwise
        end % for i_ouput
    end % if multi_mask
        
end % if roi


%% WRITE SEARCHLIGHT, ROI OR WHOLEBRAIN RESULTS AS .MAT FILE
% write only setwise when permutations are running

% first remove all output fields and store separately
for i_output = 1:n_outputs
    outputname = cfg.results.output{i_output};
    results_outputonly.(outputname) = results.(outputname);
    results = rmfield(results,outputname);
end
results_nooutput = results;

% Now loop over all outputs to store results separately
for i_output = 1:n_outputs
    
    % and add results again for each iteration
    outputname = cfg.results.output{i_output};
    results = results_nooutput;
    results.(outputname) = results_outputonly.(outputname);
    
    % Save overall results and save to returning variable
    fdir = cfg.results.dir;
    fname = fullfile(fdir,sprintf('%s.mat',cfg.results.resultsname{i_output}));
    
    if ~isperm % when permutations run, we don't need to check, because we don't write it
        if exist(fname,'file')
            if cfg.results.overwrite
                % simply overwrite the file
                str = sprintf('Resultfile %s already existed. Overwriting it (because cfg.results.overwrite = 1)',fname);
                warningv('decoding_write_results:overwrite_results', str)
            else
                % dont overwrite file, copy it
                [old_results_path, old_results_file, dummy_ending] = fileparts(fname);
                old_fname = fullfile(old_results_path, old_results_file);
                backup_fname = fullfile(old_results_path, [old_results_file, '_old_before_', datestr(now, 'yyyymmddTHHMMSS')]);
                str = sprintf('Resultfile %s already existed. Copying old files %s to %s (because cfg.results.overwrite = 0)', fname, old_fname, backup_fname);
                warningv('decoding_write_results:overwrite_results', str);
                
                fext = '.mat';
                source = [old_fname, fext];
                target = [backup_fname, fext];
                dispv(1, 'Copying %s to %s', source, target)
                ignore = copyfile(source, target);
            end
        end
        
        dispv(1,'Saving %s results to %s', cfg.decoding.method, fname)
        
        saveflag = checkvarsize(results);
        save(fname,'results',saveflag);
    
        results.(outputname).fname = fname;
    
    end
    
    % Save set results (should each set be saved separately?)
    if cfg.results.setwise && cfg.design.n_sets > 1
        n_sets = length(results.(outputname).set);
        results_all = results;
        for i_set = 1:n_sets
            fname = fullfile(fdir,sprintf('%s_set%04i.mat', cfg.results.resultsname{i_output}, results.(outputname).set(i_set).set_id));
            dispv(2,'Saving results for set %i to %s', i_set, fname)
            results.(outputname).output = results.(outputname).set(i_set).output;
            results.(outputname) = rmfield(results.(outputname),'set');
            results.(outputname).set(i_set).fname = fname;
            
            saveflag = checkvarsize(results);
            save(fname,'results',saveflag);
            
            results = results_all; % reset
        end
    end
    
end



%% SUBFUNCTIONS

function [resultsvol,continueflag] = assign_output(cfg,resultsvol_hdr,curr_output,mask_index_each,i_roi)

% numeric output can be written as image when it matches mask_index_each or is scalar.
% cell output can be written as image if we can find a unique and
% meaningful way to convert it to numeric (e.g. if cell array is 1x1 and
% contains numeric)

continueflag = 0;
resultsvol = cfg.results.backgroundvalue * ones(resultsvol_hdr.dim(1:3)); % prepare results volume

% cell case
if iscell(curr_output)
    curr_output = curr_output{1}; % must be the case
    if iscell(curr_output)
        if numel(curr_output)==1
            curr_output = curr_output{1};
        else % cannot work with multiple cell entries
            continueflag = 1;
            return
        end
    end
end

% numeric case
if isnumeric(curr_output)
    try
        resultsvol(mask_index_each{i_roi}) = curr_output;
        return
    catch %#ok<CTCH>
        continueflag = 1;
        return
    end
end

% in all other cases return, because results cannot be written
continueflag = 1;
return

%%%%%
function saveflag = checkvarsize(var)

% If larger than 2GB, use -v7.3 option

v = whos('var');
sz = v.bytes/(1024^3);
if sz > 2
    saveflag = '-v7.3';
    warning('CHECKVARSIZE:LARGEFILE','Variable is larger than 2GB. To be able to write it, we are using the -v7.3 option (see help save for details)')
else
    saveflag = ''; % when empty, default flag will be used
end