addpath('/group/language/data/thomascope/7T_SERPENT_pilot_analysis')
setup_file = 'SERPENT_subjects_parameters';
eval(setup_file)

behaviour_folder = '/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/judgment_dissim_matrices/';

visualise = 0; %whether to show averages at the end

all_control_photo_judgment_matrices = [];
all_control_line_judgment_matrices = [];
all_patient_photo_judgment_matrices = [];
all_patient_line_judgment_matrices = [];

for i = 1:length(subjects)
    if group(i) == 1 %control
        if isempty(all_control_photo_judgment_matrices)
            all_control_photo_judgment_matrices = struct2array(load([behaviour_folder subjects{i} '_photo_judgment_matrix.mat']));
            all_control_line_judgment_matrices = struct2array(load([behaviour_folder subjects{i} '_line_judgment_matrix.mat']));
        else
            all_control_photo_judgment_matrices(:,:,end+1) = struct2array(load([behaviour_folder subjects{i} '_photo_judgment_matrix.mat']));
            all_control_line_judgment_matrices(:,:,end+1) = struct2array(load([behaviour_folder subjects{i} '_line_judgment_matrix.mat']));
        end
    elseif group(i) == 2 %patient
        if isempty(all_patient_photo_judgment_matrices)
            all_patient_photo_judgment_matrices = struct2array(load([behaviour_folder subjects{i} '_photo_judgment_matrix.mat']));
            all_patientline_judgment_matrices = struct2array(load([behaviour_folder subjects{i} '_line_judgment_matrix.mat']));
        else
            all_patient_photo_judgment_matrices(:,:,end+1) = struct2array(load([behaviour_folder subjects{i} '_photo_judgment_matrix.mat']));
            all_patient_line_judgment_matrices(:,:,end+1) = struct2array(load([behaviour_folder subjects{i} '_line_judgment_matrix.mat']));
        end
    end
end

average_control_photo_judgment_matrix = mean(all_control_photo_judgment_matrices,3);
average_control_line_judgment_matrix = mean(all_control_line_judgment_matrices,3);
average_patient_photo_judgment_matrix = mean(all_patient_photo_judgment_matrices,3);
average_patient_line_judgment_matrix = mean(all_patient_line_judgment_matrices,3);
overall_control_judgment_matrix = (average_control_photo_judgment_matrix+average_control_line_judgment_matrix)/2;
overall_patient_judgment_matrix = (average_patient_photo_judgment_matrix+average_patient_line_judgment_matrix)/2;

unmixed_model = {average_control_photo_judgment_matrix; average_control_line_judgment_matrix; average_patient_photo_judgment_matrix; average_patient_line_judgment_matrix; overall_control_judgment_matrix; overall_patient_judgment_matrix};
this_model_name = {'average_control_photo_judgment_matrix'; 'average_control_line_judgment_matrix'; 'average_patient_photo_judgment_matrix'; 'average_patient_line_judgment_matrix'; 'overall_control_judgment_matrix'; 'overall_patient_judgment_matrix'};

save('average_judgments.mat','average_control_photo_judgment_matrix', 'average_control_line_judgment_matrix', 'average_patient_photo_judgment_matrix', 'average_patient_line_judgment_matrix', 'overall_control_judgment_matrix', 'overall_patient_judgment_matrix');

if visualise
    for m = 1:length(this_model_name)
    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf,'color','w');
    b = imagesc(unmixed_model{m}(1:15,1:15),[floor(min(min(unmixed_model{m}(1:15,1:15)))) ceil(max(max(unmixed_model{m}(1:15,1:15))))]);
    set(b,'AlphaData',~isnan(unmixed_model{m}(1:15,1:15)+diag(NaN(1,15)))) %Ensure diagonal is NaN because it is ignored by Mahalanobis distance
    axis square
    title(this_model_name{m})
    drawnow
    saveas(gcf,[behaviour_folder this_model_name{m} '.pdf'])
    saveas(gcf,[behaviour_folder this_model_name{m} '.png'])
    colorbar
    drawnow
    saveas(gcf,[behaviour_folder this_model_name{m} '_withcolorbar.pdf'])
    saveas(gcf,[behaviour_folder this_model_name{m} '_withcolorbar.png'])

    end
end