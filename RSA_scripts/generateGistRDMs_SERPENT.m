function gistRDM = generateGistRDMs_SERPENT(line_drawing_stimuli,photo_stimuli)

% ---------- adjust paths to stimuli and dependent functions --------------
resultsPath=fullfile(pwd,'gist_results');
if ~exist(resultsPath,'dir'); mkdir(resultsPath); end
addpath('./gist');
% ---------- adjust paths to stimuli and dependent functions --------------


%% control variables
monitor = 0;
grey_color = 127; %Mid of 0-255 scale

try load(fullfile(resultsPath,'gistRDMs'));
catch
    
    %% load images
    if ~exist('line_drawing_stimuli','var')
        line_drawing_stimuli = load('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/MultiArrangementTaskData/S7C01_line_drawings_session2_2018-5-1_13h56m_workspace.mat','stimuli'); %Example behavioural RDM
    end
    if ~exist('photo_stimuli','var')
        photo_stimuli = load('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/MultiArrangementTaskData/S7C01_photos_session1_2018-5-1_13h41m_workspace','stimuli'); %Example behavioural RDM
    end
    nImages = size(line_drawing_stimuli.stimuli,1);
    im = line_drawing_stimuli.stimuli(1).image;
    im_dims = size(im);
    photo_images_left = single(ones([im_dims,nImages])*grey_color);
    line_images_left = single(ones([im_dims,nImages])*grey_color);
    photo_images_right = single(ones([im_dims,nImages])*grey_color);
    line_images_right = single(ones([im_dims,nImages])*grey_color);
    for imageI = 1:nImages
        % images were presented on a mid-grey background according to the alpha channel
        this_alpha = line_drawing_stimuli.stimuli(imageI).alpha/255;
        line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = line_drawing_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
        line_images_right(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = fliplr(line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI));
        this_alpha = photo_stimuli.stimuli(imageI).alpha/255;
        photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = photo_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
        photo_images_right(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = fliplr(photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI));
    end % imageI
    save(fullfile(resultsPath,'images'),'line_images_left','photo_images_left','line_images_right','photo_images_right');
    
    %% compute GIST descriptors
    % set params
    param.orientationsPerScale = [8 8 8 8]; % number of orientations per scale (from HF to LF)
    param.numberBlocks = 4;
    param.fc_prefilt = 4;
    
    % pre-allocate gist
    nFeatures = sum(param.orientationsPerScale)*param.numberBlocks^2;
    line_gist_left = zeros(nImages,nFeatures);
    photo_gist_left = zeros(nImages,nFeatures);
    line_gist_right = zeros(nImages,nFeatures);
    photo_gist_right = zeros(nImages,nFeatures);
    
    % compute descriptors
    [line_gist_left(1,:),param]=LMgist(line_images_left(:,:,:,1),[],param); % first call
    [photo_gist_left(1,:),param]=LMgist(photo_images_left(:,:,:,1),[],param); % first call
    [line_gist_right(1,:),param]=LMgist(line_images_right(:,:,:,1),[],param); % first call
    [photo_gist_right(1,:),param]=LMgist(photo_images_right(:,:,:,1),[],param); % first call
    for imageI = 1:nImages
        line_gist_left(imageI,:)=LMgist(line_images_left(:,:,:,imageI),[],param); % the next calls will be faster
        photo_gist_left(imageI,:)=LMgist(photo_images_left(:,:,:,imageI),[],param); % the next calls will be faster
        line_gist_right(imageI,:)=LMgist(line_images_right(:,:,:,imageI),[],param); % the next calls will be faster
        photo_gist_right(imageI,:)=LMgist(photo_images_right(:,:,:,imageI),[],param); % the next calls will be faster
        if monitor
            figI = 10; figure(figI); clf;
            set(gcf,'position',[100,100,500,800])
            subplot(4,2,1); imshow(uint8(line_images_left(:,:,:,imageI))); title('original image');
            subplot(4,2,2); showGist((line_gist_left(imageI,:)),param); title('gist descriptor');
            subplot(4,2,3); imshow(uint8(photo_images_left(:,:,:,imageI)));
            subplot(4,2,4); showGist((photo_gist_left(imageI,:)),param);
            subplot(4,2,5); imshow(uint8(line_images_right(:,:,:,imageI)));
            subplot(4,2,6); showGist((line_gist_right(imageI,:)),param);
            subplot(4,2,7); imshow(uint8(photo_images_right(:,:,:,imageI)));
            subplot(4,2,8); showGist((photo_gist_right(imageI,:)),param);
            drawnow
        end % monitor
    end % stimI
    save(fullfile(resultsPath,'GISTdescriptors'),'line_gist_left','photo_gist_left','line_gist_right','photo_gist_right','param');
    
    %% compute RDM
    matrices = {'photo_gist_left','photo_gist_right','line_gist_left','line_gist_right'};
    for i = 1:length(matrices)
        for j = 1:length(matrices)
            eval(['gistRDM(i,j,1).RDM = pdist2(' matrices{i} ',' matrices{j} ',''euclidean'');']);
            eval(['gistRDM(i,j,1).name = [''' matrices{i} ' to ' matrices{j} ' GIST euclidean dissimilarity''];']);
            eval(['gistRDM(i,j,1).shortname = [''' matrices{i} ' to ' matrices{j} '''];']);
            eval(['gistRDM(i,j,2).RDM = pdist2(' matrices{i} ',' matrices{j} ',''correlation'');']);
            eval(['gistRDM(i,j,2).name = [''' matrices{i} ' to ' matrices{j} ' GIST correlation distance dissimilarity''];']);
            eval(['gistRDM(i,j,2).shortname = [''' matrices{i} ' to ' matrices{j} '''];']);
        end
    end
    
    save(fullfile(resultsPath,'gistRDMs'),'gistRDM');
    
    if monitor
        figI = 500;
        %showRDMs(gistRDM_line_left,figI);
        figure(figI); clf;
        set(gcf,'position',[100,100,1000,1000])
        for i = 1:length(matrices)
            for j = 1:length(matrices)
                subplot(length(matrices),length(matrices),((i-1)*length(matrices))+j)
                image(scale01(rankTransform_equalsStayEqual(gistRDM(i,j,1).RDM)),'CDataMapping','scaled')
                title(gistRDM(i,j,1).shortname,'Interpreter','none','FontSize',8);
            end
        end
        figI = 550;
        figure(figI); clf;
        set(gcf,'position',[100,100,1000,1000])
        for i = 1:length(matrices)
            for j = 1:length(matrices)
                subplot(length(matrices),length(matrices),((i-1)*length(matrices))+j)
                image(scale01(rankTransform_equalsStayEqual(gistRDM(i,j,2).RDM)),'CDataMapping','scaled')
                title(gistRDM(i,j,2).shortname,'Interpreter','none','FontSize',8);
            end
        end
    end
end


