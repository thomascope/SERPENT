%% MODEL SIMPLE AND COMPLEX V1 RESPONSES%   [S1 , C1] = V1modelResponse ( imageFileName )%   reads the image stored in the file "imageFileName" and processes it%   by a bank of simple and complex V1-like cells. The receptive fields of%   simple V1 cells are modeled by Gabor filters, and complex V1 cells are%   assumed to perform a MAX operation on the output of simple cells (Lampl%   et al 2004). %   The receptive field sizes are in the range of the actual V1 cells when  %   every 25 pixels of the image corresponds to one degree of visual%   angle. %   S1 and C1 are responses of the simple and complex cells respectively.%   They also correspond to the S1 and C1 layers of the MAX model. Adopted%   from the HMAX model of Riesenhuber and Poggio.%%   Roozbeh Kiani   07/04/2005%   modified: niko kriegeskorte, oct 2006function [S1 , C1, stim] = V1modelResponse_SERPENT ( stim )stim = im2double(rgb2gray(stim));if size(stim,1) ~= size(stim,2),    error ( 'the image should be a square' );end;filter_sizes = { [7:2:9] , [11:2:15] , [17:2:21] , [23:2:29] };C1_pooling = [ 4 , 6 , 9 , 12];num_orientation = 4;gaborspec.k = 2.1;gaborspec.sig_xy = [1/3, 1/1.8]*2*pi;gaborspec.phase = 0;size_S1 = 0;for which_band = 1 : length(filter_sizes),    size_S1 = size_S1 + length(filter_sizes{which_band});end;S1 = zeros ( size(stim,1) , size(stim,2) , size_S1 , num_orientation );C1 = zeros ( size(stim,1) , size(stim,2) , length(filter_sizes) , num_orientation );S1_idx = 1;for which_band = 1 : length(filter_sizes),    S1_tmp = S1resp_gabor_zeropad ( stim , filter_sizes{which_band} , num_orientation , gaborspec );    C1(:,:,which_band,:) = C1resp_zeropad ( S1_tmp , C1_pooling(which_band) );    S1(:,:,S1_idx+(0:length(filter_sizes{which_band})-1),:) = S1_tmp;    S1_idx = S1_idx + length(filter_sizes{which_band});    end;function C1 = C1resp_zeropad ( S1 , C1_pooling )C1 = zeros(size(S1));for i = 1 : size(S1,1),    x1 = i;    x2 = min([size(S1,1) x1+C1_pooling-1]);    for j = 1 : size(S1,2),        y1 = j;        y2 = min([size(S1,2) y1+C1_pooling-1]);        S1_patch = abs(S1(x1:x2,y1:y2,:,:));        C1(i,j,:,:) = max(max(S1_patch,[],2),[],1);    end;end;C1 = squeeze(max(C1,[],3));function S1 = S1resp_gabor_zeropad ( stim , filter_sizes , num_orientation , gaborspec )S1 = zeros ( size(stim,1) , size(stim,2) , length(filter_sizes) , num_orientation );for j = 1 : length(filter_sizes),    S1_filter = gabor ( filter_sizes(j) , num_orientation , gaborspec );    circ = double(get_circle ( filter_sizes(j) ));    norm = sqrt ( conv2(stim.^2,circ,'full') + eps );    for i = 1 : num_orientation,        clear S1_buf;        S1_buf = conv2 ( stim , S1_filter(:,:,i) , 'full' );        S1_buf = S1_buf ./ norm;        S1(:,:,j,i) = S1_buf ( ceil(filter_sizes(j)/2)+(0:size(stim,1)-1) , ceil(filter_sizes(j)/2)+(0:size(stim,2)-1) );    end;end;function filt = gabor ( filter_size , num_orientation , gaborspec )filt = zeros ( filter_size , filter_size , num_orientation );filt_tmp = zeros ( filter_size );inc = 2*pi/filter_size;xy_range = [-pi+inc/2:inc:pi-inc/2];[x,y] = meshgrid ( xy_range , xy_range );circ = get_circle ( filter_size );circ_sum = sum(circ(:));Sx = gaborspec.sig_xy(1)^2;Sy = gaborspec.sig_xy(2)^2;phi = gaborspec.phase;k = gaborspec.k;for i = 1 : num_orientation,        %make the gabor filter    theta = pi/num_orientation*(i-1);    u = x*cos(theta) - y*sin(theta);    v = x*sin(theta) + y*cos(theta);    filt_tmp = exp(-u.^2/2/Sx-v.^2/2/Sy) .* cos(k*u-phi);    filt_tmp = filt_tmp .* circ;    filt_tmp_sum = sum(filt_tmp(:));        %normalize the gabor filter -> mean of zero, squared integral of 1    filt_tmp = filt_tmp - circ*filt_tmp_sum/circ_sum;    filt_tmp = filt_tmp / sqrt(sum(filt_tmp(:).^2));    filt(:,:,i) = filt_tmp;    end;function circle_template = get_circle ( filter_size )inc = 2/filter_size;xy_range = -1+inc/2:inc:1-inc/2;[x,y] = meshgrid ( xy_range , xy_range );circle_template = (x.^2+y.^2<=1);