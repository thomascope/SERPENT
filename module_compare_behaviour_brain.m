function module_compare_behaviour_brain(subject,spmpath,outpath)
%A function to extract the dissimilarity matrix from the behavioural data
%and compare it to brain data
%TEC May2018

addpath(genpath('/imaging/tc02/toolboxes/pilab')) %Path to pattern information toolbox
addpath(genpath('/imaging/tc02/toolboxes/rsatoolbox')) % Path to rsa toolbox|

load('./7T_JudgementData/' subject '_line_drawings_session2_2018-5-1_13h56m_workspace.mat','estimate_dissimMat_ltv_MA')
thisRDM = rank_transform_RDM(estimate_dissimMat_ltv_MA);

%First load in the epi from the relevant SPM, masked to the warped structural
[epivol,designvol] = spm2vol(fullfile(spmdir,'SPM.mat'),'mask',fullfile(outdir,'wstructural_csf.nii'));

%Then determine 100voxel ROIs (parallelised)
[searchrois,diagnostic] = mask2searchrois(epivol,'nvox',100);





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