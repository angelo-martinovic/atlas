function thisTree = makeSegmentationTree()
    stem = 'monge_6';

    load(['/esat/nereid/amartino/Facades/ECPdatabase/cvpr2010/images/gpb/' stem '.mat']);
    load('/esat/nereid/amartino/RNN/data/haussmanngpb-FOLD1_eval.mat','allData');

    segLabels = allData{2}.segLabels;
    steps = unique(ucm2);

    initialSeg = bwlabel(ucm2 <= 0);
    % initialSeg = initialSeg(2:2:end, 2:2:end);
    % initialSeg = initialSeg-1;

    numTotalSegs = max(initialSeg(:));
    numTotalSuperSegs = numTotalSegs + numTotalSegs - 1;
    
    thisTree = tree();
    thisTree.pp = zeros(numTotalSuperSegs,1); % we have numRemSegs many leaf nodes and numRemSegs-1 many nonterminals
    thisTree.kids = zeros(numTotalSuperSegs,2);
    thisTree.nodeNames =  [1:numTotalSegs -ones(1,numTotalSegs-1)]; %Terminals are labeled with 1,2,3... , nonterminals with -1
%     thisTree.nodeFeatures = [segsHid zeros(size(segsHid,1),numTotalSegs-1)]; %Terminal semantic vectors and zeros for nonterminals
%     thisTree.leafFeatures = feat; %Features before the bottom layer
    nonVoidSegs = segLabels>0; 
    nonVoidSegsInd = find(nonVoidSegs);

    thisTree.catOut = sparse(segLabels(nonVoidSegs),nonVoidSegsInd,ones(1,length(nonVoidSegsInd)),8,numTotalSuperSegs,numTotalSegs);
    thisTree.catOut = full(thisTree.catOut);
    thisTree.nodeLabels = zeros(8,numTotalSuperSegs);
    thisTree.nodeLevels = zeros(numTotalSuperSegs);
    
    seg=initialSeg;
    parentIndex = numTotalSegs;
        
    for i=2:size(steps,1)
        [seg1,seg2] = getMergingSegments(seg,ucm2,steps(i));
           
        parentIndex = parentIndex + 1;
        
        seg(seg==seg1) = parentIndex;
        seg(seg==seg2) = parentIndex;
          
        thisTree.pp([seg1,seg2]) = parentIndex;
        thisTree.kids(parentIndex,:) = [seg1 seg2];
        thisTree.catOut(:,parentIndex) = thisTree.catOut(:,seg1) + thisTree.catOut(:,seg2);
        thisTree.nodeLevels(parentIndex) = max(thisTree.nodeLevels(seg1),thisTree.nodeLevels(seg2))+1;

        
        %disp(['Merging ' num2str(seg1) ' and ' num2str(seg2) ' into ' num2str(parentIndex)]);
  
    end

%     topNode = thisTree.getTopNode();
%     disp(thisTree.nodeLevels(topNode));
%     
%     leaves = thisTree.getLeaves(topNode);
    
    nodes = thisTree.getNodesAtLevel(3);
    nCoveredLeaves = 0;
    for i=1:length(nodes)
        %leaves = [leaves;thisTree.getLeaves(nodes(i))];
        nCoveredLeaves = nCoveredLeaves + length(thisTree.getLeaves(nodes(i)));
    end
     
    % TODO : Relabel leaves not covered
    seg = initialSeg;
    index = numTotalSegs - nCoveredLeaves;
    for i=1:length(nodes)
        leaves = thisTree.getLeaves(nodes(i));
        index = index+1;
        for j=1:length(leaves)
            seg(seg==leaves(j)) = index;
        end
    end
    
    figure;imagesc(seg);
    
    
   



    
    
end

function [seg1,seg2] = getMergingSegments(seg,boundaries,threshold)
    h = size(seg,1);
    w = size(seg,2);
    
    boundary = find(abs(boundaries-threshold)<eps);
    
    adjacent = [boundary-1; boundary+1; boundary-h; boundary+h];
    
    adjacent = unique(adjacent(adjacent>0 & adjacent<=w*h));
    
    segments = seg(adjacent);
    segments = segments(segments~=0);

    
    seg1 = mode(segments);
    segments = segments(segments~=seg1);
    seg2 = mode(segments);
    
end