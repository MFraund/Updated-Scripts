%% fig1
figure; 
maxfig(gcf,1); 
pause(0.1);
imagesc(Snew.ThickMap(:,:,end)); colorbar;
axis square;
export_fig([Snew.particle,'OVF'],'-png');
pause(0.1); close(gcf);

%% fig 2
figure; 
maxfig(gcf,1);
pause(0.1);
imagesc(uint8(Snew.RGBCompMap));
axis square;
export_fig([Snew.particle,'Cspec'],'-png');
pause(0.1); close(gcf);

%% fig 3
figure;
maxfig(gcf,1);
histogram(Snew.VolFrac,[0:0.05:1]);
axis square;
export_fig([Snew.particle,'OVFhist'],'-png');
pause(0.1); close(gcf);


%% fig 4
figure;
axh = tight_subplot(2,2,[0.03,0.01],[0.01,0.03],[0.01,0.01]);
set(gcf,'Units','pixels','Position',[20,50,950,950]);
pause(0.1);
axes(axh(1));
imagesc(Snew.spectr(:,:,1));
title('278')
axis square
colormap gray

axes(axh(2));
imagesc(Snew.spectr(:,:,2));
title('285.4');
axis square
colormap gray

axes(axh(3));
imagesc(Snew.spectr(:,:,3));
title('288.6');
axis square
colormap gray

axes(axh(4));
imagesc(Snew.spectr(:,:,4));
title('320');
axis square
colormap gray

set(axh,'XTick',[],'YTick',[],'Color','none');

export_fig([Snew.particle,'raw'],'-png');
pause(0.1);

close(gcf);
