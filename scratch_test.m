for start_idx = [idx_r, idx_l]
    %Work forwards and backwards from those points to make a tensor;
    [r,c,p] = ind2sub(size(face_map),start_idx);
    MNI_x = [face_map_info.mat(1,4)+(r*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(c*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(p*face_map_info.mat(3,3))];
    
    %Work forwards and backwards from that point to make a tensor;
    y_start = MNI_x(2);
    %First go backwards
    last_location = [r,c,p];
    these_negative_locations = [];
    these_negative_MNI_locations = [];
    for this_y = (c-1):-1:(c-50)
        this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)-r_temp+6,this_y,last_location(3)-c_temp+6];
            these_negative_locations = [these_negative_locations; last_location];
            last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
            these_negative_MNI_locations = [these_negative_MNI_locations; last_MNI_location];
        else % Less than 10% of subjects have face preference - end of tensor
            break
        end
    end
    
    %Then go forwards
    last_location = [r,c,p];
    these_positive_locations = [];
    these_positive_MNI_locations = [];
    for this_y = (c+1):1:(c+50)
        this_plane = face_map((last_location(1)-5):(last_location(1)+5),this_y,(last_location(3)-5):(last_location(3)+5));
        [mxv,idx] = max(this_plane(:)); % Look for a voxel within 1cm of previous in X+Z
        if mxv>0.1 % More than 10% of subjects have face preference here
            [r_temp,c_temp,p_temp] = ind2sub(size(this_plane),idx);
            last_location = [last_location(1)-r_temp+6,this_y,last_location(3)-c_temp+6];
            these_positive_locations = [these_positive_locations; last_location];
            last_MNI_location = [face_map_info.mat(1,4)+(last_location(1)*face_map_info.mat(1,1)), face_map_info.mat(2,4)+(last_location(2)*face_map_info.mat(2,2)), face_map_info.mat(3,4)+(last_location(3)*face_map_info.mat(3,3))];
            these_positive_MNI_locations = [these_positive_MNI_locations; last_MNI_location];
        else % Less than 10% of subjects have face preference - end of tensor
            break
        end
    end
    
    %Then create tensor
    these_locations = [flipud(these_negative_locations); [r,c,p]; these_positive_locations];
    these_MNI_locations = [flipud(these_negative_MNI_locations); MNI_x; these_positive_MNI_locations];
    % Interpolate from 2mm to 1mm resolution
    these_interpolated_MNI_locations = [];
    for this_y_loc = 1:size(these_MNI_locations,1)-1
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(this_y_loc,:)];
        these_interpolated_MNI_locations = [these_interpolated_MNI_locations; mean(these_MNI_locations(this_y_loc:this_y_loc+1,:),1)];
    end
    these_interpolated_MNI_locations = [these_interpolated_MNI_locations; these_MNI_locations(end,:)];
    try
        all_interpolated_MNI_locations = cat(3,all_interpolated_MNI_locations,these_interpolated_MNI_locations);
    catch
        all_interpolated_MNI_locations = these_interpolated_MNI_locations;
    end
end