function [i, j, s] = insert_trans(prev, curr, i, j, s)
    index = prev == i & curr == j;
    if ~any(index)
        i = [i; prev];
        j = [j; curr];
        s = [s; 0];
        index = length(i);
    end
    s(index) = s(index) + 1;
end