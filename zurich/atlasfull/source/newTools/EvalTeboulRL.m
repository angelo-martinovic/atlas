function [acc,confusionMatrix] = EvalTeboulRL(fold,nImages)

    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    

    dataLocation = '/usr/data/amartino/Facades/ECPdatabase/cvpr2010/theirSegmentation/png/';
    rfLocation = '/usr/data/amartino/Facades/ECPdatabase/cvpr2010/rf/png/';
    
    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames = ReadFoldImageNames('haussmann',fold,'eval');
    
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    for imageNr=1:nImages
        fprintf('.');
        
        rfName = [rfLocation imageNames{imageNr}(7:end) '_classification.png'];
        rf = imread(rfName);
        labelsrf = CreateLabelsFromImage(rf);
        
        results = struct('labels',{});
        bestAcc=0;
        bestIndex=0;
        for i=0:4
            imageName = [dataLocation 'iter_' num2str(i) '_' imageNames{imageNr} '_5_5000_Qlearning_e-dd_best_symbols.png' ];
            image = imread(imageName);
            labels = CreateLabelsFromImage(image);
            [corImg, totImg, ~]= EvaluateLabeling('haussmann',labels,labelsrf,8,[0 8]);
            results(i+1).labels = labels;
            if corImg/totImg>bestAcc
                bestAcc=corImg/totImg;
                bestIndex=i+1;
            end
        end
        
        labels = results(bestIndex).labels;
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

function labels = CreateLabelsFromImage(image)
    labels = zeros(size(image,1),size(image,2));
        for i=1:size(image,1)
            for j=1:size(image,2)
                if (image(i,j,1)==255) && (image(i,j,2)==0) && (image(i,j,3)==0)
                    labels(i,j)=1;%Window
                end
                if (image(i,j,1)==255) && (image(i,j,2)==255) && (image(i,j,3)==0)
                    labels(i,j)=2;%Wall
                end
                if (image(i,j,1)==128) && (image(i,j,2)==0) && (image(i,j,3)==255)
                    labels(i,j)=3;%Balcony
                end
                if (image(i,j,1)==255) && (image(i,j,2)==128) && (image(i,j,3)==0)
                    labels(i,j)=4;%Door  
                end
                if (image(i,j,1)==0) && (image(i,j,2)==0) && (image(i,j,3)==255)
                    labels(i,j)=5;%Roof
                end
                if (image(i,j,1)==128) && (image(i,j,2)==255) && (image(i,j,3)==255)
                    labels(i,j)=6;%Sky 
                end
                if (image(i,j,1)==0) && (image(i,j,2)==255) && (image(i,j,3)==0)
                    labels(i,j)=7;%Shop
                end  
                if (image(i,j,1)==128) && (image(i,j,2)==128) && (image(i,j,3)==128)
                    labels(i,j)=8;%Chimney
                end  
                if (image(i,j,1)==0) && (image(i,j,2)==0) && (image(i,j,3)==0)
                    labels(i,j)=0;%Outlier
                end  

            end
        end
end