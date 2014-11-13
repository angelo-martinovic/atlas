function bgMap = analyzeStructure(X)

load ('mapFinal.mat');

rnnMap = segMap;
segMap = mapFinal;

height = size(segMap,1);
width = size(segMap,2);
Ylines = find(verSet~=0);
Xlines = find(horSet~=0);

numGridElemY = size(Ylines,2)-1;
numGridElemX = size(Xlines,2)-1;

gridSize = numGridElemY*numGridElemX;
segmentMask = getSegmentMask(Ylines,Xlines);
% ---------------------------------------------------
% ------------------------ WINDOWS ------------------
% ---------------------------------------------------
window = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{},'pixelCount',{},'indices',{});
[mask,num] = bwlabel(segMap==1);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    window(i).width = maxX-minX+1;
    window(i).height = maxY-minY+1;
    window(i).centerX = minX+ window(i).width/2;
    window(i).centerY = minY+ window(i).height/2;
    window(i).pixels = [y x];
    window(i).pixelCount = size(window(i).pixels,1);
    window(i).indices = unique(segmentMask(comp==1));
end

% figure;hist([windows.centerX]);
% figure;hist([windows.centerY]);
% median([windows.width])
% ---------------------------------------------------
% ------------------------ WALL ----------------
% ---------------------------------------------------
wall = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{},'indices',{});
[mask,num] = bwlabel(segMap==2);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    wall(i).width = maxX-minX+1;
    wall(i).height = maxY-minY+1;
    wall(i).centerX = minX+ wall(i).width/2;
    wall(i).centerY = minY+ wall(i).height/2;
    wall(i).pixels = [y x];
    wall(i).indices = unique(segmentMask(comp==1));
end
% ---------------------------------------------------
% ------------------------ BALCONIES ----------------
% ---------------------------------------------------
balcony = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{});
[mask,num] = bwlabel(segMap==3);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    balcony(i).width = maxX-minX+1;
    balcony(i).height = maxY-minY+1;
    balcony(i).centerX = minX+ balcony(i).width/2;
    balcony(i).centerY = minY+ balcony(i).height/2;
    balcony(i).pixels = [y x];
    balcony(i).indices = unique(segmentMask(comp==1));
end

% figure;bar([balconies.centerX]);
% figure;bar([balconies.centerY]);
% figure;bar([balconies.width]);
% figure;bar([balconies.height]);
% ---------------------------------------------------
% ------------------------ DOOR ----------------
% ---------------------------------------------------
door = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{});
[mask,num] = bwlabel(segMap==4);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    door(i).width = maxX-minX+1;
    door(i).height = maxY-minY+1;
    door(i).centerX = minX+ door(i).width/2;
    door(i).centerY = minY+ door(i).height/2;
    door(i).pixels = [y x];
    door(i).indices = unique(segmentMask(comp==1));
end

% ---------------------------------------------------
% ------------------------ ROOF ----------------
% ---------------------------------------------------
roof = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{});
[mask,num] = bwlabel(segMap==5);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    roof(i).width = maxX-minX+1;
    roof(i).height = maxY-minY+1;
    roof(i).centerX = minX+ roof(i).width/2;
    roof(i).centerY = minY+ roof(i).height/2;
    roof(i).pixels = [y x];
    roof(i).indices = unique(segmentMask(comp==1));
end
% ---------------------------------------------------
% ------------------------ SKY ----------------
% ---------------------------------------------------
sky = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{});
[mask,num] = bwlabel(segMap==6);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    sky(i).width = maxX-minX+1;
    sky(i).height = maxY-minY+1;
    sky(i).centerX = minX+ sky(i).width/2;
    sky(i).centerY = minY+ sky(i).height/2;
    sky(i).pixels = [y x];
    sky(i).indices = unique(segmentMask(comp==1));
end

% ---------------------------------------------------
% ------------------------ SHOP ----------------
% ---------------------------------------------------
shop = struct('width',[],'height',[],'centerX',[],'centerY',[],'pixels',{});
[mask,num] = bwlabel(segMap==7);
for i=1:num
    comp = mask==i;
    
    [y,x] = find (comp==1);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    
    if (maxX-minX+1<5 || maxY-minY+1<5)
        continue;
    end
    
    shop(i).width = maxX-minX+1;
    shop(i).height = maxY-minY+1;
    shop(i).centerX = minX+ shop(i).width/2;
    shop(i).centerY = minY+ shop(i).height/2;
    shop(i).pixels = [y x];
    shop(i).indices = unique(segmentMask(comp==1));
end

% ---------------------------------------------------
% ------------------------ CHIMNEYS ----------------
% ---------------------------------------------------
% - SKIPPED FOR NOW --

% ---------------------------------------------------
% ----------------HAUSSMANN ANALYSIS ----------------
% ---------------------------------------------------

% 10. Y-ordering: shop-wall-roof-sky
if (size([sky.centerY],2)==0)
    disp('No sky.');
end
if (size([roof.centerY],2)==0)
    disp('No roof.');
end
if (size([wall.centerY],2)==0)
    disp('No wall.');
end
if (size([shop.centerY],2)==0)
    disp('No shop.');
end
if (max([sky.centerY]) > min ([roof.centerY]))
    disp('Sky-roof ordering violated.');
end
if (max([roof.centerY]) > min ([wall.centerY]))
    disp('Roof-wall ordering violated.');
end
if (max([wall.centerY]) > min ([shop.centerY]))
    disp('Wall-shop ordering violated.');
end

skySize =  sum(sum(segMap(:,:)==6));
for i=1:numGridElemX-1
    pos=Xlines(i+1);
    ratio=sum(sum(segMap(1:pos,:)==6))/skySize;
    if ratio>0.95
        break;
    end
end
bSkyRoof = pos;

roofSize =  sum(sum(segMap(:,:)==5));
for i=1:numGridElemX-1
    pos=Xlines(i+1);
    ratio=sum(sum(segMap(1:pos,:)==5))/roofSize;
    if ratio>0.95
        break;
    end
end
bRoofWall = pos;

wallSize =  sum(sum(segMap(:,:)==2));
for i=1:numGridElemX-1
    pos=Xlines(i+1);
    ratio=sum(sum(segMap(1:pos,:)==2))/wallSize;
    if ratio>0.95
        break;
    end
end
bWallShop = pos;

% Find borders between large regions
% bSkyRoof =  round(( max([sky.centerY]+[sky.height]/2) + min([roof.centerY]-[roof.height]/2) )/2);
% bRoofWall =  round(( max([roof.centerY]+[roof.height]/2) + min([wall.centerY]-[wall.height]/2) )/2);
% bWallShop =  round(( max([wall.centerY]+[wall.height]/2) + min([shop.centerY]-[shop.height]/2) )/2);

bgMap = zeros(height,width);
bgMap(1:bSkyRoof,:)=6;
bgMap(bSkyRoof:bRoofWall,:)=5;
bgMap(bRoofWall:bWallShop,:)=2;
bgMap(bWallShop:end,:)=7;
%figure;imagesc(bgMap);
% 1. Window size distribution

disp (['Standard deviation in window width: ' num2str(std([window.width]))]);
disp (['Standard deviation in window height: ' num2str(std([window.height]))]);

% 1.5 Window rectangularity
bboxSizes = [window.width].*[window.height];
pixelSizes = [window.pixelCount];
disp(['Number of non rectangular windows: ' num2str(sum((bboxSizes-pixelSizes)~=0))]);

Erectangularity = sum(sum(bboxSizes-pixelSizes));

Eregularity = 0.0;
nonRegularWindows = zeros(size(window,2),1);
for i=1:size(window,2)
    if (window(i).width*window(i).height~=window(i).pixelCount)
        nonRegularWindows(i)=1;
        
    elseif (abs(window(i).width-median([window.width])) > median([window.width]))
        nonRegularWindows(i)=1;
        Eregularity = Eregularity + abs(window(i).width-median([window.width]));
        
    elseif (abs(window(i).height-median([window.height])) > median([window.height]))
        nonRegularWindows(i)=1;
        Eregularity = Eregularity + abs(window(i).height-median([window.height]));
    end
    
end
% 2. Window grid

%Creating a horizontal and  vertical histogram of windows
horHist = sum((segMap==1 & bgMap==2),2);
verHist = sum((segMap==1 & bgMap==2),1)';
horHist = [0;horHist;0];
verHist = [0;verHist;0];

%Smooth the histograms with a gaussian filter
% horHist = smooth(horHist);
% verHist = smooth(verHist);


%Maximum value to 1
horHist = horHist/max(horHist);
verHist = verHist/max(verHist);


%Detections of peaks in the histograms
[maxtabHor,~] = peakdet(horHist,0.15);%0.1*median(horHist)); %hyperParams
[maxtabVer,~] = peakdet(verHist,0.1);%0.1*median(verHist));

windowRowsCnt = size(maxtabHor,1);
windowColumnsCnt = size(maxtabVer,1);

%Visualize the peaks
% figure; bar(horHist);hold on;plot(maxtabHor(:,1), maxtabHor(:,2), 'r*');
% figure; bar(verHist);hold on;plot(maxtabVer(:,1), maxtabVer(:,2), 'r*');

windowRowsStart = zeros(windowRowsCnt,1);windowRowsEnd = zeros(windowRowsCnt,1);
windowColumnsStart = zeros(windowColumnsCnt,1);windowColumnsEnd = zeros(windowColumnsCnt,1);

thresh = 0.5;
for i=1:size(maxtabHor,1)
    pos = maxtabHor(i,1);
    score = maxtabHor(i,2);
    for j=pos:height
        if horHist(j)<thresh*score
            break;
        end
    end
    for k=pos:-1:1
        if horHist(k)<thresh*score
            break;
        end
    end
    windowRowsStart(i) = k+1;
    windowRowsEnd(i) = j-1;
end
for i=1:size(maxtabVer,1)
    pos = maxtabVer(i,1);
    score = maxtabVer(i,2);
    for j=pos:width
        if verHist(j)<thresh*score
            break;
        end
    end
    for k=pos:-1:1
        if verHist(k)<thresh*score
            break;
        end
    end
    windowColumnsStart(i) = k+1;
    windowColumnsEnd(i) = j-1;
end


mask = zeros(height,width);

for i=1:windowRowsCnt
    for j=1:windowColumnsCnt
        posStartY = windowRowsStart(i);
        posStartX= windowColumnsStart(j);
        posEndY = windowRowsEnd(i)-1;
        posEndX= windowColumnsEnd(j)-1;
        
        mask(posStartY:posEndY,posStartX:posEndX)=1;
    end
end

windowSegments = unique(segmentMask(mask==1));
wmap = zeros(height,width);

for i=1:size(windowSegments,1)
    wmap(segmentMask==windowSegments(i))=1;
end

wmap(segMap==1 & bgMap==5) = 1;


% 3. Balcony stripes

%Creating a horizontal histogram 
horHist = sum((segMap==3 & bgMap==2),2);
horHist = [0;horHist;0];
horHist = horHist/max(horHist);

%Detections of peaks in the histograms
[maxtabHor,~] = peakdet(horHist,0.1);%0.1*median(horHist)); %hyperParams
balconyRowsCnt = size(maxtabHor,1);


%Visualize the peaks
%figure; bar(horHist);hold on;plot(maxtabHor(:,1), maxtabHor(:,2), 'r*');

balconyRowsStart = zeros(balconyRowsCnt,1);
balconyRowsEnd = zeros(balconyRowsCnt,1);

thresh = 0.5;
for i=1:size(maxtabHor,1)
    pos = maxtabHor(i,1);
    score = maxtabHor(i,2);
    for j=pos:height
        if horHist(j)<thresh*score
            break;
        end
    end
    for k=pos:-1:1
        if horHist(k)<thresh*score
            break;
        end
    end
    balconyRowsStart(i) = k+1;
    balconyRowsEnd(i) = j-1;
end

mask = zeros(height,width);

for i=1:balconyRowsCnt
        posStartY = balconyRowsStart(i);
        posEndY = balconyRowsEnd(i)-1;
        mask(posStartY:posEndY,1:end)=1;
end

affectedSegments = unique(segmentMask(mask==1));
allowedBalconyPositions = zeros(height,width);

for i=1:size(affectedSegments,1)
    allowedBalconyPositions(segmentMask==affectedSegments(i))=1;
end

bmap = zeros(height,width);
bmap(allowedBalconyPositions==1 & segMap==3 ) = 1;

newBalconies = zeros(height,width);
candidateBalconies = (allowedBalconyPositions==1 & segMap~=3);
segments = unique(segmentMask(candidateBalconies==1));
for i=1:size(segments,1)
    winScore=0.0;
    %Check if there's a window above
    upperSegment = getGridIndex(segments(i),'top',numGridElemY,numGridElemX);
    if (ismember(upperSegment,windowSegments))
        winScore=1.0;
    end
    
    rowScore = 0.0;
    %Check for the rest of the row
    [y,x]=find(segmentMask==segments(i));
    minY = min(y); maxY = max(y);
    minX = min(x); maxX = max(x);
    rowScore = rowScore + sum(sum(bmap(minY:maxY,1:end))) / (width*(maxY-minY+1));
    
    rnnScore = 0.0;
    %Check for RNN score
    balconyRNNmap = rnnMap(:,:,3);
    rnnScore = rnnScore + sum(sum(balconyRNNmap(segmentMask==segments(i))))/ ((maxX-minX+1)*(maxY-minY+1));
    
    if (winScore >0 || rowScore + rnnScore > 1)
        newBalconies(segmentMask==segments(i)) = 1;
    end
end

bmap(newBalconies==1) = 1;

%figure;imagesc(wmap);

bgMap(wmap==1) = 1;
bgMap(bmap==1) = 3;
bgMap(segMap==4) = 4;
%figure; imagesc(bgMap);





    

