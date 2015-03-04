function door,mass =findDoor(y,pm,bb,winw, winh)
cc =0
mass =1;
door = zeros(4,1);
if ~isempty(bb)
    %take only door lower y
    
    bb = bb(:, bb(2,:)>y);
    for i=1:size(bb,2)
        h = bb(4,i) -bb(2,i);
        w = bb(3,i) -bb(1,i);
        if h/w > 1 && w>winw*1.5
            cc = cc+1
           door(cc) = bb(:,i);
        end

    end
    if cc>0
        return;
    end
     w= winw*1.5;
     h=w*1.2;
    maxmass = -inf;
    for i=1:size(pm,2)-w
        for j=y:size(pm,1)-y-1
            mass = sum(sum(pm(j:j+h, i:i+w)))/(w*h);
            if mass> maxmass
                maxmass = mass;
                door(:,1)= [i j i+w j+h]';
            end
            
        end 
    end
    
    
    
end



