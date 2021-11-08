function cnnRDM = getNetActivations_SERPENT(netStr,line_drawing_stimuli,photo_stimuli)

% function getNetActivations([imagePath,netStr,filter])

% INPUT
% imagePath: stimulus directory
% netStr:    string that defines the network you want to use 
%            options: 'alexnet' 'vgg16' 'resnet50'
% filter:    filename filter for stimuli, e.g. '*.bmp'


%% preparation
% -------------------- adjust to set your own defaults --------------------
if ~exist('netStr','var'), netStr = 'alexnet'; end
if strcmp(netStr,'alexnet'), layerIs = [2 6 10 12 14 17 20 23]; % select convolutional layers
elseif strcmp(netStr,'vgg16'), layerIs = [2 4 7 9 12 14 16 19 21 23 26 28 30 33 36 39]; % select convolutional layers 
elseif strcmp(netStr,'resnet50'), layerIs = [2 6 9 12 13 18 21 24 28 31 34 38 41 44 45 50 53 56 60 63 66 70 73 76 80 83 86 87 92 95 98 102 105 108 112 115 118 122 125 128 132 135 138 142 145 148 149 154 157 160 164 167 170 175]; % select convolutional layers  
end
% -------------------- adjust to set your own defaults --------------------

resultsPath=fullfile(pwd,'DNN_results');
if ~exist(resultsPath,'dir'); mkdir(resultsPath); end

% --------- set to folder where you saved the dependent functions ---------
% addpath('C:\Users\zwoeg\Documents\programs\matlab\spm_custom'); % for function get_files
% addpath('C:\Users\zwoeg\Documents\programs\rsatoolbox\Engines'); % if you want to show the RDMs
% --------- set to folder where you saved the dependent functions ---------


%% control variables
monitor = 1;
grey_color = 127; %Mid of 0-255 scale

%% load network
if strcmp(netStr,'alexnet'), net = alexnet;
elseif strcmp(netStr,'vgg16'), net = vgg16;
elseif strcmp(netStr,'resnet50'), net = resnet50; 
end
net.Layers % print layer info
inputSize = net.Layers(1).InputSize;


%% load & prepare images - note, input images must be square
if ~exist('line_drawing_stimuli','var')
    line_drawing_stimuli = load('../MultiArrangementTaskData/S7C01_line_drawings_session2_2018-5-1_13h56m_workspace.mat','stimuli'); %Example behavioural RDM
end
if ~exist('photo_stimuli','var')
    photo_stimuli = load('../MultiArrangementTaskData/S7C01_photos_session1_2018-5-1_13h41m_workspace','stimuli'); %Example behavioural RDM
end
nImages = size(line_drawing_stimuli.stimuli,1);
im = line_drawing_stimuli.stimuli(1).image;
im_dims = size(im);
photo_images_left = single(ones([im_dims,nImages])*grey_color); 
line_images_left = single(ones([im_dims,nImages])*grey_color); 
photo_images_right = single(ones([im_dims,nImages])*grey_color); 
line_images_right = single(ones([im_dims,nImages])*grey_color); 
images=single(ones([inputSize,nImages,4])*grey_color);
image_type_order = {'photo_images_left','photo_images_right','line_images_left','line_images_right'};
for imageI = 1:nImages    
    % images were presented on a mid-grey background according to the alpha channel
    this_alpha = line_drawing_stimuli.stimuli(imageI).alpha/255;
    line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = line_drawing_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
    line_images_right(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = fliplr(line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI));
    this_alpha = photo_stimuli.stimuli(imageI).alpha/255;
    photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = photo_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
    photo_images_right(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = fliplr(photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI));
    if monitor, figure(10); imshow(uint8(photo_images_left(:,:,:,imageI))); title('original'); end
    images(:,:,:,imageI,1) = activations(net,imresize(photo_images_left(:,:,:,imageI),[inputSize(1) inputSize(2)]),net.Layers(1).Name); % assuming first layer performs 'zerocenter' normalisation
    images(:,:,:,imageI,2) = activations(net,imresize(photo_images_right(:,:,:,imageI),[inputSize(1) inputSize(2)]),net.Layers(1).Name); % assuming first layer performs 'zerocenter' normalisation    
    images(:,:,:,imageI,3) = activations(net,imresize(line_images_left(:,:,:,imageI),[inputSize(1) inputSize(2)]),net.Layers(1).Name); % assuming first layer performs 'zerocenter' normalisation
    images(:,:,:,imageI,4) = activations(net,imresize(line_images_right(:,:,:,imageI),[inputSize(1) inputSize(2)]),net.Layers(1).Name); % assuming first layer performs 'zerocenter' normalisation    
    if monitor, figure(13); imshow(uint8(images(:,:,:,imageI,1))); title('after zerocenter normalisation'); end
end % imageI
save(fullfile(resultsPath,'images'),'images','photo_images_left','photo_images_right','line_images_left','line_images_right');    

%% compute activations
nLayers = numel(layerIs);
nUnits = nan(nLayers,1);
fileID = fopen(fullfile(resultsPath,'top5.txt'),'w');
for imageI = 1:nImages
    for imagetype = 1:length(image_type_order)
        im = images(:,:,:,imageI,imagetype);
        acti = cell(nLayers,1);
        for layerIsI = 1:nLayers
            layerI = layerIs(layerIsI);
            layerName = net.Layers(layerI).Name;
            acti{layerIsI} = activations(net,im,layerName);
            nUnits(layerIsI) = numel(acti{layerIsI});
        end % layerI
        [label,scores] = classify(net,im);
        [~,idx] = sort(scores,'descend');
        idx = idx(1:5);
        top5 = net.Layers(end).ClassNames(idx);
        fle = [line_drawing_stimuli.stimuli(imageI).category '_' line_drawing_stimuli.stimuli(imageI).frequency '_' image_type_order{imagetype}];
        save(fullfile(resultsPath,fle),'im','acti','scores','top5');
        % print top5 to text file
        formatSpec1 = '%s\n'; formatSpec2 = '%s\n\n';
        fprintf(fileID,formatSpec1,[fle]);
        for labelI = 1:numel(idx)
            if labelI < numel(idx), fprintf(fileID,formatSpec1,top5{labelI});
            else fprintf(fileID,formatSpec2,top5{labelI}); end
        end
    end
end % imageI
save(fullfile(resultsPath,'vars'),'nImages','nLayers','nUnits');
fclose(fileID);


%% compute RDMs
matrices = {'photo_images_left','photo_images_right','line_images_left','line_images_right'};
for i = 1:length(matrices)
    for j = 1:length(matrices)
        for layerIsI = 1:nLayers
            layerI = layerIs(layerIsI);
            acti_i_images_units = single(nan(nImages,nUnits(layerIsI)));
            acti_j_images_units = single(nan(nImages,nUnits(layerIsI)));
            for imageI = 1:nImages
                fle_i = [line_drawing_stimuli.stimuli(imageI).category '_' line_drawing_stimuli.stimuli(imageI).frequency '_' image_type_order{i}];
                acti_i = load(fullfile(resultsPath,fle_i),'acti');
                acti_i_images_units(imageI,:) = acti_i.acti{layerIsI}(:);
                fle_j = [line_drawing_stimuli.stimuli(imageI).category '_' line_drawing_stimuli.stimuli(imageI).frequency '_' image_type_order{j}];
                acti_j = load(fullfile(resultsPath,fle_j),'acti');
                acti_j_images_units(imageI,:) = acti_j.acti{layerIsI}(:);
            end % imageI
            cnnRDM(i,j,1,layerIsI).RDM = pdist2(acti_i_images_units,acti_j_images_units,'euclidean');
            cnnRDM(i,j,1,layerIsI).name =  [matrices{i} ' to ' matrices{j} ' DNN euclidean dissimilarity ' net.Layers(layerI).Name];
            cnnRDM(i,j,1,layerIsI).shortname =  [matrices{i} ' to ' matrices{j}];
            cnnRDM(i,j,2,layerIsI).RDM = pdist2(acti_i_images_units,acti_j_images_units,'correlation');
            cnnRDM(i,j,1,layerIsI).name =  [matrices{i} ' to ' matrices{j} ' DNN correlation dissimilarity ' net.Layers(layerI).Name];
            cnnRDM(i,j,2,layerIsI).shortname =  [matrices{i} ' to ' matrices{j}];
        end
    end
end

if monitor
    for layerIsI = 1:nLayers
        figI = 500+layerIsI;
        %showRDMs(gistRDM_line_left,figI);
        figure(figI); clf;
        set(gcf,'position',[100,100,1000,1000])
        for i = 1:length(matrices)
            for j = 1:length(matrices)
                subplot(length(matrices),length(matrices),((i-1)*length(matrices))+j)
                image(scale01(rankTransform_equalsStayEqual(cnnRDM(i,j,1,layerIsI).RDM)),'CDataMapping','scaled')
                title(cnnRDM(i,j,1,layerIsI).shortname,'Interpreter','none','FontSize',8);
            end
        end
        figI = 550+layerIsI;
        figure(figI); clf;
        set(gcf,'position',[100,100,1000,1000])
        for i = 1:length(matrices)
            for j = 1:length(matrices)
                subplot(length(matrices),length(matrices),((i-1)*length(matrices))+j)
                image(scale01(rankTransform_equalsStayEqual(cnnRDM(i,j,2,layerIsI).RDM)),'CDataMapping','scaled')
                title(cnnRDM(i,j,2,layerIsI).shortname,'Interpreter','none','FontSize',8);
            end
        end
    end
end

save(fullfile(resultsPath,'cnnRDM'),'cnnRDM');
