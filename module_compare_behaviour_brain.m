function [disvol, searchlight_locations, thisRDM, disvol_cross, disvol_collapsed, disvol_cross_collapsed] = module_compare_behaviour_brain(subject,spmdir,outdir,subsamp_fac,crosscon,crosscon_collapsed)
%A function to extract the dissimilarity matrix from the behavioural data
%and compare it to brain data
%TEC May2018

addpath(genpath('/imaging/tc02/toolboxes/pilab')) %Path to pattern information toolbox
addpath(genpath('/imaging/tc02/toolboxes/rsatoolbox')) % Path to rsa toolbox
addpath(genpath('/imaging/tc02/toolboxes/helpers')) % Path to Johan's helper files

line_draw_data = dir(['./7T_JudgementData/' subject '_line_drawings*']);
load(['./7T_JudgementData/' line_draw_data.name],'estimate_dissimMat_ltv_MA')
thisRDM = rank_transform_RDM(estimate_dissimMat_ltv_MA);

if exist([outdir '/ldc_data/filtereddata.mat'],'file') && exist([outdir '/ldc_data/designs.mat'],'file')
    disp('Loading previous filtered data')
    load([outdir '/ldc_data/filtereddata.mat'])
    load([outdir '/ldc_data/designs.mat'])
else
    %First load in the epi from the relevant SPM, masked to the warped structural
    [epivol,designvol] = spm2vol(fullfile(spmdir,'SPM.mat'),'mask',fullfile(outdir,'wstructural_csf.nii'));
    
    %Then preprocess the design, removing button presses from LDC
    [filtereddatavol,filtereddesignvol] = preprocessvols(epivol,designvol,'ignorelabels',{'Left Button Press','Right Button Press','null_null_null_null'});
    
    if ~exist([outdir '/ldc_data'],'dir')
        mkdir([outdir '/ldc_data'])
    end
    save([outdir '/ldc_data/filtereddata.mat'],'filtereddatavol','filtereddesignvol','-v7.3');
    save([outdir '/ldc_data/designs.mat'],'designvol','filtereddesignvol','-v7.3');
    clear epivol %For memory
end

%Then determine 800voxel ROIs (roughly 9mm radius) (parallelised)
%[fullrois,diagnostic] = mask2searchrois(filtereddatavol,'nvox',800);

if exist([outdir '/ldc_data/searchroisdata.mat'],'file')
    disp('Loading previous roi data')
    load([outdir '/ldc_data/searchroisdata.mat'])
else
[searchrois,diagnostic] = mask2searchrois(filtereddatavol,'nvox',800);

save([outdir '/ldc_data/searchroisdata.mat'],'searchrois','diagnostic','-v7.3');
end

%Now subsample the mask space by a factor of n (i.e. if n = 2 from 1.5mm voxels to 3mm searchlight spacing)
these_locs = ~logical(mod(searchrois.xyz(1,:),subsamp_fac))&~logical(mod(searchrois.xyz(2,:),subsamp_fac))&~logical(mod(searchrois.xyz(3,:),subsamp_fac));
searchrois = searchrois(these_locs,:);
% searchrois.data = searchrois.data(these_locs,:);
% searchrois.nsamples = sum(these_locs);

%Now create collapsed designs where we average across a dimension
load('example_file.mat','category_labels','direction_labels','all_drawstyles','frequency_labels')
mapper = struct('name',{'drawstyle','frequency','direction','category'},'levels',{all_drawstyles, frequency_labels, direction_labels, category_labels});

collapsed_design{1} = collapsedesign(designvol, mapper(1).levels); %Collapse on drawstyle
collapsed_design{2} = collapsedesign(designvol, mapper(3).levels); %Collapse on direction
collapsed_design{3} = collapsedesign(drawstyle_collapsed, mapper(3).levels); %Collapse both

for i = 1:numel(collapsed_design)
[~,filtered_collapsed_design{i}] = preprocessvols([],collapsed_design{i},'ignorelabels',{'Left Button Press','Right Button Press','null_null_null_null'});
end

%Do the main LDC process for collapsed volumes first
if exist([outdir '/ldc_data/disvol_collapsed' num2str(subsamp_fac) '.mat'],'file')
    disp('Loading previous collapsed disvol')
    load([outdir '/ldc_data/disvol_collapsed' num2str(subsamp_fac) '.mat'])
else
    disvol_collapsed = cell(1,numel(filtered_collapsed_design));
    for i = 1:numel(filtered_collapsed_design)
        disvol_collapsed{i} = roidata2rdmvol_lindisc_batch(searchrois,filtered_collapsed_design{i},filtereddatavol);
    end
    save([outdir '/ldc_data/disvol_collapsed' num2str(subsamp_fac) '.mat'],'disvol_collapsed','-v7.3');
end

%Now do the main LDC process for the full volume
if exist([outdir '/ldc_data/disvol_' num2str(subsamp_fac) '.mat'],'file')
    disp('Loading previous disvol')
    load([outdir '/ldc_data/disvol_' num2str(subsamp_fac) '.mat'])
else
%disvol = module_ldc_subsamp(searchrois,filtereddesignvol,filtereddatavol);
disvol = roidata2rdmvol_lindisc_batch(searchrois,filtereddesignvol,filtereddatavol);
save([outdir '/ldc_data/disvol_' num2str(subsamp_fac) '.mat'],'disvol','-v7.3');

end

%Now do cross training/testing on full volume
if ~isempty(crosscon)
    if exist([outdir '/ldc_data/disvol_cross_' num2str(subsamp_fac) '.mat'],'file')
        load([outdir '/ldc_data/disvol_cross_' num2str(subsamp_fac) '.mat'],'file')
    else
        disvol_cross = cell(1,numel(crosscon));
        for i = 1:numel(crosscon)
            disvol_cross{i} = roidata2rdmvol_lindisc_batch(searchrois,filtereddesignvol,filtereddatavol,'crosscon',crosscon{i});
                 
        end
        save([outdir '/ldc_data/disvol_cross_' num2str(subsamp_fac) '.mat'],'disvol_cross','-v7.3');    
    end
else
    disvol_cross = {};
end

%Now do cross training on collapsed volume
if ~isempty(crosscon_collapsed)
    if exist([outdir '/ldc_data/disvol_cross_collapsed' num2str(subsamp_fac) '.mat'],'file')
        load([outdir '/ldc_data/disvol_cross_collapsed' num2str(subsamp_fac) '.mat'],'file')
    else
        disvol_cross_collapsed = cell(1,numel(crosscon_collapsed));
        for i = 1:numel(crosscon_collapsed)
            disvol_cross_collapsed{i} = roidata2rdmvol_lindisc_batch(searchrois,filtereddesignvol,filtereddatavol,'crosscon',crosscon_collapsed{i});
                 
        end
        save([outdir '/ldc_data/disvol_cross_collapsed' num2str(subsamp_fac) '.mat'],'disvol_cross_collapsed','-v7.3');    
    end
else
    disvol_cross_collapsed = {};
end

searchlight_locations =  searchrois.xyz(:,these_locs);

% function visualiseepidata(epivol)
%     
% figure
% imagesc(makeimagestack(data2mat(epivol,epivol.data(1,:))));
% % pedantic styling below
% axis('off');
% set(gca,'dataaspectratio',[epivol.voxsize(1:2) 1])
% chandle = colorbar;
% set(chandle,'position',get(chandle,'position') .* [1.1 1 .5 .5])
% 
% end



end