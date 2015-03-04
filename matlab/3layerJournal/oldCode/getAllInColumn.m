function out = getAllInColumn(bb, qbb, overlap)
xa1= qbb(1);
xa2= qbb(3);
ya1= qbb(2);  
ya2= qbb(4);
out = [];
cc=0;
    
 for i=1:size(bb,2)
        %search balcony for every window
        xb1=bb(1,i);
        xb2=bb(3,i);
        yb1=bb(2,i);
        yb2=bb(4,i);
        if min(xa2,xb2) - max(xa1, xb1)>0
           if  (min(xa2,xb2) - max(xa1, xb1))/(xa2-xa1) > overlap
               cc = cc+1;
               out(cc) =i;
           end
        end
 end

end