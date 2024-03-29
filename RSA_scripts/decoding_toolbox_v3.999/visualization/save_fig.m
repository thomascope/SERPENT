% function save_fig(filename, cfg, fighdl)
%
% This function serves to save a figure (the current axis) as
% matlab-figure + other formats (if desired).
%
% INPUT
%   filename: name for the file to be saved to (extensions will be added
%       automatically)
%
% OPTIONAL INPUT
%   cfg.plot_design_formats: if this is a cell of strings, each string specifies one
%       format to save the files as. E.g. {'-dpng', '-depsc2'} will save
%       the figure as png and eps. See print.m for more formats.
%       Other input types will be ignored (e.g. numbers), and the default
%       file formats will be used. Add 'NOFIGFILE' to avoid writing the 
%       design as .fig (sometimes these can get very large).
%
% OUTPUT
%   Files that saved the current figure under filename.*

function save_fig(filename, cfg, fighdl)

%     % replace '.' in filename by '_' to avoid problems with file ending
%     if any(filename == '.')
%       disp(['Replacing''.'' in filename ''' filename ''' by ''_'' to avoid problems with file ending'])
%       filename(filename == '.') = '_';
%       disp(['New Filename: ' filename])
%     end

    if ~exist('cfg', 'var')
        cfg = [];
    end

    if ~exist('fighdl', 'var')
        fighdl = gcf;
    end
    
    if isfield(cfg,'results') && isfield(cfg.results,'write') && cfg.results.write == 0
        dispv(1, 'Not writing any figures, because cfg.results.write == 0')
        return
    end
    
    % backward compatibility
    if isfield(cfg, 'plot_design')
        cfg.plot_design_formats = cfg.plot_design;
    end
    
    if isfield(cfg, 'plot_design_formats')
        if iscell(cfg.plot_design_formats) && ischar(cfg.plot_design_formats{1})
            formats = cfg.plot_design_formats;
        end
    end

    if ~exist('formats', 'var')
        formats = {'-dpng', '-depsc2'}; % list all formats that you want to save the figure as
    end

    
    
    % Save as FIG
    try
        if ~any(strcmp(formats, 'NOFIGFILE')) 
            dispv(1, '%s', ['Saving figure as ' filename '.fig'])
            saveas(fighdl, filename, 'fig')
        else
            dispv(1, 'Not writing figure as .fig file, switched off because cfg.plot_design_formats contains ''NOFIGFILE''')
        end
    catch %#ok<CTCH>
        disp(lasterror) %#ok<LERR>
        warningv('SAVE_FIG:SavingFigureFailed', 'Saving as .fig failed')
    end

    % prevent resizing the figure
    set(fighdl,'PaperPositionMode','auto')
    % prevent changing the background color
    set(fighdl, 'InvertHardCopy', 'off');
    % get old color for recovery
    oldcolor = get(fighdl, 'color');
    % but set background to white
    set(fighdl, 'color', 'white');    
    
    for f_ind = 1:length(formats)
        curr_format = formats{f_ind};
        if strcmp(curr_format, 'NOFIGFILE'), continue, end % skip for 'NOFIGFILE' entry, it's to avoid that the .fig file is saved above
        try
            dispv(1, '%s', ['Saving figure as ' filename '.* as ' curr_format])
            print(fighdl, curr_format, filename)
        catch %#ok<CTCH>
            warningv('SAVE_FIG:SavingFigureFormattedFailed',['Saving as ' curr_format ' failed'])
        end
    end
    dispv(2, 'Saving figure done')    

    % set background back
    set(fighdl, 'color', oldcolor);  
end