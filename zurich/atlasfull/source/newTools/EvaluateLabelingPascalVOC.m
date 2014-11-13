% EVALUATELABELINGPASCALVOC Evaluates the Pascal VOC overlap criterion for
% bounding boxes of a given class in a single image 
% 
% [ tp,fp,fn  ] = EvaluateLabelingPascalVOC( ourLabeling, groundTruth, targetClass, overlapThresh )
%
% 
% Returns the number of true positives, false positives and false negatives
% for a given class and the overlap ratio threshold.
function [ tp,fp,fn ] = EvaluateLabelingPascalVOC( ourLabeling, groundTruth, targetClass, overlapThresh )

    tp = 0; fp = 0;
    if nargin~=4
        error('Usage: EvaluateLabeling( ourLabeling, groundTruth, targetClass, overlapThresh)');
    end
    
    ourCCP = bwconncomp(ourLabeling==targetClass);
    gtCCP =  bwconncomp(groundTruth==targetClass);

    ourNObjects = ourCCP.NumObjects;
    gtNObjects = gtCCP.NumObjects;

    ourRects = zeros(5,ourNObjects);
    gtRects = zeros(5,gtNObjects);
    % For each object, extract bounding box
    for i=1:ourNObjects
       objectPixels = ourCCP.PixelIdxList{i};

       [y,x] = ind2sub(size(ourLabeling),objectPixels);
       topY = min(y); topX = min(x);
       botY = max(y); botX = max(x);

       ourRects(:,i) = [topY;topX;botY;botX;0];
    end
    
    for i=1:gtNObjects
       objectPixels = gtCCP.PixelIdxList{i};

       [y,x] = ind2sub(size(ourLabeling),objectPixels);
       topY = min(y); topX = min(x);
       botY = max(y); botX = max(x);

       gtRects(:,i) = [topY;topX;botY;botX;0];
    end
    
    % For each detection
    for i=1:ourNObjects
        % Try to find a ground truth object that matches it
        for j=1:gtNObjects
           % If not already matched
           if ~gtRects(5,j)
               matched = MatchRects(ourRects(1:4,i),gtRects(1:4,j),overlapThresh);
               
               if matched
                   % Found a true positive
                   ourRects(5,i) = 1;
                   gtRects(5,j) = 1;
                   tp = tp + 1;
                   break;
               end
           end
        end
        
        if ~ourRects(5,i)
            % No GT object was found - false positive
            fp = fp + 1;
        end
    end
    
    % Unmatched GT objects are false negatives
    fn = sum(gtRects(5,:)==0);

end

% Matches two rectangles if their overlap over union area ratio exceeds the 
% given threshold
function matched = MatchRects(rect1,rect2,thresh)
    maxY = max(rect1(3),rect2(3));
    maxX = max(rect1(4),rect2(4));
    
    map = zeros(maxY,maxX);
    
    map(rect1(1):rect1(3),rect1(2):rect1(4)) = 1;
    map(rect2(1):rect2(3),rect2(2):rect2(4)) = map(rect2(1):rect2(3),rect2(2):rect2(4)) + 1;
    
    overlap = sum(sum(map==2));
    union = sum(sum(map==1)) + overlap;
    
    if (overlap/union)>thresh
        matched = 1;
    else
        matched = 0;
    end
end

