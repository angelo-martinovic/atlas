function score = scoreWindowGrid3(boxes, dw, dh,imgSize)
% if false
%[x1,y1, x2,y2, classidx, score];
    locationLUT = zeros(imgSize);
    boxes = round(boxes);
    
    objID=0;
    for k=1:size(boxes,2)
              
               topY =boxes(2,k); topX =boxes(1,k);
               botY =boxes(4,k); botX = boxes(3,k);

               objID = objID+1;
               if (botX - topX) < imgSize(2)/2
                locationLUT(topY:botY,topX:botX)=objID;

               end
    end
    
      
    
    n_count = 0;
    jumpvtop = zeros(1,size(boxes,2));
    jumpvbottom = zeros(1,size(boxes,2));
    jumphtop = zeros(1,size(boxes,2));
    jumphbottom = zeros(1,size(boxes,2));
    
    indexvtop = zeros(1,size(boxes,2));
    indexvbottom = zeros(1,size(boxes,2));
    indexhtop = zeros(1,size(boxes,2));
    indexhbottom = zeros(1,size(boxes,2));
    for  k=1:size(boxes,2)
            topY =boxes(2,k); topX =boxes(1,k);
            botY =boxes(4,k); botX = boxes(3,k);

            objCenterX = round((topX+botX)/2);
            objCenterY = round((topY+botY)/2);
            if objCenterX -dw < 1 || objCenterX+dw > imgSize(2)
                continue;
            end
            % Extract column above object
            column = locationLUT(1:topY-1,objCenterX-dw:objCenterX+dw);
            % Find lowest non-zero
            [yC,xC] = find(column);
            [~,index] = max(yC);
            if ~isempty(index)
                neighIndex = column( yC(index),xC(index) );
                topX2 =boxes(1,neighIndex);
                botX2 = boxes(3,neighIndex);
                topY2 =boxes(2,neighIndex);
                botY2 = boxes(4,neighIndex);
                align_score = 0;
                align_score = align_score + tukey(topX-topX2, dw);
                align_score = align_score + tukey(botX-botX2, dw);
%                 thisObjCenterX = round((topX2+botX2)/2);
                thisObjCenterY = round((topY2+botY2)/2);
                if align_score == -2 
                    jumpvtop(k) = abs(thisObjCenterY - objCenterY);
                    indexvtop(k) = neighIndex;

                else
                   jumpvtop(k) = 0; 
                end
                
            else
                %jumpvtop(k) = objCenterY;
                jumpvtop(k) = 0;
            end
            
            % Extract column under object
            column = locationLUT(botY+1:end,objCenterX-dw:objCenterX+dw);
            % Find highest non-zero
            [yC,xC] = find(column);
            [~,index] = min(yC);
            if ~isempty(index)
                neighIndex = column( yC(index),xC(index) );
            
                topX2 =boxes(1,neighIndex);
                botX2 = boxes(3,neighIndex);
                topY2 =boxes(2,neighIndex);
                botY2 = boxes(4,neighIndex);
                align_score = 0;
                align_score = align_score + tukey(topX-topX2, dw);
                align_score = align_score + tukey(botX-botX2, dw);
   
%                 thisObjCenterX = round((topX2+botX2)/2);
                thisObjCenterY = round((topY2+botY2)/2);
                if align_score == -2
                    jumpvbottom(k) = abs(thisObjCenterY - objCenterY);
                    indexvbottom(k) = neighIndex;
                else
                   jumpvbottom(k) = 0; 
                end
                
                
            else
                %jumpvbottom(k) = imgSize(1) - objCenterY;
                jumpvbottom(k) = 0;
            end
            
            
            
            % Extract row left of object
            row = locationLUT(objCenterY-dh:objCenterY+dh,1:topX-1);
            % Find rightest non-zero
            [yC,xC] = find(row);
            [~,index] = max(xC);
            if ~isempty(index)
                neighIndex = row( yC(index),xC(index) );
                            
                topX2 =boxes(1,neighIndex);
                botX2 = boxes(3,neighIndex);
                topY2 =boxes(2,neighIndex);
                botY2 = boxes(4,neighIndex);
               align_score = 0;
                align_score = align_score + tukey(topY-topY2, dh);
                align_score = align_score + tukey(botY-botY2, dh);
  
                thisObjCenterX = round((topX2+botX2)/2);
%                 thisObjCenterY = round((topY2+botY2)/2);
                if align_score == -2 
                    jumphtop(k) = abs(thisObjCenterX - objCenterX);
                    indexhtop(k) = neighIndex;
                else
                   jumphtop(k)  = 0; 
                end
                
                
            else
                %jumphtop(k) = objCenterX;
                jumphtop(k) = 0;
            end
            
            % Extract row right of object
            row = locationLUT(objCenterY-dh:objCenterY+dh,botX+1:end);
            % Find leftest non-zero
            [yC,xC] = find(row);
            [~,index] = min(xC);
            if ~isempty(index)
                neighIndex = row( yC(index),xC(index) );
                
                topX2 =boxes(1,neighIndex);
                botX2 = boxes(3,neighIndex);
                topY2 =boxes(2,neighIndex);
                botY2 = boxes(4,neighIndex);
               align_score = 0;
                align_score = align_score + tukey(topY-topY2, dh);
                align_score = align_score + tukey(botY-botY2, dh);

                thisObjCenterX = round((topX2+botX2)/2);
%                 thisObjCenterY = round((topY2+botY2)/2);
                if align_score == -2 
                   jumphbottom(k) = abs(thisObjCenterX - objCenterX);
                   indexhbottom(k) = neighIndex;
                else
                   jumphbottom(k)= 0; 
                end
                
                
                            
            else
                %jumphbottom(k) = imgSize(2)-   objCenterX;
                jumphbottom(k) = 0;
            end
        
    end
    jumpvall = [jumpvbottom jumpvtop];
    jumpvall = jumpvall(jumpvall>0);
    normv = median(jumpvall);
    jumphall = [jumphbottom jumphtop];
    jumphall = jumphall(jumphall>0);
    normh = median(jumphall);

    penalizeH = 0;
    penalizeV = 0;
    for  k=1:size(boxes,2)
        
        if indexvtop(k) ~=0
           penalizeH = penalizeH + abs(jumphbottom(k) - jumphbottom(indexvtop(k)))/normh + abs(jumphtop(k)- jumphtop(indexvtop(k)))/normh;
%         else
%             penalizeH  = penalizeH + 2*normh;
        end
        if indexvbottom(k) ~=0
           penalizeH = penalizeH + abs(jumphbottom(k) - jumphbottom(indexvbottom(k)))/normh + abs(jumphtop(k)- jumphtop(indexvbottom(k)))/normh;
%         else
%             penalizeH  = penalizeH + 2*normh;
        end
        if indexhtop(k) ~=0
            penalizeV = penalizeV + abs(jumpvbottom(k) - jumpvbottom(indexhtop(k)))/normv + abs(jumpvtop(k)- jumpvtop(indexhtop(k)))/normv;
%         else
%             penalizeV  = penalizeV + 2*normv;
        end
        if indexhbottom(k) ~=0
            penalizeV = penalizeV + abs(jumpvbottom(k) - jumpvbottom(indexhbottom(k)))/normv + abs(jumpvtop(k)- jumpvtop(indexhbottom(k)))/normv;
%         else
%             penalizeV  = penalizeV + 2*normv;
        end
    end
    
    
   
   score = penalizeH + penalizeV;
    
end