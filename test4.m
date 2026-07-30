all_partial_combinations = nchoosek(partial_matrices,these_partial_numbers);
for this_partial = 1:size(all_partial_combinations,1)
    number_partialled_out = size(all_partial_combinations,2);
    partial_name = [];
    for this_partial_matrix = 1:number_partialled_out
        partial_name = [partial_name '+' this_model_name{all_partial_combinations(this_partial,this_partial_matrix)}];
    end
    partial_name = ['_partialling_' partial_name(2:end)];

    for k = 1:length(mask_names)
        for crun = 1:nrun
            %ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/RSA/spearman']; %Where are the results>
            ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI/' mask_names{k} '/RSA/spearman'];
            if ~exist(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} partial_name '.mat']),'file')
                ROI_RSA_dir = [preprocessedpathstem subjects{crun} '/stats_native_mask0.3_3_coreg_reversedbuttons/TDTcrossnobis_ROI' mask_names{k} '/RSA/spearman']; % Stupid coding error earlier in analysis led to misnamed directories
            end
            try
                temp_data = load(fullfile(ROI_RSA_dir,['roi_effects_' this_model_name{j} partial_name '.mat']));
                all_data(j,k,crun) = temp_data.roi_effect; %Create a matrix of condition by ROI by subject
                RSA_ROI_data_exist(j,k,crun) = 1;
            catch
                warning(['No data for ' subjects{crun} ' probably because of SPM dropout, ignoring them'])
                %error
                RSA_ROI_data_exist(j,k,crun) = 0;
                all_data(j,k,crun) = NaN;
                continue
            end
        end
        roi_names = temp_data.roi_names;
        disp(['Excluding subjects ' num2str(find(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' belonging to groups ' num2str(group(squeeze(RSA_ROI_data_exist(j,k,:))==0)) ' maybe check them'])
    end
    all_corrected_data(j,:,group==1) = es_removeBetween_rotated(all_data(j,:,group==1),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here
    all_corrected_data(j,:,group==2) = es_removeBetween_rotated(all_data(j,:,group==2),[3,2,1]); %Subjects, conditions, measures columns = 3,2,1 here

    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    hold on
    errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
    errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
    %                         for m = 1:length(mask_names)
    %                             scatter(repmat(m-0.1,1,size(squeeze(all_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
    %                             scatter(repmat(m+0.1,1,size(squeeze(all_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
    %                         end
    xlim([0 length(mask_names)+1])
    set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
    plot([0 length(mask_names)+1],[0,0],'k--')
    title([this_model_name{j} partial_name ' RSA'],'Interpreter','none')
    if verLessThan('matlab', '9.2')
        legend('Controls','Patients','location','southeast')
    else
        legend('Controls','Patients','location','southeast','AutoUpdate','off')
    end
    [h,p] = ttest(squeeze(all_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
    end
    [h,p] = ttest(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
    end
    [h,p] = ttest(squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
    end

    [h,p] = ttest2(squeeze(all_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
    end

    drawnow
    saveas(gcf,[outdir filesep this_model_name{j} partial_name '_by_Glasser.png'])
    saveas(gcf,[outdir filesep this_model_name{j} partial_name '_by_Glasser.pdf'])

    figure
    set(gcf,'Position',[100 100 1600 800]);
    set(gcf, 'PaperPositionMode', 'auto');
    hold on
    errorbar([1:length(mask_names)]-0.1,nanmean(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),'kx')
    errorbar([1:length(mask_names)]+0.1,nanmean(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2),nanstd(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))')/sqrt(sum(group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),'rx')
    %                                     for m = 1:length(mask_names)
    %                             scatter(repmat(m-0.1,1,size(squeeze(all_corrected_data(j,:,group==1&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==1&squeeze(RSA_ROI_data_exist(j,k,:))'))','k')
    %                             scatter(repmat(m+0.1,1,size(squeeze(all_corrected_data(j,:,group==2&squeeze(RSA_ROI_data_exist(j,k,:))')),2)),squeeze(all_corrected_data(j,m,group==2&squeeze(RSA_ROI_data_exist(j,k,:))'))','r')
    %                         end
    xlim([0 length(mask_names)+1])
    set(gca,'xtick',[1:length(mask_names)],'xticklabels',mask_names,'XTickLabelRotation',45,'TickLabelInterpreter','none')
    plot([0 length(mask_names)+1],[0,0],'k--')
    title(['Corrected ' this_model_name{j} partial_name ' RSA'],'Interpreter','none')
    if verLessThan('matlab', '9.2')
        legend('Controls','Patients','location','southeast')
    else
        legend('Controls','Patients','location','southeast','AutoUpdate','off')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/10),'g*')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)-0.1,these_y_lims(2)-diff(these_y_lims/10),'k*')
    end
    [h,p] = ttest(squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    these_y_lims = ylim;
    if sum(h)~=0
        plot(find(h)+0.1,these_y_lims(2)-diff(these_y_lims/10),'r*')
    end

    [h,p] = ttest2(squeeze(all_corrected_data(j,:,group==1&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))',squeeze(all_corrected_data(j,:,group==2&logical(squeeze(RSA_ROI_data_exist(j,k,:))')))');
    if sum(h)~=0
        plot(find(h),these_y_lims(2)-diff(these_y_lims/20),'gx')
    end

    drawnow
    saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} partial_name '_by_Glasser.png'])
    saveas(gcf,[outdir filesep 'Corrected_' this_model_name{j} partial_name '_by_Glasser.pdf'])

end