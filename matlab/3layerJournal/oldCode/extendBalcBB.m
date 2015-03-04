function balcbb = extendBalcBB(boundingBoxes_win, boundingBoxes_balc, balc_ddh)

    winbb = boundingBoxes_win;%(:,classidx==1);
    balcbb =  boundingBoxes_balc; %(:,classidx==3);
 
     
    for i = 1 : size(balcbb,2)
        
        for j = 1 : size(winbb,2)
            
            w1 = balcbb(3,i)-balcbb(1,i);
            w2 = winbb(3,j)-winbb(1,j);
            
            ol = getOverlap(balcbb(:,i), winbb(:,j));
            if ol(1)>0 
                if ol(2) >0 || (abs(balcbb(2,i) - winbb(4,j)) < balc_ddh)
                      %center balcony
                   
                      if w2>w1
                          balcbb(1,i) = winbb(1,j);
                          balcbb(3,i) = winbb(3,j);
                      end
                      if ol(2) > 0 && balcbb(2,i) > winbb(2,j) && balcbb(4,i) < winbb(4,j)
                         %offset to move down
                         d = winbb(4,j) - balcbb(4,i);
                         balcbb(2,i) = balcbb(2,i) + d;
                         balcbb(4,i) = balcbb(4,i) + d;
                         
                      end
                end
          
            end
        end

    end
    
end

