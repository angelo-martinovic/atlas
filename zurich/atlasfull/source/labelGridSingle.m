function maps = labelGridSingle(setHorLines, setVerLines, totalConfidenceMap)
height = size(setHorLines,2);
width = size(setVerLines,2);
nLabels = size(setHorLines,1);
%bar(setHorLines);
%figure; bar(setVerLines);
horLines = setHorLines>0;
verLines = setVerLines>0;

% compH = bwlabel(horLines);
% compV = bwlabel(verLines);
% 
% centroidsH = regionprops(compH,'Centroid');
% centroidsV = regionprops(compV,'Centroid');
% 
% centroidsH = centroidsH(2:end-1);
% centroidsV = centroidsV(2:end-1);



%figure;imagesc(zeros(height,width));

outMap = zeros(height,width,nLabels);
totalHor = [];
totalVer = [];
for label=1:nLabels
    gridH = find(horLines(label,:)==1);
    gridV = find(verLines(label,:)==1);

    maxtabHor = gridH';
    maxtabVer = gridV';
    
    totalHor = [totalHor;maxtabHor];
    totalVer = [totalVer;maxtabVer];

    if (size(maxtabHor,1)>1)
        for i=1:size(maxtabHor,1)-1
            begLineHor = maxtabHor(i);
            endLineHor = maxtabHor(i+1)-1; 
            if (endLineHor==height-1) 
                endLineHor = height; 
            end
            if (endLineHor-begLineHor<0)
                continue;
            end

            if (size(maxtabVer,1)>1)
                for j=1:size(maxtabVer,1)-1
                    begLineVer = maxtabVer(j);
                    endLineVer = maxtabVer(j+1)-1;  
                    if (endLineVer==width-1) 
                        endLineVer = width; 
                    end
                    if (endLineVer-begLineVer<0)
                        continue;
                    end
                    
                    allLabels = [1:nLabels];
                    otherLabels = allLabels(allLabels~=label);

                    scores = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,:),2),1);
                    score = scores(label);
                    otherScores = scores(otherLabels);
                    

                    if (score>max(otherScores))
                          outMap(begLineHor:endLineHor,begLineVer:endLineVer,label)=1;
                    else
                          outMap(begLineHor:endLineHor,begLineVer:endLineVer,label)=0;
                    end

                end
            end

        end
    end
    
   % figure;imagesc(outMap(:,:,label));
end





 
outImg = zeros(height,width);

outImg(outMap(:,:,6)==1) = 6;
outImg(outMap(:,:,5)==1) = 5;
outImg(outMap(:,:,2)==1) = 2;
outImg(outMap(:,:,7)==1) = 7;
outImg(outMap(:,:,4)==1) = 4;
outImg(outMap(:,:,1)==1) = 1;
outImg(outMap(:,:,3)==1) = 3;


maxtabHor = unique(totalHor);
maxtabVer = unique(totalVer);
outBG = zeros(height,width);
if (size(maxtabHor,1)>1)
    for i=1:size(maxtabHor,1)-1
        begLineHor = maxtabHor(i);
        endLineHor = maxtabHor(i+1)-1; 
        if (endLineHor==height-1) 
            endLineHor = height; 
        end
        if (endLineHor-begLineHor<0)
            continue;
        end

        if (size(maxtabVer,1)>1)
            for j=1:size(maxtabVer,1)-1
                begLineVer = maxtabVer(j);
                endLineVer = maxtabVer(j+1)-1;  
                if (endLineVer==width-1) 
                    endLineVer = width; 
                end
                if (endLineVer-begLineVer<0)
                    continue;
                end

                scores = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,:),2),1);
                [val,pos] = max([0 scores(2) 0 0 scores(5) scores(6) 0 0]);
                outBG(begLineHor:endLineHor,begLineVer:endLineVer)=pos; 

            end
        end

    end
end
figure;imagesc(outImg);
 
 hold on;
 for j=1:size(maxtabHor,1)
     line( [0 width], [maxtabHor(j,1) maxtabHor(j,1)]);
 end
 for j=1:size(maxtabVer,1)
     line( [maxtabVer(j,1) maxtabVer(j,1)], [0 height]);
 end
 
%figure;imagesc(outBG);
%outImg(outImg==0) = outBG(outImg==0);
% oldOutImg = outImg;
% outImg(outImg==0) = outBG(outImg==0);
% figure;imagesc(outImg);
% 
% outImg=oldOutImg;

mask = outImg==0;
[L,num] = bwlabel(mask);
for i=1:num
    comp = L==i;
    map1 = totalConfidenceMap(:,:,1); score1 = sum(map1(comp),1);
    map2 = totalConfidenceMap(:,:,2); score2 = sum(map2(comp),1);
    map3 = totalConfidenceMap(:,:,3); score3 = sum(map3(comp),1);
    map4 = totalConfidenceMap(:,:,4); score4 = sum(map4(comp),1);
    map5 = totalConfidenceMap(:,:,5); score5 = sum(map5(comp),1);
    map6 = totalConfidenceMap(:,:,6); score6 = sum(map6(comp),1);
    map7 = totalConfidenceMap(:,:,7); score7 = sum(map7(comp),1);
    map8 = totalConfidenceMap(:,:,8); score8 = sum(map8(comp),1);
    %scores = [score1 score2 score3 score4 score5 score6 score7 score8];
    scores = [0 score2 0 0 score5 score6 0 0];
    [val,pos] = max(scores);
    outImg(comp) = pos;
     
end
map1(outImg==1) = 1;map1(outImg~=1) = 0;maps(:,:,1) = map1;
map2(outImg==2) = 1;map2(outImg~=2) = 0;maps(:,:,2) = map2;
map3(outImg==3) = 1;map3(outImg~=3) = 0;maps(:,:,3) = map3;
map4(outImg==4) = 1;map4(outImg~=4) = 0;maps(:,:,4) = map4;
map5(outImg==5) = 1;map5(outImg~=5) = 0;maps(:,:,5) = map5;
map6(outImg==6) = 1;map6(outImg~=6) = 0;maps(:,:,6) = map6;
map7(outImg==7) = 1;map7(outImg~=7) = 0;maps(:,:,7) = map7;
map8(outImg==8) = 1;map8(outImg~=8) = 0;maps(:,:,8) = map8;
% 
% figure;imagesc(outImg);


   
end