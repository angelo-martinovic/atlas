%%
load('/esat/sadr/amartino/RNN/data/detLabelDistributions_haussmann_window-specific_fold1_winSize_200.mat');

figure('Color',[1 1 1],'Position',[0 0 1000 1000]);

subplot(3,3,1),imagesc(labelMaps(1).labelMap(:,:,1),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,2),imagesc(labelMaps(1).labelMap(:,:,2),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,3),imagesc(labelMaps(1).labelMap(:,:,3),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );

subplot(3,3,4),imagesc(labelMaps(end/2).labelMap(:,:,1),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,5),imagesc(labelMaps(end/2).labelMap(:,:,2),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,6),imagesc(labelMaps(end/2).labelMap(:,:,3),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );

subplot(3,3,7),imagesc(labelMaps(end).labelMap(:,:,1),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,8),imagesc(labelMaps(end).labelMap(:,:,2),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );
subplot(3,3,9),imagesc(labelMaps(end).labelMap(:,:,3),[0 1]);set(gca,'XTickLabel','','YTickLabel','' );

colormap('hot');

%%
figure('Name','a','Color',[1 1 1],'Position',[0 0 1500 1000]);
myPlot = plot([labelMaps(:).score]);

set(myPlot                        , ...
  'LineWidth'       , 2.5         , ...
  'Color'           , [0.447,0.624,0.812]    );
set( gca                       , ...
    'FontName'   , 'Helvetica' , ...
    'FontSize'   , 12 );

hXLabel = xlabel('Detection index'                     );
hYLabel = ylabel('Detection score'                      );

grid on;
