function [correctPixels,totalPixels,confusionMatrixImg] = LabelOneImage( ...
    dataset,type,fold,imageFilename,imageName,groundTruthFilename,segFilename,classificationFilename,...
    imgNumber,hyperParameters)

    cacheLocation=['cache_' dataset '_' type '/'];
    
    % Create the directory if it doesnt exist
    if ~exist(cacheLocation,'dir')
        mkdir(cacheLocation);
    end

    image = imread(imageFilename);
    labels = dlmread(groundTruthFilename);
    
    height = size(image,1);
    width = size(image,2);

    
    %% First layer
    segmentation = dlmread(segFilename);
    % Since segments start from 0
    segmentation = segmentation + 1;   

    % Number of segments in the image
    numSegs = max(segmentation(:));
    
    % In eTrims, groundtruth will not match the size of the segmentation
    % due to the rectification. In all other cases, resize the gt to fit. 
    if ~strcmp(dataset,'eTrims') && ~strcmp(dataset,'monge30Rect')
        if (~isequal(size(segmentation),size(labels)))
            fprintf('x');
            labels = imresize(labels,size(segmentation),'nearest');
            fprintf('o');
        end
    end

    % Superpixel classification
    filename = [cacheLocation 'fold' num2str(fold) '_classification_' imageName '.mat'];
    if (~exist(filename,'file'))
    
        % New SVM testing
        prob_estimates = dlmread(classificationFilename);
        
        if length(prob_estimates)~=numSegs
            error(['Image ' imageName ': segment count mismatch!']);
        end

        % ---- Label probability maps   
        map1 = zeros(height,width);  map2 = zeros(height,width);  
        map3 = zeros(height,width);  map4 = zeros(height,width);  
        map5 = zeros(height,width);  map6 = zeros(height,width);  
        map7 = zeros(height,width);  map8 = zeros(height,width);  

        for s=1:numSegs
            % Eliminating void class
            finalLabelProbs = prob_estimates(s,:);
            finalLabelProbs = finalLabelProbs(2:end);

            map1(segmentation==s) = finalLabelProbs(1);
            map2(segmentation==s) = finalLabelProbs(2);
            map3(segmentation==s) = finalLabelProbs(3);
            map4(segmentation==s) = finalLabelProbs(4);
            map5(segmentation==s) = finalLabelProbs(5);
            map6(segmentation==s) = finalLabelProbs(6);
            map7(segmentation==s) = finalLabelProbs(7);
            map8(segmentation==s) = finalLabelProbs(8);
        end
        segMap = cat(3,map1,map2,map3,map4,map5,map6,map7,map8);

        
        save(filename, 'segMap');
    else
        load(filename);
    end

    % Superpixel output
    [~,oldImg] = max(segMap,[],3);
    
    %% Second layer 
        
    %% Contrast sensitive Potts model
    % Calculate the average contrast in the image, if not precalculated

    if (~exist(['/esat/sadr/amartino/RNN/data/' dataset '/allInMatlab/' imageName '.beta.mat'],'file'))
        % Calculating average image contrast
        dif_h_1=conv2(single(image(:,:,1)),[1 -1],'valid');
        dif_h_2=conv2(single(image(:,:,2)),[1 -1],'valid');
        dif_h_3=conv2(single(image(:,:,3)),[1 -1],'valid');

        dif_v_1=conv2(single(image(:,:,1)),[1;-1],'valid');
        dif_v_2=conv2(single(image(:,:,2)),[1;-1],'valid');
        dif_v_3=conv2(single(image(:,:,3)),[1;-1],'valid');

        dif_h = dif_h_1.^2+dif_h_2.^2+dif_h_3.^2;
        dif_v = dif_v_1.^2+dif_v_2.^2+dif_v_3.^2;

        avgContrast = (sum(sum(dif_h))+sum(sum(dif_v))) / (length(dif_h(:))+length(dif_v(:)));

        beta = 1 / (2*avgContrast);

        clear dif*

        save(['/esat/sadr/amartino/RNN/data/' dataset '/allInMatlab/' imageName '.beta.mat'],'beta');
    else
        load(['/esat/sadr/amartino/RNN/data/' dataset '/allInMatlab/' imageName '.beta.mat']);
    end


    %% Detectors
    % Felsz detector
    % allDetections=importDetections(['/esat/sadr/amartino/RNN/data/haussmannDetectionsFelsz-FOLD' num2str(fold) '_valid.txt']);
    % longImageName = [imageName '.jpg']; % monge_1
    % dets = allDetections(ismember(allDetections.filename,longImageName),:);

    % Our new detector
    detectionData = hyperParameters.detections;
    
    
    if ~isempty(detectionData(1).filenames)
        nDetectors = length(detectionData);
        filename = [cacheLocation 'fold' num2str(fold) '_detections_' imageName '.mat'];
        if (~exist(filename,'file'))

            detectionMaps = struct('detector',[],'detectionMap',[],'detectionMapUnrect',[]);
            for i=1:nDetectors
                detectionFilenames = detectionData(i).filenames;
                if ~isempty(detectionFilenames)
                    detectionFilename = detectionFilenames{imgNumber};
                else
                    detectionFilename = '';
                end
                detectorName = detectionData(i).detector;

                if ~isempty(detectionFilename)
                    s = dir(detectionFilename);
                    disp(detectionFilename);
                    if s.bytes == 0
                        warning(['No ' detectorName ' detections found in this image.']);
                        dets =[];
                    else
                        dets = dlmread(detectionFilename);
                    end;   
                else
                    dets =[];
                end

                labelMaps = detectionData(i).labelMaps;

                detectionMap = 1/8* ones(height,width,8);

                numDetections = size(dets,1);

                for d = 1:numDetections
                    detectionRect = dets(d,1:4);  %Detection bounding box rectangle
                    detectionScore = dets(d,5);   %Score of the detection
                    %Determine the closest distribution
                    [~,pos] =min(abs([labelMaps.score]-detectionScore));

                    startRow = max(round(detectionRect(2)),1);
                    endRow = min(round(detectionRect(4)),height);
                    startColumn = max(round(detectionRect(1)),1);
                    endColumn = min(round(detectionRect(3)),width);

                    if (endRow-startRow<1) || (endColumn-startColumn<1)
                     continue;
                    end

                    detWidth = endRow-startRow+1;
                    detHeight = endColumn-startColumn+1;
                    if strcmp(detectorName,'window-generic')
                        startRow = max(1,round(startRow - detHeight*0.05));
                        endRow = min(height,round(endRow + detHeight*0.05));

                        startColumn = max(1,round(startColumn - detWidth*0.05));
                        endColumn = min(width,round(endColumn + detWidth*0.05));
                    end

                    resizedProbMap = imresize(labelMaps(pos).labelMap,[endRow-startRow+1 endColumn-startColumn+1],'nearest');

                    detectionMap(startRow:endRow,startColumn:endColumn,:) = resizedProbMap;
                end   
                detectionMaps(i).detector = detectorName;
                detectionMaps(i).detectionMap = detectionMap;

            end

            save(filename,'detectionMaps');
        else
            load(filename,'detectionMaps');  
        end
    else
        nDetectors = 0;
        detectionMaps=[];
    end

%              pDet = (detectionScore*7+1)/8;
%              pRest= (1-pDet)/7;
%              detectionLabels = pRest * ones(1,8);
%              detectionLabels(4) = pDet;
%              for l=1:8
%                 detectionMap2(startRow:endRow,startColumn:endColumn,l) = detectionLabels(1,l);
%              end
     
    % Remember original matrices (before possible rectification) 
    origImg = image;
    
    % For eTrims, the resulting labeling has to be 'unrectified'
    if strcmp(dataset,'eTrims') || strcmp(dataset,'monge30Rect')
        homographyFilename = strcat(segFilename(1:end-4),'rect.dat');
        homography = load(homographyFilename);
        
        segMapUnrect = zeros(size(labels,1),size(labels,2),hyperParameters.nClasses);
        for i=1:nDetectors
            detectionMaps(i).detectionMapUnrect = zeros(size(labels,1),size(labels,2),hyperParameters.nClasses);
        end

        for i=1:hyperParameters.nClasses
            segMapUnrect(:,:,i)=rewarp(labels,segMap(:,:,i),homography);
            for j=1:nDetectors
                detectionMaps(j).detectionMapUnrect(:,:,i) = rewarp(labels,detectionMaps(j).detectionMap(:,:,i),homography);
            end
        end
        segMap = segMapUnrect;
        for i=1:nDetectors
            detectionMaps(i).detectionMap = detectionMaps(i).detectionMapUnrect;
        end
        clear segMapUnrect;
        
        height = size(labels,1);
        width = size(labels,2);
        imageUnrect = zeros(height,width,3);
        for i=1:3
            imageUnrect(:,:,i) = rewarp(labels,single(image(:,:,i)),homography,'linear');
        end
        image = uint8(imageUnrect);
        clear imageUnrect;
        
    end
    
    %% Position map - currently not used
    if nDetectors>1
%         data = ['/esat/sadr/amartino/RNN/data/detLabelDistributions_' dataset '_' detectionData(1).detector '_fold' num2str(fold) '_winSize_200.mat'];   
%         loadedData = load(data,'labelPrior');
%         labelPrior = loadedData.labelPrior;
% 
%         positionMap = zeros(height,width,8);
%         for l=1:8
%             positionMap(:,:,l) = imresize(labelPrior(:,:,l),[height width],'nearest');
%         end
%  clear labelPrior;
        data=['/users/visics/amartino/BMM/output/haussmann_eval_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'];
        loadedData = load(data,'probMapAll');
        
        positionMap = loadedData.probMapAll;
       
    else
        data = ['/esat/sadr/amartino/RNN/data/detLabelDistributions_haussmann_window-specific_fold' num2str(fold) '_winSize_200.mat'];   
        loadedData = load(data,'labelPrior');
        labelPrior = loadedData.labelPrior;

        positionMap = zeros(height,width,8);
        for l=1:8
            positionMap(:,:,l) = imresize(labelPrior(:,:,l),[height width],'nearest');
        end
        clear labelPrior;
    end
    
    %% Run CRF
    [outImg,~,~] = runCRF_noPosition(cacheLocation,segMap,detectionMaps,positionMap,imageName,fold,beta,single(image),hyperParameters);
    
    if strcmp(dataset,'eTrims') || strcmp(dataset,'monge30Rect')
        oldImgRect = oldImg;
        oldImg = rewarp(labels,oldImg,homography);

        origImgRect= origImg;

        origImg2(:,:,1) = rewarp(labels,origImgRect(:,:,1),homography);
        origImg2(:,:,2) = rewarp(labels,origImgRect(:,:,2),homography);
        origImg2(:,:,3) = rewarp(labels,origImgRect(:,:,3),homography);
        origImg = origImg2;
    end
    
    if strcmp(dataset,'eTrims')
        selector=2;
    else
        selector=1;
    end
    
    % Save overlayed result image to disk
    writeSegmentationToDisk(oldImg,['visual_journal/' dataset '_' num2str(fold) '_' num2str(imgNumber) '_layer1.png'],origImg,0.5,2,selector);
    writeSegmentationToDisk(outImg,['visual_journal/' dataset '_' num2str(fold) '_' num2str(imgNumber) '_layer2.png'],origImg,0.5,2,selector);
    writeSegmentationToDisk(labels,['visual_journal/' dataset '_' num2str(fold) '_' num2str(imgNumber) '_label.png'],origImg,0.5,2,selector);
    save(['/users/visics/amartino/monge3d/' dataset '_' num2str(fold) '_' num2str(imgNumber) '_labeling.mat'],'outImg');
    
    if strcmp(dataset,'eTrims')  || strcmp(dataset,'monge30Rect')
        oldImg = oldImgRect;
        origImg = origImgRect;
    end
    %% Third layer

    % --- Output of MAT files to Markus

%     if strcmp(dataset,'eTrims')
%         outImgNonRect = outImg;
%         outImg=rewarp(oldImg,outImg,reshape(inv(reshape(homography,3,3)),1,9));
%         labelsNonRect = labels;
%         labels=rewarp(oldImg,labels,reshape(inv(reshape(homography,3,3)),1,9));
%         
%         save(['markus_journal/markus_' dataset '_' type '_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'], ...
%         'sgmp','oldImg','outImg','origImg','detectionMap','detectionMap2','labels');
%     
%         outImg = outImgNonRect;
%         labels = labelsNonRect;
%     else
%         save(['markus_journal/markus_' dataset '_' type '_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'], ...
%         'sgmp','oldImg','outImg','origImg','detectionMap','detectionMap2','labels');
%     end
    


    %% Calculating the result
    
    
    % Show results
    figure(1),subplot(131),imagesc(oldImg),subplot(132),imagesc(outImg),subplot(133),imagesc(labels);
    colormap jet;
    
    [correctPixels, totalPixels, confusionMatrixImg] = EvaluateLabeling(dataset,outImg,labels,hyperParameters.nClasses,hyperParameters.ignoreClasses);

end
