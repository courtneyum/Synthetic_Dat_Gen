function ret = is_irreducible_matrix(M)
    if size(M, 1) ~= size(M, 2)
        error('ERR_NOTSQUARE: matrix is not square.');
    end
    B = find_block_upper_triangular_form(M);
    
    if all(size(B) == size(M))
        ret = false;
    else
        ret = true;
    end