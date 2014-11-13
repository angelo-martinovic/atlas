% Re-evaluate eTRIMS

function [acc, confusionMatrix] = reEvaluateEtrims(fold)

    addpath tools
    evalListLocation = ['/users/visics/amartino/RNN/data/eTrims/evalList' num2str(fold) '.txt'];
    
    originalLabelsLocation = '/usr/data/amartino/Facades/etrims-db_v1/annotations/08_etrims-ds/';
    ourLabelsLocation = '/usr/data/amartino/RNN/repo/source_eccv/visual/';
    homographiesLocation = '/esat/kochab/mmathias/etrims-db_v1/images/08_etrims-ds/';
    
    fileList = readTextFile(evalListLocation);
    
    confusionMatrix = zeros(8,8);
    
    correctPixels = 0;
    totalPixels = 0; 
    
    for f=1:numel(fileList)
        disp(['Evaluating image ' num2str(f) ' of ' num2str(numel(fileList)) '...']);
        groundTruthFile = [originalLabelsLocation fileList{f} '.txt'];
        homographyFile = [homographiesLocation fileList{f} 'rect.dat'];
        
        ourLabelingFile = [ourLabelsLocation 'eTrims_mrf' num2str(fold) '_' num2str(f) '.txt'];
        
        
        groundTruth = load(groundTruthFile);
        ourLabeling = load(ourLabelingFile);
        homography = load(homographyFile);
        
        
        ourLabeling = rewarp(groundTruth,ourLabeling,homography);
        
        confusionMatrixImg = zeros(8);
        for i=1:size(groundTruth,1)
            for j=1:size(groundTruth,2)
                if (groundTruth(i,j)>0)% && imgData.labels(i,j)~=8)
                   confusionMatrixImg(groundTruth(i,j),ourLabeling(i,j)) = confusionMatrixImg(groundTruth(i,j),ourLabeling(i,j)) + 1;
                end
            end
        end

        correctTestImg = (ourLabeling==groundTruth) & (groundTruth>0);
        
        correctPixels = correctPixels + sum(correctTestImg(:));
        totalPixels = totalPixels + sum(sum(groundTruth>0));
        
        confusionMatrix = confusionMatrix + confusionMatrixImg;
        
    end
    
    for i=1:8
        confusionMatrix(i,:) = confusionMatrix(i,:)/sum(confusionMatrix(i,:));
    end
    %Accuracy
    acc = correctPixels/totalPixels;
    
    disp(acc);
    disp(uint8(100*confusionMatrix));
    
end
    

