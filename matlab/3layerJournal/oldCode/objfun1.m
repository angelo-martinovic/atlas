function e = objfun1(p, PM)
    e = 0;
    for i = 1 : size(p,2)
        for j = i + 1 : size(p,2)
            e = e + tukey(p(1,i)-p(1,j), 20);
            e = e + tukey(p(2,i)-p(2,j), 20);
        end
        
        e = e + 1000 * PM(round(p(2,i)), round(p(1,i)));
    end
    
    
end

