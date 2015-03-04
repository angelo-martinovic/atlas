function drawRects(p2,fignum, image)
figure(fignum); imagesc(image); axis image;
   hold on

for k=1:size(p2,2)
       
       x = round(p2(1,k));
       y = round(p2(2,k));
       w = round(p2(3,k)-p2(1,k));
       h = round(p2(4,k)-p2(2,k));
       X =[x, x+w, x+w,x+w,x+w,x, x,x];
       Y =[y, y,y, y+h, y+h,y+h, y+h, y];
       line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);  
end

end