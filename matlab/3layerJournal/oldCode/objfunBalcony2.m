function e = objfunBalcony2(p, PM,ddw, ddh)
    e1 = 0;
    e2 = 0;
    %dd = 35;
    w = 0;
    ddh = ddh*2;
    for i = 1 : size(p,2)
        %calc median w and h
        w(i) = p(3,i)-p(1,i);
        h(i) = p(4,i)-p(2,i);
       
    end
    %dd= median(w)*2;
    
    normalizationFactor = size(p,2)*(size(p,2)-1)/2;
    maxval = 0;
   
    for i = 1 : size(p,2)

        for j = i + 1 : size(p,2)
            whorBottom = 2;
            whorWidth = 2;
            if i ==1 && j ==2
             %   maxval = maxval + tukey(ddw+1, ddh);    

                maxval = maxval + tukey(ddw+1, ddw);
                maxval = maxval + tukey(ddw+1, ddw);
                maxval = maxval + tukey(ddh*3+1, ddh*3); 
                maxval = maxval + whorBottom*tukey(ddh*3+1, ddh*3);
                maxval = maxval + whorWidth* tukey(ddw*2+1, ddw*4);
                
               
            end

           
            %vertical allignment
            e1 = e1 + tukey(p(1,i)-p(1,j), ddw);
            e1 = e1 + tukey(p(3,i)-p(3,j), ddw);
            %horizontal allignment
            ol = getOverlap(p(:,i), p(:,j));
            %if ol(2) >0
                 e1 = e1 +tukey(p(2,i)-p(2,j), ddh*3);
                e1 = e1 + whorBottom* tukey(p(4,i)-p(4,j), ddh*3);
            %else
                 %e1 = e1 + whorWidth* tukey(ddh*3+1, ddh*3);
             %    e1 = e1 + tukey(ddh*3 +1, ddh*3);
            %end
            
            %horizontal widths

            d1 = max(p(2,i), p(2,j));
            d2 = min(p(4,i), p(4,j));
            w1 = p(3,i)-p(1,i);
            w2 = p(3,j)-p(1,j);
            %e1 = e1 + whorWidth*weightWidths2(d1,d2,w1,w2,ddw*2);
            
%             y11 = p(2,i);
%             if isnan(y11);
%                 y11
%             end
%             y21 = p(4,i);
%             yy1 = round(y11+(y21-y11)/2);
%             
%             y12 = p(2,j);
%             y22 = p(4,j);
%             yy2 = round(y12+(y22-y12)/2);
% 
%             cpdist = yy1-yy2;
%             w1 = p(3,i)-p(1,i);
%             w2 = p(3,j)-p(1,j);
%             e1 = e1 + weightWidths(cpdist,w1,w2,ddw);
            
            
           
        end
        
        
        e2 = e2 + getPD(p(1,i), p(2,i), p(3,i)-p(1,i), p(4,i)-p(2,i), PM, max(ddw,ddh))
%         e2 = e2 + getPD(round(p(1,i)), round(p(2,i)), round(p(3,i)-p(1,i)), round(p(4,i)-p(2,i)), PM,max(ddw,ddh));
        
    end
    e1 =e1/(normalizationFactor*maxval);
   
    e = 1*e1 +  0.00001*e2;
    
    
end

function e = weightWidths2(d1, d2, w1,w2, dd)
    if d1>d2
        e = tukey(dd+1, dd); %tukey(4001,400);     
    else
       e = tukey(w1-w2, dd); % exp(0.1*abs(w1-w2));%:
    end


end

function e = weightWidths(dist, w1,w2, dd)
    if abs(dist) > dd
        e = tukey(dd+1, dd); %tukey(4001,400);     
    else
       e = tukey(w1-w2, 40); % exp(0.1*abs(w1-w2));%:
    end


end




function energy = getPD(x,y,w,h,PM,dd)

    if isnan(x) || isnan(y) || isnan(w) || isnan(y) || w*h<1 || x<1 || y<1
        energy =20;%tukey(dd+1, dd); 
        return;
    end
    if (y+h > size(PM,1)) || x+w > size(PM,2)
        energy =20;% tukey(dd+1, dd); 
    else
        
        energy =1-sum(sum(PM(round(y):round(y+h),round(x):round(x+w))))/round(w*h);
%         energy =sum(sum(PM(floor(y)+1:floor(y+h),floor(x)+1:floor(x+w))));
%         yw = y -floor(y);
%         xw = x - floor(x);
%         top = yw* sum(sum(PM(floor(y):floor(y),floor(x)+1:floor(x+w))));
%         bottom = yw* sum(sum(PM(floor(y+h)+1:floor(y+h)+1,floor(x)+1:floor(x+w))));
%         left = xw * sum(sum(PM(floor(y)+1:floor(y+h),floor(x):floor(x))));
%         right = xw * sum(sum(PM(floor(y)+1:floor(y+h),floor(x+w)+1:floor(x+w)+1)));
%         energy = energy + top+bottom+left+right;
%         energy = 1- energy/(w*h);
    end
end

