function [result,E_begin,E_end] = runCRF(segMap,detectionMap,detectionMap2,imgNumber,fold,hyperParams)
addpath('GCMex/');

H = size(segMap,1);
W = size(segMap,2);

segclass = zeros(W*H,1);
pairwise = sparse(W*H,W*H);
unary = zeros(8,W*H);

alpha1 = hyperParams(1);
alpha2 = hyperParams(2);
alpha3 = hyperParams(3);
lambda = hyperParams(4);

labelcost = lambda * [0 1 1 1 1 1 1 1;   %Wi
             1 0 1 1 1 1 1 1;   %Wa
             1 1 0 1 1 1 1 1;   %Ba
             1 1 1 0 1 1 1 1;   %Do
             1 1 1 1 0 1 1 1;   %Ro
             1 1 1 1 1 0 1 1;   %Sk
             1 1 1 1 1 1 0 1;   %Sh
             1 1 1 1 1 1 1 0];  %Ch
% labelcost(1,4) = 1000;
% labelcost(4,1) = 1000;
% 
% labelcost(6,7) = 1000;
% labelcost(7,6) = 1000;
% 
% labelcost(7,8) = 1000;
% labelcost(8,7) = 1000;
% 
% labelcost(6,5) = 1000;
% labelcost(5,6) = 1000;

%filename = ['adjacencies/fold' num2str(fold) 'img' num2str(imgNumber) '.mat'];
i = zeros( 4*W*H-2*H-2*W,1);
j = zeros( 4*W*H-2*H-2*W,1);
s = ones( 4*W*H-2*H-2*W,1);
m = W * H;
n = W * H;
count = 0;
%if ~exist(filename,'file')
    for row = 0:H-1
        for col = 0:W-1
            pixel = 1+ row*W + col;
   
            if row+1 < H, count = count +1;  i(count) = pixel;j(count)=1+col+(row+1)*W; end
            if row-1 >= 0, count = count +1; i(count) = pixel;j(count)=1+col+(row-1)*W; end 
            if col+1 < W, count = count +1;  i(count) = pixel;j(count)=1+(col+1)+row*W; end
            if col-1 >= 0, count = count +1; i(count) = pixel;j(count)=1+(col-1)+row*W; end 
    
        end
    end
    pairwise = sparse(i,j,s,m,n);
%    save(filename,'pairwise');
%else
%    pairwise=load(filename);
%    pairwise = pairwise.pairwise;
%end
% alpha = 2;
% alpha2 = 4;
%disp(alpha);

positionMap = load('positionMap.mat','positionMap');
positionMap = positionMap.positionMap;

posProbMap = zeros(H,W,8);
for i=1:8
   %Convert to grayscale image
   I = mat2gray(positionMap(:,:,i));
   
   %Rescale to a common size 
   posProbMap(:,:,i) = imresize(I,[H,W],'nearest');
   
end
uniformMap = (1-sum(posProbMap(:,:,5:8),3))/4;
for i=1:4
    posProbMap(:,:,i) = uniformMap;
end

unary(1,:) = reshape(-log(segMap(:,:,1)')- alpha1*log(detectionMap(:,:,1)') -alpha2*log(detectionMap2(:,:,1)') -alpha3*log(posProbMap(:,:,1)'),1,W*H);
unary(2,:) = reshape(-log(segMap(:,:,2)')- alpha1*log(detectionMap(:,:,2)') -alpha2*log(detectionMap2(:,:,2)') -alpha3*log(posProbMap(:,:,2)'),1,W*H);
unary(3,:) = reshape(-log(segMap(:,:,3)')- alpha1*log(detectionMap(:,:,3)') -alpha2*log(detectionMap2(:,:,3)') -alpha3*log(posProbMap(:,:,3)'),1,W*H);
unary(4,:) = reshape(-log(segMap(:,:,4)')- alpha1*log(detectionMap(:,:,4)') -alpha2*log(detectionMap2(:,:,4)') -alpha3*log(posProbMap(:,:,4)'),1,W*H);
unary(5,:) = reshape(-log(segMap(:,:,5)')- alpha1*log(detectionMap(:,:,5)') -alpha2*log(detectionMap2(:,:,5)') -alpha3*log(posProbMap(:,:,5)'),1,W*H);
unary(6,:) = reshape(-log(segMap(:,:,6)')- alpha1*log(detectionMap(:,:,6)') -alpha2*log(detectionMap2(:,:,6)') -alpha3*log(posProbMap(:,:,6)'),1,W*H);
unary(7,:) = reshape(-log(segMap(:,:,7)')- alpha1*log(detectionMap(:,:,7)') -alpha2*log(detectionMap2(:,:,7)') -alpha3*log(posProbMap(:,:,7)'),1,W*H);
unary(8,:) = reshape(-log(segMap(:,:,8)')- alpha1*log(detectionMap(:,:,8)') -alpha2*log(detectionMap2(:,:,8)') -alpha3*log(posProbMap(:,:,8)'),1,W*H);

disp('Running the graph cut...');
[labels E Eafter] = GCMex(segclass, single(unary), pairwise, single(labelcost),0);
disp('Done.');
labels = labels + 1;

% fprintf('E: %d, Eafter: %d \n', E, Eafter);
% fprintf('unique(labels) is: [');
% fprintf('%d ', unique(labels));
% fprintf(']\n');

E_begin = E;
E_end = Eafter;

result = reshape(labels,W,H)';
