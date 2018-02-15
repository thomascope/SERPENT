function module_rsa_job(tpattern_numbers,mask_path,data_path)

%Define matrix based on shared features
judgmentRDM.RDM = zeros(16,16);
judgmentRDM.RDM(1:17:end) = 1;
judgmentRDM.RDM(2:67:end) = 2/3;
judgmentRDM.RDM(3:17:end) = 1/3;
judgmentRDM.RDM(17:64:end) = 2/3;
judgmentRDM.RDM(19:64:end) = 2/3;
judgmentRDM.RDM(33:64:end) = 2/3;
judgmentRDM.RDM(32:64:end) = 1/3;
judgmentRDM.RDM = 1-judgmentRDM.RDM;
judgmentRDM.name = 'feature_vowel';

% now we make an RDM per session
RDMs=struct();

for sessionI=1 %At the moment, only implements average
    % the correlation distance patterns are computed using the pdist function
    %First create t patterns from mask
    mask = spm_read_vols(spm_vol(mask_path));
    for pat = 1:length(tpattern_numbers)
        raw_pattern = spm_read_vols(spm_vol([data_path 'spmT_' sprintf('%04d',tpattern_numbers(pat)) '.nii']));
        if min(size(mask) == size(raw_pattern)) ~= 1
            error('Your mask and t-patterns are not in the same space, try again')
        end
        thesepatterns(pat,:) = raw_pattern(mask~=0)';
    end
        
    RDMs(1,sessionI).RDM   = squareform(pdist(thesepatterns,'correlation'));
    RDMs(1,sessionI).name  = sprintf('Univariate Mask | session %d | condition %s excluding %s',sessionI,condition_order{condJ},num2str(find(all_empty_conditions)));
    RDMs(1,sessionI).color = [];
end

% show the 2 session RDMs
figI=condJ;
figure(figI);clf;set(gcf,'Position',[100 100 800 800],'Color','w')
showRDMs(RDMs,figI);

% ---------------------------------------------------------------------
% compare RDMs across sessions
r12=corr([vectorizeRDMs(RDMs(1).RDM)]',[vectorizeRDMs(RDMs(2).RDM)]');
% ---------------------------------------------------------------------

avgRDM = averageRDMs_subjectSession(RDMs,'subject');
avgRDM.name=sprintf('RDM across sessions | condition %s',condition_order{condJ});

figure(figI);set(gcf,'Position',[100 100 800 800],'Color','w')
showRDMs(avgRDM,figI);


% define the labels and indices for familiar and unfamiliar images
reductionLabels = {'vowel1','vowel2','vowel3'};
reductionvectors = logical(1-all_empty_conditions);
nobjects = sum(logical(1-all_empty_conditions));

%reduction = reductionvectors;

Vowel1 = 1:3; Vowel2 = 4:6; Vowel3 = 7:9;

nCols=3;
cmap=RDMcolormap;
colors=cmap([1 111 222],:);
options.categoryColors=zeros(9,3);
options.categoryColors(Vowel1,:)=repmat(colors(1,:),length(Vowel1),1);
options.categoryColors(Vowel2,:)=repmat(colors(2,:),length(Vowel2),1);
options.categoryColors(Vowel3,:)=repmat(colors(3,:),length(Vowel3),1);
options.categoryColors(all_empty_conditions,:) = [];

options.spheres=2;
options.cols=options.categoryColors;
options.replicability=0;
options.view=1;

%D=avgRDM.RDM(reduction,reduction);
D=avgRDM.RDM;
%[pats_mds_2D,stress,disparities]=extractMDS(D,2,options);
[pats_mds_2D,stress,disparities]=mdscale(D,2);

% draw the mds
nImages=size(pats_mds_2D,1);

% compute image size
imageAreaProportion=.5;
boundingBoxArea=max(prod(range(pats_mds_2D)),max(range(pats_mds_2D))^2/10);
totalImageArea=boundingBoxArea*imageAreaProportion;
imageWidth=sqrt(totalImageArea/nImages);

% smooth alpha channel
transparentCol=[128 128 128 2];
hsize=5*transparentCol(4);
sigma=1*transparentCol(4);
kernel=fspecial('gaussian', hsize, sigma);

markerSize=85;
figure(figI+10);clf;
set(gcf,'Position',[ 100 100 800 800],'Color',[1 1 1],'Renderer','OpenGL','BackingStore','on'); % much better
axes('Position',[0.05 0.2 0.9 0.75])


hold on
%     for imageI=1:nImages
%
%         plot(pats_mds_2D(imageI,1),pats_mds_2D(imageI,2),'o','MarkerFaceColor',[128 128 128]./255,'MarkerEdgeColor',[128 128 128]./255,'MarkerSize',markerSize+20);
%
%
%         %[xs,ys,rgb3]=size(imageStruct(imageI).image);
%
%         if reductionI==1
%             transparent=imageIcons(imageI).image(:,:,1)==transparentCol(1) & imageIcons(imageI).image(:,:,2)==transparentCol(2) & imageIcons(imageI).image(:,:,3)==transparentCol(3);
%         else
%             transparent=imageIcons(imageI+36).image(:,:,1)==transparentCol(1) & imageIcons(imageI+36).image(:,:,2)==transparentCol(2) & imageIcons(imageI+36).image(:,:,3)==transparentCol(3);
%         end
%         if numel(transparentCol)==4
%             % smooth alpha channel
%             opacity=imfilter(double(1-transparent),kernel);
%         else
%             opacity=~transparent;
%         end
%         if reductionI==1
%             if imageI<=18
%                 plot(pats_mds_2D(imageI,1),pats_mds_2D(imageI,2),...
%                     'o','MarkerFaceColor',[128 128 128]./255,'MarkerEdgeColor',[128 128 128]./255,'MarkerSize',markerSize+20);
%             end
%         end
%
%         %     plot(pats_mds_2D(imageI,1),pats_mds_2D(imageI,2),...
%         %         'o','MarkerFaceColor',options.categoryColors(imageI,:),'MarkerEdgeColor',options.categoryColors(imageI,:),'MarkerSize',markerSize);
%         %
%         %imagesc(npats_mds_2D(imageI,1),npats_mds_2D(imageI,2),imageIcons(imageI+36).image);
%         if reductionI==1
%             image('CData',imageIcons(imageI).image,'XData',[pats_mds_2D(imageI,1)-imageWidth/2, pats_mds_2D(imageI,1)+imageWidth/2],'YData',[pats_mds_2D(imageI,2)+imageWidth/2, pats_mds_2D(imageI,2)-imageWidth/2],'AlphaData',opacity);
%         else
%             image('CData',imageIcons(imageI+36).image,'XData',[pats_mds_2D(imageI,1)-imageWidth/2, pats_mds_2D(imageI,1)+imageWidth/2],'YData',[pats_mds_2D(imageI,2)+imageWidth/2, pats_mds_2D(imageI,2)-imageWidth/2],'AlphaData',opacity);
%         end
%     end
%     axis tight equal off
%     annotation('textbox',[0 .90 1 0.1],'EdgeColor','none','String','MDS plot for unfamiliar images',...
%         'HorizontalAlignment','center','FontWeight','bold','FontSize',18);
%
%     axes('Position',[0.7 0 0.25 0.25])
%     hold on;
% add a micro mds plot
markerSize=18;
for imageI=1:nImages
    
    plot(pats_mds_2D(imageI,1),pats_mds_2D(imageI,2),...
        'o','MarkerFaceColor',options.categoryColors(imageI,:),'MarkerEdgeColor',options.categoryColors(imageI,:),'MarkerSize',markerSize);
end
axis tight equal off

% relate activation pattern and candidate models
userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
userOptions.nBootstrap=100; % XXX CHange to 10000 when code finalised
judgments=cell(1,2);
judgments{1}=judgmentRDM;
judgments{1}.RDM = judgments{1}.RDM(reductionvectors,reductionvectors);
judgments{2}.name = 'vowels_only';
judgments{2}.RDM = ones(9,9);
judgments{2}.RDM(1:10:end) = 1;
judgments{2}.RDM(2:30:end) = 0.5;
judgments{2}.RDM(3:30:end) = 0.5;
judgments{2}.RDM(10:30:end) = 0.5;
judgments{2}.RDM(12:30:end) = 0.5;
judgments{2}.RDM(20:30:end) = 0.5;
judgments{2}.RDM(19:30:end) = 0.5;
judgments{2}.RDM = judgments{2}.RDM(reductionvectors,reductionvectors);


userOptions.figureIndex = [20+condJ, 30+condJ];
stats_p_r=compareRefRDM2candRDMs(avgRDM, judgments, userOptions);

% ---------------------------------------------------------------------
% add a second model




% ---------------------------------------------------------------------