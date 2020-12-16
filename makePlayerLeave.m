function [data, par, occupied] = makePlayerLeave(data, occupied, player, par)
    % Choose a new player
    playerChoicesIndex = ~ismember(par.uniquePlayers, par.players);
    playerChoices = par.uniquePlayers(playerChoicesIndex);
    playersDist = par.playersDist(playerChoicesIndex)/sum(par.playersDist(playerChoicesIndex));
    cumDist = cumsum1(playersDist);
    num = rand;
    k = find(cumDist > num, 1);
    newPlayer = playerChoices(k);
    par.players(par.players == player) = newPlayer;
    par.playerIndex(par.players == newPlayer) = find(par.uniquePlayers == newPlayer);

    % Insert initial event for this player
    machineChoicesIndex = ~occupied;
    machineChoices = par.uniqueMachineNumbers(machineChoicesIndex);
    cumDist = cumsum1(par.firstMachinesDist);
    num = rand;
    k = find(cumDist > num, 1);
    machine = machineChoices(k);
    occupied(par.uniqueMachineNumbers == machine) = true;
    
    par.eventNum(par.uniquePlayers == newPlayer) = par.eventNum(par.uniquePlayers == newPlayer) + 1;
    par.dataHeight = par.dataHeight + 1;
    data_i = data(1:par.dataHeight, :);
    times = data_i.numericTime(data_i.patronID == player);
    t = max(cumsum1(times)) + 5; % Chose 5 just cause, need to come up with a better way to choose the offset
    dataRecord = table(par.eventNum(par.uniquePlayers == newPlayer), machine, par.initEventCode, newPlayer, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), t, 'VariableNames', par.varNames);
    data(par.dataHeight, :) = dataRecord;
    
end