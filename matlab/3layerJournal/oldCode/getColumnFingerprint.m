function w = getColumnFingerprint(boxes, h)
    h = zeros(1,h);
    for i=1:size(boxes,2)
       bb = boxes(:,i);
       h(bb(2,i):bb(4,i)) = 1;
    end
end