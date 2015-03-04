function [r, match_it]= matchLines(b1, b2)
    match_it = false;
    matches = zeros(1,size(b1,2));
    matches2 = zeros(1,size(b2,2));
    if size(b1,2) < size(b2,2)
        r = 0;
        return;
    end
    for i=1:size(b2,2)
        %every box in b2 should match with a box in b1
        for j=1:size(b1,2)
            o = min(b2(3,i), b1(3,j)) - max(b2(1,i), b1(1,j));
            if o > 0
                u = max(b2(3,i), b1(3,j))  - min(b2(1,i), b1(1,j));
                if o/u > 0.5
                    matches(j) = 1;
                    matches2(i) =1;
                end
            end
        end
        
       
    end
    %not all in b2 are matched
    if sum(matches2) < size(b2,2) 
        r = 0;
        match_it = false;
    else

        r = sum(matches ~=1);
       
        match_it = true;
    end
end