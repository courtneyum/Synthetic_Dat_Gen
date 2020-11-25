function arr = cumsum1(arr)
    if isempty(arr)
        return;
    end
    
    for i=2:length(arr)
        arr(i) = arr(i) + arr(i-1);
    end
end