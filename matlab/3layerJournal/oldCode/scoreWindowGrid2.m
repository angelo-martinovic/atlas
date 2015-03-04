function error = scoreWindowGrid2(boxes, dw, dh,imgSize)

align_score = 0;
nc = 0;
maxAlignh = 1;
maxAlignv = 1;
medianAlignh = [];
medianAlignv = [];
usedBoxesh = zeros(1,size(boxes,2));
usedBoxesv = zeros(1,size(boxes,2));
allAlignh = {};
allAlignv = {};
for k=1:size(boxes,2)
    alignh = boxes(:,k);
    alignv = boxes(:,k);
    %usedBoxesv(k) = 1;
    %usedBoxesh(k) = 1;
    
    x11 = boxes(1,k);
    y11 = boxes(2,k);
    x21 = boxes(3,k);
    y21 = boxes(4,k);
    cx = x11 + (x21-x11)/2;
    cy = y11 + (y21-y11)/2;
    
    for j=1:size(boxes,2)
        x12 = boxes(1,j);
        y12 = boxes(2,j);
        x22 = boxes(3,j);
        y22 = boxes(4,j);
        if j ~=k
            
                a = tukey(x11-x12, dw);
                b = tukey(y11-y12, dh);
                c = tukey(x21-x22, dw);
                d = tukey(y21-y22, dh);
                if (a+c) ==-2 && usedBoxesv(j) ==0 
                    alignv(:,end+1) = boxes(:,j);
                    usedBoxesv(j) =1;
                    usedBoxesv(k) =1;
                end
                if (b+d) ==-2 && usedBoxesh(j) ==0
                    alignh(:, end+1) = boxes(:,j);
                    usedBoxesh(j) =1;
                    usedBoxesh(k) =1;
                end
                
                
         
        end
    end
    
    if size(alignh,2) >1
        allAlignh{size(allAlignh,2)+1} = alignh;
    end
    if size(alignv,2) >1
        allAlignv{size(allAlignv,2)+1} = alignv;
    end
      
end
notUsedV = boxes(:,~usedBoxesv);
notUsedH = boxes(:,~usedBoxesh);
if ~isempty(notUsedV)
    for cc=1:size(notUsedV,2)
        allAlignv{size(allAlignv,2)+1} = notUsedV(:,cc);
    end
end
if ~isempty(notUsedH)
    for cc=1:size(notUsedH,2)
        allAlignh{size(allAlignh,2)+1} = notUsedH(:,cc);
    end
end

error = 0;
for i=1:size(allAlignh,2)
    match = false;
    for j=1:size(allAlignh,2)
        if i~=j
            [error1, matchit] = matchLines(allAlignh{i}, allAlignh{j});
            error = error + error1;%/size(allAlignh,2);
            match = match || matchit; 
        end
    end
    if ~match
        error = error +1;
    end
    
end
for i=1:size(allAlignv,2)
    match = false;
    for j=1:size(allAlignv,2)
        if i~=j 
            [error1, matchit] =matchRows(allAlignv{i}, allAlignv{j});
            error = error + error1;%/size(allAlignv,2);
            match = match || matchit; 
        end
    end
    if ~match
        error = error +1;
    end
    
end
% for i=1:size(allAlignv,2)
%     for j=1:size(allAlignv,2)
%         error = error + matchLines(allAlignh{i}, allAlignh{j})
%     end
%     
% end



end