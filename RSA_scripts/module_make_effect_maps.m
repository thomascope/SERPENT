function module_make_effect_maps(GLMDir,downsamp_ratio,subject)
%For taking already calculated crossnobis distances and doing RSA

redo_maps = 0; %If you want to calculate them again for some reason.
save_design_matrices = 0; %If you want to output the design matrices for visualisation

if ~exist('downsamp_ratio','var')
    downsamp_ratio = 1;
end

addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/RSA_scripts/es_scripts_fMRI')
addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/RSA_scripts/decoding_toolbox_v3.999')
addpath(genpath('/group/language/data/ediz.sohoglu/matlab/rsatoolbox'));

%Define input data location
if downsamp_ratio == 1
    %cfg.results.dir = fullfile(GLMDir,'TDTcrossnobis');
    cfg.results.dir = fullfile(GLMDir,'TDTcrossnobis_parallel');
else
    cfg.results.dir = fullfile(GLMDir,['TDTcrossnobis_downsamp_' num2str(downsamp_ratio)]);
end

behaviour_folder = ['/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/judgment_dissim_matrices/'];

% Set the label names to the regressor names which you want to use for
% your similarity analysis, e.g.
%labelnames = {'Strong+M_Set1_Item1','Strong+M_Set1_Item2','Strong+M_Set1_Item3','Strong+M_Set1_Item4','Strong+M_Set2_Item1','Strong+M_Set2_Item2','Strong+M_Set2_Item3','Strong+M_Set2_Item4','Strong+M_Set3_Item1','Strong+M_Set3_Item2','Strong+M_Set3_Item3','Strong+M_Set3_Item4','Strong+M_Set4_Item1','Strong+M_Set4_Item2','Strong+M_Set4_Item3','Strong+M_Set4_Item4','Strong+M_Set5_Item1','Strong+M_Set5_Item2','Strong+M_Set5_Item3','Strong+M_Set5_Item4','Strong+M_Set6_Item1','Strong+M_Set6_Item2','Strong+M_Set6_Item3','Strong+M_Set6_Item4','Strong+M_Set7_Item1','Strong+M_Set7_Item2','Strong+M_Set7_Item3','Strong+M_Set7_Item4','Strong+M_Set8_Item1','Strong+M_Set8_Item2','Strong+M_Set8_Item3','Strong+M_Set8_Item4','Weak+M_Set1_Item1','Weak+M_Set1_Item2','Weak+M_Set1_Item3','Weak+M_Set1_Item4','Weak+M_Set2_Item1','Weak+M_Set2_Item2','Weak+M_Set2_Item3','Weak+M_Set2_Item4','Weak+M_Set3_Item1','Weak+M_Set3_Item2','Weak+M_Set3_Item3','Weak+M_Set3_Item4','Weak+M_Set4_Item1','Weak+M_Set4_Item2','Weak+M_Set4_Item3','Weak+M_Set4_Item4','Weak+M_Set5_Item1','Weak+M_Set5_Item2','Weak+M_Set5_Item3','Weak+M_Set5_Item4','Weak+M_Set6_Item1','Weak+M_Set6_Item2','Weak+M_Set6_Item3','Weak+M_Set6_Item4','Weak+M_Set7_Item1','Weak+M_Set7_Item2','Weak+M_Set7_Item3','Weak+M_Set7_Item4','Weak+M_Set8_Item1','Weak+M_Set8_Item2','Weak+M_Set8_Item3','Weak+M_Set8_Item4','Strong+MM_Set1_Item1','Strong+MM_Set1_Item2','Strong+MM_Set1_Item3','Strong+MM_Set1_Item4','Strong+MM_Set2_Item1','Strong+MM_Set2_Item2','Strong+MM_Set2_Item3','Strong+MM_Set2_Item4','Strong+MM_Set3_Item1','Strong+MM_Set3_Item2','Strong+MM_Set3_Item3','Strong+MM_Set3_Item4','Strong+MM_Set4_Item1','Strong+MM_Set4_Item2','Strong+MM_Set4_Item3','Strong+MM_Set4_Item4','Strong+MM_Set5_Item1','Strong+MM_Set5_Item2','Strong+MM_Set5_Item3','Strong+MM_Set5_Item4','Strong+MM_Set6_Item1','Strong+MM_Set6_Item2','Strong+MM_Set6_Item3','Strong+MM_Set6_Item4','Strong+MM_Set7_Item1','Strong+MM_Set7_Item2','Strong+MM_Set7_Item3','Strong+MM_Set7_Item4','Strong+MM_Set8_Item1','Strong+MM_Set8_Item2','Strong+MM_Set8_Item3','Strong+MM_Set8_Item4','Weak+MM_Set1_Item1','Weak+MM_Set1_Item2','Weak+MM_Set1_Item3','Weak+MM_Set1_Item4','Weak+MM_Set2_Item1','Weak+MM_Set2_Item2','Weak+MM_Set2_Item3','Weak+MM_Set2_Item4','Weak+MM_Set3_Item1','Weak+MM_Set3_Item2','Weak+MM_Set3_Item3','Weak+MM_Set3_Item4','Weak+MM_Set4_Item1','Weak+MM_Set4_Item2','Weak+MM_Set4_Item3','Weak+MM_Set4_Item4','Weak+MM_Set5_Item1','Weak+MM_Set5_Item2','Weak+MM_Set5_Item3','Weak+MM_Set5_Item4','Weak+MM_Set6_Item1','Weak+MM_Set6_Item2','Weak+MM_Set6_Item3','Weak+MM_Set6_Item4','Weak+MM_Set7_Item1','Weak+MM_Set7_Item2','Weak+MM_Set7_Item3','Weak+MM_Set7_Item4','Weak+MM_Set8_Item1','Weak+MM_Set8_Item2','Weak+MM_Set8_Item3','Weak+MM_Set8_Item4','Strong+Noise_Set1_Item1','Strong+Noise_Set1_Item2','Strong+Noise_Set1_Item3','Strong+Noise_Set1_Item4','Strong+Noise_Set2_Item1','Strong+Noise_Set2_Item2','Strong+Noise_Set2_Item3','Strong+Noise_Set2_Item4','Strong+Noise_Set3_Item1','Strong+Noise_Set3_Item2','Strong+Noise_Set3_Item3','Strong+Noise_Set3_Item4','Strong+Noise_Set4_Item1','Strong+Noise_Set4_Item2','Strong+Noise_Set4_Item3','Strong+Noise_Set4_Item4','Strong+Noise_Set5_Item1','Strong+Noise_Set5_Item2','Strong+Noise_Set5_Item3','Strong+Noise_Set5_Item4','Strong+Noise_Set6_Item1','Strong+Noise_Set6_Item2','Strong+Noise_Set6_Item3','Strong+Noise_Set6_Item4','Strong+Noise_Set7_Item1','Strong+Noise_Set7_Item2','Strong+Noise_Set7_Item3','Strong+Noise_Set7_Item4','Strong+Noise_Set8_Item1','Strong+Noise_Set8_Item2','Strong+Noise_Set8_Item3','Strong+Noise_Set8_Item4','Weak+Noise_Set1_Item1','Weak+Noise_Set1_Item2','Weak+Noise_Set1_Item3','Weak+Noise_Set1_Item4','Weak+Noise_Set2_Item1','Weak+Noise_Set2_Item2','Weak+Noise_Set2_Item3','Weak+Noise_Set2_Item4','Weak+Noise_Set3_Item1','Weak+Noise_Set3_Item2','Weak+Noise_Set3_Item3','Weak+Noise_Set3_Item4','Weak+Noise_Set4_Item1','Weak+Noise_Set4_Item2','Weak+Noise_Set4_Item3','Weak+Noise_Set4_Item4','Weak+Noise_Set5_Item1','Weak+Noise_Set5_Item2','Weak+Noise_Set5_Item3','Weak+Noise_Set5_Item4','Weak+Noise_Set6_Item1','Weak+Noise_Set6_Item2','Weak+Noise_Set6_Item3','Weak+Noise_Set6_Item4','Weak+Noise_Set7_Item1','Weak+Noise_Set7_Item2','Weak+Noise_Set7_Item3','Weak+Noise_Set7_Item4','Weak+Noise_Set8_Item1','Weak+Noise_Set8_Item2','Weak+Noise_Set8_Item3','Weak+Noise_Set8_Item4','Noise+Speech_Set1_Item1','Noise+Speech_Set1_Item2','Noise+Speech_Set1_Item3','Noise+Speech_Set1_Item4','Noise+Speech_Set2_Item1','Noise+Speech_Set2_Item2','Noise+Speech_Set2_Item3','Noise+Speech_Set2_Item4','Noise+Speech_Set3_Item1','Noise+Speech_Set3_Item2','Noise+Speech_Set3_Item3','Noise+Speech_Set3_Item4','Noise+Speech_Set4_Item1','Noise+Speech_Set4_Item2','Noise+Speech_Set4_Item3','Noise+Speech_Set4_Item4','Noise+Speech_Set5_Item1','Noise+Speech_Set5_Item2','Noise+Speech_Set5_Item3','Noise+Speech_Set5_Item4','Noise+Speech_Set6_Item1','Noise+Speech_Set6_Item2','Noise+Speech_Set6_Item3','Noise+Speech_Set6_Item4','Noise+Speech_Set7_Item1','Noise+Speech_Set7_Item2','Noise+Speech_Set7_Item3','Noise+Speech_Set7_Item4','Noise+Speech_Set8_Item1','Noise+Speech_Set8_Item2','Noise+Speech_Set8_Item3','Noise+Speech_Set8_Item4'};
temp = load([GLMDir filesep 'SPM.mat']);
labelnames = {};
for i = 1:length(temp.SPM.Sess(1).U)
    if ~strncmp(temp.SPM.Sess(1).U(i).name,{'photo','line'},4)
        continue
    else
        labelnames(end+1) = temp.SPM.Sess(1).U(i).name;
    end
end
labels = 1:length(labelnames);

%% Make effect-maps (by correlating neural RDMs to model RDMs)

version = 'spearman'; % how to assess accuracy of model RDMs (pearson, spearman, weighted average)

if downsamp_ratio == 1
    outputDir = fullfile(GLMDir,'TDTcrossnobis',version);
else
    outputDir = fullfile(GLMDir,['TDTcrossnobis_downsamp_' num2str(downsamp_ratio)],version);
end
if ~exist(outputDir,'dir') mkdir(outputDir); end

clear models

version = 'spearman'; % how to assess accuracy of model RDMs (pearson, spearman, weighted average)

if downsamp_ratio == 1
    outputDir = fullfile(GLMDir,'TDTcrossnobis',version);
else
    outputDir = fullfile(GLMDir,['TDTcrossnobis_downsamp_' num2str(downsamp_ratio)],version);
end
if redo_maps&&exist(outputDir,'dir'); rmdir(outputDir,'s'); mkdir(outputDir); else; mkdir(outputDir); end

clear models

basemodels.templates = zeros(15,15);
basemodels.templates(1:16:end) = 1;
basemodels.templates(2:48:end) = 1/3;
basemodels.templates(3:48:end) = 1/3;
basemodels.templates(16:48:end) = 1/3;
basemodels.templates(18:48:end) = 1/3;
basemodels.templates(31:48:end) = 1/3;
basemodels.templates(32:48:end) = 1/3;
basemodels.templates = 1-basemodels.templates;
basemodelNames = {'templates'};

basemodels.templates_noself = basemodels.templates;
basemodels.templates_noself(1:16:end) = NaN;
basemodelNames = {'templates','templates_noself'};

basemodels.decoding = ones(15,15);
basemodels.decoding(1:16:end) = 0;
basemodelNames = {'templates','templates_noself','decoding'};

% Load behavioural judgments
load([behaviour_folder subject '_photo_judgment_matrix.mat']);
load([behaviour_folder subject '_line_judgment_matrix.mat']);

basemodels.photo = photo_judgment_matrix;
basemodels.photo_noself = photo_judgment_matrix;
basemodels.photo_noself(1:16:end) = NaN;

basemodels.line = line_judgment_matrix;
basemodels.line_noself = line_judgment_matrix;
basemodels.line_noself(1:16:end) = NaN;

basemodels.judgment = (photo_judgment_matrix+line_judgment_matrix)/2;
basemodels.judgment_noself = (photo_judgment_matrix+line_judgment_matrix)/2;
basemodels.judgment_noself(1:16:end) = NaN;

basemodelNames = {'templates','templates_noself','decoding','photo','photo_noself','line','line_noself','judgment','judgment_noself'};

[physical_dissimilarity,domesticity_dissimilarity,setting_dissimilarity,biological_dissimilarity,nonphysical_dissimilarity] = McRae_Dissimilarities;

basemodels.physical_dissimilarity = physical_dissimilarity;
basemodels.physical_dissimilarity_noself = physical_dissimilarity;
basemodels.physical_dissimilarity_noself(1:16:end) = NaN;

basemodels.nonphysical_dissimilarity = nonphysical_dissimilarity;
basemodels.nonphysical_dissimilarity_noself = nonphysical_dissimilarity;
basemodels.nonphysical_dissimilarity_noself(1:16:end) = NaN;

basemodelNames = {'templates','templates_noself','decoding','photo','photo_noself','line','line_noself','judgment','judgment_noself','physical_dissimilarity','physical_dissimilarity_noself','nonphysical_dissimilarity','nonphysical_dissimilarity_noself'};

% Now load visual models
gistRDM = generateGistRDMs_SERPENT; %NB: Time consuming, so just loads result if re-run

load(fullfile(cfg.results.dir,'res_other_average.mat'));
data = results.other_average.output;
notempty_data = find(~cellfun(@isempty,results.other_average.output));
modeltemplate = NaN(size(results.other_average.output{notempty_data(1)}));
 
    % Condition order is annoying - not conducive to easy RSA matrix formation
    %stim_type_labels = allcomb(styledir, frequency_labels, direction_labels, category_labels)
    % Rotation order is:
    % Style - photo vs line_drawing
    % Frequency - common vs moderate vs rare
    % Direction - left vs right
    % Template - dog-like vs cat-like vs horse-like vs marine vs birds
    
    styles = {'photo','line_drawings'};
    frequency = {'common','moderate','rare'};
    direction = {'left','right'};
    template = {'dog-like','cat-like','horse-like','marine','birds'};
    all_combinations = {[styles{1} '_' direction{1}];[styles{1} '_' direction{2}];[styles{2} '_' direction{1}];[styles{2} '_' direction{2}]};
    all_combinations_replicated = [repmat({[styles{1} '_' direction{1}]},15,1);repmat({[styles{1} '_' direction{2}]},15,1);repmat({[styles{2} '_' direction{1}]},15,1);repmat({[styles{2} '_' direction{2}]},15,1)];
    %rotations = [2,3,2,5]; % For later illustration of dissimilarity matrices
    stim_type_table = cell2table(allcomb(styles, frequency, direction, template),'VariableNames',{'styles','frequency','direction','template'});
    stim_type_table.stimnumber = [1:size(stim_type_table,1)]';
    
    %Now sort into a more sensible order for visualisation
    sorted_stim_type_table = cell2table(allcomb(styles, direction, template, frequency),'VariableNames',{'styles','direction','template','frequency'});
    sorted_stim_type_table.designnumber = [1:size(stim_type_table,1)]';
    joined_table = join(sorted_stim_type_table,stim_type_table);
    joined_table_originalorder = join(stim_type_table,sorted_stim_type_table);
    [stim_type_table(strcmp(stim_type_table.direction,direction{1}),:);stim_type_table(strcmp(stim_type_table.direction,direction{2}),:)];
    
    % First set up a global template based model - keep the others for later
    % more complex design matrices
    global_template_model = zeros(size(modeltemplate));
    for i = 1:length(labelnames)
        this_template = zeros(1,length(template));
        for j = 1:length(template)
            this_template(j) = contains(labelnames{i},template{j});
        end
        this_template_type = template{find(this_template)};
        for j = 1:length(labelnames)
            if contains(labelnames{j},this_template_type)
                global_template_model(i,j) = 1/3;
            end
        end
    end
    global_template_model(1:size(global_template_model,1)+1:end) = NaN; %Diagonal
    global_template_model = 1-global_template_model; %Dissimilarity
    this_model_name{1} = 'Global_Template_Model';
    models{1} = global_template_model;

%     %Individual sets
%     for i = 1:length(basemodelNames)
%         for j = 1:length(all_combinations)
%             model_unsorted = modeltemplate;
%             this_basemodel = eval(['basemodels.' basemodelNames{i}]);
%             model_unsorted(15*(j-1)+1:15*j,15*(j-1)+1:15*j)=this_basemodel;
%             models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
%             this_model_name{end+1} = [basemodelNames{i} ' within ' all_combinations{j}];
%             %Optional check - view matrix
%             %                 imagesc(models{this_model},'AlphaData',~isnan(models{this_model}))
%             %                 title(this_model_name{this_model})
%             %                 pause
%         end
%     end
    
    %Combined set
    for i = 1:length(basemodelNames)
        model_unsorted = modeltemplate;
        for j = 1:length(all_combinations)
            this_basemodel = eval(['basemodels.' basemodelNames{i}]);
            model_unsorted(15*(j-1)+1:15*j,15*(j-1)+1:15*j)=this_basemodel;
        end
        models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
        this_model_name{end+1} = ['All ' basemodelNames{i}];
    end
 
% cross_decode_label_pairs = {
%     'photo_left', 'line_drawings_left';
%     'photo_right', 'line_drawings_left';
%     'photo_left', 'line_drawings_right';
%     'photo_right', 'line_drawings_right';
%     'photo_left', 'photo_right';
%     'line_drawings_left', 'line_drawings_right';
% };
% 
% for i = 1:length(basemodelNames)
%     for j = 1:size(cross_decode_label_pairs,1)
%         this_basemodel = eval(['basemodels.' basemodelNames{i}]);
%         model_unsorted = modeltemplate;
%         model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
%         model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
%         models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
%         this_model_name{end+1} = [cross_decode_label_pairs{j,1} ' to ' cross_decode_label_pairs{j,2} ' ' basemodelNames{i}];
%     end
% end

cross_decode_label_pairs = {
    'photo_left', 'line_drawings_left';
    'photo_right', 'line_drawings_left';
    'photo_left', 'line_drawings_right';
    'photo_right', 'line_drawings_right';
};

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Photo to Line ' basemodelNames{i}];
end

cross_decode_label_pairs = {
    'photo_right', 'line_drawings_left';
    'photo_left', 'line_drawings_right';
    'photo_left', 'photo_right';
    'line_drawings_left', 'line_drawings_right';
    };

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Left to Right ' basemodelNames{i}];
end

cross_decode_label_pairs = {
    'photo_left', 'photo_left'
    'photo_right', 'photo_right';
    'photo_right', 'photo_left';
    };

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Global Photo ' basemodelNames{i}];
end

cross_decode_label_pairs = {
    'line_drawings_left', 'line_drawings_left'
    'line_drawings_right', 'line_drawings_right';
    'line_drawings_right', 'line_drawings_left';
    };

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Global Line Drawings ' basemodelNames{i}];
end

cross_decode_label_pairs = {
    'photo_right', 'photo_left';
    'line_drawings_right', 'line_drawings_left';
    'photo_right', 'line_drawings_right';
    'photo_right', 'line_drawings_left';
    'photo_left', 'line_drawings_right';
    'photo_left', 'line_drawings_left';
    };

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Between ' basemodelNames{i}];
end

cross_decode_label_pairs = {
    'photo_left', 'photo_left'
    'photo_right', 'photo_right';
    'line_drawings_left', 'line_drawings_left'
    'line_drawings_right', 'line_drawings_right';
    'photo_right', 'photo_left';
    'line_drawings_right', 'line_drawings_left';
    'photo_right', 'line_drawings_right';
    'photo_right', 'line_drawings_left';
    'photo_left', 'line_drawings_right';
    'photo_left', 'line_drawings_left';
    };

for i = 1:length(basemodelNames)
    this_basemodel = eval(['basemodels.' basemodelNames{i}]);
    model_unsorted = modeltemplate;
    for j = 1:size(cross_decode_label_pairs,1)
        model_unsorted(strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated)) = this_basemodel;
        model_unsorted(strcmp(cross_decode_label_pairs{j,2},all_combinations_replicated),strcmp(cross_decode_label_pairs{j,1},all_combinations_replicated)) = this_basemodel';
    end
    models{end+1} = model_unsorted(joined_table_originalorder.designnumber,joined_table_originalorder.designnumber);
    this_model_name{end+1} = ['Global ' basemodelNames{i}];
end

% 
% % Now add combined conditions
% cross_decode_label_pairs = {
%     'Match Unclear', 'Mismatch Unclear';
%     'Match Clear', 'Mismatch Unclear';
%     'Match Unclear', 'Mismatch Clear';
%     'Match Clear', 'Mismatch Clear';
%     'Match Unclear', 'Match Clear';
%     'Mismatch Unclear', 'Mismatch Clear';};
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['All spoken Cross-decode_Match'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['All spoken SS_Match'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments';
% end
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['All spoken SS_Match - no self'];
% basemodels.shared_segments(1:17:end) = NaN;
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments';
% end
% basemodels.shared_segments(1:17:end) = 0;
% 
% cross_decode_label_pairs = {
%     'Match Unclear', 'Written';
%     'Match Clear', 'Written';
%     'Mismatch Unclear', 'Written';
%     'Mismatch Clear', 'Written'
%     };
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written Cross-decode_Match'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written SS_Match - no self'];
% basemodels.shared_segments(1:17:end) = NaN;
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments';
% end
% basemodels.shared_segments(1:17:end) = 0;
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written Cross-decode_written'];
% for i = 1:2
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% for i = 3:4
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = MisMatch_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = MisMatch_Cross_decode_base';
% end
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written Cross-decode_written-lowpe'];
% for i = 2
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% for i = 3
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = MisMatch_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = MisMatch_Cross_decode_base';
% end
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written Cross-decode_written-highpe'];
% for i = 1
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% for i = 4
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = MisMatch_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = MisMatch_Cross_decode_base';
% end
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Spoken to Written SS_written - no self'];
% basemodels.shared_segments(1:17:end) = NaN;
% basemodels.shared_segments_cross(9:17:end/2) = NaN;
% basemodels.shared_segments_cross(end/2+1:17:end) = NaN;
% for i = 1:2
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments';
% end
% for i = 3:4
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments_cross';
% end
% basemodels.shared_segments_cross(9:17:end/2) = 0;
% basemodels.shared_segments_cross(end/2+1:17:end) = 0;
% basemodels.shared_segments(1:17:end) = 0;
% 
% % Now look at Match-Mismatch written word cross decoding
% cross_decode_label_pairs = {
%     'Match Unclear', 'Mismatch Unclear';
%     'Match Clear', 'Mismatch Unclear';
%     'Match Unclear', 'Mismatch Clear';
%     'Match Clear', 'Mismatch Clear';
%     };
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch Shared Segments - no self'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments_cross_noself;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments_cross_noself';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch SS_Match - no self'];
% basemodels.shared_segments(1:17:end) = NaN;
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.shared_segments;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.shared_segments';
% end
% basemodels.shared_segments(1:17:end) = 0;
% 
% basemodels.shared_segments(1:17:end) = NaN;
% basemodels.combined_SS = basemodels.shared_segments-basemodels.shared_segments_cross_noself;
% basemodels.shared_segments(1:17:end) = 0;
% 
% basemodels.combined_SS = (basemodels.combined_SS +1)/2; %Scale zero to 1
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch combined_SS - no self - rescaled'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.combined_SS;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.combined_SS';
% end
% 
% basemodels.only_cross = basemodels.combined_SS;
% basemodels.only_cross(basemodels.shared_segments~=1) = NaN;
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch only cross'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_cross';
% end
% 
% basemodels.only_not_cross = basemodels.combined_SS;
% basemodels.only_not_cross(basemodels.shared_segments_cross_noself~=1) = NaN;
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch only not cross'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_not_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_not_cross';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch cross-decode written'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = MisMatch_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = MisMatch_Cross_decode_base';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Match to Mismatch cross-decode spoken'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = Match_Cross_decode_base;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = Match_Cross_decode_base';
% end
% 
% % Now look at these three models Clear-Unclear
% % then in every individual combination
% cross_decode_label_pairs = {
%     'Match Unclear', 'Match Clear';
%     'Mismatch Unclear', 'Mismatch Clear';
%     'Match Unclear', 'Mismatch Clear';
%     'Match Clear', 'Mismatch Unclear';
%     };
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Clear to Unclear combined_SS - no self - rescaled'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.combined_SS;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.combined_SS';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Clear to Unclear only cross'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_cross';
% end
% 
% models{end+1} = modeltemplate;
% this_model_name{end+1} = ['Clear to Unclear only not cross'];
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_not_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_not_cross';
% end
% 
% cross_decode_label_pairs = {
%     'Match Unclear', 'Mismatch Unclear';
%     'Match Clear', 'Mismatch Unclear';
%     'Match Unclear', 'Mismatch Clear';
%     'Match Clear', 'Mismatch Clear'
%     'Match Unclear', 'Match Clear';
%     'Mismatch Unclear', 'Mismatch Clear';
%     };
% 
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end+1} = modeltemplate;
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.combined_SS;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.combined_SS';
%     this_model_name{end+1} = [cross_decode_label_pairs{i,1} ' to ' cross_decode_label_pairs{i,2} ' combined_SS - no self'];
%     %Optional check - view matrix
%     %             imagesc(models{end},'AlphaData',~isnan(models{end}))
%     %             title(this_model_name{end})
%     %             pause
% end
% 
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end+1} = modeltemplate;
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_cross';
%     this_model_name{end+1} = [cross_decode_label_pairs{i,1} ' to ' cross_decode_label_pairs{i,2} ' only cross'];
%     %Optional check - view matrix
%     %             imagesc(models{end},'AlphaData',~isnan(models{end}))
%     %             title(this_model_name{end})
%     %             pause
% end
% 
% for i = 1:size(cross_decode_label_pairs,1)
%     models{end+1} = modeltemplate;
%     models{end}(strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered)) = basemodels.only_not_cross;
%     models{end}(strcmp(cross_decode_label_pairs{i,2},labelnames_denumbered),strcmp(cross_decode_label_pairs{i,1},labelnames_denumbered)) = basemodels.only_not_cross';
%     this_model_name{end+1} = [cross_decode_label_pairs{i,1} ' to ' cross_decode_label_pairs{i,2} ' only not cross'];
%     %Optional check - view matrix
%     %             imagesc(models{end},'AlphaData',~isnan(models{end}))
%     %             title(this_model_name{end})
%     %             pause
% end
% 

V = spm_vol(fullfile(GLMDir,'mask.nii'));
mask = spm_read_vols(V);
mask_index = results.mask_index;
downsamped_V.mat = V.mat;
downsamped_V.mat(1:3,1:3)=downsamped_V.mat(1:3,1:3)*downsamp_ratio;

clear results % to free memory

%% Save design matrices for visualisation
if save_design_matrices
    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf,'color','w');
    multivariate_matrix_dir = './multivariate_design matrices/';
    if ~exist(multivariate_matrix_dir,'dir')
        mkdir(multivariate_matrix_dir)
    end
    for m=1:length(this_model_name)
        if ~all(all(isnan(models{m}(1:60,1:60))))
            %Unmix model to more sensible ordering:
            unmixed_model{m} = models{m}(joined_table.stimnumber,joined_table.stimnumber)
            b = imagesc(unmixed_model{m}(1:60,1:60),[floor(min(min(unmixed_model{m}(1:60,1:60)))) ceil(max(max(unmixed_model{m}(1:60,1:60))))]);
            set(b,'AlphaData',~isnan(unmixed_model{m}(1:60,1:60)+diag(NaN(1,60)))) %Ensure diagonal is NaN because it is ignored by Mahalanobis distance
            axis square
            text(7.5,-1,'Photos Left', 'HorizontalAlignment', 'center', 'fontweight', 'bold' )
            text(15+7.5,-1,'Photos Right', 'HorizontalAlignment', 'center', 'fontweight', 'bold' )
            text(30+7.5,-1,'Line Left', 'HorizontalAlignment', 'center', 'fontweight', 'bold' )
            text(45+7.5,-1,'Line Right', 'HorizontalAlignment', 'center', 'fontweight', 'bold' )
            set(gca,'xtick',[0:15:60],'ytick',[0:15:60])
            drawnow
            saveas(gcf,[multivariate_matrix_dir this_model_name{m} '.pdf'])
            saveas(gcf,[multivariate_matrix_dir this_model_name{m} '.png'])
            colorbar
            drawnow
            saveas(gcf,[multivariate_matrix_dir this_model_name{m} '_withcolorbar.pdf'])
            saveas(gcf,[multivariate_matrix_dir this_model_name{m} '_withcolorbar.png'])
        end
    end
end

%% Now make effect maps
%parfor m=1:length(this_model_name) %Parallelising here impossible due to out of memory on serialisation unless data downsampled
for m=1:length(this_model_name) %Parallelising here impossible due to out of memory on serialisation unless data downsampled
    fprintf('\nComputing effect-map for model %s\n',this_model_name{m});
    if ~exist(fullfile(outputDir,['effect-map_' this_model_name{m} '.nii'])) || redo_maps == 1
        modelRDM = vectorizeRDMs(models{m})';
        effectMap = NaN(size(mask));
        for vx=1:numel(data)
            neuralRDM = vectorizeRDMs(data{vx})';
            if isempty(neuralRDM)
                continue
            end
            notempty = vx;
            if ~isempty(strfind(version,'pearson'))
                effectMap(mask_index(vx)) = fisherTransform(corr(modelRDM,neuralRDM,'type','Pearson','Rows','pairwise'));
            elseif ~isempty(strfind(version,'spearman'))
                effectMap(mask_index(vx)) = fisherTransform(corr(modelRDM,neuralRDM,'type','Spearman','Rows','pairwise'));
            elseif ~isempty(strfind(version,'average'))
                %effectMap(mask_index(vx)) = mean(neuralRDM(find(~isnan(modelRDM)),:),1);
                effectMap(mask_index(vx)) = mean(neuralRDM(find(modelRDM==1),:),1);
            end
            if ~mod(vx,100)
                disp(['Processing voxel ' num2str(vx) ' of ' num2str(numel(data))])
            end
        end
        dims = size(effectMap);
        downsamped_effectMap = effectMap(1:downsamp_ratio:dims(1),1:downsamp_ratio:dims(2),1:downsamp_ratio:dims(3));
        
        saveMRImage(downsamped_effectMap,fullfile(outputDir,['effect-map_' this_model_name{m} '.nii']),downsamped_V.mat);
    else
        disp('Already exists - moving on - set redo_maps to 1 if you want to re-make')
    end
end