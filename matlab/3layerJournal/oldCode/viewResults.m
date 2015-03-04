function viewResults(fold)
    for i=1:20
        name = ['markus_new_test_foldt_' int2str(fold) '_' int2str(i) '.mat'];
        load(name)
        tmp = max(sgmp,[],3);
        figure(i);imagesc(tmp);
        
        
         name = ['markus_new_test_foldtt_' int2str(fold) '_' int2str(i) '.mat'];
        load(name)
        tmp = max(sgmp,[],3);
        figure(i+1000);imagesc(tmp);
    end
        

end