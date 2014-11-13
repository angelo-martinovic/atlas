% Returns an image-sized map with the indices of segments
function segmentMask = getSegmentMask(gridX,gridY)

numGridElemX = size(gridX,2)-1;
numGridElemY = size(gridY,2)-1;

width = gridX(end);
height = gridY(end);

segmentMask = zeros(height,width);
index=0;
for i=1:numGridElemY
    begLineY = gridY(i);
    endLineY = gridY(i+1)-1;
    if i==numGridElemY
        endLineY = gridY(i+1);
    end
   
    for j=1:numGridElemX
        begLineX = gridX(j);
        endLineX = gridX(j+1)-1;
        if j==numGridElemX
            endLineX = gridX(j+1);
        end
   
        index=index+1;
        
        segmentMask(begLineY:endLineY,begLineX:endLineX) = index;
    end
end
