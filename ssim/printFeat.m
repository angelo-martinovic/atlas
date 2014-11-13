function vs2 = printFeat(patchname)
patchGray = rgb2gray(imread(patchname));
patch = double(patchGray);


parms.size=5;
parms.coRelWindowRadius=40;
parms.numRadiiIntervals=3;
parms.numThetaIntervals=20;
parms.varNoise=25*3*36;
parms.autoVarRadius=1;
parms.saliencyThresh=0.2; % I usually disable saliency checking
parms.nChannels=size(patch,3);
radius=(parms.size-1)/2; % the radius of the patch
marg=radius+parms.coRelWindowRadius;

idx = strfind(patchname,'.');
patchFeatureName = patchname(1:idx(end));
patchFeatureName = strcat(patchFeatureName, 'hesaff');

[feat1 nb dim]=loadFeatures(patchFeatureName);


allXCooPatch = [];
allYCooPatch = [];
[feat1 nb dim]=loadFeatures(patchFeatureName);


for c1=1:nb,%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allXCooPatch = [allXCooPatch round(feat1(1,c1))];
allYCooPatch = [allYCooPatch round(feat1(2,c1))];
end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check bounds
[allXCooPatch, allYCooPatch] = remPclose2Border(allXCooPatch,allYCooPatch,size(patch,2)-marg,marg+1, size(patch,1)-marg,marg+1);


[respPatch,drawCoordsPatch,salientCoordsPatch,uniformCoordsPatch]=ssimDescriptor(patch ,parms ,allXCooPatch ,allYCooPatch);

for i=1:size(respPatch,2)
    fprintf('Feature: xxx (x,y) = (%i, %i)\n', drawCoordsPatch(1,i), drawCoordsPatch(2,i));
    fprintf('angle | radius | value\n');
    for j=1:parms.numThetaIntervals
       for k=1:parms.numRadiiIntervals
           fprintf(' %i | %i | %f\n', j-1,k-1,respPatch((j-1)*parms.numRadiiIntervals + k,1));
       end
    end
    
    
end


% %save voting vector
% noOfCoords = size(drawCoordsPatch,2);
% votingVectorPatch = [];
% for i=1:noOfCoords  
%     x = xmean - drawCoordsPatch(1,i);
%     y = ymean - drawCoordsPatch(2,i);
%     %fprintf('(%d,%d)\n',round(x),round(y));
%     votingVectorPatch = [votingVectorPatch [x; y]];
% end
% 
% %check votesvector
% % for i=1:size(drawCoordsPatch,2)
% %     fprintf('(%d,%d)\n',round(drawCoordsPatch(1,i) + votingVectorPatch(1,i))...
% %         ,round(drawCoordsPatch(2,i) + votingVectorPatch(2,i)));
% %    
% %     %drawCoordsPatch(1,i) + votingVectorPatch(1:i)
% % end
% 
% figure(111);
% clf;
% query = imread(queryname);
% imagesc(query);
% hold on
% count = 0;
% vs = zeros(size(query,1),size(query,2));
% ks = 30;
% gk = fspecial('gaussian',2*ks+1,10);
% minimum = 10000000;
% maximum = 0;
% for i = 1:size(respPatch,2)
%     for j = 1:size(respQuery,2)
%         %compare the vectors
%         %count = count +1;
% %         if (i~=j)
% %             continue;
% %         end
%         if count < 100000
%       %  comp = dist(respPatch(:,i), respQuery(:,j));
%         comp = abs(respPatch(:,i) - respQuery(:,j));
%         comp = sum(comp);
%         minimum = min (minimum, comp);
%         maximum = max( maximum, comp);
%         if comp < 8
%            %vote for
%            voteCoord = drawCoordsQuery(:,j) + votingVectorPatch(:,i);
%            y = round(voteCoord(1));
%            x = round(voteCoord(2));
%            if x < size(query,1)-ks && y < size(query,2)-ks && x> ks && y > ks
%                vs(-ks+x:x+ks,-ks+y:y+ks) = vs(-ks+x:x+ks,-ks+y:y+ks) + gk;
%            end
%         end
%         end
%     end
% 
% 
% 
% end
% minimum
% maximum
% 
% figure(112);
% clf;
% vs2 = vs./max(vs(:));
% imagesc(vs2);
% colormap(jet);


function [feat nb dim]=loadFeatures(file)
fid = fopen(file, 'r');
dim=fscanf(fid, '%f',1);
if dim==1
dim=0;
end
nb=fscanf(fid, '%d',1);
feat = fscanf(fid, '%f', [5+dim, inf]);
fclose(fid);
end


function [retx, rety]=remPclose2Border(x,y, maxx, minx, maxy, miny)
    xm = (x<maxx);
    ym = (y<maxy);
    m = (xm&ym);
    xm = (x>minx);
    ym = (y>miny);
    m = (m&xm);
    m = (m&ym);
    retx = x(m);
    rety = y(m);
end

end

