function results = LabelOneImage( ...
    dataLocation,datasetName,origImageName,groundTruthFilename,segFilename,classificationFilename,...
    imgNumber,hyperParameters)

    nClasses = hyperParameters.nClasses;
%     cacheLocation=['cache_' datasetName '/'];
%     
%     % Create the directory if it doesnt exist
%     if ~exist(cacheLocation,'dir')
%         mkdir(cacheLocation);
%     end

    image = imread(origImageName);
    
    height = size(image,1);
    width = size(image,2);

    gtExists = true;
    if exist(groundTruthFilename,'file')
        labels = dlmread(groundTruthFilename);
    else
        gtExists = false;
    end
    
    %% Bottom layer
    
    segmentation = dlmread(segFilename);
    
    % Since segments start from 0
    segmentation = segmentation + 1;   

    % Number of segments in the image
    numSegs = max(segmentation(:));
    
    % If rectification was performed, groundtruth will not match the size of the segmentation.
    % If rectification hasn't been performed, and sizes mismatch, resize the gt to fit. 
    if gtExists
        if ~hyperParameters.rectification
            if (~isequal(size(segmentation),size(labels)))
                fprintf('x');
                labels = imresize(labels,size(segmentation),'nearest');
                fprintf('o');
            end
        end
    end

    % Superpixel classification
    prob_estimates = dlmread(classificationFilename);

    if length(prob_estimates)~=numSegs
        error(['Image ' imageName ': segment count mismatch!']);
    end

    segMap = zeros(height,width,nClasses);
    for s=1:numSegs

        % Eliminating void class
        finalLabelProbs = prob_estimates(s,:);
        finalLabelProbs = finalLabelProbs(2:end);

        mask = (segmentation==s);
        segMap(repmat(mask,[1 1 nClasses])) = repmat(finalLabelProbs,[sum(sum(mask)) 1]);
    end


    % Bottom layer output
    [~,oldImg] = max(segMap,[],3);
    
    %% Second layer 
    disp('MIDDLE LAYER');
    % Detectors
    detectionData = hyperParameters.detections;
    
    
    if ~isempty(detectionData(1).filenames)
        nDetectors = length(detectionData);

        detectionMaps = struct('detector',[],'detectionMap',[],'detectionMapUnrect',[]);
        
        % For every detector
        for i=1:nDetectors
            detectionFilenames = detectionData(i).filenames;
            detectorName = detectionData(i).detector;
            labelMaps = detectionData(i).labelMaps;
            
            % Try to load the file with detections
            if ~isempty(detectionFilenames)
                detectionFilename = detectionFilenames{imgNumber};
            else
                detectionFilename = '';
            end
            
            if ~isempty(detectionFilename)
                s = dir(detectionFilename);
%                 disp(detectionFilename);
                if isempty(s)
                    disp(['--The detection file ' detectionFilename ' was not found.']);
                    dets =[];
                elseif s.bytes == 0
                    disp(['--No ' detectorName ' detections found in this image.']);
                    dets =[];
                else
                    dets = dlmread(detectionFilename);
                end;   
            else
                dets =[];
            end

            % Create the detector-based image potential
            detectionMap = 1/nClasses* ones(height,width,nClasses);

            numDetections = size(dets,1);

            % For each detection
            for d = 1:numDetections
                detectionRect = dets(d,1:4);  %Detection bounding box rectangle
                detectionScore = dets(d,5);   %Score of the detection

                % Determine the closest label distribution
                [~,pos] =min(abs([labelMaps.score]-detectionScore));

                % Get the detection position
                startRow = max(round(detectionRect(2)),1);
                endRow = min(round(detectionRect(4)),height);
                startColumn = max(round(detectionRect(1)),1);
                endColumn = min(round(detectionRect(3)),width);

                % Discard zero-sized detections
                if (endRow-startRow<1) || (endColumn-startColumn<1)
                    continue;
                end

                % Generic window detectors are trained to detect a tighter
                % bounding box. This enlarges the bounding box slightly 
                % during testing.
                detWidth = endRow-startRow+1;
                detHeight = endColumn-startColumn+1;
                if strcmp(detectorName,'window-generic')
                    startRow = max(1,round(startRow - detHeight*0.05));
                    endRow = min(height,round(endRow + detHeight*0.05));

                    startColumn = max(1,round(startColumn - detWidth*0.05));
                    endColumn = min(width,round(endColumn + detWidth*0.05));
                end

                % Resize the probability map to the detection
                resizedProbMap = imresize(labelMaps(pos).labelMap,[endRow-startRow+1 endColumn-startColumn+1],'nearest');

                detectionMap(startRow:endRow,startColumn:endColumn,:) = resizedProbMap;
            end   
            detectionMaps(i).detector = detectorName;
            detectionMaps(i).detectionMap = detectionMap;

        end
    else
        nDetectors = 0;
        detectionMaps=[];
    end
    
    %% Position map
    labelPrior = hyperParameters.labelPrior;

    positionMap = zeros(height,width,nClasses);
    for l=1:nClasses
        positionMap(:,:,l) = imresize(labelPrior(:,:,l),[height width],'nearest');
    end
    clear labelPrior;
     
    % Remember original matrices (before possible rectification) 
    origImg = image;
    
    % For rectified images, the resulting labeling has to be 'unrectified'
    % in order to compare it with the original ground truth
    if hyperParameters.rectification && gtExists
        homographyFilename = strcat(segFilename(1:end-4),'rect.dat');
        homography = load(homographyFilename);
        
        segMapUnrect = zeros(size(labels,1),size(labels,2),hyperParameters.nClasses);
        positionMapUnrect = zeros(size(labels,1),size(labels,2),hyperParameters.nClasses);
        for i=1:nDetectors
            detectionMaps(i).detectionMapUnrect = zeros(size(labels,1),size(labels,2),hyperParameters.nClasses);
        end

        for i=1:hyperParameters.nClasses
            sgmpUnrect=rewarp(labels,segMap(:,:,i),homography);
            sgmpUnrect(sgmpUnrect==0)=1/nClasses;
            segMapUnrect(:,:,i) = sgmpUnrect;
            
            psmpUnrect=rewarp(labels,positionMap(:,:,i),homography);
            psmpUnrect(psmpUnrect==0)=1/nClasses;
            positionMapUnrect(:,:,i) = psmpUnrect;
            
            for j=1:nDetectors
                 dmUnrect= rewarp(labels,detectionMaps(j).detectionMap(:,:,i),homography);
                 dmUnrect(dmUnrect==0)=1/nClasses;
                 detectionMaps(j).detectionMapUnrect(:,:,i) = dmUnrect;
            end
            
        end
        segMap = segMapUnrect;
        positionMap = positionMapUnrect;
        for i=1:nDetectors
            detectionMaps(i).detectionMap = detectionMaps(i).detectionMapUnrect;
        end
        clear segMapUnrect;
        clear positionMapUnrect;
        
        height = size(labels,1);
        width = size(labels,2);
        imageUnrect = zeros(height,width,3);
        for i=1:3
            imageUnrect(:,:,i) = rewarp(labels,single(image(:,:,i)),homography,'linear');
        end
        image = uint8(imageUnrect);
        clear imageUnrect;
        
    end
    


    
    %% Run CRF
    [outImg,~,~] = runCRF_noPosition(segMap,detectionMaps,positionMap,hyperParameters);
    
    if hyperParameters.rectification && gtExists
        oldImgRect = oldImg;
        oldImg = rewarp(labels,oldImg,homography);

        origImgRect= origImg;

        origImg2(:,:,1) = rewarp(labels,origImgRect(:,:,1),homography);
        origImg2(:,:,2) = rewarp(labels,origImgRect(:,:,2),homography);
        origImg2(:,:,3) = rewarp(labels,origImgRect(:,:,3),homography);
        origImg = origImg2;
    end
    
    % Colormap
    colorMap = hyperParameters.colormap;

    
    % Save overlayed result image to disk
    
    % Bottom layer
    writeSegmentationToDisk(oldImg,[origImageName(1:end-4) '_output_layer1.png'],origImg,1,colorMap);
    writeSegmentationToDisk(oldImg,[origImageName(1:end-4) '_output_overlay_layer1.png'],origImg,0.5,colorMap);
    dlmwrite([origImageName(1:end-4) '_output_layer1.txt'],uint8(origImg),' ');
    
    % Middle layer
    if (strcmp(datasetName,'eTrims'))
        imwrite(uint8(detectionMaps(1).detectionMap(:,:,8)* 255),[origImageName(1:end-4) '_output_detections_window.png']);
        imwrite(uint8(detectionMaps(2).detectionMap(:,:,3)* 255),[origImageName(1:end-4) '_output_detections_door.png']);
    elseif (strcmp(datasetName,'haussmann'))
        imwrite(uint8(detectionMaps(1).detectionMap(:,:,1)* 255),[origImageName(1:end-4) '_output_detections_window.png']);
        imwrite(uint8(detectionMaps(2).detectionMap(:,:,4)* 255),[origImageName(1:end-4) '_output_detections_door.png']);
    end

    writeSegmentationToDisk(outImg,[origImageName(1:end-4) '_output_layer2.png'],origImg,1,colorMap);
    writeSegmentationToDisk(outImg,[origImageName(1:end-4) '_output_overlay_layer2.png'],origImg,0.5,colorMap);
    dlmwrite([origImageName(1:end-4) '_output_layer2.txt'],uint8(outImg),' ');
   
    
%     if hyperParameters.rectification && gtExists
%         oldImg = oldImgRect;
%         origImg = origImgRect;
%     end
    %% Top layer
     addpath('3layerJournal/');
%     
     disp('TOP LAYER');
% %     save('tmp.mat','datasetName','hyperParameters','origImg','segMap','outImg');
     thirdLayerOutput = elementSampling(origImg,segMap,outImg,hyperParameters);
 
     writeSegmentationToDisk(thirdLayerOutput,[origImageName(1:end-4) '_output_layer3.png'],origImg,1,colorMap);
     writeSegmentationToDisk(thirdLayerOutput,[origImageName(1:end-4) '_output_overlay_layer3.png'],origImg,0.5,colorMap);
     dlmwrite([origImageName(1:end-4) '_output_layer3.txt'],uint8(thirdLayerOutput),' ');

%    thirdLayerOutput=outImg;
    %% Calculating the result
    
    
    % Show results
%     figure(1),subplot(131),imagesc(oldImg),subplot(132),imagesc(outImg),subplot(133),imagesc(labels);
%     colormap jet;
    if gtExists
        results = struct();

        [results.bottom.correct, results.bottom.total, results.bottom.confusion] = EvaluateLabeling(dataset,oldImg,labels,hyperParameters.nClasses,hyperParameters.ignoreClasses);
        [results.middle.correct, results.middle.total, results.middle.confusion] = EvaluateLabeling(dataset,outImg,labels,hyperParameters.nClasses,hyperParameters.ignoreClasses);
        [results.top.correct, results.top.total, results.top.confusion] = EvaluateLabeling(dataset,thirdLayerOutput,labels,hyperParameters.nClasses,hyperParameters.ignoreClasses);
    
    
    else
        results = [];

    end
end
