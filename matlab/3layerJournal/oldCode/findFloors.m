function ypos = findFloors(winbb, ymax, facadepositions)

    %go down with a line
    isin = false;
    ypos = [];
    for y=1:ymax
        overlappingWin = find(round(winbb(2,:)) <= y & round(winbb(4,:)) >= y)
        if ~isempty(overlappingWin) && size(overlappingWin,2) >1
            if isin == false
                ypos = [ypos y];
            end
            isin = true;
        else
            isin = false;
            
        end
    end
    
    if ypos(1) >= facadepositions(3)
        ypos = [facadepositions(2) ypos];
    end
    
    if ypos(end) >= facadepositions(end-1)
        ypos = ypos(1:end-1);
    end
    
   

end
