%posNew is a vector [upperLeftCorner X, upperLeftCorner Y,bottomRightCorner X, bottomRightCornerY]
%detections is N*5 matrix, each row is [Xpos,Ypos,width,height]
%Returns a score from 0 to maxScore
function reward = calculateDetectionReward(posNew,detections)

lambdaOverlap = 1.0;  % Weighs the reward depending on the overlap between the segment and the detection
lambdaScore = 0.0;    % Weighs the reward depending on the score of the detection
maxScore = 1000;         % Rescales the result to [0,maxScore]

reward = 0;
numDetections = size(detections,1);
if numDetections<1
    return;
end

for i=1:numDetections
    posRect = [posNew(1) posNew(2) posNew(3)-posNew(1) posNew(4)-posNew(2)];    %Segment bounding box rectangle
    detectionRect = detections(i,1:4);  %Detection bounding box rectangle
    detectionScore = detections(i,5);   %Score of the detection
    
    intersectionArea = rectint(posRect,detectionRect);  %Intersection of the two areas
    if (intersectionArea == 0) 
        continue;
    end
    unionArea = detectionRect(3)*detectionRect(4) +posRect(3)*posRect(4);
    
    %Part of the detection that was covered
    overlap = intersectionArea/unionArea;
    
    %Calculate the weighted reward
    tempReward = maxScore * (lambdaOverlap * overlap + lambdaScore * detectionScore);
    %Remember the maximum score
    if (tempReward>reward)
        reward = tempReward;
    end
 
end
%disp(['Maximum reward is ' num2str(reward)]);

end