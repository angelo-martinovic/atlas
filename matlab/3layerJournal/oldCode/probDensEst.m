function S =  probDensEst()
    fold =2;
    cl = 5;
    chimney=8;
    window =1;
    balcony = 3;
    door=4;
    
    sky = 6;
    roof=5;
    facade = 2;
    shop =7;
    S = zeros(100,1);
    
    for i=1:20
        %close all;
        name = ['new/markus_ECP_valid_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
        load (name)

       
       % D = probDensity(sky, labels);
        S = S + columnSum(cl, labels);
        

        
        
        
        
    end
    [f,xi] = ksdensity(S)
    S = S/sum(S);
    histfit(S)
    
    
    


end

function S = columnSum(cl, label, remMask)
    delmask =zeros(size(label));
    mask = (label ==cl);
    
    %figure;imagesc(mask);
    
    B = imresize(mask, [100 100]);
    S = sum(B,2);
    

end

