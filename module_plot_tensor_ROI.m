function all_data = module_plot_tensor_ROI(these_tensors,atlaspath,radius)
% A function for plotting the beta weights along pre-specified tensors

% First check tensors same length

this_volume_info = spm_vol(atlaspath); % Assume all input images have same dimensions and slicing - necessary for SPM. Could put this in the loop otherwise, but slower
for this_tensor = 1:length(these_tensors)
    for this_location = 1:size(these_tensors{this_tensor},1)
        center_point = these_tensors{this_tensor}(this_location,:);
        x_locs = these_tensors{this_tensor}(this_location,1)-radius:these_tensors{this_tensor}(this_location,1)+radius;
        z_locs = these_tensors{this_tensor}(this_location,3)-radius:these_tensors{this_tensor}(this_location,3)+radius;
        all_combinations = combvec(x_locs,z_locs)';
        Idx = rangesearch(all_combinations,[these_tensors{this_tensor}(this_location,1),these_tensors{this_tensor}(this_location,3)],radius); % Create a coronal circle of given radius around the y-coordinate
        all_combinations = all_combinations(sort(Idx{1}),:);
        these_voxel_coordinates = [all_combinations(:,1),repmat(these_tensors{this_tensor}(this_location,2),size(all_combinations(:,1))),all_combinations(:,2),ones(size(all_combinations(:,1)))]*(inv(this_volume_info.mat))';
        XYZ = these_voxel_coordinates(:,1:3)';
        try
            all_data{this_tensor} = [all_data{this_tensor}; nonzeros(unique(spm_get_data(atlaspath, XYZ)))];
        catch
            all_data{this_tensor} = [nonzeros(unique(spm_get_data(atlaspath, XYZ)))];
        end
    end
    all_data{this_tensor} = unique(all_data{this_tensor},'stable');
end

