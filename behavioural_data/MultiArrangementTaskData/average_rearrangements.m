load('scan_subjects')
all_drawstyles ={'photos','line_drawings'};
all_controls_dissimMats = nan(2,sum(group==1),105);
all_patients_dissimMats = nan(2,sum(group==2),105);
this_con = 0;
this_pat = 0;

for i = 1:length(scan_subjects)
    if group(i) == 1
        this_con = this_con+1;
    elseif group(i) == 2
        this_pat = this_pat+1;
    end
    for j = 1:length(all_drawstyles)
        this_file = dir([scan_subjects{i} '_' all_drawstyles{j} '*']);
        load(this_file.name,'estimate_dissimMat_ltv_MA')
        if group(i) == 1
            all_controls_dissimMats(j,this_con,:)=estimate_dissimMat_ltv_MA;
        elseif group(i) == 2
            all_patients_dissimMats(j,this_pat,:)=estimate_dissimMat_ltv_MA;
        end
    end
end

[cons_photo_mds_2D,~,~]=mdscale(squeeze(mean(all_controls_dissimMats(1,:,:),2))',2,'criterion',criterion);
[cons_line_mds_2D,~,~]=mdscale(squeeze(mean(all_controls_dissimMats(2,:,:),2))',2,'criterion',criterion);
[pats_photo_mds_2D,~,~]=mdscale(squeeze(mean(all_patients_dissimMats(1,:,:),2))',2,'criterion',criterion);
[pats_line_mds_2D,~,~]=mdscale(squeeze(mean(all_patients_dissimMats(2,:,:),2))',2,'criterion',criterion);

for j = 1:length(all_drawstyles)
    i = 1
    this_file = dir([scan_subjects{i} '_' all_drawstyles{j} '*']);
    load(this_file.name)
    if j == 1
        pageFigure(400);
        SD_drawImageArrangement(stimuli,cons_photo_mds_2D,1,stimuli(1).image(1,1,:));
        title({'\fontsize{14}Average Control Photo arrangement\fontsize{11}',[' (',criterion,')']});
        saveas(gcf,'Average Control Photo arrangement.png')
        
        pageFigure(400);
        SD_drawImageArrangement(stimuli,pats_photo_mds_2D,1,stimuli(1).image(1,1,:));
        title({'\fontsize{14}Average Patient Photo arrangement\fontsize{11}',[' (',criterion,')']});
        saveas(gcf,'Average Patient Photo arrangement.png')
    else
        pageFigure(400);
        SD_drawImageArrangement(stimuli,cons_line_mds_2D,1,stimuli(1).image(1,1,:));
        title({'\fontsize{14}Average Control Line arrangement\fontsize{11}',[' (',criterion,')']});
        saveas(gcf,'Average Control Line arrangement.png')
        
        pageFigure(400);
        SD_drawImageArrangement(stimuli,pats_line_mds_2D,1,stimuli(1).image(1,1,:));
        title({'\fontsize{14}Average Patient Line arrangement\fontsize{11}',[' (',criterion,')']});
        saveas(gcf,'Average Patient Line arrangement.png')
    end
end
basemodels.templates = zeros(15,15);
basemodels.templates(1:16:end) = 1;
basemodels.templates(2:48:end) = 1/3;
basemodels.templates(3:48:end) = 1/3;
basemodels.templates(16:48:end) = 1/3;
basemodels.templates(18:48:end) = 1/3;
basemodels.templates(31:48:end) = 1/3;
basemodels.templates(32:48:end) = 1/3;
basemodels.templates = 1-basemodels.templates; %Dissimilarities

basemodels.templates_noself = basemodels.templates;
basemodels.templates_noself(1:16:end) = NaN;

figure
set(gcf,'Position',[100 100 1600 800]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
for i = 1:22
    subplot(7,6,i)
    image(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_controls_dissimMats(1,i,:))'),1)),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    this_corr = corr(vectorizeRDMs(basemodels.templates_noself)',vectorizeRDMs(squareform(squeeze(all_controls_dissimMats(1,i,:))'))','type','Spearman','Rows','pairwise');
    title(['Control ' num2str(i) ', rho ' num2str(this_corr)])
end
for j =1:19
subplot(7,6,i+j)
image(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_patients_dissimMats(1,j,:))'),1)),'CDataMapping','scaled')
set(gca,'CLim',[0 1],'CLimMode','manual');
axis square
    this_corr = corr(vectorizeRDMs(basemodels.templates_noself)',vectorizeRDMs(squareform(squeeze(all_patients_dissimMats(1,j,:))'))','type','Spearman','Rows','pairwise');
    title(['Patient ' num2str(j) ', rho ' num2str(this_corr)])
end
sgtitle('Photos')

figure
set(gcf,'Position',[100 100 1600 800]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
for i = 1:22
    subplot(7,6,i)
    image(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_controls_dissimMats(2,i,:))'),1)),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    this_corr = corr(vectorizeRDMs(basemodels.templates_noself)',vectorizeRDMs(squareform(squeeze(all_controls_dissimMats(2,i,:))'))','type','Spearman','Rows','pairwise');
    title(['Control ' num2str(i) ', rho ' num2str(this_corr)])
end
for j =1:19
subplot(7,6,i+j)
image(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_patients_dissimMats(2,j,:))'),1)),'CDataMapping','scaled')
set(gca,'CLim',[0 1],'CLimMode','manual');
axis square
    this_corr = corr(vectorizeRDMs(basemodels.templates_noself)',vectorizeRDMs(squareform(squeeze(all_patients_dissimMats(2,j,:))'))','type','Spearman','Rows','pairwise');
    title(['Patient ' num2str(j) ', rho ' num2str(this_corr)])
end
sgtitle('Line Drawings')

figure
set(gcf,'Position',[100 100 1600 800]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
for i = 1:22
    subplot(7,6,i)
    image(scale01(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_controls_dissimMats(1,i,:))'),1))-scale01(rankTransform_equalsStayEqual(basemodels.templates,1))),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    title(['Control ' num2str(i)])
end
for j =1:19
    subplot(7,6,i+j)
    image(scale01(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_patients_dissimMats(1,j,:))'),1))-scale01(rankTransform_equalsStayEqual(basemodels.templates,1))),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    title(['Patient ' num2str(j)])
end
sgtitle('Photos Difference from Template')

figure
set(gcf,'Position',[100 100 1600 800]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
for i = 1:22
    subplot(7,6,i)
    image(scale01(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_controls_dissimMats(2,i,:))'),1))-scale01(rankTransform_equalsStayEqual(basemodels.templates,1))),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    title(['Control ' num2str(i)])
end
for j =1:19
    subplot(7,6,i+j)
    image(scale01(scale01(rankTransform_equalsStayEqual(squareform(squeeze(all_patients_dissimMats(2,j,:))'),1))-scale01(rankTransform_equalsStayEqual(basemodels.templates,1))),'CDataMapping','scaled')
    set(gca,'CLim',[0 1],'CLimMode','manual');
    axis square
    title(['Patient ' num2str(j)])
end
sgtitle('Line Drawings Difference from Template')


