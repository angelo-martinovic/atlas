function e = objfun2(p, PM)
    e = 0;
    dd = 50
    for i = 1 : size(p,2)
        for j = i + 1 : size(p,2)
            e = e + tukey(p(1,i)-p(1,j), dd);
            e= e+ rateDist(p(1,i)-p(1,j),p(3,i),p(3,j),dd);
            e = e + tukey(p(2,i)-p(2,j), dd);
            e= e+ rateDist(p(2,i)-p(2,j),p(4,i),p(4,j),dd);
            %e= e+ tukey(p(4,i)-p(4,j),100);
        end
        e = e + 0.2 * getPD(round(p(1,i)-p(3,i)/2), round(p(2,i) - p(4,i)/2), round(p(3,i)), round(p(4,i)), PM);
        %e = e + 1000 * PM(round(p(2,i)), round(p(1,i)));
    end
    
    
end

function energy = getPD(x,y,w,h,PM)
    
    energy = 1-sum(sum(PM(y:y+h,x:x+w)))/(w*h);
end

function energy = rateDist(d, w1,w2, k)
    e = w2-w1;
    if d<k
        energy = k^2/6 * (1 - (1-(e/k)^2)^3);
    else
        energy = tukey(10,20);

    end
end