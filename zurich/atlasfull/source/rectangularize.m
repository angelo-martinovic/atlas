function [horLines verLines] = rectangularize(maps,hyperParams)

height = size(maps,1);
width = size(maps,2);
nLabels = size(maps,3);
%figure; imagesc(map);
%Detecting horizontal and vertical boundaries between segment and
%background
horS = [1 2 1; 0 0 0; -1 -2 -1];
verS = [1 0 -1; 2 0 -2; 1 0 -1];
horEdges = zeros(height,width,nLabels);
verEdges = zeros(height,width,nLabels);
for i=1:nLabels
    temp = abs(conv2(maps(:,:,i),horS));
    horEdges(:,:,i) = temp(2:end-1,2:end-1);
    temp = abs(conv2(maps(:,:,i),verS));
    verEdges(:,:,i) = temp(2:end-1,2:end-1);
end

%Creating a horizontal and  vertical histogram of edges
horHist = sum(sum(horEdges,3),2);
verHist = (sum(sum(verEdges,3),1))';

%Smooth the histograms with a gaussian filter
horHist = smooth(horHist);
verHist = smooth(verHist);


%Maximum value to 1
horHist = horHist/max(horHist);
verHist = verHist/max(verHist);


%Detections of peaks in the histograms
[maxtabHor,~] = peakdet(horHist,0.15);%0.1*median(horHist)); %hyperParams
[maxtabVer,~] = peakdet(verHist,0.1);%0.1*median(verHist));

if maxtabHor(1,1)==1
    maxtabHor = maxtabHor(2:end,:);
end
if maxtabHor(end,1)==height
    maxtabHor = maxtabHor(1:end-1,:);
end
if maxtabVer(1,1)==1
    maxtabVer = maxtabVer(2:end,:);
end
if maxtabVer(end,1)==width
    maxtabVer = maxtabVer(1:end-1,:);
end

%Visualize the peaks
% figure; bar(horHist);hold on;plot(maxtabHor(:,1), maxtabHor(:,2), 'r*');
% figure; bar(verHist);hold on;plot(maxtabVer(:,1), maxtabVer(:,2), 'r*');

horLines = zeros(1,height);%Positions of horizontal lines and their probabilities
horLines([1; maxtabHor(:,1); height]) = [1; maxtabHor(:,2); 1];

verLines = zeros(1,width);
verLines([1; maxtabVer(:,1); width]) = [1; maxtabVer(:,2); 1];


%Visualize the grid
 %figure;
 %imagesc(maps(:,:,4));
%  hold on;
%  for i=1:size(maxtabHor,1)
%      line( [0 width], [maxtabHor(i,1) maxtabHor(i,1)]);
%  end
%  for i=1:size(maxtabVer,1)
%      line( [maxtabVer(i,1) maxtabVer(i,1)], [0 height]);
%  end


% 
% outMapImg = zeros(height,width);
% outMapImg(outMap==1)=255;
% image(outMapImg,'AlphaData',0.5); hold off;


end