function ol = getOverlap(bb1, bb2)
    ol = zeros(2,1);
    xa1=bb1(1);
    xa2=bb1(3);
    ya1=bb1(2);
    ya2=bb1(4);
    
    xb1=bb2(1);
    xb2=bb2(3);
    yb1=bb2(2);
    yb2=bb2(4);

    ol(1) = min(xa2,xb2) -  max(xb1, xb1);
    ol(2) = min(ya2,yb2) -  max(yb1, yb1);
    if (xa2  <= xb1 ||  xa1>xb2)
       ol(1) = 0;
    end
    if (ya2 <=yb1 || ya1>yb2)
        ol(2) = 0;
    end
    
end