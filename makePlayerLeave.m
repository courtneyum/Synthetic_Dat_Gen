function [data, player_pool_all, occupied] = makePlayerLeave(data, player_pool_all, occupied, player, par)
    playerChoices = setdiff(par.uniquePlayers, player_pool_all);
    newPlayer = playerChoices(randi(length(playerChoices)));
    player_pool_all(player_pool_all == player) = newPlayer;

    % Insert initial event for this player
    machineChoices = par.firstMachines(ismember(par.firstMachines, par.uniqueMachineNumbers(~occupied)));
    machine = machineChoices(randi(length(machineChoices)));
    occupied(par.uniqueMachineNumbers == machine) = true;
    
    t = max(cumsum1(data.numericTime(data.patronID == player))) + 5; % Chose 5 just cause, need to come up with a better way to choose the offset
    dataRecord = table(machine, par.initEventCode, newPlayer, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), t, 'VariableNames', par.varNames);
    data = [data; dataRecord];
end