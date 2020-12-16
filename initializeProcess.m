function [data, occupied] = initializeProcess(par, data, occupied)
    player_pool = par.players;
    playersDist = par.playersDist(par.playerIndex)/sum(par.playersDist(par.playerIndex));
    for j=1:par.J
        % Select a player from the pool
%         k = randi(length(player_pool));
%         player = player_pool(k);
        num = rand;
        cumDist = cumsum1(playersDist);
        k = find(cumDist > num, 1);
        player = player_pool(k);

        % Select a machine for the player to start at
        %machine = choices(randi(length(choices)));
        num = rand;
        machinesIndex = find(~occupied);
        machinesDist = par.firstMachinesDist(~occupied);
        machinesDist = machinesDist/sum(machinesDist);
        cumDist = cumsum1(machinesDist);
        k = find(cumDist > num, 1);
        machine = par.uniqueMachineNumbers(machinesIndex(k));

        % Insert initial data point
        dataRecord = table(1, machine, par.initEventCode, player, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), 0, 'VariableNames', par.varNames);
        data = [data; dataRecord];

        % Update available machines and players
        machineIndex = par.uniqueMachineNumbers == machine;
        occupied(machineIndex) = true;
        playersDist(player_pool == player) = [];
        playersDist = playersDist/sum(playersDist);
        player_pool = setdiff(player_pool, player);
    end
end
