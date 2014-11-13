% Testing stage
function [allResults allResultString confusionMatrix acc] = labelImagePixels(allData,Wbot,W,Wout,Wcat,params,fold,hyperParams,nImages)
 
allResults=[];
allDataLength = length(allData);
allTrees = cell(1,allDataLength);
%par
%For each image
% tic;
% for i = 1:nImages%length(allData)
%     disp(['Parsing image ' num2str(i) '/' num2str(length(allData)) '...']);
%     if length(allData{i}.segLabels)~=size(allData{i}.feat2,1)
%         disp(['Image ' num2str(i) ' has faulty data, skipping!'])
%         continue
%     end
%     topCorr=0;
%     %Parse the image
%     imgTreeTop = parseImage(topCorr,Wbot,W,Wout,Wcat,allData{i},params);
%     %Saving the result
%     allTrees{i} = imgTreeTop;
%     
%  % imgTreeTop.plotTree();
% 
% end
% toc;

allCorrectPixels = 0;
allPixels = 0;
confusionMatrix = zeros(8);

for i = 1:nImages%length(allData)
    if length(allData{i}.segLabels)~=size(allData{i}.feat2,1)
        disp(['Image ' num2str(i) ' has faulty data, skipping!'])
        continue
    end
  
    disp(['Labeling image ' num2str(i) '/' num2str(allDataLength) '...']);
    %Do the actual labeling and compare the parse tree labeling with the 
    %ground truth
    [correctPixels,totalPixelsImg,confusionMatrixImg] = labelOneImagePixels(allData{i},allTrees{i},i,fold,hyperParams);

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
allResults = [allResults ; acc];
allResultString = sprintf('a:%f',acc);


