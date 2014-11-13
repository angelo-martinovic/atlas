function y = smooth_old(x)

%Build a gaussian filter
sigma = 5;
size = 5;

base = -1/2:1/(size-1):1/2;
h = exp( -(base.^2)/(2*sigma^2) );
h = h / sum(sum(h));

%Perform 1D convolution
n = length(x); p = length(h);
if mod(p,2)==1
    d1 = (p-1)/2; d2 = (p-1)/2;
else
    d1 = p/2-1; d2 = p/2;
end
xx = [ x(d1:-1:1); x; x(end:-1:end-d2+1) ];
y = conv(xx,h);
y = y( (2*d1+1):(2*d1+n) );


end