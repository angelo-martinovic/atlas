function drawAllRects(p2,fignum)

    figure(fignum);axis image;   hold on

    for k=1:size(p2,2)

           x = round(p2(1,k));
           y = round(p2(2,k));
           w = round(p2(3,k)-p2(1,k));
           h = round(p2(4,k)-p2(2,k));
           c = getColor(p2(5,k));
           X =[x, x+w, x+w,x+w,x+w,x, x,x];
           Y =[y, y,y, y+h, y+h,y+h, y+h, y];
           line(X,Y,'LineWidth',4,'Color',c);  
    end

end

function c = getColor(idx)
    if idx == 1
        c = [1,0,0];
    elseif idx ==3
        c  = [0,1,0];
    elseif idx == 4
        c = [0,0,1];
    else
        c = [1,1,1];
    end
     

end