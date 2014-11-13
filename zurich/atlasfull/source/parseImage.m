% Returns a parse tree for the given image.
function thisTree = parseImage(topCorr,Wbot,W,Wout,Wcat,allData,params)
% topCorr:
%           0 - highest scoring tree (best) without training loss penalty!
%               TESTING TIME
%           1 - highest scoring tree with training loss
%               TRAINING TIME - INCORRECT TREE
%           2 - correct tree (with random choices inside regions)
%               TRAINING TIME - CORRECT TREE
adj = allData.adj;
feat = allData.feat2;
segLabels = allData.segLabels;
segDistributions = allData.segDistributions;

%segBBoxes = allData.segBoundingBoxes;
% if (topCorr==0)
%     detections = allData.detections;
% end
numSegs= size(feat,1);  %number of segments in the image
segsHid = (1./(1 + exp(-Wbot * [feat' ;ones(1,numSegs)]))); %semantic vectors

%segBoundingBoxes = segBBoxes;

preallocate =  5000 * 4; % maxSegmentsPerImage * maxNumberOfNeighborsPerSegment
allPairs = zeros(2*params.numHid,preallocate); %All pairs of segments' semantic vectors.. should preallocate a larger number I guess
allPairsNum = zeros(2,preallocate);    %Indexes of the pairs
pairGood = zeros(1,preallocate);   %One if the pair has the same label, 0 otherwise
startNum=1;
for s = 1:size(adj,1)   %For each segment
  
    neighbors = find(adj(s,:));     %Find neighbors
    numN = length(neighbors);   %There are numN of them
    allPairs(:,startNum:startNum+numN-1) = [repmat(segsHid(:,s),1,numN); segsHid(:,neighbors)]; %Fill numN columns, each with segment's vector and his neighbor's vector
    allPairsNum(:,startNum:startNum+numN-1) = [repmat(s,1,numN); neighbors]; %Fill numN columns with segment's index and his neighbors' indexes
    
    % if topCorr==2, we care about whether this is a good collapse (segs have same label)
    pairGood(startNum:startNum+numN-1) = segLabels(s)==segLabels(neighbors); %Fills with 0's and 1's
    
    startNum=startNum+numN; %Increase index
end
numPairsAll = startNum-1;
% delete trailing zeros in pre-allocated matrix
allPairs= allPairs(:,1:numPairsAll);
allPairsNum=allPairsNum(:,1:numPairsAll);
pairGood=pairGood(1:numPairsAll);

% forward prop those pairs
pairHid = (1./(1 + exp(-W * [allPairs; ones(1,numPairsAll)])));
scores = Wout*pairHid;

if topCorr==1
    % add structure loss penalization for incorrect decisions (to choose them and decrease their scores)
    addPenToScores = params.LossPerError * ~pairGood;
    scores = scores+addPenToScores;
end

%If we are parsing a testing image, we should give more preference to
%segments which go together in a detection
% if topCorr==0
%     %For all pairs
%     for i=1:numPairsAll
%         %That are adjacent
%         if pairGood(i)
%             %Get the positions of both segments
%             pos1 = segBoundingBoxes(:,allPairsNum(1,i)); 
%             pos2 = segBoundingBoxes(:,allPairsNum(2,i));
%             %Calculate the new bounding box
%             posNew = [min(pos1(1),pos2(1)); min(pos1(2),pos2(2)); max(pos1(3),pos2(3)); max(pos1(4),pos2(4)) ]; 
%             
%             %How do we know which detector to call?
%             reward = calculateDetectionReward(posNew,detections);%calculate based on detector output and position of the bounding box
%             
%             %disp([num2str(reward) ', ' num2str(scores(i))]);
%            
%             scores(i) = scores(i) + reward;    
%             
%             
%         end
%        
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%
% init tree with pp - parent pointers, features
numTotalSegs = size(adj,1);
numTotalSuperSegs = numTotalSegs+numTotalSegs-1; % We start with numTotalSegs, and we can create maximally numTotalSegs-1 joinings.

adj = [adj zeros(numTotalSegs,numTotalSegs-1); zeros(numTotalSegs-1,numTotalSuperSegs)];    %Extend the adjacency matrix
%segBoundingBoxes = [segBoundingBoxes zeros(4,numTotalSegs-1)];  %Extending the bounding box matrix

thisTree = tree();
for s=1:numSegs
  thisTree.nodeScores(s) = Wout * segsHid(:,s) ;
end
thisTree.pp = zeros(numTotalSuperSegs,1); % we have numRemSegs many leaf nodes and numRemSegs-1 many nonterminals
thisTree.kids = zeros(numTotalSuperSegs,2);
thisTree.nodeNames =  [1:numTotalSegs -ones(1,numTotalSegs-1)]; %Terminals are labeled with 1,2,3... , nonterminals with -1
thisTree.nodeFeatures = [segsHid zeros(size(segsHid,1),numTotalSegs-1)]; %Terminal semantic vectors and zeros for nonterminals
thisTree.leafFeatures = feat; %Features before the bottom layer


% delete void regions from category/label training!!!
nonVoidSegs = segLabels>0;  %zeros for segments that are void, ones for others
nonVoidSegsInd = find(nonVoidSegs); %indexes of non-void segments
% Creating a numLabels x numTotalSuperSegs matrix
% thisTree.nodeLabels = sparse(segLabels(nonVoidSegs),nonVoidSegsInd,ones(1,length(nonVoidSegsInd)),params.numLabels,numTotalSuperSegs,numTotalSegs);
% thisTree.nodeLabels = full(thisTree.nodeLabels);
thisTree.nodeDistributions = segDistributions';
thisTree.nodeLabels = thisTree.nodeDistributions ./ repmat(sum(thisTree.nodeDistributions),params.numLabels,1) ;
thisTree.nodeDistributions = [thisTree.nodeDistributions zeros(params.numLabels,numTotalSegs-1)];
thisTree.nodeLabels = [thisTree.nodeLabels zeros(params.numLabels,numTotalSegs-1)];
% disp(size(thisTree.nodeLabels));
% here we only train the category classifier on the correct tree!

% compute cost for kids' categories
thisTree.catAct = Wcat*[ segsHid ;ones(1,numSegs)];
thisTree.catOut = softmax(thisTree.catAct);
[catProbs cats] = max(thisTree.catOut);
if size(cats,2) ==1
    cats=cats';
end
thisTree.nodeCatsRight = cats==segLabels';  % See which labels were correctly predicted

thisTree.catAct = [thisTree.catAct zeros(params.numLabels,numTotalSegs-1)]; %Label activations, zeros for nonterminals
thisTree.catOut = [thisTree.catOut zeros(params.numLabels,numTotalSegs-1)]; %Label softmax outputs, zeros for nonterminals
% compute the actual predicted category (and CEE... what to do with )
% CEE = CROSS-ENTROPY ERROR
thisTree.nodeCat = [cats zeros(1,numTotalSegs-1)];  %Predicted labels, zeros for nonterminals
thisTree.nodeCatsRight = [thisTree.nodeCatsRight zeros(1,numTotalSegs-1)]; %Correct labels from groundtruth, zeros for nonterminals

if topCorr==2
    %label errors cost
    catCEE = -sum(sum(thisTree.nodeLabels(:,nonVoidSegs).*log(thisTree.catOut(:,nonVoidSegs))));
    % minimize this cost/error later
    thisTree.cost = catCEE;
end
%if (topCorr~=0)
    newParentIndex = numTotalSegs+1;    %Position the index to the first non-terminal
    while newParentIndex<=numTotalSuperSegs

        %trees with training loss or the testing images
        if topCorr<2
            [thisScore ind] = max(scores);%Score of a (super)segment + the appropriate penalty


        else%if topCorr==2
            %correct trees
            stillGoodCollapses = any(pairGood); %if there are any correct merges remaining
            if stillGoodCollapses
                scores(~pairGood) = -Inf;   %put the score for incorrect merge to -inf, so it doesnt get selected
            end
            [thisScore ind] = max(scores);
        end

        %disp(['Merging. Score: ' num2str(thisScore)]);

        % add to score which we want to maximize
        thisTree.score = thisTree.score+thisScore;
        newSegHid = pairHid(:,ind);

        % find kids of best merge
        kids = allPairsNum(:,ind);

        % add parent to tree datastructure
        thisTree.pp(kids) = newParentIndex ;
        thisTree.kids(newParentIndex,:) = kids';
        thisTree.nodeNames(newParentIndex) = newParentIndex;
        thisTree.nodeFeatures(:,newParentIndex) = newSegHid;
        
%         thisTree.nodeLabels(:,newParentIndex) = thisTree.nodeLabels(:,kids(1)) + thisTree.nodeLabels(:,kids(2));
        thisTree.nodeDistributions(:,newParentIndex) = thisTree.nodeDistributions(:,kids(1)) + thisTree.nodeDistributions(:,kids(2));
        thisTree.nodeLabels(:,newParentIndex) = thisTree.nodeDistributions(:,newParentIndex) / sum(thisTree.nodeDistributions(:,newParentIndex));
        thisTree.nodeScores(newParentIndex) = thisScore;

        % compute category/label activation of this new node
        thisTree.catAct(:,newParentIndex) = Wcat*[newSegHid ;1 ];
        thisTree.catOut(:,newParentIndex) = softmax(thisTree.catAct(:,newParentIndex));
        [prob catNew] = max(thisTree.catOut(:,newParentIndex));
        thisTree.nodeCat(newParentIndex) = catNew;
        correctNodeLabels = thisTree.nodeLabels(:,newParentIndex);
        [prob catCorr] = max(correctNodeLabels);
        % nodes are only "right" if they have 1 label in the ground truth!
%         if sum(correctNodeLabels>0)==1
            thisTree.nodeCatsRight(newParentIndex) = catCorr;%catNew==find(correctNodeLabels);
%         end
        % for funky multi-label nodes, it might still make sense to predict their leaf nodes' label distribution
        if topCorr==2
            labelsTrue = thisTree.nodeLabels(:,newParentIndex);
            if any(labelsTrue)
                labelDistribution = labelsTrue./sum(labelsTrue);
                newCEE = -sum(labelDistribution.*log(thisTree.catOut(:,newParentIndex)));
                thisTree.cost = thisTree.cost+newCEE;
            end
        end

        %Adding the childrens' neighbors to the parent in the adjacency matrix
        adj(newParentIndex,:) = adj(kids(1),:) | adj(kids(2),:);
        adj(:,newParentIndex) = adj(newParentIndex,:)';

        %Adding the parent's bounding box as the combination of the kids
%         pos1 = segBoundingBoxes(:,kids(1));
%         pos2 = segBoundingBoxes(:,kids(2));
%         segBoundingBoxes(:,newParentIndex) =[min(pos1(1),pos2(1)); min(pos1(2),pos2(2)); max(pos1(3),pos2(3)); max(pos1(4),pos2(4)) ]; 

        % delete pairs in pairHid that have either of the kids anywhere and from the adj matrix
        delete = allPairsNum==kids(1) | allPairsNum==kids(2);
        delete = any(delete);
        allPairsNum(:,delete)=[];
        allPairs(:,delete)=[];
        pairHid(:,delete)=[];
        scores(:,delete)=[];
        pairGood(delete)=[];


        %Removing the children from the adjacency matrix
        adj(kids(1),:) = 0;
        adj(:,kids(1)) = 0;
        adj(kids(2),:) = 0;
        adj(:,kids(2)) = 0;

        % add new pairs to set of pairs with scores
        newSegsNeighbors = find(adj(newParentIndex,:));
        if ~isempty(newSegsNeighbors)
            newPairsNum = zeros(length(newSegsNeighbors),2);
            newPairsNum(:,1) = newParentIndex;  %Left is the new parent
            newPairsNum(:,2) = newSegsNeighbors';   %Right is an old neighbor

            allPairsNum=[allPairsNum newPairsNum']; %Adding the new pairs' indices

            newPairs = [thisTree.nodeFeatures(:,newPairsNum(:,1)) ; thisTree.nodeFeatures(:,newPairsNum(:,2))];
            allPairs=[allPairs newPairs];   %Adding the new pairs' features

            newHidCand = (1./(1 + exp(-W * [newPairs; ones(1,length(newSegsNeighbors))])));
            pairHid = [pairHid newHidCand ];    %Adding the pairs' activations

            %Label vectors for the left and right child are summed
%             newGoodness = thisTree.nodeLabels(:,newPairsNum(:,1)) + thisTree.nodeLabels(:,newPairsNum(:,2));
            [~,pos1] = max(thisTree.nodeLabels(:,newPairsNum(:,1)));
            [~,pos2] = max(thisTree.nodeLabels(:,newPairsNum(:,2)));
%             newGoodness = newGoodness>0;    %We select the rows with positive values
%             newGoodness = sum(newGoodness)==1;  %If there's only one row remaining
            newGoodness = pos1==pos2;
            pairGood = [pairGood newGoodness];  %That means both segments have the same labels, and they are good.

            newScores = Wout*newHidCand;    %Also calculate the scores for the possible new merges
            if topCorr==1
                % add structure loss penalization for incorrect decisions (to choose them and decrease their scores)
                % (we should only add this if there are other good decisions left)
                addPenToScores = params.LossPerError * ~newGoodness; %add penalty to those rows which have 0 goodness: different labels
                newScores = newScores+addPenToScores;
            end
            %For testing images
    %         if topCorr==0
    %             %For all pairs
    %             for i=1:length(newSegsNeighbors)
    %                 %That are "good"
    %                 if newGoodness(i)
    %                     %Get the positions of both segments
    %                     pos1 = segBoundingBoxes(:,newPairsNum(i,1));
    %                     pos2 = segBoundingBoxes(:,newPairsNum(i,2));
    %                     %Calculate the new bounding box
    %                     posNew = [min(pos1(1),pos2(1)); min(pos1(2),pos2(2)); max(pos1(3),pos2(3)); max(pos1(4),pos2(4)) ]; 
    % 
    %                     %How do we know which detector to call?
    %                     reward = calculateDetectionReward(posNew,detections);% calculate based on detector output and position of the bounding box
    % 
    %                     newScores(i) = newScores(i) + reward;  
    %                 end
    %                  
    %             end
    %         end

            scores = [scores newScores];



        end

        newParentIndex = newParentIndex+1;
     end
