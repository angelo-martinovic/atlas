function e = objfunJoint2(boundingBoxes_win, boundingBoxes_balc, classidx, PM_win, PM_balc, win_ddw, win_ddh, balc_ddw, balc_ddh)

    winbb = boundingBoxes_win;%(:,classidx==1);
    balcbb =  boundingBoxes_balc; %(:,classidx==3);
    
    e0 = objfunBalcony(boundingBoxes_balc, PM_balc, win_ddw, balc_ddh);
 
    
    maxpaircount = 0;
 
     maxval = 0;
     %win_ddw = 1;
     e1 =0;
     
    for i = 1 : size(balcbb,2)
        
        balconywidth = balcbb(3,i) - balcbb(1,i);
        balconycenterx = balcbb(1,i) + 0.5* balconywidth;
        
        balconyy = balcbb(2,i) ;
        
        for j = 1 : size(winbb,2)
            
            w1 = balcbb(3,i)-balcbb(1,i);
            w2 = winbb(3,j)-winbb(1,j);
            cp1 = balcbb(1,i) + w1/2; 
            cp2 = winbb(1,j) + w2/2;
            
      
             maxval = maxval +tukey(w2+1, w2) ;
            
            
            
            ol = getOverlap(balcbb(:,i), winbb(:,j));
            if ol(1)>0 
                if ol(2) >0 || (abs(balcbb(2,i) - winbb(4,j)) < balc_ddh)
                      %center balcony
                   
                      if w2>w1
                          balcbb(:,1)
                          e1 = e1 + tukey(w2-w1, w2);
                      else
                          e1 = e1 + tukey(w2+1, w2);
                      end
                else
                  
                    e1 = e1 + tukey(w2+1, w2);
                end
            else
                
                  e1 = e1 + tukey(w2+1, w2);
            end
            
            
           %
            
            
           
        end

        
       
    end
    e1 = e1/maxval;
   
    e = 1*e1
end

function e = weightWidths2(d1, d2, w1,w2, dd)
    if d1>d2
        e = tukey(dd+1, dd); %tukey(4001,400);     
    else
       e = tukey(w1-w2, dd); % exp(0.1*abs(w1-w2));%:
    end


end
