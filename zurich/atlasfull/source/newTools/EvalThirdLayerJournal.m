% For haussmann, best dataweight=80, best gridweight=5
function [acc,classAcc,confusionMatrix,TP,FP,FN,precision,recall] = EvalThirdLayerJournal(fold,nImages,overlap,dataweight,gridweight)

    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    
    thingsLabels = [1 3 4];
    totalTP = zeros(1,length(thingsLabels));
    totalFP = zeros(1,length(thingsLabels));
    totalFN = zeros(1,length(thingsLabels));

    dataLocation = '/esat/sadr/amartino/Work/3layerJournal/';
%     dataLocation = '/users/visics/mmathias/devel/3layerJournal/';

    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames = ReadFoldImageNames('haussmann',fold,'eval');
    
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    origImgFilenames = strcat(stems,'.jpg');
    
    for imageNr=1:nImages
        fprintf('.');
        outputMat = [dataLocation 'haussmann_sampling_40_set_eval_fold_' num2str(fold) '_image_' num2str(imageNr) ...
            '_dataweight_' num2str(dataweight) '_gridweight_' num2str(gridweight) '.mat' ];
        
        load(outputMat);
        labels = output;
        
        groundTruth = dlmread(groundTruthFilenames{imageNr});
        
        

        [corImg, totImg, cmImg]= EvaluateLabeling('haussmann',labels,groundTruth,8,[0 8]);
        
        correctPixels = correctPixels + corImg;
        totalPixels = totalPixels + totImg;
        confusionMatrix = confusionMatrix + cmImg;
        
        for i=1:length(thingsLabels)
            class = thingsLabels(i);
            [tp,fp,fn]= EvaluateLabelingPascalVOC(labels,groundTruth,class,overlap);
            totalTP(i) = totalTP(i) + tp;
            totalFP(i) = totalFP(i) + fp;
            totalFN(i) = totalFN(i) + fn;
        end
        
        origImg = imread(origImgFilenames{imageNr});
%         writeSegmentationToDisk(labels,['visual_journal/haussmann_' num2str(fold) '_' num2str(imageNr) '_layer3.png'],origImg,0.5,2,1);
%         writeSegmentationToDisk(labels,['visual_journal/haussmann_' num2str(fold) '_' num2str(imageNr) '_orig.png'],origImg,0,2,1);
    end
    
    for i=1:8
        confusionMatrix(i,:) = confusionMatrix(i,:)/sum(confusionMatrix(i,:));
    end
    %Accuracy
    acc = correctPixels/totalPixels;
    
    confusionMatrix = (100*confusionMatrix);
    confusionMatrix(isnan(confusionMatrix))=0;
    
    % HACK - not using chimneys in the class accuracy computation for ECP
    d = diag(confusionMatrix);
    classAcc = mean(d(1:end-1));
    
    TP = totalTP;
    FP = totalFP;
    FN = totalFN;
    
    precision = TP./(TP+FP);
    recall = TP./(TP+FN);
%     disp(acc);
%     disp(confusionMatrix);
%     disp([TP FP FN]);
end
