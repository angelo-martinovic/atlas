function labelMaps  = LearnDetectionLabelDistributionFromMask( dataset,fold,detectionLocation,detectorType,nClasses,positiveClass )
%LEARNDETECTIONLABELDISTRIBUTION Based on the detections in the validation
%set, learns a probability distribution of each pixel in the detection mask
%belonging to a certain label.

    if nargin<6
        error('Usage: LearnDetectionLabelDistribution( dataset,fold,detectionLocation,detectorType,nClasses,positiveClass)');
    end
    modelSizeW = 100;
    modelSizeH = 100;
   
   
    labelMaps = struct('score',{},'labelMap',{});
    
    %% Read the mask
    mask=imread([detectionLocation detectorType '/mask.png']);
    
    % Resize
    mask = imresize(mask,[modelSizeH,modelSizeW]);
    
    % Threshold
    mask = mask(:,:,1)<128;
    
    accumulator = zeros(modelSizeH,modelSizeW,nClasses);   %Histogram: P(C|detection)
    
    boostTo = 0.9;
    for i=1:nClasses
        
        distr = 1/nClasses * ones(modelSizeH,modelSizeW);
        if i==positiveClass
            distr(mask) = boostTo;
        else
            distr(mask) = (1-boostTo)/(nClasses-1);
        end
        
        accumulator(:,:,i) = distr;
    end
    

    % Save the pair (score,labelmap)
    labelMaps(1)=struct('score',1,'labelMap',accumulator);
        
       
    fprintf('Done.\n');
    
    %% Display the learned maps
    for i=1:8
        subplot(1,8,i),imagesc(labelMaps(1).labelMap(:,:,i));
    end
    %% Saving the results
    save(['/esat/sadr/amartino/RNN/data/detLabelDistributions_' dataset '_' detectorType '_fold' ...
        num2str(fold) '_winSize_10.mat'], 'labelMaps');
           


end

