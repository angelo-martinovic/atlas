function [countMatrix,indices,pixIndexes,pixIndexes_neigh] = GetLabelChanges(y,nClasses)
    height=size(y,1);
    width = size(y,2);
    
    [locY_H,locX_H]=find(y(1:end,1:end-1)>0);
    [locY_V,locX_V]=find(y(1:end-1,1:end)>0);

    
    % Pair of neighboring pixels with diff labels in the x-direction
    pixIndexes_H = 1+ (locY_H-1)*width+ (locX_H-1);
    pixIndexes_H_neigh = 1+ (locY_H-1)*width+ (locX_H-1) + 1;
    
    % Pair of neighboring pixels with diff labels in the y-direction
    pixIndexes_V = 1+ (locY_V-1)*width+ (locX_V-1);
    pixIndexes_V_neigh = 1+ (locY_V-1 + 1)*width+ (locX_V-1) ;
    
    % Joining all pixel indices
    pixIndexes = [pixIndexes_H; pixIndexes_V];
    pixIndexes_neigh = [pixIndexes_H_neigh; pixIndexes_V_neigh];
    
    % Indices in the pairwise term matrix (size of WH * WH)
%     indices=sub2ind([width*height,width*height],pixIndexes,pixIndexes_neigh);
    
%     psi(4) = sum(x.pairwise(indices));
    
    
    % 6th term - pairwise: simple Potts model potential
%     psi(1+numDetectors+1) = sum(x.pairwise2(indices));

    % Linearize y
    yReshaped=reshape(y',1,height*width);
    
    % Label values of first vertex i and second vertex j
    yValues1=yReshaped(pixIndexes);
    yValues2=yReshaped(pixIndexes_neigh);
    
    % Ignore void labels
    nonVoidIndices = yValues1>0 & yValues2>0;
    yValues1 = yValues1(nonVoidIndices);
    yValues2 = yValues2(nonVoidIndices);
    
    yValues = sort([yValues1; yValues2]);

    % Index into labelcost matrix for (i,j) and (j,i)
    indices = (yValues(1,:)-1)*nClasses+yValues(2,:);
        
    uniqIndices = unique(indices);
    counts = hist(indices,uniqIndices);
    counts = counts(counts>0);
    
    countMatrix = zeros(nClasses,nClasses);
    countMatrix(uniqIndices)=counts;
end