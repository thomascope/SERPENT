
% Add covariates of interest - Animal knowlege
% Note the lookup below relies on the new Matlab variable renaming on table
% read
psychology_lookup = readtable('SERPENT_Only_Included.csv');
for crun = 1:length(subjects)
    this_animalknowledge(crun) = psychology_lookup.TotalAnimals_60(strcmp(psychology_lookup.SubjectID,subjects{crun}));
    this_PyramidsPalmTrees(crun)= psychology_lookup.PyramidsPalmTrees_52(strcmp(psychology_lookup.SubjectID,subjects{crun}));
end
covariates = [this_animalknowledge', this_PyramidsPalmTrees'];
covariate_names = horzcat({'Animal Knowledge' 'Pyramids and Palm Trees'});

% Now plot ROI results
GLMDir = [preprocessedpathstem subjects{1} '/stats_native_mask0.3_3_coreg_reversedbuttons']; %Template, first subject
outdir = ['./ROI_figures/stats_native_mask0.3_3_coreg_reversedbuttons/correlations'];
mkdir(outdir)
temp = load([GLMDir filesep 'SPM.mat']);

% %Just list all the mask names in tensors 1+2 for reference here
% mask_names = {
%     'rwGlasser_ 1_V1_L'
% 'rwGlasser_ 4_V2_L'
% 'rwGlasser_ 5_V3_L'
% 'rwGlasser_ 6_V4_L'
% 'rwGlasser_ 158_V3CD_L'
% 'rwGlasser_ 20_LO1_L'
% 'rwGlasser_ 21_LO2_L'
% 'rwGlasser_ 156_V4t_L'
% 'rwGlasser_ 157_FST_L'
% 'rwGlasser_ 2_MST_L'
% 'rwGlasser_ 23_MT_L'
% 'rwGlasser_ 22_PIT_L'
% 'rwGlasser_ 138_PH_L'
% 'rwGlasser_ 18_FFC_L'
% 'rwGlasser_ 7_V8_L'
% 'rwGlasser_ 163_VVC_L'
% 'rwGlasser_ 127_PHA3_L'
% 'rwGlasser_ 201_V1_R'
% 'rwGlasser_ 204_V2_R'
% 'rwGlasser_ 205_V3_R'
% 'rwGlasser_ 206_V4_R'
% 'rwGlasser_ 358_V3CD_R'
% 'rwGlasser_ 220_LO1_R'
% 'rwGlasser_ 221_LO2_R'
% 'rwGlasser_ 222_PIT_R'
% 'rwGlasser_ 356_V4t_R'
% 'rwGlasser_ 223_MT_R'
% 'rwGlasser_ 338_PH_R'
% 'rwGlasser_ 357_FST_R'
% 'rwGlasser_ 218_FFC_R'
% 'rwGlasser_ 363_VVC_R'
% 'rwGlasser_ 336_TE2p_R'
% 'rwGlasser_ 327_PHA3_R'};

%regions of particular interest:
mask_names = {
    'rwGlasser_ 338_PH_R'
    'rwGlasser_ 357_FST_R'
    'rwGlasser_ 218_FFC_R'
    'rwGlasser_ 336_TE2p_R'
    };

%simplified list
this_model_name = {
    'Photo to Line templates_noself'
    'Photo to Line control_judgment_noself'
    };

nrun = size(subjects,2); % enter the number of runs here
% First load in the similarities
RSA_ROI_data_exist = zeros(length(this_model_name),length(mask_names),nrun);
all_data = [];

all_rho = [];
all_corr_ps = [];
all_corrected_rho = [];
all_corrected_corr_ps = [];

for j = 1:length(this_model_name)
    all_data = [];
    all_corrected_data = [];
    for k = 1:length(mask_names)
        for crun = 1:nrun
            %ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/RSA/spearman']; %Where are the results>
            ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/' mask_names{k} '/RSA/spearman'];
            if ~exist(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} '.mat']),'file')
                ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI' mask_names{k} '/RSA/spearman']; % Stupid coding error earlier in analysis led to misnamed directories
            end
            try
                temp_data = load(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} '.mat']));
                all_data(j,k,crun) = temp_data.roi_effect; %Create a matrix of condition by ROI by subject
                RSA_ROI_data_exist(j,k,crun) = 1;
            catch
                warning(['No data for ' subjects{crun} ' probably because of SPM dropout, ignoring them'])
                %error
                RSA_ROI_data_exist(j,k,crun) = 0;
                all_data(j,k,crun) = NaN;
                continue
            end
        end
        roi_names = temp_data.roi_names;
        disp(['Excluding subjects ' num2str(find(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' belonging to groups ' num2str(group(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' maybe check them'])
    end
    all_corrected_data(j,:,group==1) = es_removeBetween_rotated(all_data(j,:,group==1),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
    all_corrected_data(j,:,group==2) = es_removeBetween_rotated(all_data(j,:,group==2),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here

    for k = 1:length(mask_names)
        for l = 1:length(covariate_names)
            figure
            set(gcf,'Position',[100 100 1600 800]);
            set(gcf, 'PaperPositionMode', 'auto');
            hold on
            scatter(covariates(:,l),squeeze(all_corrected_data(j,k,:)),1,'kx')
            lsline
            pats = scatter(covariates(group==1,l),squeeze(all_corrected_data(j,k,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx');
            cons = scatter(covariates(group==2,l),squeeze(all_corrected_data(j,k,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx');

            title([this_model_name{j} ' ' mask_names{k} ' ' covariate_names{l}],'Interpreter','none')

            if verLessThan('matlab', '9.2')
                legend([pats cons],'Controls','Patients','location','northeast')
            else
                legend([pats cons],'Controls','Patients','location','northeast','AutoUpdate','off')
            end

            ylabel('RSA');
            xlabel(covariate_names{l},'Interpreter','none')

            plot([min(covariates(:,l)) max(covariates(:,l))],[0,0],'k--')
            [overall_rho,overall_p] = corr(covariates(:,l), squeeze(all_corrected_data(j,k,:)),'type', 'Spearman');
            [patientsonly_rho,patientsonly_p] = corr(covariates(group==2,l), squeeze(all_corrected_data(j,k,group==2)),'type', 'Spearman');

            subtitle(['Overall correllation ' num2str(overall_rho) ' p=' num2str(overall_p) ', patient correlation ' num2str(patientsonly_rho) ', p=' num2str(patientsonly_p)])

            drawnow
            saveas(gcf,[outdir filesep this_model_name{j} ' ' mask_names{k} ' ' covariate_names{l} '.png'])
            saveas(gcf,[outdir filesep this_model_name{j} ' ' mask_names{k} ' ' covariate_names{l} '.pdf'])

        end
    end
end
close all