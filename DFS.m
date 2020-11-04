function cycles = DFS(trans_mat)
    discovered = [];
    finished = [];
    cycles = {};
    
    for i=1:size(trans_mat, 1)
        if ~any(discovered == i) && ~any(finished == i)
            path = i;
            [discovered, finished, cycles] = visit(trans_mat, i, discovered, finished, cycles, path);
        end
    end
end

function [discovered, finished, cycles] =  visit(trans_mat, start, discovered, finished, cycles, path)
    discovered = [discovered; start];
    adj = find(trans_mat(start, :) > 0);
    
    path = [path; NaN];
    
    for i=1:length(adj)
        if any(discovered == adj(i)) || any(finished == adj(i))
            index1 = find(path == adj(i));
            cycle = path(index1:end);
            if ~isempty(cycle)
                cycles = [cycles, {cycle}];
            end
        end
        
        if ~any(finished == adj(i)) && ~any(discovered == adj(i))
            path(end) = adj(i);
            [discovered, finished, cycles] = visit(trans_mat, adj(i), discovered, finished, cycles, path);
        end
        
        discovered(discovered == start) = [];
        finished = [finished; start];
    end
end