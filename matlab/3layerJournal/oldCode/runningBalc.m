function [b2, b5, maxEnergy] = runningBalc(winbb, balcbb,pm, facadepositions)
    b5 = [0 0];
    b2 = [0 0];
    margin = 5;
    maxEnergy = [0 0];
   % figure; imagesc(pm); axis image;
    ypos = findFloors(winbb, size(pm,1), facadepositions);
    if size(ypos,2) ~=6
        return;
    end
    gradpm = edge(pm, 'sobel');
    o5 = ypos(2)
    u5 = ypos(3)
    o2 = ypos(5)
    u2 = ypos(6)
    
    balcbb5 = balcbb(:,balcbb(2,:) >= o5 & balcbb(4,:) <= u5);
    winbb5 = winbb(:,winbb(2,:) >= o5 & winbb(4,:) <= u5);
    balcbb2 = balcbb(:,balcbb(2,:) >= o2 & balcbb(4,:) <= u2);
    winbb2 = winbb(:,winbb(2,:) >= o2 & winbb(4,:) <= u2);
    
%     if ~isempty(winbb5)
%     o5 = round(max(o5, max(winbb5(2,:))))+margin
%     end
%     if ~isempty(winbb2)
%     o2 = round(max(o2, max(winbb2(2,:))))+margin
%     end
    
    maxe = -inf;
    w = size(pm,2);
    
    for y = o5+margin:u5-margin
        e = sum(sum(gradpm(y,:)))/w;
        e = e*sum(sum(pm(y:u5, 1:w)))/(w*(u5-y));
        if e> maxe
            maxe = e;
            
            b5(1) = y;
        end
        
    end
       
     maxe = -inf;
     for y = b5(1)+margin:u5-margin
        e = sum(sum(gradpm(y,:)))/w;
        e = e*sum(sum(pm(b5(1):y, 1:w)))/(w*(y-b5(1)));
        if e> maxe
            maxe = e;
            maxEnergy(1) = e;
            b5(2) = y;
        end    
     end
    
    
maxe = -inf;
    for y = o2+margin:u2-margin
        e = sum(sum(gradpm(y,:)))/w;
        e = e*sum(sum(pm(y:u2, 1:w)))/(w*(u2-y));
        if e> maxe
            maxe = e;
            b2(1) = y;
        end
        
    end
       
     maxe = -inf;
     for y = b2(1)+margin:u2-margin
        e = sum(sum(gradpm(y,:)))/w;
        e = e*sum(sum(pm(b2(1):y, 1:w)))/(w*(y-b2(1)));
        if e> maxe
            maxe = e;
            maxEnergy(2) = e;
            b2(2) = y;
        end    
     end


end