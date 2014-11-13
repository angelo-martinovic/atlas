function ThirdLayerExperiment4(img)
%     for img=1:1

        fold = 1;
        imageNr = img;
        dataweight = 80;
        gridweight = 5;
        dataLocation = '/users/visics/mmathias/devel/3layerJournal/';
        
        %% Load the 3rd layer output
        outputMat = [dataLocation 'haussmann_sampling_40_set_eval_fold_' num2str(fold) '_image_' num2str(imageNr) ...
            '_dataweight_' num2str(dataweight) '_gridweight_' num2str(gridweight) '.mat' ];
        
        load(outputMat);
        labels = output;
        
        figure;imagesc(labels);
        
end