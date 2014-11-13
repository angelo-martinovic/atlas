% dataset - eTrims or haussmann
% fold - 1 to 5
% dataLocation - e.g. /usr/data/amartino/gould/testMeanShiftNew/
% detectionLocation - e.g. /users/visics/amartino/RNN_link/RNN/data/detections_haussmann/
% detectorType - e.g. window-generic
% nClasses - 8
% windowSize - sliding window size for averaging, usually 200
function labelMaps  = LearnDetectionLabelDistribution( dataset,fold,dataLocation,detectionLocation,detectorType,nClasses,windowSize )
%LEARNDETECTIONLABELDISTRIBUTION Based on the detections in the validation
%set, learns a probability distribution of each pixel in the detection mask
%belonging to a certain label.

    if nargin<7
        error('Usage: LearnDetectionLabelDistribution( dataset,fold,dataLocation,detectionLocation,detectorType,nClasses,windowSize)');
    end
    modelSizeW = 100;
    modelSizeH = 100;
    
    imageSizeW = 500;
    imageSizeH = 500;
    
    
    imageNames = ReadFoldImageNames(dataset,fold,'valid');
    
    origImageNames = strcat(dataLocation,imageNames);
    
    detectionLocation1 = [detectionLocation detectorType '/detections_fold' num2str(fold) '_valid/'];
    detectionFilenames = strcat(detectionLocation1, imageNames);
    detectionFilenames = strcat(detectionFilenames,'.txt');
    
    groundTruthFilenames = strcat(origImageNames,'.txt');
    
    % We can use the training data as well if we have a generic detector
    if (strcmp(detectorType(end-6:end),'generic'))
        imageNames2 = ReadFoldImageNames(dataset,fold,'train');
        origImageNames2 = strcat(dataLocation,imageNames2);
    
        detectionLocation2 = [detectionLocation detectorType '/detections_fold' num2str(fold) '/'];
        detectionFilenames2 = strcat(detectionLocation2, imageNames2);
        detectionFilenames2 = strcat(detectionFilenames2,'.txt');

        groundTruthFilenames2 = strcat(origImageNames2,'.txt');
        
        detectionFilenames = [detectionFilenames; detectionFilenames2];
        groundTruthFilenames = [groundTruthFilenames; groundTruthFilenames2];
    end
    
    
    labels=cell(0);
    detections=[];
    for i=1:length(detectionFilenames)
        fprintf('.');
        s = dir(detectionFilenames{i});
        if isempty(s)
            error(['File not found: ' detectionFilenames{i}]);
        end
        if s.bytes == 0
            warning('No detections found');
            detectionsList =[];
        else
            detectionsList = dlmread(detectionFilenames{i});
        end;
       
        groundTruth = dlmread(groundTruthFilenames{i});
        
        detectionsList = [detectionsList repmat(i,size(detectionsList,1),1)];
        
        detections = [detections; detectionsList];
        labels{end+1} = groundTruth;
    end
    fprintf('\n');
    
    numDetections = length(detections);
    
    if (numDetections==0)
        error('No detections to learn from.');
    end
    
    % Sort by detection score
    normDetections = flipud(sortrows(detections,5));
   

    % Masks for each image
    detectionMap = cell(1,length(detectionFilenames));
    
    labelMaps = struct('score',{},'labelMap',{});
    
    %% Calculate the cumulative sum for all detection scores 
    % (similar idea to integral image)
    integralAccumulator = cell(numDetections,1);
    
    fprintf('Calculating integral sums...');
    for d=1:numDetections
        accumulator = zeros(modelSizeH,modelSizeW,nClasses);   %Histogram: P(C|detection)
        
        i = normDetections(d,6);    %Index of the image where the detection lies
        height = size(labels{i},1);
        width = size(labels{i},2);
        if (size(detectionMap{i},1)==0)
            detectionMap{i} = zeros(height,width);
        end

         %Detection bounding box rectangle
         detectionRect = normDetections(d,1:4);  
         startRow = max(round(detectionRect(2)),1);
         endRow = min(round(detectionRect(4)),height);
         startColumn = max(round(detectionRect(1)),1);
         endColumn = min(round(detectionRect(3)),width);

         if (endRow-startRow<1) || (endColumn-startColumn<1)
             continue;
         end

         detWidth = endRow-startRow+1;
         detHeight = endColumn-startColumn+1;
         if strcmp(detectorType,'window-generic')
              startRow = max(1,round(startRow - detHeight*0.05));
              endRow = min(height,round(endRow + detHeight*0.05));

              startColumn = max(1,round(startColumn - detWidth*0.05));
              endColumn = min(width,round(endColumn + detWidth*0.05));
         end
                
         % Mask out the selected area on the image
         detectionMap{i}(startRow:endRow,startColumn:endColumn) = 1; 

         extractedLabels = labels{i}(startRow:endRow,startColumn:endColumn);
         extractedLabels = imresize(extractedLabels,[modelSizeH modelSizeW],'nearest');

         % Accumulate evidence
         for l=1:nClasses
             accumulator(:,:,l) = accumulator(:,:,l) + (extractedLabels==l);
         end
         
         if (d>1)
            integralAccumulator{d} = integralAccumulator{d-1}+accumulator;
         else
            integralAccumulator{d} = accumulator;
         end
             
    end
    fprintf('Done.\n');
   
    %% Calculate the actual windowed sums from the integral sum
    fprintf('Calculating windowed sums...');
    for detPosition=1:numDetections
        startPosition = detPosition-round(windowSize/2);
        endPosition = detPosition+round(windowSize/2);
        
        if (endPosition>numDetections)
            endPosition = numDetections;
        end
        
        if startPosition>1
            accumulator = integralAccumulator{endPosition} - integralAccumulator{startPosition-1};
        else
            accumulator = integralAccumulator{endPosition};
        end
        
        % Laplace smoothing
        alpha = 1;
        accumulator = bsxfun(@rdivide,accumulator+alpha,sum(accumulator,3)+nClasses*alpha);
        
        % Save the pair (score,labelmap)
        labelMaps(detPosition)=struct('score',normDetections(detPosition,5),'labelMap',accumulator);
        
        
    end
    fprintf('Done.\n');
    
    %% Calculate the prior distribution of labels
    imageNamesTrain = ReadFoldImageNames(dataset,fold,'train');
    origImageNamesTrain = strcat(dataLocation,imageNamesTrain);
    groundTruthFilenamesTrain = strcat(origImageNamesTrain,'.txt');
    
    labelPrior = zeros(imageSizeH,imageSizeW,nClasses);
    allGroundTruthFilenames = groundTruthFilenamesTrain;
    for i=1:length(allGroundTruthFilenames)
        fprintf('.');
        groundTruth = dlmread(allGroundTruthFilenames{i});
        extractedLabels = imresize(groundTruth,[imageSizeH imageSizeW],'nearest');
        for l=1:nClasses
             labelPrior(:,:,l) = labelPrior(:,:,l) + (extractedLabels==l);
        end
    end
    
    % Laplace smoothing
    alpha = 1;
    labelPrior = bsxfun(@rdivide,labelPrior+alpha,sum(labelPrior,3)+nClasses*alpha);
%     labelPrior=[];
    
    %% Display the learned maps
    for i=1:8
        subplot(1,8,i),imagesc(labelMaps(1).labelMap(:,:,i));
    end
    %% Saving the results
    save(['/esat/sadr/amartino/RNN/data/detLabelDistributions_' dataset '_' detectorType '_fold' ...
        num2str(fold) '_winSize_' num2str(windowSize) '.mat'], 'labelMaps', 'labelPrior');
           


end

