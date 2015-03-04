function out = removePositions(p,ypositions)
   out = [];
   cc = 0;
 
    for i = 1 : size(ypositions,2)
        removethis = false;
        y = ypositions(i);
        for j =1 : size(p,2)
            
            
           
            upperbound = p(2,j);
            lowerbound = p(4,j);
            
            if y > upperbound && y < lowerbound
                removethis = true;
           
            end
            
            
           
        end
        if (removethis ==false)
            cc = cc+1;
            out(cc) = y;
        end
       
    end
   
    out = unique(out);
    
    
end