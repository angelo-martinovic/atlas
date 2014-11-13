% This function should prepare the training and evaluation data and save
% them in two bigass .mat files (you call it twice)
function preProSegFeatsAndSave(dataFolder,neighNameStem,trainList, neighName, dataSet, params,mainDataSet)

% Check if allData exists in the workspace
if ~exist('allData','var')
    % If it doesn't, preallocate space
    allData = cell(1,length(trainList));
    % Load all prepared mat files
    for i = 1:length(trainList)
        allData{i} = load([dataFolder trainList{i} '.mat']);
    end
end


disp('Importing detections');
detections = cell(4,1);
 
%%%%%%%%%%%%%%%%%%%
% 'whiten' inputs (each feature separately) to mean 0
% If we are dealing with the training set
if strcmp(dataSet,'train') || strcmp(dataSet,'valid')
    allFeats = [];
    % Read all features from all segments from all images
   
    for i = 1:length(allData)
        allFeats = [allFeats ; allData{i}.feat2];
        %%%%%%%%%%%%%%%%%%%%%%%%%
        numDetections = size(allData{i}.detections,1);
        if (numDetections>0)
            detections{1} = [detections{1};[allData{i}.detections repmat(i,numDetections,1)]];  
        end
        
%      
%         %%%%%%%%%%%%%%%%%%%%%%%%%
%         numDetections2 = size(allData{i}.detections2,1);
%         if (numDetections2>0)
%             detections{2} = [detections{2};[allData{i}.detections2 repmat(i,numDetections2,1)]];  
%         end
%         
%         %%%%%%%%%%%%%%%%%%%%%%%%%
%         numDetectionsValid = size(allData{i}.detectionsValid,1);
%         if (numDetectionsValid>0)
%             detections{3} = [detections{3};[allData{i}.detectionsValid repmat(i,numDetectionsValid,1)]];  
%         end
%         
%         %%%%%%%%%%%%%%%%%%%%%%%%%
%         numDetectionsValid2 = size(allData{i}.detectionsValid2,1);
%         if (numDetectionsValid2>0)
%             detections{4} = [detections{4};[allData{i}.detectionsValid2 repmat(i,numDetectionsValid2,1)]];  
%         end
%          %%%%%%%%%%%%%%%%%%%%%%%%%    
%         
    end
    % Calculate means and std deviations for all feature vectors'
    % components
    meanAll = mean(allFeats);
    stdAll  = std(allFeats); 

else
    %If this is the eval set, just load the training set information.
    neighNameTrain = [neighNameStem '_train.mat'];
    load(neighNameTrain ,'meanAll','stdAll');
end
numDetections = size(detections{1},1);
numDetections2 = 0;%size(detections{2},1);
detectionLabels = []; 
detectionLabels2 = [];
if strcmp(dataSet,'train')
    if (numDetections>0)
        detectionLabels = zeros(numDetections,8);   %Histogram: P(C|detection)
      
        %Sort by detection score
        normDetections = flipud(sortrows(detections{1},5));

        %Masks for each image
        detectionMap = cell(1,length(allData));
        for d=1:numDetections 
            i = normDetections(d,6);    %Index of the image where the detection lies
            height = size(allData{i}.labels,1);
            width = size(allData{i}.labels,2);
            if (size(detectionMap{i},1)==0)
                detectionMap{i} = zeros(height,width);
            end
           
             detectionRect = normDetections(d,1:4);  %Detection bounding box rectangle
             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end
             detectionMap{i}(startRow:endRow,startColumn:endColumn) = 1; %Mask out the selected area on the image
             
             for l=1:8
                detectionLabels(d,l) = detectionLabels(d,l) + sum(sum(allData{i}.labels(startRow:endRow,startColumn:endColumn)==l));
             end
        end
       
        %Get the cumulative scores
        if numDetections>1
            for d=2:numDetections
                detectionLabels(d,:) = sum(detectionLabels(d-1:d,:),1);
            end
        end
        for d=1:numDetections
            detectionLabels(d,:) = detectionLabels(d,:) / sum(detectionLabels(d,:));
            detectionLabels(d,9) = normDetections(d,5); %Detection score
        end
      
    end

    if (numDetections2>0)
          detectionLabels2 = zeros(numDetections2,8);   %Histogram: P(C|detection)
        %Sort by detection score
        normDetections2 = flipud(sortrows(detections{2},5));

        %Masks for each image
        detectionMap2 = cell(1,length(allData));
        for d=1:numDetections2
            i = normDetections2(d,6);    %Index of the image where the detection lies
            height = size(allData{i}.labels,1);
            width = size(allData{i}.labels,2);
            if (size(detectionMap2{i},1)==0)
                detectionMap2{i} = zeros(height,width);
            end
           
             detectionRect = normDetections2(d,1:4);  %Detection bounding box rectangle
             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end
             detectionMap2{i}(startRow:endRow,startColumn:endColumn) = 1; %Mask out the selected area on the image
             
             for l=1:8
                detectionLabels2(d,l) = detectionLabels2(d,l) + sum(sum(allData{i}.labels(startRow:endRow,startColumn:endColumn)==l));
             end
        end
       
        %Get the cumulative scores
        if numDetections2>1
            for d=2:numDetections2
                detectionLabels2(d,:) = sum(detectionLabels2(d-1:d,:),1);
            end
        end
        for d=1:numDetections2
            detectionLabels2(d,:) = detectionLabels2(d,:) / sum(detectionLabels2(d,:));
            detectionLabels2(d,9) = normDetections2(d,5); %Detection score
        end
        
     end
end

numDetectionsValid = 0;%size(detections{3},1);
numDetectionsValid2 = 0;%size(detections{4},1);
detectionLabelsValid = [];
detectionLabelsValid2 = [];
if strcmp(dataSet,'valid')
    if (numDetectionsValid>0)
        detectionLabelsValid = zeros(numDetectionsValid,8);   %Histogram: P(C|detection), when using folds
        
        %Sort by detection score
        normDetections = flipud(sortrows(detections{3},5));

        %Masks for each image
        detectionMap = cell(1,length(allData));
        for d=1:numDetectionsValid 
            i = normDetections(d,6);    %Index of the image where the detection lies
            height = size(allData{i}.labels,1);
            width = size(allData{i}.labels,2);
            if (size(detectionMap{i},1)==0)
                detectionMap{i} = zeros(height,width);
            end
           
             detectionRect = normDetections(d,1:4);  %Detection bounding box rectangle
             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end
             detectionMap{i}(startRow:endRow,startColumn:endColumn) = 1; %Mask out the selected area on the image
             
             for l=1:8
                detectionLabelsValid(d,l) = detectionLabelsValid(d,l) + sum(sum(allData{i}.labels(startRow:endRow,startColumn:endColumn)==l));
             end
        end
       
        %Get the cumulative scores
        if numDetectionsValid>1
            for d=2:numDetectionsValid
                detectionLabelsValid(d,:) = sum(detectionLabelsValid(d-1:d,:),1);
            end
        end
        for d=1:numDetectionsValid
            detectionLabelsValid(d,:) = detectionLabelsValid(d,:) / sum(detectionLabelsValid(d,:));
            detectionLabelsValid(d,9) = normDetections(d,5); %Detection score
        end
      
    end

    if (numDetectionsValid2>0)
        detectionLabelsValid2 = zeros(numDetectionsValid2,8);   %Histogram: P(C|detection), when using folds
        %Sort by detection score
        normDetections2 = flipud(sortrows(detections{4},5));

        %Masks for each image
        detectionMap2 = cell(1,length(allData));
        for d=1:numDetectionsValid2
            i = normDetections2(d,6);    %Index of the image where the detection lies
            height = size(allData{i}.labels,1);
            width = size(allData{i}.labels,2);
            if (size(detectionMap2{i},1)==0)
                detectionMap2{i} = zeros(height,width);
            end
           
             detectionRect = normDetections2(d,1:4);  %Detection bounding box rectangle
             startRow = max(round(detectionRect(2)),1);
             endRow = min(round(detectionRect(4)),height);
             startColumn = max(round(detectionRect(1)),1);
             endColumn = min(round(detectionRect(3)),width);
             

             if (endRow-startRow<1) || (endColumn-startColumn<1)
                 continue;
             end
             detectionMap2{i}(startRow:endRow,startColumn:endColumn) = 1; %Mask out the selected area on the image
             
             for l=1:8
                detectionLabelsValid2(d,l) = detectionLabelsValid2(d,l) + sum(sum(allData{i}.labels(startRow:endRow,startColumn:endColumn)==l));
             end
        end
       
        %Get the cumulative scores
        if numDetectionsValid2>1
            for d=2:numDetectionsValid2
                detectionLabelsValid2(d,:) = sum(detectionLabelsValid2(d-1:d,:),1);
            end
        end
        for d=1:numDetectionsValid2
            detectionLabelsValid2(d,:) = detectionLabelsValid2(d,:) / sum(detectionLabelsValid2(d,:));
            detectionLabelsValid2(d,9) = normDetections2(d,5); %Detection score
        end
        
     end    
    

end

%%%%%%%%%%%%%%%%%%%
disp('Normalizing features');
% normalize features
for i = 1:length(allData)
    featsNow = allData{i}.feat2;
    % Subtract the mean
    featsNow = bsxfun(@minus, featsNow, meanAll);
    % Truncate to +/-3 standard deviations and scale to -1 to 1
    pstd = 3 * stdAll;
    featsNow = bsxfun(@max,bsxfun(@min,featsNow,pstd),-pstd);
    featsNow = bsxfun(@times,featsNow,1./pstd);
    %For some reason, if we are using a sigmoid activation function (and we
    %are), we should rescale the features.
   % if strcmp(params.actFunc,'sigmoid')
        % Rescale from [-1,1] to [0.1,0.9]
        featsNow = (featsNow + 1) * 0.4 + 0.1;
    %end
    allData{i}.feat2 = featsNow;

end

numCorrectPixels = zeros(1,8);
numIncorrectPixels = zeros(1,8);
%%%%%%%%%%%%%%%%%%%
disp('Assigning segment labels');
% assign each segment a label (by pixel majority vote from the annotated regions in labels)
for i = 1:length(allData)
    labelRegs = allData{i}.labels;
    %allData{i}.segs2 = allData{i}.segs2 + 1;% If your segments start with index 0, uncomment this line
    segs = allData{i}.segs2 ; 
    numSegs = max(segs(:));
    segLabels = zeros(numSegs,1);
    
    %We should also get the information about the bounding boxes of the segments
    segBoundingBoxes = zeros(4,numSegs);
    
    for r = 1:numSegs
        res2 = labelRegs(segs==r);  % For each segment, get all pixel labels and use the one which is the most common.
        segLabels(r) = mode(res2);
        if (mode(res2)~=0)
            numCorrectPixels(mode(res2)) = numCorrectPixels(mode(res2)) + sum(res2==mode(res2));
            for s=1:8
                if s~=mode(res2)
                    numIncorrectPixels(s) = numIncorrectPixels(s) + sum(res2==s);
                end
            end
        end
        
        [row,col,~] = find(segs==r);
        segBoundingBoxes(:,r)=[min(row); min(col); max(row); max(col)]; %Bounding box of the segment
    end
    allData{i}.segLabels = segLabels;
    allData{i}.segBoundingBoxes = segBoundingBoxes;

end
if strcmp(dataSet,'eval')
    disp('Num correct');
    disp(numCorrectPixels);
    disp('Num incorrect');
    disp(numIncorrectPixels);
    disp('Precision');
    disp( numCorrectPixels ./ (numCorrectPixels + numIncorrectPixels) );
    disp( sum(numCorrectPixels(1:7))/ (sum(numCorrectPixels(1:7))+sum(numIncorrectPixels(1:7))) );
end

disp('Collecting good-bad segment pairs');
% collect all good and bad segment pairs
% pre-allocate (and later delete empty rows)
if strcmp(mainDataSet,'msrc')
    upperBoundSegPairsNum = length(allData) * 600*10;
else
    % This should estimate the number of possible segment pairs
    %upperBoundSegPairsNum = length(allData) * 150*5;
    upperBoundSegPairsNum = length(allData) * 5000 * 4;
end

%We have two arrays, L for the left side of the pair, and R for the right
%side. There can be up to upperBoundSegPairsNum of different pairs. We have
%good and bad pairs.
goodPairsL = zeros(params.numFeat+1,upperBoundSegPairsNum);
goodPairsR = zeros(params.numFeat+1,upperBoundSegPairsNum);
badPairsL = zeros(params.numFeat+1,upperBoundSegPairsNum);
badPairsR = zeros(params.numFeat+1,upperBoundSegPairsNum);
startBoth = 1;
startBad = 1;

%Only good pairs - segments with the same label
onlyGoodL = zeros(params.numFeat+1,upperBoundSegPairsNum);
onlyGoodR = zeros(params.numFeat+1,upperBoundSegPairsNum);
onlyGoodLabels = zeros(1,upperBoundSegPairsNum);
startOnlyGood = 1;

%Only bad pairs - segments with the same label
onlyBadL = zeros(params.numFeat+1,upperBoundSegPairsNum);
onlyBadR = zeros(params.numFeat+1,upperBoundSegPairsNum);
startOnlyBad = 1;

%All segments
allSegs = zeros(params.numFeat+1,upperBoundSegPairsNum);
allSegLabels =  zeros(1,upperBoundSegPairsNum);
startAllSegs = 1;

%So we have all segments, only good pairs, and good pairs-bad pairs.

for i = 1:length(allData)
    disp(['Processing image ' num2str(i) '...']);
    segs = allData{i}.segs2;            %Segments
    feats = allData{i}.feat2;           %Features
    segLabels = allData{i}.segLabels;   %Labels
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % find neighbors!
    % Get adjacency matrix - upper triangular
    adjHigher = getAdjacentSegments(segs);%getAdjacentSegments(segs,1)
    %Creating a symmetric adjacency matrix
    adj = adjHigher|adjHigher';
    allData{i}.adj = adj;
    
    % compute only all pairs and train to merge or not 
    % For all segments...
    for s = 1:length(segLabels)

        % save all segs and their labels for pre-training
        
        % If the current segment is not void
        if segLabels(s)>0
            allSegs(:,startAllSegs)= [feats(s,:)' ;1]; %Fill columns by adding the feature vector and a '1'
            allSegLabels(startAllSegs) = segLabels(s); %Fill the label array as well
            startAllSegs=startAllSegs+1;
        end
        
        neighbors = find(adj(s,:)); %find the non-zero elements of s-th row - neighbors of s
        sameLabelNeigh = segLabels(neighbors)==segLabels(s);    %indexes of neighbors with the same label
        goodNeighbors = neighbors(sameLabelNeigh);  %neighbors with the same label
        badNeighbors = neighbors(~sameLabelNeigh);  %neighbors with different label
        numGood = length(goodNeighbors);    %number of good neighbors
        numBad = length(badNeighbors);      %number of bad neighbors
        numGBPairs = numGood * numBad;      %good-bad pairs...?
        
        % never train on void segments: !cartprod
        %if the current segment has a nonzero label
        if segLabels(s)>0
            %for all neighbors with the same label
            for g = 1:numGood
                %Fill numGood columns in onlyGood pairs' arrays
                onlyGoodL(:,startOnlyGood:startOnlyGood+numGood-1)= [repmat(feats(s,:)',1,numGood ) ;ones(1,numGood)]; %Features of the current segment and a '1'
                onlyGoodR(:,startOnlyGood:startOnlyGood+numGood-1)= [feats(goodNeighbors,:)' ;ones(1,numGood)]; %Features of a neighboring segment and a '1'
                onlyGoodLabels(startOnlyGood:startOnlyGood+numGood-1) = segLabels(s);   %Pair label is the current segment's label
            end
            startOnlyGood = startOnlyGood + numGood;    %Increasing the index
            
            for g = 1:numBad
                %Fill numGood columns in onlyGood pairs' arrays
                onlyBadL(:,startOnlyBad:startOnlyBad+numBad-1)= [repmat(feats(s,:)',1,numBad) ;ones(1,numBad)]; %Features of the current segment and a '1'
                onlyBadR(:,startOnlyBad:startOnlyBad+numBad-1)= [feats(badNeighbors,:)' ;ones(1,numBad)]; %Features of a neighboring segment and a '1'
            end
            startOnlyBad = startOnlyBad + numBad;    %Increasing the index
            
            
        end
        
        % if the current segment has at least one neighbor with the same label
        % and one with a different label
        if numGood>0 && numBad>0
            gbPairNums = cartprod(goodNeighbors,badNeighbors);  %all pairs of good-bad neighbors
            % these are the inputs to Wbot
            %Fill numGBPairs columns in good pairs' arrays
            goodPairsL(:,startBoth:startBoth+numGBPairs-1)= [repmat(feats(s,:)',1,numGBPairs) ;ones(1,numGBPairs)]; %Features of the current segment and a '1'
            goodPairsR(:,startBoth:startBoth+numGBPairs-1)= [feats(gbPairNums(:,1),:)' ;ones(1,numGBPairs)];    %Features of a GOOD neighboring segment and a '1'
            
            badPairsL(:,startBoth:startBoth+numGBPairs-1)= [repmat(feats(s,:)',1,numGBPairs) ;ones(1,numGBPairs)];  %Features of the current segment and a '1'
            badPairsR(:,startBoth:startBoth+numGBPairs-1)= [feats(gbPairNums(:,2),:)' ;ones(1,numGBPairs)];  %Features of a BAD neighboring segment and a '1'
            
            startBoth = startBoth+numGBPairs;
        end
        
    end
    if mod(i,20)==0, disp([num2str(i) '/' num2str(length(allData))]);end
end

%Cropping the arrays to real sizes
numAllSegs = startAllSegs-1;
allSegs= allSegs(:,1:numAllSegs);
allSegLabels= allSegLabels(1:numAllSegs);

numOnlyGood = startOnlyGood-1;
onlyGoodL = onlyGoodL(:,1:numOnlyGood);
onlyGoodR = onlyGoodR(:,1:numOnlyGood);
onlyGoodLabels= onlyGoodLabels(1:numOnlyGood);

numOnlyBad = startOnlyBad-1;
onlyBadL = onlyBadL(:,1:numOnlyBad);
onlyBadR = onlyBadR(:,1:numOnlyBad);

numGBPairsAll = startBoth-1;
% delete trailing zeros in pre-allocated matrix
goodPairsL = goodPairsL(:,1:numGBPairsAll);
goodPairsR = goodPairsR(:,1:numGBPairsAll);
badPairsL = badPairsL(:,1:numGBPairsAll);
badPairsR = badPairsR(:,1:numGBPairsAll);


%Finally, save everything in a mat file
save(neighName,'allData','goodPairsL','goodPairsR','badPairsL','badPairsR','meanAll','stdAll','onlyGoodL','onlyGoodR','onlyGoodLabels','onlyBadL','onlyBadR','allSegs','allSegLabels',...
    'detectionLabels','detectionLabels2','detectionLabelsValid','detectionLabelsValid2', '-v7.3');


