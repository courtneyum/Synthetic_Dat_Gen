function dataRecord = makeDataRecord(curr_eventID, next_eventID, e, n, player, par)
    % Draw accompanying info, choose as a quadruple rather than
    % independently to account for correlation
    
    %index = par.delta.key(:,1) == curr_eventID & par.delta.key(:,2) == next_eventID;
    index = par.delta.key(curr_eventID, next_eventID);
    
    choices = par.delta.CI{index};
    k = randi(length(choices));
    CI = choices(k);

    choices = par.delta.CO{index};
    CO = choices(k);

    choices = par.delta.GP{index};
    GP = choices(k);

    choices = par.delta.t{index};
    t = choices(k);

    % Add to data
    dataRecord = table(par.eventNum(par.uniquePlayers == player) + 1, par.uniqueMachineNumbers(n), par.uniqueEventCodes(e), player, CI, CO, GP, datetime(0, 1, 1, 0, 0, 0), t, 'VariableNames', par.varNames);
end