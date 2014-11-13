filenames=dir('/esat/nereid/amartino/gould/test/*.jpg');

for i=1:size(filenames,1)
    inputFilename = filenames(i).name;
    stem = inputFilename(1:end-4);
    
    load(['/esat/nereid/amartino/Facades/ECPdatabase/cvpr2010/images/gpb/' stem '.mat']);

    initialSeg = bwlabel(ucm2 <= 0);
    initialSeg = initialSeg(2:2:end, 2:2:end);
    
    initialSeg = initialSeg-1;

    dlmwrite(['segs/' stem '.seg'],initialSeg,'delimiter',' ','newline','pc');

    disp(['Processed image ',num2str(i),'/',num2str(size(filenames,1)),'.']);

end;
