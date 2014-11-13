%MAXPOSSIBLESEGMENTATIONACCURACYFOLD For a dataset fold, evaluates the 
%segmentation accuracy by assigning each segment to the pixel majority vote.
function [ acc,confusionMatrix ] = MaxPossibleSegmentationAccuracyFold( dataset,fold, dataLocation, nClasses, ignoreClasses )

    if nargin~=5
        error('Usage: MaxPossibleSegmentationAccuracyFold( dataset,fold, dataLocation, nClasses, ignoreClasses )');
    end
    
    evalFilename = ['/esat/sadr/amartino/RNN/data/' dataset '/evalList' num2str(fold) '.txt'];
    delimiter = '';
    formatSpec = '%s%[^\n\r]';
    fileID = fopen(evalFilename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
    fclose(fileID);
    imageNames = [dataArray{:,1:end-1}];
    
    origImageNames = strcat(dataLocation,imageNames);
    segFilenames = strcat(origImageNames,'.seg');
    
    % Load non-rectified groundtruth for etrims
    if strcmp(dataset,'eTrims')
        gtLocation = '/usr/data/amartino/Facades/etrims-db_v1/annotations/08_etrims-ds/';
        groundTruthFilenamesNonRectified = strcat(gtLocation,imageNames);
        groundTruthFilenamesNonRectified = strcat(groundTruthFilenamesNonRectified,'.txt');        
    else
        groundTruthFilenamesNonRectified = [];
    end
    
    groundTruthFilenames = strcat(origImageNames,'.txt');
    
    [acc, confusionMatrix] = MaxPossibleSegmentationAccuracySet(dataset,segFilenames,groundTruthFilenames,groundTruthFilenamesNonRectified,nClasses,ignoreClasses);
end

%MAXPOSSIBLESEGMENTATIONACCURACYSET For a set of images, evaluates the 
%segmentation accuracy by assigning each segment to the pixel majority vote.
function [ acc,confusionMatrix ] = MaxPossibleSegmentationAccuracySet( dataset,segFilenames, groundTruthFilenames,groundTruthFilenamesNonRectified, nClasses, ignoreClasses )

    if (length(segFilenames)~=length(groundTruthFilenames))
        error('The length of segFilenames must be equal to the length of groundTruthFilenames');
    end
    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(nClasses,nClasses);
    
    for i=1:length(segFilenames)
        disp(['Processing image ' num2str(i) '/' num2str(length(segFilenames)) '...']);
        if strcmp(dataset,'eTrims')
            gtNonRect = groundTruthFilenamesNonRectified{i};
        else
            gtNonRect = [];
        end
        [corImg,totImg,cmImg] = MaxPossibleSegmentationAccuracy( dataset,segFilenames{i}, groundTruthFilenames{i}, gtNonRect, nClasses, ignoreClasses );
        correctPixels = correctPixels + corImg;
        totalPixels = totalPixels + totImg;
        confusionMatrix = confusionMatrix + cmImg;
    end

    for i=1:nClasses
        confusionMatrix(i,:) = confusionMatrix(i,:)/sum(confusionMatrix(i,:));
    end
    %Accuracy
    acc = correctPixels/totalPixels;
    
    confusionMatrix = (100*confusionMatrix);
    confusionMatrix(isnan(confusionMatrix))=0;
end

%MAXPOSSIBLESEGMENTATIONACCURACY Evaluates the segmentation accuracy by
%assigning each segment to the pixel majority vote.
function [ correctPixels,totalPixels,confusionMatrixImg ] = MaxPossibleSegmentationAccuracy( dataset,segFilename, groundTruthFilename, gtNonRectFilename, nClasses, ignoreClasses )

    segmentation = dlmread(segFilename);
    groundTruth = dlmread(groundTruthFilename);
    
    if strcmp(dataset,'eTrims') 
        groundTruthNonRect = dlmread(gtNonRectFilename);
    end
    
    % In eTrims, groundtruth will not match the size of the segmentation
    % due to the rectification. In all other cases, resize the result to
    % fit. 
    
    if (~isequal(size(segmentation),size(groundTruth)))
        fprintf('x');
        groundTruth = imresize(groundTruth,size(segmentation),'nearest');
        fprintf('o');
    end
   
    
    if strncmp(segFilename,'/esat/sadr/amartino/gould/testgpb_0.052/',40) || ...
            strncmp(segFilename,'/usr/data/amartino/gould/testgpb_0.052/',39)
            segmentation=segmentation-1;
    end

    if strncmp(segFilename,'/esat/sadr/amartino/gould/testSeeds/',36)|| ...
        strncmp(segFilename,'/usr/data/amartino/gould/testSeeds/',35)
        if (length(unique(segmentation))~=max(segmentation(:))-min(segmentation(:))+1)
            fprintf('x');
            indexHighest = length(unique(segmentation))-1;

            segUniques = unique(segmentation);
           
            % Relabel the segment matrix
            for s=0:indexHighest
                segmentation(segmentation==segUniques(s+1))=s;
            end
            fprintf('o');
        end

    end
    
    % Since segments start from 0
    segmentation = segmentation + 1;   
    
    % Number of segments in the image
    numSegs = max(segmentation(:));
    
    % Best possible labeling
    labeling=zeros(size(groundTruth,1),size(groundTruth,2));
    
    % For each segment, get all pixel labels and use the majority vote
    for r = 1:numSegs
        res2 = groundTruth(segmentation==r);  
        majority = mode(res2);
        
        labeling(segmentation==r)= majority;
    end
    
     % For eTrims, the resulting labeling has to be 'unrectified'
    if strcmp(dataset,'eTrims') 
        homographyFilename = strcat(segFilename(1:end-4),'rect.dat');
        homography = load(homographyFilename);
        labeling2 = rewarp(groundTruthNonRect,labeling,homography);
        
        labeling = labeling2;
        groundTruth = groundTruthNonRect;
    end
    
    figure(1),subplot(211),imagesc(labeling),subplot(212),imagesc(groundTruth);
      
    % Evaluate the best labeling
    [correctPixels, totalPixels, confusionMatrixImg]= EvaluateLabeling(dataset,labeling,groundTruth,nClasses,ignoreClasses);
    
end

