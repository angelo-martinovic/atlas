function precision = evalSegmentationPrecision()

    load('haussmannFinal-FOLD1_train.mat','allData');
    
    fid = fopen('haussmannFinal/trainList1.txt', 'r');
    fileLines = textscan(fid, '%s', 'delimiter', '\n', 'bufsize', 99900000);
    fclose(fid);
    fileLines = fileLines{1};
    
    numCorrectPixels = zeros(1,8);
    numIncorrectPixels = zeros(1,8);
    
    for i=1:size(allData,2)
        disp(['Calculating ' num2str(i) '/' num2str(size(allData,2))]);
        load(['/esat/nereid/amartino/Facades/ECPdatabase/cvpr2010/images/gpb/' fileLines{i} '.mat']);
        
        initialSeg = bwlabel(ucm2 <= 0);
        initialSeg = initialSeg(2:2:end, 2:2:end);
    
%        figure;imshow(initialSeg,[]);colormap(jet);
        %figure(111);imagesc(initialSeg);


        labelRegs = allData{i}.labels;
        segs = initialSeg ; 
        numSegs = max(segs(:));
        segLabels = zeros(numSegs,1);

        for r = 1:numSegs
            res2 = labelRegs(segs==r);  % For each segment, get all pixel labels and use the one which is the most common.
            segLabels(r) = mode(res2);
            if (mode(res2)~=0)
                numCorrectPixels(mode(res2)) = numCorrectPixels(mode(res2)) + sum(res2==mode(res2));
                for s=1:8
                    if s~=mode(res2)
                        numIncorrectPixels(s) = numIncorrectPixels(s) + sum(res2==s);
                    end
                end
            end

        end

    end
    disp('Precision');
    precision = numCorrectPixels ./ (numCorrectPixels + numIncorrectPixels);
    disp( precision );
    disp( sum(numCorrectPixels(1:7))/ (sum(numCorrectPixels(1:7))+sum(numIncorrectPixels(1:7))) );
end