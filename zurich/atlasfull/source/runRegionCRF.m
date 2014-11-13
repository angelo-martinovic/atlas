function [labels,E_begin,E_end] = runRegionCRF(adj,labels,regionSizes,segMask,segFeatures,hyperParams,svm)
addpath('GCMex/');

N = size(adj,1);

segclass = zeros(N,1);

lambda = hyperParams(5);

labelcost = lambda * [0 1 1 1 1 1 1 1;   %Wi
             1 0 1 1 1 1 1 1;   %Wa
             1 1 0 1 1 1 1 1;   %Ba
             1 1 1 0 1 1 1 1;   %Do
             1 1 1 1 0 1 1 1;   %Ro
             1 1 1 1 1 0 1 1;   %Sk
             1 1 1 1 1 1 0 1;   %Sh
             1 1 1 1 1 1 1 0];  %Ch

labelcost(1,4) = 1000;labelcost(4,1) = 1000;
labelcost(4,5) = 1000;labelcost(5,4) = 1000;
labelcost(4,6) = 1000;labelcost(6,4) = 1000;
labelcost(4,8) = 1000;labelcost(8,4) = 1000;
labelcost(5,7) = 1000;labelcost(7,5) = 1000;
labelcost(6,7) = 1000;labelcost(7,6) = 1000;
labelcost(7,8) = 1000;labelcost(8,7) = 1000;


pairwise = zeros(size(adj,1),size(adj,2));

X=zeros(10000,size(segFeatures,2));
numAdj = 0;
for i=1:size(adj,1)
    for j=1:size(adj,2)
        if (adj(i,j)==1)
            numAdj = numAdj+1;
            X(numAdj,:) = min(segFeatures(i,:),segFeatures(j,:));
            X(numAdj,:) = (X(numAdj,:)-svm.mi)./(svm.Mi-svm.mi);
        end
    end
end
X = X(1:numAdj,:); %#ok<NASGU>

[~, ~, ~, prob_estimates] = evalc(['svmpredict_chi2(ones(numAdj,1), X, svm.model, ' char(39) '-b 1' char(39) ')']);
% prob_estimates(:,1) are the probabilities that two segments have different labels
adjCnt=0;
for i=1:size(adj,1)
    for j=1:size(adj,2)
        if (adj(i,j)==1)
            adjCnt=adjCnt+1;
            pairwise(i,j) = -log(prob_estimates(adjCnt,1));  
        end
    end
end
pairwise = sparse(pairwise);
% pairwise(i,j) = getBoundaryFeatures(segMask,i,j);

disp('Done calculating the pairwise term');
%pairwise = load('pairwise.mat','pairwise');
%pairwise = pairwise.pairwise;
%pairwise = sparse(double(adj));
unary = -log(labels);

for i=1:N
     unary(:,i) = unary(:,i)*sqrt(regionSizes(i));
     %[~,c] = sort(unary(:,i));
     %unary(c(3:end),i) = 1e5;
end
disp('Running the graph cut...');
[labels E Eafter] = GCMex(segclass, single(unary), pairwise, single(labelcost),0);
disp('Done.');
labels = labels + 1;

E_begin = E;
E_end = Eafter;
