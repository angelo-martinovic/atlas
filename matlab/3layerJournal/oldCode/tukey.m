% function psi = tukey(e, k)
%     if abs(e) < k
%         psi =  k^2/6 * (1 - (1-(e/k)^2)^3) - k^2/6;
%     else
%         psi = 0;%k^2/6;
%     end
% end
% function psi = tukey(e, k)
%     if abs(e) < k
%         psi =  k^2/6 * (1 - (1-(e/k)^2)^3);
%     else
%         psi = k^2/6;
%     end
% end

function psi = tukey(e, k)
    if abs(e) < k
        psi =  -1;%k^2/6 * (1 - (1-(e/k)^2)^3);
    else
        psi = 0;%k^2/6;
    end
end