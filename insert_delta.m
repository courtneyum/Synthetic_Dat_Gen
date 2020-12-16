function delta = insert_delta(delta, prev, curr, EVD_j, e)
    if delta.key(prev, curr) == 0
        delta.length = delta.length + 1;
        delta.key(prev, curr) = delta.length;
        index = delta.length + 1;
        delta.CI(index) = {[]};
        delta.CO(index) = {[]};
        delta.GP(index) = {[]};
        delta.t(index) = {[]};
    end
    
    index = delta.key(prev, curr);
    
    delta.CI{index} = [delta.CI{index}; EVD_j.delta_CI(e)];
    delta.CO{index} = [delta.CO{index}; EVD_j.delta_CO(e)];
    delta.GP{index} = [delta.GP{index}; EVD_j.delta_GP(e)];
    delta.t{index} = [delta.t{index}; EVD_j.secondTime(e+1) - EVD_j.secondTime(e)];
end

