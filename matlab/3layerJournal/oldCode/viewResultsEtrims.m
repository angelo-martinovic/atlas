function viewResultsEtrims(fold)
    for i=1:20
        name =  ['markus_eTrims_out3_fold_' int2str(fold) '_img_' int2str(i) '.mat']
        load(name)
        tmp = max(sgmp,[],3);
        figure(i+3000);imagesc(tmp);
        
        name = ['markus_eTrims_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
        load(name)
        
        figure(i+1000);imagesc(origImg);
        
%         
%          name = ['markus_new_test_foldtt_' int2str(fold) '_' int2str(i) '.mat'];
%         load(name)
%         tmp = max(sgmp,[],3);
%         figure(i+1000);imagesc(tmp);
    end
        

end