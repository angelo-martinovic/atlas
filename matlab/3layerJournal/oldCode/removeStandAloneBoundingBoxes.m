function bbnew = removeStandAloneBoundingBoxes(bb,y1,y2)
    if (y2 ~=0)
    bb = bb(:,bb(2,:) <y2);
    end
    score =[];
    for i = 1 : size(bb,2)
        if y1 ~=0
            if bb(2,i) < y1
                score(i) =1;
                continue;
            
            end
        end
       w = round(bb(3,i)-bb(1,i));
       h = round(bb(4,i)-bb(2,i));
       if w<1 || h<1
           bbnew = removeStandAloneBoundingBoxes([bb(:,1:i-1) bb(:,i+1:end)]);
           return;
       end
   
       pt = [bb(:,1:i-1) bb(:,i+1:end)];
       score(i) =  alignmentScore(pt, bb(:,i) ,2,2)    

      
       
         
    end
    bbnew = bb(:,(score==1));
    
    
end