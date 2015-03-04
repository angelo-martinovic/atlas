function run_etrims(fold)
for i=1:20
	name = ['markus_eTrims_fold_' num2str(fold) '_img_' num2str(i) '.mat']
    %name = ['markus_eTrims_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
    savename = ['markus_eTrims_out3_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
    combined_windowBalconyEtrims(name,savename,i, fold);
end
