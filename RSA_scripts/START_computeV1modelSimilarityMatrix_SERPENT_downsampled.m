function START_computeV1modelSimilarityMatrix_SERPENT_downsampled(line_drawing_stimuli,photo_stimuli)

% compute the V1-model similarity matrix

resultsPath=fullfile(pwd,'V1model_results');
if ~exist(resultsPath,'dir'); mkdir(resultsPath); end

monitor=0;
grey_color = 127; %Mid of 0-255 scale

% First place square images on a grey background, as they would have been shown in the 7T
if ~exist('line_drawing_stimuli','var')
    line_drawing_stimuli = load('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/MultiArrangementTaskData/S7C01_line_drawings_session2_2018-5-1_13h56m_workspace.mat','stimuli'); %Example behavioural RDM
end
if ~exist('photo_stimuli','var')
    photo_stimuli = load('/group/language/data/thomascope/7T_SERPENT_pilot_analysis/behavioural_data/MultiArrangementTaskData/S7C01_photos_session1_2018-5-1_13h41m_workspace','stimuli'); %Example behavioural RDM
end
nImages = size(line_drawing_stimuli.stimuli,1);
im = line_drawing_stimuli.stimuli(1).image;
im_dims = size(im);
assert(im_dims(1)==im_dims(2),'At least the first input image must be square, and no image must be larger than this')
inputSize = im_dims;
photo_images_left = uint8(ones([im_dims,nImages])*grey_color); 
line_images_left = uint8(ones([im_dims,nImages])*grey_color); 
photo_images_right = uint8(ones([im_dims,nImages])*grey_color); 
line_images_right = uint8(ones([im_dims,nImages])*grey_color); 
images=uint8(ones([inputSize,nImages,4])*grey_color);
matrices = {'photo_images_left','photo_images_right','line_images_left','line_images_right'};
for imageI = 1:nImages    
    % images were presented on a mid-grey background according to the alpha channel
    this_alpha = line_drawing_stimuli.stimuli(imageI).alpha/255;
    line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = line_drawing_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
    line_images_right(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI) = fliplr(line_images_left(1:size(line_drawing_stimuli.stimuli(imageI).image,1),1:size(line_drawing_stimuli.stimuli(imageI).image,2),1:size(line_drawing_stimuli.stimuli(imageI).image,3),imageI));
    this_alpha = photo_stimuli.stimuli(imageI).alpha/255;
    photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = photo_stimuli.stimuli(imageI).image.*this_alpha + 127.*(1-this_alpha);
    photo_images_right(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI) = fliplr(photo_images_left(1:size(photo_stimuli.stimuli(imageI).image,1),1:size(photo_stimuli.stimuli(imageI).image,2),1:size(photo_stimuli.stimuli(imageI).image,3),imageI));
    images(:,:,:,imageI,1) = photo_images_left(:,:,:,imageI);
    images(:,:,:,imageI,2) = photo_images_right(:,:,:,imageI);    
    images(:,:,:,imageI,3) = line_images_left(:,:,:,imageI);
    images(:,:,:,imageI,4) = line_images_right(:,:,:,imageI);    
end % imageI
save(fullfile(resultsPath,'images'),'images','photo_images_left','photo_images_right','line_images_left','line_images_right');    

%Now calculate the dissimiarities
V1modelSimMat=nan(nImages);
V1modelSimMat(logical(eye(nImages)))=0;
for image1I=1:nImages
    for i = 1:length(matrices)
        disp(['Calculating dissimilarities for ' matrices{i} ' ' num2str(image1I)]);
        [S1_im1 ,C1_im1, stim1]=V1modelResponse_SERPENT_downsampled(squeeze(images(:,:,:,image1I,i)));
        for j = 1:length(matrices)
            this_V1modelSimMat = V1modelSimMat;
            parfor image2I=1:nImages
                
                % load images and compute V1 represenation
                [S1_im2 ,C1_im2, stim2]=V1modelResponse_SERPENT_downsampled(squeeze(images(:,:,:,image2I,j)));
                
                if monitor
                    h=figure(10); clf; set(h,'Color','w');
                    
                    subplot(3,2,1); imshow(stim1);
                    subplot(3,2,3); imagesc(S1_im1(:,:,1,1)); axis equal off;
                    subplot(3,2,5); imagesc(C1_im1(:,:,1,1)); axis equal off;
                    
                    subplot(3,2,2); imshow(stim2);
                    subplot(3,2,4); imagesc(S1_im2(:,:,1,1)); axis equal off;
                    subplot(3,2,6); imagesc(C1_im2(:,:,2,1)); axis equal off;
                end
                
                
                
                % compute similarity
                V1_im1=[S1_im1(:);C1_im1(:)];
                V1_im2=[S1_im2(:);C1_im2(:)];
                
                dissimilarity=1-corr(V1_im1,V1_im2);
                
                this_V1modelSimMat(image1I,image2I)=dissimilarity;
                %V1modelSimMat(image2I,image1I)=dissimilarity;
                
            end % image2I
            V1RDM_ds(i,j).RDM(image1I,:) = this_V1modelSimMat(image1I,1:nImages);
            V1RDM_ds(i,j).name =  [matrices{i} ' to ' matrices{j} ' V1 model dissimilarity'];
            V1RDM_ds(i,j).shortname =  [matrices{i} ' to ' matrices{j}];
            
        end
    end
end % image1I
save(fullfile(resultsPath,'V1RDM_ds'),'V1RDM_ds');
            
            
            
            
            
            
            
            
            
            
            
            
            