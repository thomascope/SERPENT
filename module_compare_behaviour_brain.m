function [disvol, thisRDM] = module_compare_behaviour_brain(subject,spmdir,outdir)
%A function to extract the dissimilarity matrix from the behavioural data
%and compare it to brain data
%TEC May2018

addpath(genpath('/imaging/tc02/toolboxes/pilab')) %Path to pattern information toolbox
addpath(genpath('/imaging/tc02/toolboxes/rsatoolbox')) % Path to rsa toolbox|

line_draw_data = dir(['./7T_JudgementData/' subject '_line_drawings*']);
load(['./7T_JudgementData/' line_draw_data.name],'estimate_dissimMat_ltv_MA')
thisRDM = rank_transform_RDM(estimate_dissimMat_ltv_MA);

if exist([outdir '/ldc_data/filtereddata.mat'],'file')
    disp('Loading previous filtered data')
    load([outdir '/ldc_data/filtereddata.mat'])
else
    %First load in the epi from the relevant SPM, masked to the warped structural
    [epivol,designvol] = spm2vol(fullfile(spmdir,'SPM.mat'),'mask',fullfile(outdir,'wstructural_csf.nii'));
    
    %Then preprocess the design, removing button presses from LDC
    [filtereddatavol,filtereddesignvol] = preprocessvols(epivol,designvol,'ignorelabels',{'Left Button Press','Right Button Press','null_null_null_null'});
    
    if ~exist([outdir '/ldc_data'],'dir')
        mkdir([outdir '/ldc_data'])
    end
    save([outdir '/ldc_data/filtereddata.mat'],'filtereddatavol','filtereddesignvol','-v7.3');
    clear epivol %For memory
    clear designvol
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

% %Now subsample the mask space by a factor of 3 (from 1.5mm voxels to 4.5mm searchlight spacing)
% these_locs = ~logical(mod(fullrois.xyz(1,:),3))&~logical(mod(fullrois.xyz(2,:),3))&~logical(mod(fullrois.xyz(3,:),3));
% searchrois = fullrois;
% searchrois.linind = searchrois.linind(1,these_locs);
% searchrois.xyz = searchrois.xyz(:,these_locs);
% searchrois.data = searchrois.data(these_locs,these_locs);
% searchrois.nsamples = sum(these_locs);
% searchrois.nfeatures = sum(these_locs);
% searchrois.meta.samples.order = 1:sum(these_locs);

if exist([outdir '/ldc_data/disvol.mat'],'file')
    disp('Loading previous disvol')
    load([outdir '/ldc_data/disvol.mat'])
else
disvol = roidata2rdmvol_lindisc_batch(searchrois,filtereddesignvol,filtereddatavol);

save([outdir '/ldc_data/disvol.mat'],'disvol','-v7.3');
end

function visualiseepidata(epivol)
    
figure
imagesc(makeimagestack(data2mat(epivol,epivol.data(1,:))));
% pedantic styling below
axis('off');
set(gca,'dataaspectratio',[epivol.voxsize(1:2) 1])
chandle = colorbar;
set(chandle,'position',get(chandle,'position') .* [1.1 1 .5 .5])

end



end