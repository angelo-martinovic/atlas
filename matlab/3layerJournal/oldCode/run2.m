function run2(fold)
% clc
tic

if fold==1
    nImages = 24;
else
    nImages = 20;
end
for i=1:nImages
    close all;
    set = 'eval';
    run_fold_image(fold, i, set, 80,5);
    
    
    
end
toc
    




