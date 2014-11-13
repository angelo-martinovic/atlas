%ClassificationAccuracyFold For a dataset fold, evaluates the 
%segmentation accuracy by assigning each segment to the classifier vote.
% [acc,cm]= ClassificationAccuracyFold(1,'/usr/data/amartino/gould/testSeeds/','NN_fixed',8,[0 8])
function [ acc,confusionMatrix ] = ClassificationAccuracyFold( dataset,fold, dataLocation, classifier, nClasses, ignoreClasses )

    if nargin~=6
        error('Usage: ClassificationAccuracyFold( dataset,fold, dataLocation, classifier, nClasses, ignoreClasses )');
    end
    
    imageNames = ReadFoldImageNames(dataset,fold,'eval');
    
    origImageNames = strcat(dataLocation,imageNames);
    segFilenames = strcat(origImageNames,'.seg');
    
    % Load non-rectified groundtruth for etrims
    if strcmp(dataset,'eTrims')
        gtLocation = '/usr/data/amartino/Facades/etrims-db_v1/annotations/08_etrims-ds/';
        groundTruthFilenames = strcat(gtLocation,imageNames);
        groundTruthFilenames = strcat(groundTruthFilenames,'.txt');        
    elseif strcmp(dataset,'monge30Rect')
        gtLocation = '/usr/data/amartino/Facades/Monge3D/subset30_800px_labels/labels_angelo/';
        groundTruthFilenames = strcat(gtLocation,imageNames);
        groundTruthFilenames = strcat(groundTruthFilenames,'.txt');    
    else
        groundTruthFilenames = strcat(origImageNames,'.txt');
    end
   
    
    classificationLocation = [dataLocation 'output/' classifier '_fold' num2str(fold) '/'];
    classificationImageNames = strcat(classificationLocation,imageNames);
    classificationFilenames = strcat(classificationImageNames,'.marginal.txt');
    
    [acc, confusionMatrix] = ClassificationAccuracySet(dataset,segFilenames,groundTruthFilenames,classificationFilenames,nClasses,ignoreClasses);
end

%ClassificationAccuracySet For a set of images, evaluates the 
%segmentation accuracy by assigning each segment to the classifier vote.
function [ acc,confusionMatrix ] = ClassificationAccuracySet(dataset, segFilenames, groundTruthFilenames,classificationFilenames, nClasses, ignoreClasses )

    if (length(segFilenames)~=length(groundTruthFilenames) || ...
        length(segFilenames)~=length(classificationFilenames))
        error('The length of segFilenames must be equal to the length of groundTruthFilenames and classificationFilenames.');
    end
    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(nClasses,nClasses);
    
    for i=1:length(segFilenames)
        disp(['Processing image ' num2str(i) '/' num2str(length(segFilenames)) '...']);
        [corImg,totImg,cmImg] = ClassificationAccuracy(dataset,segFilenames{i}, groundTruthFilenames{i}, classificationFilenames{i}, nClasses, ignoreClasses );
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

%ClassificationAccuracy Evaluates the segmentation accuracy by
%assigning each segment to the classifier vote.
function [ correctPixels,totalPixels,confusionMatrixImg ] = ClassificationAccuracy(dataset,segFilename, groundTruthFilename, classificationFilename, nClasses, ignoreClasses )

    segmentation = dlmread(segFilename);
    
    if strcmp(dataset,'monge30DepthRect')
            targetFilename=strrep(groundTruthFilename,'visualizeRect','visualize');
            target = dlmread(targetFilename);
    end
        
    if exist(groundTruthFilename, 'file')
            groundTruth = dlmread(groundTruthFilename);
        else
            warning('No ground truth');
            groundTruth = zeros(size(segmentation));
    end
    classification = dlmread(classificationFilename);
    
   
    % In eTrims, groundtruth will not match the size of the segmentation
    % due to the rectification. In all other cases, resize the result to
    % fit. 
    if ~strcmp(dataset,'eTrims') && ~strcmp(dataset,'monge30Rect') 
        if (~isequal(size(segmentation),size(groundTruth)))
            fprintf('x');
            groundTruth = imresize(groundTruth,size(segmentation),'nearest');
            fprintf('o');
        end
        
        
    end
        
    if strncmp(segFilename,'/esat/sadr/amartino/gould/testgpb_0.052/',40) || ...
            strncmp(segFilename,'/usr/data/amartino/gould/testgpb_0.052/',39)
            segmentation=segmentation-1;
            classification = classification(2:end,:);
    end

    if strncmp(segFilename,'/esat/sadr/amartino/gould/testSeeds/',36)|| ...
        strncmp(segFilename,'/usr/data/amartino/gould/testSeeds/',35)
        if (length(unique(segmentation))~=max(segmentation(:))-min(segmentation(:))+1)
            fprintf('x');
            indexHighest = length(unique(segmentation))-1;

            segUniques = unique(segmentation);
            missingSegments = find(ismember(0:indexHighest, segUniques)==0);
            
            if (length(unique(segmentation))~=length(classification))
                
                %disp(missingSegments);

                % Delete the corresponding rows from the feature matrix
                classification(missingSegments,:)=[];
            end
            
            % Relabel the segment matrix
            for s=0:indexHighest
                segmentation(segmentation==segUniques(s+1))=s;
            end
            fprintf('o');
        end

    end
    
    % Column vector, each entry is the predicted label
    % -1 because classifier's first output is class 0
    if strcmp(dataset,'eTrims') && max(vec2ind(classification'))<=nClasses
        
        regionLabels = vec2ind(classification'); 
    else
        regionLabels = vec2ind(classification') - 1; 
    end
        
    % Since segments start from 0
    segmentation = segmentation + 1;   
    
    % Number of segments in the image
    numSegs = max(segmentation(:));
    
    % Classifier labeling
    %labeling=zeros(size(segmentation,1),size(segmentation,2));
    
    % Probabilities per pixel
    segMap = zeros(size(segmentation,1),size(segmentation,2),nClasses);
    
    % For each segment, assign the same label to all pixels
    % Vectorized
    labeling = regionLabels(segmentation);
    
    % Create a probability map for each pixel
    for c=1:nClasses
        cVec = classification(:,c+1);
        segMap(:,:,c) = cVec(segmentation);
    end
    
%     for r = 1:numSegs
%         fprintf('%d',r);
%         labeling(segmentation==r) = regionLabels(r);
%         
%         for c=1:nClasses
%             tmp = zeros(size(segmentation,1),size(segmentation,2));
%             tmp(segmentation==r) = classification(r,1+c);
%             segMap(:,:,c) = segMap(:,:,c) + tmp;
%         end
%     end
    
    % For eTrims, the resulting labeling has to be 'unrectified'
    if strcmp(dataset,'eTrims') || strcmp(dataset,'monge30Rect')
        homographyFilename = strcat(segFilename(1:end-4),'rect.dat');
        homography = load(homographyFilename);
        labeling = rewarp(groundTruth,labeling,homography);
    elseif  strcmp(dataset,'monge30DepthRect')
        homographyFilename = strcat(segFilename(1:end-4),'rect.dat');
        
        homography = load(homographyFilename);
        labeling = rewarp(target,labeling,homography);
        groundTruth = rewarp(target,groundTruth,homography);
        
    end
  
    
    figure(1),subplot(211),imagesc(labeling),subplot(212),imagesc(groundTruth);
    save([segFilename(1:end-4) '.label_layer1.mat'],'labeling','segMap');
    
    % Evaluate the best labeling
    [correctPixels, totalPixels, confusionMatrixImg]= EvaluateLabeling(dataset,labeling,groundTruth,nClasses,ignoreClasses);
    
end

