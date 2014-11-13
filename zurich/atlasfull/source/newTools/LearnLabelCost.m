function labelCost = LearnLabelCost(dataset, fold, dataLocation, nClasses)
%LEARNLABELCOST Based on the groundtruth annotations in the training set,
%learns a symmetric cost matrix for each pair of classes, to be used in CRF
%optimization.

%     labelCost = zeros(nClasses,nClasses);
    
    imageNames = ReadFoldImageNames(dataset,fold,'train');
    
    origImageNames = strcat(dataLocation,imageNames);
    groundTruthFilenames = strcat(origImageNames,'.txt');
    
    countMatrixTotal = zeros(nClasses,nClasses);
    for i=1:length(groundTruthFilenames)
        fprintf('.');
        groundTruth = dlmread(groundTruthFilenames{i}); 
        
        [countMatrix,~,~,~] = GetLabelChanges(groundTruth,nClasses);
        % Make the matrix symmetric and eliminate values on the diagonal
%         countMatrix = tril(countMatrix,-1)'+tril(countMatrix,-1);
        countMatrixTotal = countMatrixTotal+countMatrix;
    end
    
    % Smooth out to eliminate zero counts.
    countMatrixTotal2 = countMatrixTotal+1;
    
    % Remove the diagonal
%     countMatrixTotal2 = countMatrixTotal2 - diag(diag(countMatrixTotal2));
    
    % Remove the upper triangular part
    countMatrixTotal2 = countMatrixTotal2 - triu(ones(nClasses,nClasses),1);
    
    % Mirror the lower triangular part without the diagonal
    countMatrixTotal2 = countMatrixTotal2+tril(countMatrixTotal2,-1)';
    
    % Calculate probabilities P(c_i|c_j)
    P = diag(1./sum(countMatrixTotal2,2))*countMatrixTotal2;
    
    % Average P(c_i|c_j) and P(c_j|c_i)
    P2 =(tril(P)+triu(P)')/2;
    
    % Create a symmetric cost matrix
    labelCost = -log(tril(P2)+tril(P2)');
    labelCost(1:nClasses+1:end) = 0;
    
    cacheLocation = ['cache_' dataset '_train/'];
    save([cacheLocation 'fold' num2str(fold) '_labelCost.mat'],'labelCost');

end