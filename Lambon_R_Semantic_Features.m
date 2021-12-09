% A script for applying the Lambon Ralph stimulus set semantic features to our
% dataset.

semantic_data = readtable('SERPENT_allfeatures_allwords.csv');

stimuli = semantic_data.Properties.VariableNames(4:end);
feature_visible = logical(semantic_data.feature_is_visible);

%Now extract data
all_datapoints = semantic_data{:,4:end};
all_knowledge = semantic_data{~feature_visible,4:end};
all_visible = semantic_data{feature_visible,4:end};

%Now calculate cosine similarity of every item
%Require text analytics toolbox
visible_cosine_dissimilarity = 1-cosineSimilarity(all_visible');
knowledge_cosine_dissimilarity = 1-cosineSimilarity(all_knowledge');
all_cosine_dissimilarity = 1-cosineSimilarity(all_datapoints');

%Now show matrices
addpath('../Visual models')
figure
set(gcf,'Position',[100 100 1600 1200]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
subplot(1,3,1)
image(scale01((visible_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('Visible, raw')
subplot(1,3,2)
image(scale01((knowledge_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('Knowledge, raw')
subplot(1,3,3)
image(scale01((all_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('All, raw')

figure
set(gcf,'Position',[100 100 1600 1200]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
subplot(1,3,1)
image(scale01(rankTransform_equalsStayEqual(visible_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('Visible, ranked')
subplot(1,3,2)
image(scale01(rankTransform_equalsStayEqual(knowledge_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('Knowledge, ranked')
subplot(1,3,3)
image(scale01(rankTransform_equalsStayEqual(all_cosine_dissimilarity)),'CDataMapping','scaled')
axis square
title('All, ranked')

save('Lambon_Dissimilarities','visible_cosine_dissimilarity','knowledge_cosine_dissimilarity','all_cosine_dissimilarity')