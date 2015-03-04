function run_fold_image( fold, i, set, dw , gw)
    global dataweight;
    global gridweight;
    global energy_hash; 
    %energy_hash = containers.Map;
    dataweight =dw;
    gridweight =gw;
 
    if isdeployed
        fold = str2double(fold);
        i = str2double(i);
        dataweight = str2double(dw);
        gridweight = str2double(gw);
    end
    name = ['/esat/sadr/amartino/RNN/repo/source/markus_journal/markus_haussmann_' set '_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
    savename = ['markus_old_code_journal_2013_fold_' int2str(fold) '_' int2str(i) '.mat'];
    elementSampling(fold, name,savename,i, set);
    if isdeployed
        exit;
    end
end

