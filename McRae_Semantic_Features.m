% A script for applying the McRae stimulus set semantic features to our
% dataset.

Physical_List = {
    'Large'
    'Medium'
    'Small'
    '4 Legs'
    '2 Legs'
    'No legs'
    'Fur'
    'Tail'
    'Paws'
    'Hooves'
    'Whiskers'
    'Teeth'
    'Wet nose'
    'Snout'
    'Hair'
    'Stripes'
    'Fins'
    'Gills'
    'Scales'
    'Beak'
    'Feathers'
    'Hump'
    };

Domesticity_List = {
    'Wild'
    'Domestic'
    };

Setting_List = {
    'Pet'
    'Zoo'
    'Farm'
    'Desert'
    'Jungle'
    'Africa'
    'England'
    'Water'
    };

Biological_List = {
    'Feline'
    'Mammal'
    'Lays eggs'
    'Carnivore'
    'Herbivore'
    'Omnivore'
    'Friendly'
    'Dangerous'
    'Flies'
    'Ridden'
    'Swims'
    };

% Now list the animals one at a time
i = 1;
stimuli_features(i).name = 'dog';
stimuli_features(i).physical = {
    'Medium'
    '4 Legs'
    'Fur'
    'Tail'
    'Paws'
    'Wet nose'
    'Hair'
    };
stimuli_features(i).domesticity = {
    'Domestic'
    };
stimuli_features(i).setting = {
    'Pet'
    'England'
    };
stimuli_features(i).biological = {
    'Mammal'
    'Carnivore'
    'Friendly'
    };

i = 2;
stimuli_features(i).name = 'Kangaroo';
stimuli_features(i).physical = {
    'Medium'
    '2 Legs'
    'Tail'
    'Hair'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Desert'
    };
stimuli_features(i).biological = {
    'Herbivore'
    };

i = 3;
stimuli_features(i).name = 'Tapir';
stimuli_features(i).physical = {
    'Medium'
    '4 Legs'
    'Tail'
    'Snout'
    'Hair'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Jungle'
    };
stimuli_features(i).biological = {
    'Herbivore'
    'Mammal'
    };

i = 4;
stimuli_features(i).name = 'Cat';
stimuli_features(i).physical = {
    'Small'
    '4 Legs'
    'Fur'
    'Tail'
    'Paws'
    'Whiskers'
    };
stimuli_features(i).domesticity = {
    'Domestic'
    };
stimuli_features(i).setting = {
    'Pet'
    'England'
    };
stimuli_features(i).biological = {
    'Feline'
    'Mammal'
    'Carnivore'
    };

i = 5;
stimuli_features(i).name = 'Lion';
stimuli_features(i).physical = {
    'Large'
    '4 Legs'
    'Fur'
    'Tail'
    'Paws'
    'Whiskers'
    'Teeth'
    'Hair'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Desert'
    'Jungle'
    'Africa'
    };
stimuli_features(i).biological = {
    'Feline'
    'Mammal'
    'Carnivore'
    'Herbivore'
    'Dangerous'
    };

i = 6;
stimuli_features(i).name = 'Raccoon';
stimuli_features(i).physical = {
    'Small'
    '4 Legs'
    'Fur'
    'Tail'
    'Paws'
    'Whiskers'
    'Stripes'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    };
stimuli_features(i).biological = {
    'Mammal'
    'Omnivore'
    };

i = 7;
stimuli_features(i).name = 'Horse';
stimuli_features(i).physical = {
    'Large'
    '4 Legs'
    'Tail'
    'Hair'
    'Hooves'
    };
stimuli_features(i).domesticity = {
    'Domestic'
    };
stimuli_features(i).setting = {
    'Farm'
    'England'
    };
stimuli_features(i).biological = {
    'Herbivore'
    'Friendly'
    'Ridden'
    };

i = 8;
stimuli_features(i).name = 'Camel';
stimuli_features(i).physical = {
    'Large'
    '4 Legs'
    'Tail'
    'Hair'
    'Hooves'
    'Hump'
    };
stimuli_features(i).domesticity = {
    'Domestic'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Desert'
    'Africa'
    };
stimuli_features(i).biological = {
    'Herbivore'
    'Ridden'
    };

i = 9;
stimuli_features(i).name = 'Antelope';
stimuli_features(i).physical = {
    'Large'
    '4 Legs'
    'Tail'
    'Hair'
    'Hooves'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Desert'
    'Africa'
    };
stimuli_features(i).biological = {
    'Mammal'
    'Herbivore'
    };

i = 10;
stimuli_features(i).name = 'Goldfish';
stimuli_features(i).physical = {
    'Small'
    'No legs'
    'Tail'
    'Fins'
    'Gills'
    'Scales'
    };
stimuli_features(i).domesticity = {
    'Domestic'
    };
stimuli_features(i).setting = {
    'Pet'
    'England'
    'Water'
    };
stimuli_features(i).biological = {
    'Friendly'
    'Swims'
    };

i = 11;
stimuli_features(i).name = 'Shark';
stimuli_features(i).physical = {
    'Large'
    'No legs'
    'Teeth'
    'Fins'
    'Gills'
    'Scales'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Water'
    };
stimuli_features(i).biological = {
    'Carnivore'
    'Dangerous'
    'Swims'
    };

i = 12;
stimuli_features(i).name = 'Seahorse';
stimuli_features(i).physical = {
    'Small'
    'No legs'
    'Tail'
    'Fins'
    'Beak'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Water'
    };
stimuli_features(i).biological = {
    'Lays eggs'
    'Herbivore'
    'Swims'
    };

i = 13;
stimuli_features(i).name = 'Duck';
stimuli_features(i).physical = {
    'Small'
    '2 Legs'
    'Tail'
    'Beak'
    'Feathers'
    };
stimuli_features(i).domesticity = {
    'Wild'
    'Domestic'
    };
stimuli_features(i).setting = {
    'Farm'
    'England'
    'Water'
    };
stimuli_features(i).biological = {
    'Lays eggs'
    'Omnivore'
    'Flies'
    };

i = 14;
stimuli_features(i).name = 'Vulture';
stimuli_features(i).physical = {
    'Medium'
    '2 Legs'
    'Tail'
    'Beak'
    'Feathers'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'Zoo'
    'Desert'
    'Africa'
    };
stimuli_features(i).biological = {
    'Lays eggs'
    'Carnivore'
    'Dangerous'
    'Flies'
    };

i = 15;
stimuli_features(i).name = 'Puffin';
stimuli_features(i).physical = {
    'Small'
    '2 Legs'
    'Tail'
    'Beak'
    'Feathers'
    };
stimuli_features(i).domesticity = {
    'Wild'
    };
stimuli_features(i).setting = {
    'England'
    'Water'
    };
stimuli_features(i).biological = {
    'Lays eggs'
    'Carnivore'
    'Flies'
    };

%Now construct dissimilarity matrices
physical_dissimilarity = nan(size(stimuli_features,2));
domesticity_dissimilarity = nan(size(stimuli_features,2));
setting_dissimilarity = nan(size(stimuli_features,2)); 
biological_dissimilarity = nan(size(stimuli_features,2)); 
nonphysical_dissimilarity = nan(size(stimuli_features,2)); 

for i = 1:size(stimuli_features,2)
    for j = 1:size(stimuli_features,2)
        physical_dissimilarity(i,j) = 1-length(intersect(stimuli_features(i).physical,stimuli_features(j).physical))/length(union(stimuli_features(i).physical,stimuli_features(j).physical));
        domesticity_dissimilarity(i,j) = 1-length(intersect(stimuli_features(i).domesticity,stimuli_features(j).domesticity))/length(union(stimuli_features(i).domesticity,stimuli_features(j).domesticity));
        setting_dissimilarity(i,j) = 1-length(intersect(stimuli_features(i).setting,stimuli_features(j).setting))/length(union(stimuli_features(i).setting,stimuli_features(j).setting));
        biological_dissimilarity(i,j) = 1-length(intersect(stimuli_features(i).biological,stimuli_features(j).biological))/length(union(stimuli_features(i).biological,stimuli_features(j).biological));
        nonphysical_dissimilarity(i,j) = 1-(length(intersect(stimuli_features(i).domesticity,stimuli_features(j).domesticity))+length(intersect(stimuli_features(i).setting,stimuli_features(j).setting))+length(intersect(stimuli_features(i).biological,stimuli_features(j).biological)))/(length(union(stimuli_features(i).domesticity,stimuli_features(j).domesticity))+length(union(stimuli_features(i).setting,stimuli_features(j).setting))+length(union(stimuli_features(i).biological,stimuli_features(j).biological)));
    end
end
addpath('../Visual models')
figure
set(gcf,'Position',[100 100 1600 1200]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
subplot(1,5,1)
image(scale01((1-physical_similarity)),'CDataMapping','scaled')
axis square
title('Physical, raw')
subplot(1,5,2)
image(scale01((1-domesticity_dissimilarity)),'CDataMapping','scaled')
axis square
title('Domesticity, raw')
subplot(1,5,3)
image(scale01((1-setting_dissimilarity)),'CDataMapping','scaled')
axis square
title('Setting, raw')
subplot(1,5,4)
image(scale01((1-biological_dissimilarity)),'CDataMapping','scaled')
axis square
title('Biology, raw')
subplot(1,5,5)
image(scale01((1-nonphysical_dissimilarity)),'CDataMapping','scaled')
axis square
title('Non-physical, raw')

figure
set(gcf,'Position',[100 100 1600 1200]);
set(gcf, 'PaperPositionMode', 'auto');
set(gcf,'color','w');
subplot(1,5,1)
image(scale01(rankTransform_equalsStayEqual(1-physical_similarity)),'CDataMapping','scaled')
axis square
title('Physical, ranked')
subplot(1,5,2)
image(scale01(rankTransform_equalsStayEqual(1-domesticity_dissimilarity)),'CDataMapping','scaled')
axis square
title('Domesticity, ranked')
subplot(1,5,3)
image(scale01(rankTransform_equalsStayEqual(1-setting_dissimilarity)),'CDataMapping','scaled')
axis square
title('Setting, ranked')
subplot(1,5,4)
image(scale01(rankTransform_equalsStayEqual(1-biological_dissimilarity)),'CDataMapping','scaled')
axis square
title('Biology, ranked')
subplot(1,5,5)
image(scale01(rankTransform_equalsStayEqual(1-nonphysical_dissimilarity)),'CDataMapping','scaled')
axis square
title('Non-physical, ranked')

save('McRae_Dissimilarities','physical_dissimilarity','domesticity_dissimilarity','setting_dissimilarity','biological_dissimilarity','nonphysical_dissimilarity')