function finalSegRelabeled = findDoor(probMap,finalSeg,threshold)
finalSegRelabeled = finalSeg;

H = size(probMap,1);
W = size(probMap,2);

doorW = 37;
doorH = 84;

hW = 19;
hH = 42;

y = H-hH;


bestScore = 0;
bestPos = 0;
for x = hW+1:1:W-hW
    score = sum(sum(probMap(y-hH:y+hH, x-hW:x+hW)));
    if score>bestScore
        bestScore = score;
        bestPos = x;
    end
end

foundDoor = zeros(H,W);
foundDoor(y-hH:y+hH, bestPos-hW:bestPos+hW) = 1;

originalDoor = finalSeg == 4;

overlap = sum(sum(originalDoor & foundDoor))/(84*37);
disp(['Best score is ' num2str(bestScore/(84*37))]);
if (overlap<threshold)
    finalSegRelabeled(y-hH:y+hH, bestPos-hW:bestPos+hW) = 4;
end

end