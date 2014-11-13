function [correctPixels totalPixels confusionMatrixImg] = labelOneImagePixels(imgData,imgTreeTop,imgNumber,fold,hyperParams)

if strcmp(hyperParams.type,'eval')
    cacheLocation='cache/';
else
    cacheLocation='cache_v/';
end
%figure;imgTreeTop.plotTree();
%figure;

% numTotalNodes = size(imgTreeTop.kids,1);

height = size(imgData.img,1);
width = size(imgData.img,2);
outImg = zeros(height,width);

% numLeafsUnder = ones(numLeafNodes,1);
% leafsUnder = cell(numLeafNodes,1);

imageNames = hyperParams.imgNames;
labelMaps = hyperParams.labelMaps;
labelPrior = hyperParams.labelPrior;

segFilename = ['/esat/sadr/amartino/gould/testMeanShiftNew/' imageNames{imgNumber} '.seg'];
segmentation = dlmread(segFilename);
% Since segments start from 0
segmentation = segmentation + 1;   

% Number of segments in the image
numSegs = max(segmentation(:));
 
positionMap = zeros(height,width,8);
for l=1:8
    positionMap(:,:,l) = imresize(labelPrior(:,:,l),[height width],'nearest');
end
clear labelPrior;
% -- CONTRAST SENSITIVE POTTS MODEL

if (~exist(['/esat/sadr/amartino/RNN/data/haussmannMeanShiftNew/allInMatlab/' imageNames{imgNumber} '.beta.mat'],'file'))
    % Calculating average image contrast
    dif_h_1=conv2(single(imgData.img(:,:,1)),[1 -1],'valid');
    dif_h_2=conv2(single(imgData.img(:,:,2)),[1 -1],'valid');
    dif_h_3=conv2(single(imgData.img(:,:,3)),[1 -1],'valid');

    dif_v_1=conv2(single(imgData.img(:,:,1)),[1;-1],'valid');
    dif_v_2=conv2(single(imgData.img(:,:,2)),[1;-1],'valid');
    dif_v_3=conv2(single(imgData.img(:,:,3)),[1;-1],'valid');

    dif_h = dif_h_1.^2+dif_h_2.^2+dif_h_3.^2;
    dif_v = dif_v_1.^2+dif_v_2.^2+dif_v_3.^2;

    avgContrast = (sum(sum(dif_h))+sum(sum(dif_v))) / (length(dif_h(:))+length(dif_v(:)));

    beta = 1 / (2*avgContrast);
    
    clear dif*

    save(['/esat/sadr/amartino/RNN/data/haussmannMeanShiftNew/allInMatlab/' imageNames{imgNumber} '.beta.mat'],'beta');
else
    load(['/esat/sadr/amartino/RNN/data/haussmannMeanShiftNew/allInMatlab/' imageNames{imgNumber} '.beta.mat']);
end



% % --- Visualize the statistics
% figure;
% hold on; plot(detectionLabels(:,9),detectionLabels(:,1),'Color','red')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,2),'Color','green')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,3),'Color','blue')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,4),'Color','black')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,5),'Color','yellow')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,6),'Color','cyan')
% hold on; plot(detectionLabels(:,9),detectionLabels(:,7),'Color','magenta')
% % hold on; plot(detectionLabels(:,9),detectionLabels(:,8),'Color','white')
% set(gca,'XDir','reverse');
% axis square;
% grid on;


% detectionLabels2=load(data,'detectionLabelsValid2');
% detectionLabels2 = detectionLabels2.detectionLabelsValid2;


% Felsz detector
% allDetections=importDetections(['/esat/sadr/amartino/RNN/data/haussmannDetectionsFelsz-FOLD' num2str(fold) '_valid.txt']);
% longImageName = [imageNames{imgNumber} '.jpg']; % monge_1
% dets = allDetections(ismember(allDetections.filename,longImageName),:);

% Our new detector
if strcmp(hyperParams.type,'eval')
    detectionLocation = ['/esat/sadr/amartino/RNN/data/detections_haussmann/specific/detections_fold' num2str(fold) '/'];
else
    detectionLocation = ['/esat/sadr/amartino/RNN/data/detections_haussmann/specific/detections_fold' num2str(fold) '_valid/'];
end
detectionFilename = strcat(detectionLocation, imageNames{imgNumber});
detectionFilename = strcat(detectionFilename,'.txt');
dets = dlmread(detectionFilename);

% % ---- Window detections

if (~exist([cacheLocation 'det_fold' num2str(fold) 'img' num2str(imgNumber) '.mat'],'file'))
    detectionMap = 1/8* ones(height,width,8);
    % 
    % Old detectors
%     numDetections = size(imgData.detections,1);

    % New detectors
    numDetections = size(dets,1);

    for d = 1:numDetections

        % Old detectors
%          detectionRect = imgData.detections(d,1:4);  %Detection bounding box rectangle
%          detectionScore = imgData.detections(d,5);   %Score of the detection
        % Felsz detectors
            %Division by 2, as the images were scaled by a factor of 2
%            detectionRect = [dets.topLeftX(d)/2 dets.topLeftY(d)/2 dets.botRightX(d)/2 dets.botRightY(d)/2];
%            detectionScore = dets.score(d);
        % Our new detectors
             detectionRect = dets(d,1:4);  %Detection bounding box rectangle
             detectionScore = dets(d,5);   %Score of the detection
    %      if (detectionScore>0.05)
             %Determine the closest distribution
    %          [~,pos] =min(abs(detectionLabels(:,9)-detectionScore));
             [~,pos] =min(abs([labelMaps.score]-detectionScore));

             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end

             resizedProbMap = imresize(labelMaps(pos).labelMap,[endRow-startRow+1 endColumn-startColumn+1],'nearest');

             detectionMap(startRow:endRow,startColumn:endColumn,:) = resizedProbMap;

    %          for l=1:8
    %             detectionMap(startRow:endRow,startColumn:endColumn,l) = detectionLabels(pos,l);
    %          end
    %      end
    end

    % hfig=figure(111);colormap('hot');
    % for l=1:1
    %     subplot(1,1,l);imagesc(detectionMap(:,:,l));
    % end

    % ---- Door detections
    detectionMap2 = zeros(height,width,8);
     for l=1:8
         detectionMap2(:,:,l) = 1/8 * ones(height,width);%nonDetectionLabels (l);
    end
    numDetections = size(imgData.detectionsTest2,1);
    for d = 1:numDetections
         detectionRect = imgData.detectionsTest2(d,1:4);  %Detection bounding box rectangle
         detectionScore = imgData.detectionsTest2(d,5);   %Score of the detection
         if (detectionScore>0.0)

             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end

             pDet = (detectionScore*7+1)/8;
             pRest= (1-pDet)/7;
             detectionLabels = pRest * ones(1,8);
             detectionLabels(4) = pDet;
             for l=1:8
                detectionMap2(startRow:endRow,startColumn:endColumn,l) = detectionLabels(1,l);
             end
        end
    end
    
    save([cacheLocation 'det_fold' num2str(fold) 'img' num2str(imgNumber) '.mat'],'detectionMap','detectionMap2');
else
    load([cacheLocation 'det_fold' num2str(fold) 'img' num2str(imgNumber) '.mat'],'detectionMap','detectionMap2');  
end
    
    
% % ---- Region CRF
% regionSizes = zeros(numLeafNodes,1);
% for s = 1:numLeafNodes
%     regionSizes(s) = sum(sum(imgData.segs2==s));
% end
% newLabels = runRegionCRF(imgData.adj, imgTreeTop.catOut(1:8,1:numLeafNodes), regionSizes, imgData.segs2, imgData.feat2, hyperParams,svm);

 
% ---- RNN-only segment labeling, first and second best label
% regionLabels1 = zeros(439,1);
% regionLabels2 = zeros(439,1);
% differences = zeros(439,1);

% bestPossible = zeros(size(imgData.segs2,1),size(imgData.segs2,2));
% for i=1:size(imgData.segLabels,1)
%     bestPossible(imgData.segs2==i) = imgData.segLabels(i);%regionLabels1(i);
% end
% figure;imagesc(bestPossible);

if (~exist([cacheLocation 'fold' num2str(fold) 'img' num2str(imgNumber) '.mat'],'file'))
    % Neural network testing
    % neuralNetFilename = ['../../data/NN_75-FOLD' num2str(fold) '.mat']; 
    % net2 = load(neuralNetFilename,'net');
    % net = net2.net;
    % 
    % predictions = net(imgTreeTop.leafFeatures');

    % SVM testing
    % modelFilename = ['../../data/SVM_rbf_haussmann_dummy_FOLD' num2str(fold) '.mat']; 
    % model2 = load(modelFilename,'model');
    % model = model2.model;
    % [~,order] = sort(model.Label);
    % 
    % inst = imgTreeTop.leafFeatures;
    % labels = ones(size(inst,1),1);
    % tic;
    % [predict_label, accuracy, prob_estimates] = svmpredict(labels,inst, model,'-b 1');
    % toc;

    % Gould testing

    % outputFilename = ['/esat/sadr/amartino/gould/test/output/crf_fold' num2str(fold) '/' imageNames{imgNumber} '.marginal.txt']; 
    % prob_estimates = dlmread(outputFilename);


    % New SVM testing

    outputFilename = ['/esat/sadr/amartino/gould/testMeanShiftNew/output/SVM_cv_fold' num2str(fold) '/' imageNames{imgNumber} '.marginal.txt']; 
    prob_estimates = dlmread(outputFilename);



    % % MKLR testing
    % modelFilename = ['../../data/MKLR_haussmann_FOLD' num2str(fold) '.mat']; 
    % 
    % load(modelFilename,'alpha','b','pars');
    % alfa=alpha;
    % 
    % 
    % Xtest = imgTreeTop.leafFeatures;
    % ytest = ones(size(Xtest,1),1);
    % 
    % [lhte,errv,predict_label,pt] = FSMKLRpredict(alfa,b,Xtest,ytest,pars);


    % ---- Label probability maps   
    map1 = zeros(height,width);  
    map2 = zeros(height,width);  
    map3 = zeros(height,width);  
    map4 = zeros(height,width);  
    map5 = zeros(height,width);  
    map6 = zeros(height,width);  
    map7 = zeros(height,width);  
    map8 = zeros(height,width);  

    for s=1:numSegs
        % %NN
        % finalLabelProbs = predictions(:,s);

        % SVM
    %     finalLabelProbs = zeros(1,8);
    %     finalLabelProbs(predict_label(s))=1;

        % SVM with output probabilities
    %     finalLabelProbs = prob_estimates(s,:);
    %     finalLabelProbs = finalLabelProbs(order);

        % Gould, eliminating class 0
        finalLabelProbs = prob_estimates(s,:);
        finalLabelProbs = finalLabelProbs(2:end);

        % RNN
    %     finalLabelProbs = imgTreeTop.catOut(:,s);

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
    
    save([cacheLocation 'fold' num2str(fold) 'img' num2str(imgNumber) '.mat'],'segMap');
else
    load([cacheLocation 'fold' num2str(fold) 'img' num2str(imgNumber) '.mat']);
end

% for s = 1:numLeafNodes
% %     
% %     currentNode = s;
% %     finalLabelProbs = zeros(8,1);
% %     weight = 1;
% %     while(1)
% %         if currentNode==0
% %             break;
% %         end
% %         
% %         finalLabelProbs = finalLabelProbs + (imgTreeTop.catOut(:,currentNode)/weight);
% %         
% %         weight = weight+1;
% %         currentNode = imgTreeTop.getParent(currentNode);
% % 
% %     end
% 
%     finalLabelProbsChild = imgTreeTop.catOut(:,s);
%     [sNode,lNode] = max(finalLabelProbsChild);
%     
%     parent = imgTreeTop.pp(s);    
%     finalLabelProbsParent = imgTreeTop.catOut(:,parent);
%     [sParent,lParent] = max(finalLabelProbsParent);
%     
% %     
% %     correctLabel = imgData.segLabels(s);
% %     
%     if sParent>sNode
%         finalLabelProbs = finalLabelProbsParent;
%     else
%         finalLabelProbs = finalLabelProbsChild;
%     end
% %         
%     
% %     currentNode = s;
% %     while(1)
% %         finalLabelProbs = imgTreeTop.catOut(:,currentNode);
% %         [~,pos] = max(finalLabelProbs);
% %         if pos==imgData.segLabels(s)
% %             bestPossible(imgData.segs2==s) = pos;
% %             break;
% %         end
% %         currentNode = imgTreeTop.getParent(currentNode);
% %         if currentNode==0
% %             bestPossible(imgData.segs2==s) = origPos;
% %             break;
% %         end
% %     end
%    
%     map1(imgData.segs2==s) = finalLabelProbs(1);
%     map2(imgData.segs2==s) = finalLabelProbs(2);
%     map3(imgData.segs2==s) = finalLabelProbs(3);
%     map4(imgData.segs2==s) = finalLabelProbs(4);
%     map5(imgData.segs2==s) = finalLabelProbs(5);
%     map6(imgData.segs2==s) = finalLabelProbs(6);
%     map7(imgData.segs2==s) = finalLabelProbs(7);
%     map8(imgData.segs2==s) = finalLabelProbs(8);
%    
% end

[~,oldImg] = max(segMap,[],3);
% outImg = oldImg;
% figure;imagesc(oldImg);
% oldImg = newMap;
% figure;imagesc(oldImg);


% ---- Output after RNN
% figure; imagesc(oldImg);
% waitforbuttonpress


% outImg = bestPossible;
[outImg,~,~] = runCRF_noPosition(segMap,positionMap,detectionMap,detectionMap2,imgNumber,fold,beta,single(imgData.img),hyperParams);
figure(1),subplot(131),imagesc(oldImg),subplot(132),imagesc(outImg),subplot(133),imagesc(imgData.labels);
% figure;imagesc(outImg);

% outImg = ones(height,width);
% writeSegmentationToDisk(detectionMap(:,:,8),['visual/win_' num2str(imgNumber) '.png'],imgData.img,0.5,1,1);
% writeSegmentationToDisk(detectionMap2(:,:,3),['visual/door_' num2str(imgNumber) '.png'],imgData.img,0.5,1,2);

% oldImg(imgData.labels==0)=0;
% outImg(imgData.labels==0)=0;
% writeSegmentationToDisk(oldImg,['visual/haussmann_rnn_' num2str(fold) '_' num2str(imgNumber) '.png'],imgData.img,0.5,2,1);
% writeSegmentationToDisk(outImg,['visual/haussmann_mrf_' num2str(fold) '_' num2str(imgNumber) '.png'],imgData.img,0.5,2,1);


% - LOADING THE RESULTS AFTER THE THIRD LAYER
% load(['/users/visics/mmathias/devel/tmp/markus_eTrims_out3_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat']);
% load(['/users/visics/mmathias/devel/tmp/markus_new_test_foldttt_' num2str(fold) '_' num2str(imgNumber) '.mat']);
% 
% segMap = sgmp;
% 
% windows = segMap(:,:,1);
% % label = max(max(windows));
% mask = windows>0;
% for i=1:1
%     mask(:,:,1) =  imdilate(mask(:,:,1), [1 1 1; 1 0 1; 1 1 1]);
% end
% % 
% windows = zeros(height,width);
% windows(mask)=label;
% segMap(:,:,1)=windows;

% --- LOADING THE RESULTS BEFORE THE THIRD LAYER
% load(['markus/markus_ECP_test_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat']); 

% load(['markus/markus_ECP_test_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat']);
% % % % load(['/usr/data/amartino/Work/eccv2012/repo/source/markus_output/ECP_fold_' num2str(fold) '_' num2str(imgNumber) '.mat']);
% % % % segMap = sgmp;
% % % % windows = segMap(:,:,1);
% % % % label = max(max(windows));
% % % % mask = windows>0;
% % % % for i=1:1
% % % %     mask(:,:,1) =  imdilate(mask(:,:,1), [1 1 1; 1 0 1; 1 1 1]);
% % % % end

% % % % windows = zeros(height,width);
% % % % windows(mask)=label;
% % % % segMap(:,:,1)=windows;

% figure;imagesc(outImg);
% oldImg(imgData.labels==0)=0;
% % % % [~,outImg] = max(segMap,[],3);
% % % % writeSegmentationToDisk(outImg,['visual/ecpFinal/img_' num2str(fold) '_' num2str(imgNumber) '.png'],origImg,1.0,2,1);
% sizes = size(labels);
% dlmwrite(['visual/rnnProbs/fold_' num2str(fold) '_' num2str(imgNumber) '_label_size.txt'],sizes,' ');
% for i=1:8
%      dlmwrite(['visual/rnnProbs/fold_' num2str(fold) '_' num2str(imgNumber) '_label_' num2str(i) '.txt'],sgmp(:,:,i),' ');
% end


% --- Output of MAT files to Markus
sgmp = segMap;
origImg = imgData.img;
labels = imgData.labels;
% save(['journal/ECP_gould_layer2_valid_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'],'sgmp','oldImg','outImg','origImg','labels');

% save(['markus/markus_ECP_valid_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'], ...
%     'sgmp','oldImg','outImg','origImg','detectionMap','detectionMap2','labels');

% load(['markus/markus_ECP_fold_' num2str(fold) '_img_' num2str(imgNumber) '.mat'], ...
%      'sgmp','oldImg','outImg','origImg','detectionMap','detectionMap2','labels');
% outImg = mapFinal;
%  outImg = oldImg;


%-----ESTIMATING THE MAXIMUM POSSIBLE SCORE------
% numCorrect = 0;
% numIncorrect = 0;
% newImg = zeros(size(imgData.segs2,1),size(imgData.segs2,2));
% for i=1:size(imgData.segLabels,1)
%     segSize = sum(sum(imgData.segs2==i));
%     if (imgData.segLabels(i)==0 || imgData.segLabels(i)==8)
%         continue;
%     end
%     if (imgData.segLabels(i)~=regionLabels1(i) && imgData.segLabels(i)~=regionLabels2(i))
%         %numIncorrect = numIncorrect + segSize;
%         newImg(imgData.segs2==i)=0;
%     else
%         if(imgData.segLabels(i)~=regionLabels1(i) && imgData.segLabels(i)==regionLabels2(i))
%             newImg(imgData.segs2==i)=1-differences(i);
%             regionLabels1(i) = regionLabels2(i);
%         else
%             newImg(imgData.segs2==i)=1;
%         end
%         %numCorrect = numCorrect + segSize;
%         
%     end
% end

% figure;imagesc(imgData.labels);
% waitforbuttonpress
% 
% outImg = newMap;
%-----ESTIMATING THE MAXIMUM POSSIBLE SCORE------

%correspondence = outImg==imgData.labels;
%figure;imagesc(correspondence);
% Calculating the confusion matrix
[correctPixels, totalPixels, confusionMatrixImg] = EvaluateLabeling('haussmannFinal',outImg,labels,8,[0 8]);
% confusionMatrixImg = zeros(8);
% for i=1:size(sgmp,1)
%     for j=1:size(sgmp,2)
%         if (labels(i,j)>0 && labels(i,j)~=8  && ...
%             outImg(i,j)>0 && outImg(i,j)~=8 )
%            confusionMatrixImg(labels(i,j),outImg(i,j)) = confusionMatrixImg(labels(i,j),outImg(i,j)) + 1;
%         end
%     end
% end

% correctPixels = numCorrect;
% totalPixels = numCorrect + numIncorrect;
%figure;imagesc(newImg);
% 
% correctTestImg = (outImg==labels & labels>0 & labels~=8);
% correctPixels = sum(correctTestImg(:));
% ignore 0 = void labels in total count (like Gould et al.)
% (we never predict 0 either)
% totalPixels = sum(sum(labels>0 & labels~=8));



