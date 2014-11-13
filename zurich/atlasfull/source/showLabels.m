

for fold=1:5
    load(['../../data/haussmannFinal-FOLD' num2str(fold) '_eval.mat'],'allData');
    fileList = readTextFile(['../../data/haussmannFinal/evalList' num2str(fold) '.txt']);

    for imgNumber=1:length(allData)
      % figure;imagesc(allData{i}.labels); 
       teboulLabel = load(['/usr/data/amartino/Facades/ECPdatabase/cvpr2010/labels/' fileList{imgNumber} '.txt']);
      % figure;imagesc(teboulLabel);
       writeSegmentationToDisk(teboulLabel,['visual/haussmann_oldLabel_' num2str(fold) '_' num2str(imgNumber) '.png'],allData{imgNumber}.img,0.5,2,1);

    end
end