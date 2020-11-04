function ret = is_block_upper_triangular(M)
    if size(M, 1) ~= size(M, 2)
        error('ERR_NOTSQUARE: matrix is not square.');
    end
    N = size(M, 1);
    partitions = get_partitions(N);
    
    for i=size(partitions, 1):-1:1
        ret = true;
        for j=1:size(partitions, 2) - 1
            if isempty(partitions{i,j+1})
                % we have reached the end of this row
                break;
            end
            curr_part = partitions{i, j};
            if ~is_zero_matrix(M(curr_part(end)+1:N, curr_part(1):curr_part(end)))
                ret = false;
            end
        end
        if ret == true
            return;
        end
    end
end