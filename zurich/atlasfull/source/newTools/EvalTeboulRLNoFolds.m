function [acc,confusionMatrix] = EvalTeboulRLNoFolds(fold,nImages)

    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    

    dataLocation = '/usr/data/amartino/Facades/ECPdatabase/cvpr2010/theirSegmentation/txt/bestRF/';

    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames1 = ReadFoldImageNames('haussmann',fold,'eval');
    imageNames2 = ReadFoldImageNames('haussmann',fold,'valid');
    imageNames3 = ReadFoldImageNames('haussmann',fold,'train');
    imageNames = [imageNames1; imageNames2; imageNames3];
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    for imageNr=1:nImages
        fprintf('.');
       
        labels = dlmread([dataLocation imageNames{imageNr} '.txt']);
        groundTruth = dlmread(groundTruthFilenames{imageNr});
         
        [corImg, totImg, cmImg]= EvaluateLabeling('haussmann',labels,groundTruth,8,[0 8]);
        
        correctPixels = correctPixels + corImg;
        totalPixels = totalPixels + totImg;
        confusionMatrix = confusionMatrix + cmImg;
    end
    
    for i=1:8
        confusionMatrix(i,:) = confusionMatrix(i,:)/sum(confusionMatrix(i,:));
    end
    %Accuracy
    acc = correctPixels/totalPixels;
    
    confusionMatrix = (100*confusionMatrix);
    confusionMatrix(isnan(confusionMatrix))=0;
    
    disp(acc);
    disp(confusionMatrix);

end
