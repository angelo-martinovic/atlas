function w = getLineFingerprint(boxes, w)
    w = zeros(1,w);
    for i=1:size(boxes,2)
       bb = boxes(:,i);
       w(bb(1,i):bb(3,i)) = 1;
    end
end




