function viewResults2
    for i=1:24
%         name = ['markus_new_valid_smallerBB' int2str(i) '.mat'];
%         load(name)
%         tmp = max(sgmp,[],3);
%         figure(i);imagesc(tmp);
        
        
         name = ['markus_new' int2str(i) '.mat'];
        load(name)
        tmp = max(sgmp,[],3);
        figure(i);imagesc(tmp);
    end
        

end