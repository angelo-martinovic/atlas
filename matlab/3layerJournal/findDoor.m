function [door] =findDoor(y,pm,bb,winw, winh)
cc =0;
mass =1;
door = zeros(6,1);
if ~isempty(bb)
    %take only door lower y
    
    bb = bb(:, bb(2,:)>y);
    for i=1:size(bb,2)
        h = bb(4,i) -bb(2,i);
        w = bb(3,i) -bb(1,i);
        if h/w > 1 && w>winw/1.5
            cc = cc+1;
            door(:,cc) = bb(:,i);
        end
        
    end
    if cc>0
        
        return;
    end
end
height = size(pm,1);
width = size(pm,2);
w=[round(winw*1.1): round(winw*3.5)];
h=[1.5:0.05:2.5];
mass =0;
maxmass = -inf;
for wi =1:size(w,2)
    ww = w(wi);
    for hi = 1:size(h,2)
        hh = round(h(hi)*w(wi));
        for i=1:size(pm,2)-ww
            
            mass = sum(sum(pm(height-hh:height, i:i+ww)))/(ww*hh); 
            if mass> maxmass
                maxmass = mass;
                door(:,1)= [i (height-hh) (i+ww) height, 4, mass]';
            end
            
        end
    end
end




end



