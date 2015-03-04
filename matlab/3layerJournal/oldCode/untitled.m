
function test(a)
load('markus_1.mat')
mask = (outImg ==1);
figure;
imagesc(mask);
hold on
[conComp, n] = bwlabel(mask);
for i=1:n
   
    t = (conComp ==i);
   [r,c] = find(t);
   ypos = sum(r,1)/size(r,1)
   xpos = sum(c,1)/size(c,1)
   plot(xpos,ypos, 'gx')
end
qualityHorrAlign(1)
end

function qualityHorrAlign(k)

    dips('test');
end