
function differenceMap = checkRectangularity(height, width, windowList,indexof)

segmentMap = zeros(height,width);
bboxMap = zeros(height,width);

firstElementMap = zeros(height,width);
%Select the last added rectangle
rect = cell2mat(windowList(indexof));

segmentMap(rect(2):rect(4),rect(1):rect(3)) = 1;
firstElementMap(rect(2):rect(4),rect(1):rect(3)) = 1; 

for i=1:size(windowList,1)
    rect = cell2mat(windowList(i));

    segmentMap(rect(2):rect(4),rect(1):rect(3)) = 1;
end

%imagesc(segmentMap);
differenceMap = zeros(height,width);
   
[L,num] = bwlabel(segmentMap);
for i=1:num
    comp = L==i;
    overlap = comp & firstElementMap;
    if (sum(sum(overlap))>0)
        [y,x] = find (comp==1);
        minX = min(x); maxX = max(x);
        minY = min(y); maxY = max(y);
        bboxMap(minY:maxY,minX:maxX) = 1;
        differenceMap = (bboxMap ~= comp);  
    end
     
end
    


end