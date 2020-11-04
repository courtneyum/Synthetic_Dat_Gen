function A = reduced_matrix(M)
    if is_irreducible_matrix(M)
        error('ERR_IRREDUCIBLE: matrix is irreducible');
    end
    
    A = find_block_upper_triangular_form(M);