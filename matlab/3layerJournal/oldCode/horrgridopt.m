function e = horrgridopt(p,ypositions, PM,ddw, ddh)
    e1 = 0;

    w = 0;
    for i = 1 : size(p,2)
        %calc median w and h
        w(i) = p(3,i)-p(1,i);
        h(i) = p(4,i)-p(2,i);
       
    end
  %  dd= median(h);
    
 
    for i = 1 : size(ypositions,2)
        y = ypositions(i);
        [minupperbound, maxlowerbound] = getUpperAndLowerBound(y, p);
        
            
             e1 = e1+(minupperbound-y)*(minupperbound-y);
             e1 = e1+(maxlowerbound-y)*(maxlowerbound-y);
            %e1 = e1+weightDist((minupperbound-y), 30);
            %e1 = e1+weightDist((maxlowerbound-y), 30);
            %e1 = e1 + weightDist(y-upperbound, ddh*3);
            %e1 = e1 + weightDist(lowerbound -y, ddh*3);
%             if y > upperbound && y < lowerbound
%                 e1 = e1+100;
%             end
            
            
      
    end
   
    e = e1;
    
    
    
end
function [minupperbound, maxlowerbound]= getUpperAndLowerBound(y, p)
    minupperbound = 300;
    maxlowerbound = 0;
    for j =  1 : size(p,2)
            
            % y - upper bound window
           
            upperbound = p(2,j);
            lowerbound = p(4,j);
            if upperbound >= y
               minupperbound = min(upperbound, minupperbound);
            end
            if lowerbound <= y
               maxlowerbound = max(lowerbound, maxlowerbound) ;
            end
                          
    end

end


function e = weightDist(dist, dd)
%     if dist < 0 || dist > dd
%         e=1000000000;
%         return;
%     end

    e = exp((1+dist/dd));% % exp(0.1*abs(w1-w2));%:
   


end


