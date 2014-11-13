%BboxMap is a mask that needs to be filled exactly.
%Difference map is a mask that states which part of bbox is already filled.
%nextElements list are candidates for filling. Those already selected must
%be discarded. 
%End result is a vector with the same length as nextElements. If no filling
%is found, it is a zero vector. Otherwise, segments selected for filling
%are marked with '1'
function indices = findExactFilling(remainingMap,nextElements)


height = size(remainingMap,1);
width = size(remainingMap,2);

indices = zeros(1,size(nextElements,1));
for i=1:size(nextElements,1)
    if nextElements{i,3}==0
          rect = cell2mat(nextElements(i,1));
          mask = zeros(height,width);
          mask(rect(2):rect(4),rect(1):rect(3)) = 1;
          
          diff = remainingMap - mask;
          notFitting = sum(sum(diff==-1));
          if (notFitting == 0)
              remainingMap = diff;
              indices(i) = 1;
          end
    end
end

if sum(sum(remainingMap))~=0
    indices = zeros(1,size(nextElements,1));
   
end