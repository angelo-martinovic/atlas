
function p = updateBBBasedOnPM(p, PM,ddw, ddh)
    
    
    for i = 1 : size(p,2)
       %fix top and bottom
       x=p(1,i);
       y=p(2,i);
       w=p(3,i)-p(1,i);
       h=p(4,i)-p(2,i);
       maxe  = -inf;
       ypos = y;
       hpos = h;
       x+w
       for yy=y-h/2:y+h/2
           e = sum(sum(PM(round(yy):round(yy),round(x):round(x+w))));
           if e>maxe
              ypos = yy;
              maxe = e;
           end
       end
       maxe  = -inf;
      
       for hh=h/2:1.5*h
           pos = round(y+hh);
            if (pos <= ypos+3)
                continue;
            end
            
            e = sum(sum(PM(pos:pos,round(x):round(x+w))));
           
           if e>maxe
              hpos = hh; 
              maxe = e;
           end
       end
        
       p(2,i) =ypos;
       p(4,i) =y+hpos;
        
    end
    
    
    
end



function energy = getPD(x,y,w,h,PM,dd)

    if isnan(x) || isnan(y) || isnan(w) || isnan(y) || w*h==0 || x<1 || y<1
        energy =20;%tukey(dd+1, dd); 
        return;
    end
    if (y+h > size(PM,1)) || x+w > size(PM,2)
        energy =20;% tukey(dd+1, dd); 
    else
        energy =1-sum(sum(PM(round(y):round(y+h),round(x):round(x+w))))/round(w*h);
       
    end
end