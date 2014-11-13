function [acc,confusionMatrix] = EvalRF(fold,nImages)

    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    

    dataLocation = '/usr/data/amartino/Code/RFlib/output/';

    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames = ReadFoldImageNames('haussmann',fold,'eval');
    
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    for imageNr=1:nImages
        fprintf('.');
        imageName = [dataLocation 'fold_' num2str(fold) '_img_' num2str(imageNr-1) '.png' ];
        image = imread(imageName);
        groundTruth = dlmread(groundTruthFilenames{imageNr});
        
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