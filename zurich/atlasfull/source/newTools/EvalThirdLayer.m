function [acc,confusionMatrix] = EvalThirdLayer(fold,nImages)

    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    

    dataLocation = '/users/visics/mmathias/devel/eccv2012/markus_old_code_journal_2013_';

    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames = ReadFoldImageNames('haussmann',fold,'eval');
    
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    for imageNr=1:nImages
        fprintf('.');
        outputMat = [dataLocation 'fold_' num2str(fold) '_' num2str(imageNr) '.mat' ];
        sgmp=[];
        load(outputMat);
        image=max(sgmp,[],3);
        
        groundTruth = dlmread(groundTruthFilenames{imageNr});
        
        labels = zeros(size(image,1),size(image,2));
        for i=1:size(image,1)
            for j=1:size(image,2)
                if (image(i,j,1)==9)
                    labels(i,j)=1;%Window
                end
                if (image(i,j,1)==2)
                    labels(i,j)=2;%Wall
                end
                if (image(i,j,1)==10)
                    labels(i,j)=3;%Balcony
                end
                if (image(i,j,1)==15)
                    labels(i,j)=4;%Door  
                end
                if (image(i,j,1)==5)
                    labels(i,j)=5;%Roof
                end
                if (image(i,j,1)==12)
                    labels(i,j)=6;%Sky 
                end
                if (image(i,j,1)==11)
                    labels(i,j)=7;%Shop
                end  
            end
        end
        
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