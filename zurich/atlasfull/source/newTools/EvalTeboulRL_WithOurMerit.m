function [acc,confusionMatrix] = EvalTeboulRL_WithOurMerit(fold,nImages)
    addpath /users/visics/amartino/BMM/treeParsing/ % For FastResize
    
    correctPixels = 0;
    totalPixels = 0;
    confusionMatrix = zeros(8,8);
    

    dataLocation = '/usr/data/amartino/Facades/ECPdatabase/cvpr2010/rl_crossvalrf/';
    
    gtLocation = '/usr/data/amartino/gould/testMeanShiftNew/';
    imageNames = ReadFoldImageNames('haussmann',fold,'eval');
    
    stems= strcat(gtLocation,imageNames);
    groundTruthFilenames = strcat(stems,'.txt');
    
    for imageNr=1:nImages
        fprintf('.');
        
        scores = zeros(1,5);
        for i=0:4 
            returnsFilename = [dataLocation 'iter_' num2str(i) '_fold_' num2str(fold) '_img_' num2str(imageNr) '_orig_5_5000_Qlearning_e-dd_returns.txt' ];
            returns = dlmread(returnsFilename);
            scores(i+1) = returns(end);
        end
        [~,pos] = max(scores);
        
        imageName = [dataLocation 'iter_' num2str(pos-1) '_fold_' num2str(fold) '_img_'  num2str(imageNr) '_orig_5_5000_Qlearning_e-dd_best_symbols.png' ];
        image = imread(imageName);
        labels = CreateLabelsFromImage(image);


        groundTruth = dlmread(groundTruthFilenames{imageNr});
         
        % Rescale the image by a factor of 1.5 (damn you teboul)
        labels = double(FastResize(labels,[size(groundTruth,1) size(groundTruth,2)]));
        
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