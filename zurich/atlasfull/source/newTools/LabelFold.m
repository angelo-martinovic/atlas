% Evaluates the 3 layer approach on a single fold of a given dataset
% Dataset: haussmann or eTrims
% Type: valid or eval
% Fold: [1..5]
% Data location: /usr/data/amartino/gould/testMeanShiftNew/ or similar
% Detection location: /users/visics/amartino/RNN_link/RNN/data/detections_haussmann/specific/
% Detectors: a cell array of detector names
% Classifier: SVM_cv, crf, logistic, NN
% nImages: ~20
% nClasses: 8
% ignoreClasses: usually class 0, also 8 for haussmann
% w: learned CRF weights
% labelCost: learned CRF labelcost
function [result,confMatrix] = LabelFold(dataset, type, fold, ...
    dataLocation, detectionLocation, detectors, classifier, ...
    nImages, nClasses, ignoreClasses, w, labelCost)

    if nargin~=12
        disp(['Usage: LabelFold(dataset, type, fold, dataLocation,'...
        'detectionLocation, detectorType, classifier, nImages,'...
        'nClasses, ignoreClasses, w, labelCost)']);
        return;
    end

    addpath 'newTools/';

    hyperParameters = struct('detections',0,'w',0,...
        'nClasses',nClasses,'ignoreClasses',ignoreClasses, ...
        'labelCost',labelCost);

    % Image names
    imageNames = ReadFoldImageNames(dataset,fold,type);
    
    % Select only a subset if so required
    maxImages = length(imageNames);
    nImages = min(nImages,maxImages);
    
    imageNames = imageNames(1:nImages);
    
    % Generate data filenames
    origImageNames = strcat(dataLocation,imageNames);
    segFilenames = strcat(origImageNames,'.seg');
    imageFilenames = strcat(origImageNames,'.jpg');
    
    % Load non-rectified groundtruth for etrims
    if strcmp(dataset,'eTrims')
        gtLocation = '/esat/sadr/amartino/Facades/etrims-db_v1/annotations/08_etrims-ds/';
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
    
    % Detectors
    loadedData = struct('detector',[],'labelMaps',[],'filenames',[]);
    detectionLocationStem = detectionLocation;
    for i=1:length(detectors)
        if strcmp(type,'eval')
            detectionLocation = [detectionLocationStem detectors{i} '/detections_fold' num2str(fold) '/'];
        else
            detectionLocation = [detectionLocationStem detectors{i} '/detections_fold' num2str(fold) '_valid/'];
        end

        detectionFilenames = strcat(detectionLocation,imageNames);
        detectionFilenames = strcat(detectionFilenames,'.txt');
        loadedData(i).filenames=detectionFilenames;

        %STATISTICS from the validation set
        statisticsFilenames = strcat(['../../data/detLabelDistributions_' dataset '_'],detectors);
        
        %HACK
        if strncmp(detectors{i},'door',4)
            statisticsFilenames = strcat(statisticsFilenames,['_fold' num2str(fold) '_winSize_10.mat']);
        else
            statisticsFilenames = strcat(statisticsFilenames,['_fold' num2str(fold) '_winSize_200.mat']);
        end
    
        labelMaps = load(statisticsFilenames{i},'labelMaps');
        labelMaps=labelMaps.labelMaps;
        loadedData(i).detector=detectors{i};
        loadedData(i).labelMaps=labelMaps;
    end
    
    
    % Detection label distribution prior
    hyperParameters.detections = loadedData;

    clear loadedData;

%     hyperParameters.w = w(fold,:);
    hyperParameters.w = w;

    disp(hyperParameters);
    tic;
    [confusionMatrix,acc] = LabelAllImages(dataset,type,fold,imageFilenames,imageNames, ...
    groundTruthFilenames, segFilenames, classificationFilenames, hyperParameters);
    toc;
    
    % Results
    result = acc;
    
    disp('Confusion matrix');
    confusionMatrix(isnan(confusionMatrix))=0;
    confMatrix = 100*confusionMatrix;
    
    disp(acc);
    disp(confMatrix);
   
end
