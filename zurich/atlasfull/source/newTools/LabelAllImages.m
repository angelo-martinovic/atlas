% For a set of images, runs the 3 layer labeling and evaluates the accuracy.
function [confusionMatrix,acc] = LabelAllImages(dataset,type,fold,imageFilenames,imageNames, ...
    groundTruthFilenames, segFilenames, classificationFilenames, hyperParams)

    % Error checking
    if (length(imageFilenames)~=length(imageNames) || ...
        length(imageFilenames)~=length(groundTruthFilenames) || ...
        length(imageFilenames)~=length(segFilenames) || ...
        length(imageFilenames)~=length(classificationFilenames))
            error('All filename sets need to have the same length.');
    end
    
    % Initialization
    nImages = length(imageFilenames);
    
    confusionMatrix = zeros(8);
    allCorrectPixels = 0;
    allPixels = 0;
    
    for i = 1:nImages
        disp(['Labeling image ' num2str(i) '/' num2str(nImages) '...']);
        %Do the actual labeling and compare the labeling with the ground truth
        [correctPixels,totalPixelsImg,confusionMatrixImg] = LabelOneImage(...
            dataset,type,fold,imageFilenames{i},imageNames{i},groundTruthFilenames{i},segFilenames{i},classificationFilenames{i},...
            i,hyperParams);

        %We get back the number of correctly labeled pixels, total number of
        %pixels, and the confusion matrix.
        allCorrectPixels = allCorrectPixels + correctPixels ;
        allPixels = allPixels + totalPixelsImg;

        confusionMatrix = confusionMatrix + confusionMatrixImg;

        if mod(i,10)==0
            disp(['Done with computing image ' num2str(i)]);
        end

    end
    %Converting the absolute values in the confusion matrix with percentages
    for i=1:8
        confusionMatrix(i,:) = confusionMatrix(i,:)/sum(confusionMatrix(i,:));
    end
    
    %Accuracy
    acc = allCorrectPixels/allPixels;

end

