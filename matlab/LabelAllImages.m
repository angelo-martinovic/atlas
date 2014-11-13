% datasetName: haussmann or eTrims
% fold: [1..5]
function result = LabelAllImages(workFolder,datasetName,fold)

    if nargin<2
        warning('Using fold 1 as default');
        fold=1;
    end

    fold = str2double(fold);
    
    hyperParameters = struct();
    
    hyperParameters.dataweight = 80;
    hyperParameters.gridweight = 5;
    hyperParameters.coOccWeight = 10;
    
    hyperParameters.p_rem = 0.4;    % probability of removing an element in the init config
    hyperParameters.num_sampling = 1;%20;
    
    hyperParameters.ga.nGenerations = 20;

if strcmpi(datasetName,'etrims')
    hyperParameters.classifierName = 'SVM-cv';
    hyperParameters.detectors = { 'window-generic' 'door-generic' 'car_side-generic' 'car_rear_front-generic'};
    hyperParameters.nClasses = 8;
    hyperParameters.ignoreClasses = [0];
    hyperParameters.rectification = true;
    
    load(['cache_eTrims_train/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_eTrims_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    hyperParameters.w = w;
    hyperParameters.labelCost = labelCost;
    
    hyperParameters.objClasses = [8];
    hyperParameters.winClass = 8;

    hyperParameters.principles.verticalRegionOrder = false;
    hyperParameters.principles.door = false;
    hyperParameters.principles.cooccurence = false;

    hyperParameters.overrideClasses = [7]; % classes that should not be overruled - vegetation

    hyperParameters.t_sym = 0.4;    % symmetry threshold 
    hyperParameters.colormap = 'eTrims';
        
    %%%
elseif strcmpi(datasetName,'haussmann')
	hyperParameters.classifierName = 'SVM-cv';
    hyperParameters.detectors = { 'window-specific' 'door-specific' };
    hyperParameters.nClasses = 8;
    hyperParameters.ignoreClasses = [0 8];
    hyperParameters.rectification = false;
    
    load(['cache_haussmann_valid/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_haussmann_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    hyperParameters.w = w;
    hyperParameters.labelCost = labelCost;
    
    hyperParameters.objClasses = [1 3 4];
    hyperParameters.winClass = 1; 
    hyperParameters.balcClass = 3; 
    hyperParameters.doorClass = 4;

    hyperParameters.principles.verticalRegionOrder = true;
    hyperParameters.principles.door = true;
    hyperParameters.principles.cooccurence = true;

    hyperParameters.overrideClasses = []; % classes that should not be overlaid

    hyperParameters.t_sym = 0.5;    % symmetry threshold
    hyperParameters.colormap = 'haussmann';
  
    %%%%
elseif strcmpi(datasetName,'monge30')
    hyperParameters.classifierName = 'SVM-cv';
    hyperParameters.detectors = { };
    hyperParameters.nClasses = 8;
    hyperParameters.ignoreClasses = [0 8];
    hyperParameters.rectification = false;
    

    load(['cache_haussmann_valid/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_haussmann_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    w=[w(1); w(4:end)];
    
    hyperParameters.w = w;
    hyperParameters.labelCost = labelCost;
    hyperParameters.colormap = 'haussmann';
    
elseif strcmpi(datasetName,'monge30rect')
    hyperParameters.classifierName = 'SVM-cv';
    hyperParameters.detectors = { };
    hyperParameters.nClasses = 8;
    hyperParameters.ignoreClasses = [0 8];
    hyperParameters.rectification = true;
    

    
    load(['cache_haussmann_valid/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_haussmann_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    w=[w(1); w(4:end)];
    
    hyperParameters.w = w;
    hyperParameters.labelCost = labelCost;
    hyperParameters.colormap = 'haussmann';

elseif strcmpi(datasetName,'seilergraben2014')
    hyperParameters.classifierName = 'SVM-cv';
    hyperParameters.detectors = { };
    hyperParameters.nClasses = 8;
    hyperParameters.ignoreClasses = [0];
    hyperParameters.rectification = false;
    
    load(['cache_eTrims_train/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_eTrims_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    hyperParameters.w = w;
    hyperParameters.labelCost = labelCost;
    
    hyperParameters.objClasses = [1 3 4];
    hyperParameters.winClass = 1; 
    hyperParameters.balcClass = 3; 
    hyperParameters.doorClass = 4;

    hyperParameters.principles.verticalRegionOrder = true;
    hyperParameters.principles.door = true;
    hyperParameters.principles.cooccurence = true;

    hyperParameters.overrideClasses = []; % classes that should not be overlaid

    hyperParameters.t_sym = 0.5;    % symmetry threshold
    hyperParameters.colormap = 'eTrims';

else
    error('Unknown dataset. Edit Run_LabelFold.m and define your own!');
end

    % Facade label distribution
    data = ['detLabelDistributions/labelPrior_' datasetName '_fold_' num2str(fold) '.mat'];   
    loadedData = load(data,'labelPrior');
    hyperParameters.labelPrior = loadedData.labelPrior;
    
    dataLocation = [ workFolder];
    
    ClassifyWithSVM(dataLocation,['classifierModels/' hyperParameters.classifierName '_' datasetName '_fold' num2str(fold) '.mat']);
    

    % Image names
    imageNames = dir([dataLocation '*.jpg']);
    imageNames = {imageNames.name};
    
    % Generate full paths
    origImageNames = strcat(dataLocation,imageNames);
    segFilenames = strrep(origImageNames,'.jpg','.seg');
    classificationFilenames = strrep(origImageNames,'.jpg','.marginal.txt');
    groundTruthFilenames = strrep(origImageNames,'.jpg','.txt');
    
    % Detectors
    loadedData = struct('detector',[],'labelMaps',[],'filenames',[]);
    detectionLocationStem = [dataLocation 'detections_'];
    
    %Statistics from the validation set
    detLabDistrFilenames = strcat(['detLabelDistributions/detLabelDistributions_' datasetName '_'],hyperParameters.detectors);
        
    for i=1:length(hyperParameters.detectors)
        
        detectionLocation = [detectionLocationStem hyperParameters.detectors{i} '/'];
        
        detectionFilenames = strcat(detectionLocation,imageNames);
        detectionFilenames = strrep(detectionFilenames,'.jpg','.txt');
        loadedData(i).filenames=detectionFilenames;

        %HACK
        if strncmp(hyperParameters.detectors{i},'door',4)
            statisticsFilenames = strcat(detLabDistrFilenames,['_fold_' num2str(fold) '_winSize_10.mat']);
        else
            statisticsFilenames = strcat(detLabDistrFilenames,['_fold_' num2str(fold) '_winSize_200.mat']);
        end
    
        labelMaps = load(statisticsFilenames{i},'labelMaps');
        labelMaps=labelMaps.labelMaps;
        loadedData(i).detector=hyperParameters.detectors{i};
        loadedData(i).labelMaps=labelMaps;
    end
    
    % Detection label distribution prior
    hyperParameters.detections = loadedData;

    clear loadedData;


    % Error checking
    if ( length(origImageNames)~=length(groundTruthFilenames) || ...
        length(origImageNames)~=length(segFilenames) || ...
        length(origImageNames)~=length(classificationFilenames))
            error('All filename sets need to have the same length.');
    end
    
    % Initialization
    nImages = length(origImageNames);
    
    cm1 = zeros(hyperParameters.nClasses); corr1 = 0; all1 = 0;
    cm2 = zeros(hyperParameters.nClasses); corr2 = 0; all2 = 0;
    cm3 = zeros(hyperParameters.nClasses); corr3 = 0; all3 = 0;
    

    for i = 1:nImages
        disp(['--Labeling image ' num2str(i) '/' num2str(nImages) '...']);
        % Do the actual labeling and compare the labeling with the ground truth
        results = LabelOneImage(...
            dataLocation,datasetName,origImageNames{i},groundTruthFilenames{i},segFilenames{i},classificationFilenames{i},...
            i,hyperParameters);

        % The results contain the number correctly labeled pixels, total number of
        % pixels, and the confusion matrix per image.
        if ~isempty(results)
            corr1 = corr1 + results.bottom.correct;
            all1 = all1 + results.bottom.total;
            cm1 = cm1 + results.bottom.confusion;
            
            corr2 = corr2 + results.middle.correct;
            all2 = all2 + results.middle.total;
            cm2 = cm2 + results.middle.confusion;
            
            corr3 = corr3 + results.top.correct;
            all3 = all3 + results.top.total;
            cm3 = cm3 + results.top.confusion;
        end

        if mod(i,10)==0
            disp(['--Done with computing image ' num2str(i)]);
        end

    end
    
    % Converting the absolute values in the confusion matrix with percentages
    for i=1:hyperParameters.nClasses
        cm1(i,:) = cm1(i,:)/sum(cm1(i,:));
        cm2(i,:) = cm2(i,:)/sum(cm2(i,:));
        cm3(i,:) = cm3(i,:)/sum(cm3(i,:));
    end
    
    result = struct();
    
    % Accuracy
    result.acc1 = corr1/all1;
    result.acc2 = corr2/all2;
    result.acc3 = corr3/all3;
    
    cm1(isnan(cm1))=0; cm1 = 100*cm1;
    cm2(isnan(cm2))=0; cm2 = 100*cm2;
    cm3(isnan(cm3))=0; cm3 = 100*cm3;
    
    result.cm1 = cm1;
    result.cm2 = cm2;
    result.cm3 = cm3;
    
    dlmwrite([dataLocation 'results_layer1.txt'],result.acc1,'delimiter','\n');
    dlmwrite([dataLocation 'results_layer1.txt'],result.cm1,'-append','delimiter',' ');
    
    dlmwrite([dataLocation 'results_layer2.txt'],result.acc2,'delimiter','\n');
    dlmwrite([dataLocation 'results_layer2.txt'],result.cm2,'-append','delimiter',' ');
    
    dlmwrite([dataLocation 'results_layer3.txt'],result.acc3,'delimiter','\n');
    dlmwrite([dataLocation 'results_layer3.txt'],result.cm3,'-append','delimiter',' ');

end
