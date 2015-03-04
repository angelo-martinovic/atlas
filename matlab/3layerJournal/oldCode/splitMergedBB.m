function pnew = splitMergedBB(p)
    
    w = 0;
    for i = 1 : size(p,2)
        %calc median w and h
        w(i) = p(3,i)-p(1,i);
        h(i) = p(4,i)-p(2,i);
       
    end
    medianW= median(w);
    medianH= median(h);
    cc = 0;
    addp = zeros(4,1);
    
    for i = 1 : size(p,2)
        %calc median w and h
        if w(i) > 2*medianW
            p(3,i) = p(1,i) + w(i)/3;
            cc = cc+1;
            addp(1,cc) = p(1,i)+ w(i)/3;
            addp(2,cc) = p(2,i);
            addp(3,cc) = p(1,i)+ 2* w(i)/3;
            addp(4,cc) = p(4,i);
            cc = cc+1;
            addp(1,cc) = p(1,i)+ 2*w(i)/3;
            addp(2,cc) = p(2,i);
            addp(3,cc) = p(1,i)+ w(i);
            addp(4,cc) = p(4,i);
            
        end
       
    end
    if (cc>0)
        pnew = [p addp];
    else
        pnew = p;
    end
    
    
end

