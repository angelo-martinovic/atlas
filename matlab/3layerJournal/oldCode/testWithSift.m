show=1
vl_setup;
noOfNeighbors = 30;
load('markus_3.mat');
im = origImg;
I = double(rgb2gray(im));

[C,resp] = vl_sift(single(I));

C= C(1:2,:);

if show
    figure;
    imshow(im)
    hold on
   
    plot(C(:,1), C(:,2),'+');
end

bb = [50 50 200 200];
detectionFeatMask = C(1,:) > bb(1) & C(1,:) < bb(3)  & C(2,:) > bb(2) & C(2,:) < bb(4);

resp = resp';

queryPoints = resp(detectionFeatMask,:);

tmp = C(:, detectionFeatMask);

if show
    figure;
    imshow(im)
    hold on
    %plot(j,i,'+');
    plot(tmp(1,:), tmp(2,:),'+');
end


nn =10;

[neighbors,distances] = knnsearch(resp, queryPoints, 'k', nn,  'Distance', 'euclidean');

%plot point and neighbors
qpt = C(:,detectionFeatMask);
ptx = 4;

figure;
imshow(im)
hold on
   
    
    
for i=1:nn
      idx = neighbors(ptx,i)';
      idx
      pt = C(:,idx);
       plot(pt(1), pt(2),'r+');
     
end
plot(qpt(1,ptx), qpt(2,ptx),'+');













