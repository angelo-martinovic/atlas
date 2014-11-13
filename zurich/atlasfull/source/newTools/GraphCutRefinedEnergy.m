function [result,E_begin,E_end] = GraphCutRefinedEnergy(x,w,yGroundTruth)

    % Make sure that w has only positive values
    % if (min(w)<0)
    %     w = w-min(w)+0.1;
    % end

    %% Extract unary and pairwise potentials from the input
    segMap = x.segMap;

    detectionMaps = x.detectionMaps;
    nDetectors = length(detectionMaps);
    pairwise2 = x.pairwise2;
    labelCost = x.labelCost;
    positionMap = x.positionMap;

    H = size(segMap,1);
    W = size(segMap,2);

    
    segclass = reshape((yGroundTruth-1)',W*H,1);%zeros(W*H,1);
    unary = zeros(8,W*H);

    % w: (1)seg (2)win (3)door (4)pos (5)lam1 (6)lam2 

    %% Unary loss
    counts = zeros(1,8);
    for i=1:8
        counts(i)=sum(sum(yGroundTruth==i));
    end
    totalCount = sum(counts);
    penalties = 1 - counts/totalCount;
    
    lossMasks = zeros(H,W,8);
    for i=1:8
        tempMask = penalties(yGroundTruth);
        tempMask(yGroundTruth==i)=0;
        lossMasks(:,:,i) = tempMask;
%         lossMasks(:,:,i) = (yGroundTruth==i);
    end
%     lossMasks = 1-lossMasks;
    
    %% Unary
    unary_mat = w(1)*  (-log(segMap));
    for i=1:nDetectors
        unary_mat = unary_mat + w(i+1)*(-log(detectionMaps(i).detectionMap));
    end
    unary_mat = unary_mat - lossMasks;
    
    
    unary_pos = zeros(8,W*H);
    for i=1:8
        unary_pos(i,:) = reshape(-log(positionMap(:,:,i)'),1,W*H);
        
        unary(i,:) = reshape(unary_mat(:,:,i)',1,W*H)+...
            w(1+nDetectors+i)*unary_pos(i,:);
    end

    
    %% Pairwise
%     % Get lower triangular
%     b=w(1+nDetectors+1:1+nDetectors+28);
% 
%     A=tril(ones(8,8),-1);
%     A(~~A)=b;
%     
%     % Transform into a symmetric matrix
%     A = A+A';
%     
%     labelCost =  A;

%     labelCost = ones (8,8);
%     labelCost(1:8+1:64) = 0;
    
%     m = W * H;
%     n = W * H;
% 
%     [~,yIndicesGt,i,j] = GetLabelChanges(yGroundTruth);
% 
%     sameLabelIndices = 1:9:64;
%     s = ismember(yIndicesGt,sameLabelIndices);
%     
%     vals = zeros(size(s));
%     vals(s) = 1;
%     
%     pairwiseloss = sparse(i,j,vals,m,n);
%     pairwiseloss=pairwiseloss+pairwiseloss';
    % Contrast sensitive
    % pairwise1 = sparse(i,j,s,m,n);
    
    pairwise = w(1+nDetectors+8+1)*pairwise2;
%     pairwise = pairwise2;% - pairwiseloss;

    %% Graph cut
    disp('Running the graph cut...');
    [labels, E, Eafter] = GCMex(segclass, double(unary), pairwise, double(labelCost),0);
    disp('Done.');
    labels = labels + 1;

    E_begin = E;
    E_end = Eafter;
    
    result = reshape(labels,W,H)';
%     figure(2);imagesc(result);
end
