function balc_bb = addBalconiesOrWindows(win_bb, balc_bb)

    correspondences = findCorrespondingWindowBalconyPairs(win_bb, balc_bb);
    %extend balconies to not stop in the middle of a window
    for i = 1:size(correspondences,2)
        balcidx = correspondences(2,i);
        winidx = correspondences(1,i);
        if win_bb(3,winidx) > balc_bb(3, balcidx)
            balc_bb(3,balcidx) = win_bb(3,winidx);
        end
        if win_bb(1,winidx) < balc_bb(1, balcidx)
            balc_bb(1,balcidx) = win_bb(1,winidx);
        end
    end
    %one window with several balconies -> merge them
    %for i = 1:size(win_bb,2)
    correspondences
    c = correspondences;
    winWithoutBalc = []
    for i = 1:size(win_bb,2)
         if isempty(find(c(1,:)==i))
             %windowwithout balc
             winWithoutBalc = [winWithoutBalc i];
         end
    end
    balcWithoutwin = []
    for i = 1:size(balc_bb,2)
         if isempty(find(c(2,:)==i))
             %windowwithout balc
             balcWithoutwin = [balcWithoutwin i];
         end
    end 
    
    
    
    
    %find other windows in the row
    for i =1:size(winWithoutBalc,2)
        ww = winWithoutBalc(i)
        ar = getAllInRow(win_bb, win_bb(:,winWithoutBalc(i)),0);
        ar = ar(ar~=winWithoutBalc(i));
        balcindices = []
        for j=1:size(ar,2)
            otherwinWithBalcIdx =find(c(1,:)==ar(j));
            if ~isempty(otherwinWithBalcIdx)
                balcidx = c(2,otherwinWithBalcIdx(1));
                balcindices = [balcindices balcidx];        
            end
        end
        balcy1 = mean(balc_bb(2,balcindices) )
        balcy2 = mean(balc_bb(4,balcindices) )
        if ~isempty(balc_bb(2,balcindices))
        
            newbalc = zeros(4,1);
            newbalc(1,1) = win_bb(1,ww);
            newbalc(3,1) = win_bb(3,ww);
            newbalc(2,1) = balcy1;
            newbalc(4,1) = balcy2;
            newbalc
            
            balc_bb = [balc_bb newbalc]
            
        end
    end
    balc_bb(:,balcWithoutwin) = [];

            
  

end