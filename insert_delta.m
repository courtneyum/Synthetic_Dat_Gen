function delta = insert_delta(delta, prev, curr, EVD_j, e)
    if isempty(delta.key)
        index = 0;
    else
        index = delta.key(:,1) == prev & delta.key(:,2) == curr;
    end
    if ~any(index)
        delta.key = [delta.key; prev, curr];
        index = size(delta.key,1);
        delta.CI(index) = {[]};
        delta.CO(index) = {[]};
        delta.GP(index) = {[]};
        delta.t(index) = {[]};
    end
    
    delta.CI{index} = [delta.CI{index}; EVD_j.delta_CI(e)];
    delta.CO{index} = [delta.CO{index}; EVD_j.delta_CO(e)];
    delta.GP{index} = [delta.GP{index}; EVD_j.delta_GP(e)];
    delta.t{index} = [delta.t{index}; EVD_j.secondTime(e+1) - EVD_j.secondTime(e)];
end

