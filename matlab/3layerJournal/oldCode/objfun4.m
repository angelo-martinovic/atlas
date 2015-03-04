function e = objfun4(b, PM,ddw, ddh, BM, bddw, bddh, useDT)
w = b(:,(b(5,:) ==1));


b = b(:,(b(5,:) ==3));

e1 = objfun3(w, PM, ddw,ddh,useDT);
e2 = objfun3(b, BM, bddw,bddh, useDT);


e3 = checkBB(b,w,bddh);
e = e1 + e2 + e3;

end



function e = checkBB(balc, win, dh)
e = 0;
for i=1:size(balc,2)
    b = balc(:,i);
    
    w = win(:,win(3,:) > b(1) & win(1,:) < b(3) & win(4,:) < b(4));
    
    for kk=1: size(w,2)
        d = (b(2) - w(4,kk) );
        if d> 0 && d < dh
            e = e+d;
        end
    end
    
    
end


end