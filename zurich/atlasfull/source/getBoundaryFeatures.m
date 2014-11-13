function penalty = getBoundaryFeatures(segMask, seg1, seg2)


mask1 = double(segMask==seg1);
mask2 = double(segMask==seg2);

SE = strel('diamond',1);
%SE = strel('square',3);

expanded1 = imdilate(mask1,SE);
difference = logical(expanded1-mask1);

boundaryPoints = difference & mask2;
changes=0;
steps=0;
while 1
    [r,c] = find(boundaryPoints==1);
    if size(r,1)<2
        break;
    end

    contour = bwtraceboundary(boundaryPoints, [r(1), c(1)], 'W', 8, Inf,'counterclockwise');

    if size(contour,1)<3
        break;
    end

    direction = [contour(2,1)-contour(1,1) contour(2,2)-contour(1,2)];
 
    boundaryPoints(contour(1,1),contour(1,2))=0;
    boundaryPoints(contour(2,1),contour(2,2))=0;
    steps = steps+1;
    for i=3:size(contour,1)
        newDirection=[contour(i,1)-contour(i-1,1) contour(i,2)-contour(i-1,2)];
        if ~isequal(newDirection,direction)
            changes = changes + 1;
            direction = newDirection;
        end
        boundaryPoints(contour(i,1),contour(i,2))=0;
        steps = steps+1;
    end
end
if steps==0
    penalty = 0;
    return;
end
penalty = changes/steps;




