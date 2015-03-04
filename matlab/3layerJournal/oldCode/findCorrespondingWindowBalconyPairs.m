function correspondence = findCorrespondingWindowBalconyPairs(winbb, balcbb)
    correspondence = zeros(2,1);
    cc =0;

    for i=1:size(winbb,2)
        %search balcony for every window
        yw2=winbb(4,i);
        
        for j=1:size(balcbb,2)

          yb1= balcbb(2,j);  
 
          %is balcony beneath?
          ol = getOverlap(winbb(:,i), balcbb(:,j))
          if ol(1) >0
              
             %a) overlapping
             if (ol(2)>0)
                  cc = cc+1;
                  correspondence(:,cc) = [i j];
             %b) touching
             elseif abs(yw2 -yb1) < 15
                 cc = cc+1;
                 correspondence(:,cc) = [i j];
             end
          end
        end
        
        
    end


end
function ol = getOverlap(bb1, bb2)
    ol = zeros(2,1);
    xa1=bb1(1);
    xa2=bb1(3);
    ya1=bb1(2);
    ya2=bb1(4);
    
    xb1=bb2(1);
    xb2=bb2(3);
    yb1=bb2(2);
    yb2=bb2(4);

    ol(1) = min(xa2,xb2) -  max(xb1, xb1);
    ol(2) = min(ya2,yb2) -  max(yb1, yb1);
    if (xa2  <= xb1 ||  xa1>xb2)
       ol(1) = 0;
    end
    if (ya2 <=yb1 || ya1>yb2)
        ol(2) = 0;
    end
    
end




