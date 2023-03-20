function y = mat2num(A)
    l = length(A);
    y = A(length(A));
    for i = 2:l
        n = fix(log(y)/log(10))+1;
        y = 10^(n) * A(l-i+1) + y;
    end        
end