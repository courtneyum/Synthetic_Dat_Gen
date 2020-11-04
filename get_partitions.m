function partitions = get_partitions(N)
    %Returns empty cell array for N <= 2

    partitions = {};
    partition_indices = 1:N-1;
    partition_vec = 1:N;
    curr_row = 1;
    for i=2:N-1
        possible_partitions = nchoosek(partition_indices, i-1);
        
        for j=1:size(possible_partitions, 1)
            start = 1;
            for k=1:i-1
                partitions{curr_row, k} = partition_vec(start:possible_partitions(j,k));
                start = possible_partitions(j,k) + 1;
            end
            partitions{curr_row, i} = partition_vec(start:end);
            curr_row = curr_row+1;
        end
        
    end
end