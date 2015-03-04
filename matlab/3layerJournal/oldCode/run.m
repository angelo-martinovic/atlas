for i=1:20  
    name = ['markus_valid_' int2str(i) '.mat'];
    savename = ['markus_new_valid' int2str(i) '.mat'];
    combined_windowBalcony(name,savename,i);
end
    
