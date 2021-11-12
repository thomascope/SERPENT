function module_plot_these_tensors_radius(this_model_name,these_tensors,outpath,group,subjects,radius)
% A function for plotting the beta weights along pre-specified tensors

% First check tensors same length

addpath ./plotting
for this_tensor = 1:length(these_tensors)
    for this_model = 1:length(this_model_name)
        
        load([outpath filesep this_model_name{this_model} filesep 'SPM.mat'])
        this_volume_info = spm_vol(SPM.xY.P{1}); % Assume all input images have same dimensions and slicing - necessary for SPM. Could put this in the loop otherwise, but slower
        for this_location = 1:size(these_tensors{this_tensor},1)    
            disp(['Working on location ' num2str(this_location) ' of ' num2str(size(these_tensors{this_tensor},1)) ' for ' this_model_name{this_model}]);
            center_point = these_tensors{this_tensor}(this_location,:);
            x_locs = these_tensors{this_tensor}(this_location,1)-radius:these_tensors{this_tensor}(this_location,1)+radius;
            z_locs = these_tensors{this_tensor}(this_location,3)-radius:these_tensors{this_tensor}(this_location,3)+radius;
            all_combinations = combvec(x_locs,z_locs)';
            Idx = rangesearch(all_combinations,[these_tensors{this_tensor}(this_location,1),these_tensors{this_tensor}(this_location,3)],radius); % Create a coronal circle of given radius around the y-coordinate
            all_combinations = all_combinations(sort(Idx{1}),:);
            these_voxel_coordinates = [all_combinations(:,1),repmat(these_tensors{this_tensor}(this_location,2),size(all_combinations(:,1))),all_combinations(:,2),ones(size(all_combinations(:,1)))]*(inv(this_volume_info.mat))';
            XYZ = these_voxel_coordinates(:,1:3)';
            for crun = 1:size(subjects,2)
                all_data{this_tensor}(crun,this_model,this_location) = max(spm_get_data(SPM.xY.P{crun}, XYZ));
            end
        end
        disp(['Working on t-scores for ' this_model_name{this_model}]);
        this_volume_info = spm_vol([outpath filesep this_model_name{this_model} filesep 'spmT_0001.nii']);
        for this_location = 1:size(these_tensors{this_tensor},1)
            
            center_point = these_tensors{this_tensor}(this_location,:);
            x_locs = these_tensors{this_tensor}(this_location,1)-radius:these_tensors{this_tensor}(this_location,1)+radius;
            z_locs = these_tensors{this_tensor}(this_location,3)-radius:these_tensors{this_tensor}(this_location,3)+radius;
            all_combinations = combvec(x_locs,z_locs)';
            Idx = rangesearch(all_combinations,[these_tensors{this_tensor}(this_location,1),these_tensors{this_tensor}(this_location,3)],radius); % Create a coronal circle of given radius around the y-coordinate
            all_combinations = all_combinations(sort(Idx{1}),:);
            these_voxel_coordinates = [all_combinations(:,1),repmat(these_tensors{this_tensor}(this_location,2),size(all_combinations(:,1))),all_combinations(:,2),ones(size(all_combinations(:,1)))]*(inv(this_volume_info.mat))';
            XYZ = these_voxel_coordinates(:,1:3)';
            
            all_control_tscores{this_tensor}(this_model,this_location) = max(spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0001.nii'], XYZ));
            all_patient_tscores{this_tensor}(this_model,this_location) = max(spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0002.nii'], XYZ));
            all_controlmax_difference_tscores{this_tensor}(this_model,this_location) = max(spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0003.nii'], XYZ));
            all_patientmax_difference_tscores{this_tensor}(this_model,this_location) = max(spm_get_data([outpath filesep this_model_name{this_model} filesep 'spmT_0004.nii'], XYZ));
        end
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
        plot(these_tensors{this_tensor}(:,2),all_controlmax_difference_tscores{this_tensor}(this_model,:),'k')
        plot(these_tensors{this_tensor}(:,2),all_patientmax_difference_tscores{this_tensor}(this_model,:),'k--')
        plot(these_tensors{this_tensor}(:,2),zeros(1,length(these_tensors{this_tensor}(:,2))),'k--')
        title(this_model_name{this_model},'Interpreter','none')
        xlabel('Y Location')
        ylabel('t-score')
    end
end