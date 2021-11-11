function module_plot_these_tensors(this_model_name,these_tensors,outpath,group,subjects)
% A function for plotting the beta weights along pre-specified tensors

% First check tensors same length

addpath ./plotting
for this_tensor = 1:length(these_tensors)
    for this_model = 1:length(this_model_name)
        
        load([outpath filesep this_model_name{this_model} filesep 'SPM.mat'])
        for crun = 1:size(subjects,2)
            disp(['Working on subject ' subjects{crun} ' ' this_model_name{this_model}]);
            this_volume_info = spm_vol(SPM.xY.P{crun});
            these_voxel_coordinates = [these_tensors{this_tensor},ones(size(these_tensors{this_tensor},1),1)]*(inv(this_volume_info.mat))';
            XYZ = these_voxel_coordinates(:,1:3)';
            all_data{this_tensor}(crun,this_model,:) = spm_get_data(SPM.xY.P{crun}, XYZ);
        end
        this_volume_info = spm_vol([outpath filesep this_model_name{this_model} filesep 'spmT_0001.nii']);
        these_voxel_coordinates = [these_tensors{this_tensor},ones(size(these_tensors{this_tensor},1),1)]*(inv(this_volume_info.mat))';
        XYZ = these_voxel_coordinates(:,1:3)';
        
        all_control_tscores{this_tensor}(this_model,:) = spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0001.nii'], XYZ);
        all_patient_tscores{this_tensor}(this_model,:) = spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0002.nii'], XYZ);
        all_difference_tscores{this_tensor}(this_model,:) = spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0003.nii'], XYZ);
        
    end
end


figure
set(gcf,'Position',[100 100 1600 800]);
for this_tensor = 1:length(these_tensors)
    for this_model = 1:length(this_model_name)
        subplot(length(this_model_name),length(these_tensors),this_tensor+((this_model-1)*length(these_tensors)))
        linehandle(1) = stdshade_TEC(squeeze(all_data{this_tensor}(group==1,this_model,:)),0.2,'g',these_tensors{this_tensor}(:,2),1,1);
        hold on
        linehandle(2) = stdshade_TEC(squeeze(all_data{this_tensor}(group==2,this_model,:)),0.2,'r',these_tensors{this_tensor}(:,2),1,1);
        plot(these_tensors{this_tensor}(:,2),zeros(1,length(these_tensors{this_tensor}(:,2))),'k--')
        title(this_model_name{this_model},'Interpreter','none')
        xlabel('Y Location')
        ylabel('Spearman')
    end
end
figure
set(gcf,'Position',[100 100 1200 1000]);
for this_tensor = 1:length(these_tensors)
    for this_model = 1:length(this_model_name)
        subplot(length(this_model_name),length(these_tensors),this_tensor+((this_model-1)*length(these_tensors)))
        plot(these_tensors{this_tensor}(:,2),all_control_tscores{this_tensor}(this_model,:),'g')
        hold on
        plot(these_tensors{this_tensor}(:,2),all_patient_tscores{this_tensor}(this_model,:),'r')
        plot(these_tensors{this_tensor}(:,2),all_difference_tscores{this_tensor}(this_model,:),'k')
        linehandle(2) = stdshade_TEC(squeeze(all_data{this_tensor}(group==2,this_model,:)),0.2,'r',these_tensors{this_tensor}(:,2),1,1);
        plot(these_tensors{this_tensor}(:,2),zeros(1,length(these_tensors{this_tensor}(:,2))),'k--')
        title(this_model_name{this_model},'Interpreter','none')
        xlabel('Y Location')
        ylabel('t-score')
    end
end