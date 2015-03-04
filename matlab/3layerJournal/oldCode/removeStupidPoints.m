function pnew = removeStupidPoints(p, PM, ddw, ddh)
    
    for i = 1 : size(p,2)
       w = round(p(3,i)-p(1,i));
       h = round(p(4,i)-p(2,i));
       if w<1 || h<1
           pnew = removeStupidPoints([p(:,1:i-1) p(:,i+1:end)],PM,ddw,ddh);
           return;
       end
   
        for j =1 : size(p,2)
            if i==j
                continue;
            end


            if(distanceQuality2(p(:,i), p(:,j)))%,ddw, ddh))
                pt = [p(:,1:i-1) p(:,i+1:end)];
                pt2 = [p(:,1:j-1) p(:,j+1:end)];
                e1 = objfun3(pt,PM, ddw,ddh);
                e2 = objfun3(pt2,PM,ddw, ddh);
                if e1 > e2
                    pnew = removeStupidPoints(pt2,PM,ddw,ddh);
                    return;
                else
                    pnew = removeStupidPoints(pt,PM,ddw,ddh);
                    return;
                end
       
            end
       
        end   
    end
    pnew = p;
    
    
end

function e = distanceQuality(p1,p2, ddw, ddh)

    x1 = p1(1);
    y1 = p1(2);
    w1 = p1(3) -x1;
    h1 = p1(4) - y1;
    cx1 = x1+w1/2;
    cy1 = y1+h1/2;
    
    x2 = p2(1);
    y2 = p2(2);
    w2 = p2(3) -x2;
    h2 = p2(4) - y2;
    cx2 = x2+w2/2;
    cy2 = y2+h2/2;
    e = false;
    if (abs(cx1 - cx2) < ddw) && abs(cy2 -cy1) < ddh
        e = true
        
    end
    

end



function e = distanceQuality2(p1,p2)

    x1 = p1(1);
    y1 = p1(2);
    w1 = p1(3) -x1;
    h1 = p1(4) - y1;
    
    x2 = p2(1);
    y2 = p2(2);
    w2 = p2(3) -x2;
    h2 = p2(4) - y2;
    e = false;
    
    
     mt = max(y1, y2);
     mb = min(y1+h1, y2+h2);
     ml = max(x1, x2);
     mr = min(x1+w1, x2+w2);
        
       if (mb-mt) > 0
           if (abs(x1+w1 - x2) < 0.2 * max(w1,w2)) || (abs(x2+w2 - x1) < 0.2 * max(w1,w2))
            e = true;
           end
            
        end
         
       
       if (mr -ml) > 0
          if (abs(y1+h1 - y2) < 0.2 * max(h1,h2)) || (abs(y2+h2 - y1) < 0.2 * max(h1,h2))
            e = true;
            
           end
       end
       if (mb-mt>0) && (mr -ml) > 0
           e = true;
       end
    
    

end
