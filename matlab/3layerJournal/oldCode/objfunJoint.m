function e = objfunJoint(boundingBoxes, classidx, PM_win, PM_balc, win_ddw, win_ddh, balc_ddw, balc_ddh)

    winbb = boundingBoxes(:,classidx==1);
    balcbb =  boundingBoxes(:,classidx==3);
    
    %WINDOWS
    e1win = 0;
    e2win = 0;
    %dd = 35;
   
    
    maxpaircount_win = 0;
    for i = 1 : size(winbb,2)
        paircount_win = 0;
        for j = i + 1 : size(winbb,2)
            
            paircount_win = paircount_win +1;
            %vertical allignment
            e1win = e1win + tukey(winbb(1,i)-winbb(1,j), win_ddw);
            e1win = e1win + tukey(winbb(3,i)-winbb(3,j), win_ddw);
            %horizontal allignment
            e1win = e1win + tukey(winbb(2,i)-winbb(2,j), win_ddh);
            e1win = e1win + tukey(winbb(4,i)-winbb(4,j), win_ddh);
            
            %horizontal widths
            y11 = winbb(2,i);
            y21 = winbb(4,i);
            yy1 = round(y11+(y21-y11)/2);
            
            y12 = winbb(2,j);
            y22 = winbb(4,j);
            yy2 = round(y12+(y22-y12)/2);

            cpdist = yy1-yy2;
            w1 = winbb(3,i)-winbb(1,i);
            w2 = winbb(3,j)-winbb(1,j);
            e1win = e1win + weightWidths(cpdist,w1,w2,win_ddw);
            
            
           
        end
        maxpaircount_win = max(paircount_win, maxpaircount_win);
        
        e2win = e2win + getPD(round(winbb(1,i)), round(winbb(2,i)), round(winbb(3,i)-winbb(1,i)), round(winbb(4,i)-winbb(2,i)), PM_win,max(win_ddw,win_ddh));
        
    end
    if (paircount_win>0)
            e1win =e1win/maxpaircount_win;
            
    end
    ewin = e1win + 1000 * e2win;
    
    
    %BALCONY
        e1balc = 0;
    e2balc = 0;
   
  

    
    maxpaircount_balc = 0;
    for i = 1 : size(balcbb,2)
        paircount = 0;
        for j = i + 1 : size(balcbb,2)
            
            paircount = paircount +1;
            %vertical allignment
            %e1 = e1 + tukey(p(1,i)-p(1,j), ddw);
            %e1 = e1 + tukey(p(3,i)-p(3,j), ddw);
            %horizontal allignment
            e1balc = e1balc + tukey(balcbb(2,i)-balcbb(2,j), balc_ddh);
            e1balc = e1balc + tukey(balcbb(4,i)-balcbb(4,j), balc_ddh);
            
            %horizontal widths
            y11 = balcbb(2,i);
            y21 = balcbb(4,i);
            yy1 = round(y11+(y21-y11)/2);
            
            y12 = balcbb(2,j);
            y22 = balcbb(4,j);
            yy2 = round(y12+(y22-y12)/2);

            cpdist = yy1-yy2;
            w1 = balcbb(3,i)-balcbb(1,i);
            w2 = balcbb(3,j)-balcbb(1,j);
            %e1 = e1 + weightWidths(cpdist,w1,w2,ddw);
            
            
           
        end
        maxpaircount_balc = max(paircount, maxpaircount_balc);
        
        e2balc = e2balc ;%+ getPD(balcbb(1,i), balcbb(2,i), balcbb(3,i)-balcbb(1,i), balcbb(4,i)-balcbb(2,i), PM_balc, max(balc_ddw,balc_ddh));
%         e2 = e2 + getPD(round(p(1,i)), round(p(2,i)), round(p(3,i)-p(1,i)), round(p(4,i)-p(2,i)), PM,max(ddw,ddh));
        
    end
    if (paircount>0)
            e1balc =e1balc/maxpaircount_balc;
            
    end
    ebalc = 1*e1balc + 1000* e2balc;
    
    e =ewin+ebalc;
    
    
%     e1_joint = 0;
%  
%     
%     maxpaircount = 0;
%     for i = 1 : size(balcbb,2)
%         paircount = 0;
%         balconywidth = balcbb(3,i) - balcbb(1,i);
%         balconycenterx = balcbb(1,i) + 0.5* balconywidth;
%         
%         balconyy = balcbb(2,i) ;
%         for j = i + 1 : size(winbb,2)
%             winwidth = winbb(3,i) - winbb(1,i);
%             wincenterx = winbb(1,i) + 0.5* winwidth;
%             winheight = winbb(4,i) - winbb(2,i);
%             winy = winbb(2,i) +  winheight;
%             
%             %xpos
%             e1_joint = e1_joint + tukey(wincenterx-balconycenterx, win_ddw);
%             %ypos
%             e1_joint = e1_joint + tukey(winy-balconyy, balc_ddh);
%             
%             windowwidth = winbb(3,j) - winbb(1,j);
%             %width
%             e1_joint = e1_joint + tukey(balconywidth - windowwidth, win_ddw);
%             
%          
%             paircount = paircount +1;
%            
%             
%             
%            
%         end
%         maxpaircount = max(paircount, maxpaircount);
%         
%        
%     end
%     if (paircount>0)
%             e1_joint =e1_joint/maxpaircount;
%             
%     end
%     e = 1*e1_joint;
end





function e = weightWidths(dist, w1,w2, dd)
    if abs(dist) > dd
        e = tukey(dd+1, dd); %tukey(4001,400);     
    else
       e = tukey(w1-w2, 40); % exp(0.1*abs(w1-w2));%:
    end


end




function energy = getPD(x,y,w,h,PM,dd)

    if isnan(x) || isnan(y) || isnan(w) || isnan(y) || w*h==0 || x<1 || y<1
        energy =tukey(dd+1, dd); 
        return;
    end
    if (y+h > size(PM,1)) || x+w > size(PM,2)
        energy = tukey(dd+1, dd); 
    else
        energy =1- sum(sum(PM(y:y+h,x:x+w)))/(w*h);
    end
end

