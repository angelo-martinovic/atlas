function bb = addRunningBalc(bb, rb)
    rem = []
    for i=1:size(bb,2)
        ol = getOverlap(bb(:,i), rb)
        if ol(1)>0 && ol(2) >0
           rem = [rem i] ;
        end
    end
    bb(:,rem) = [];
    bb(:,end+1) = rb;



end