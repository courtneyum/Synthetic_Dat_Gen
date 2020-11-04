function [data, occupied] = initializeProcess(par, data, occupied)
    choices = par.firstMachines;
    player_pool = 1:par.J; player_pool = player_pool(:);
    for j=1:par.J
        % Select a player from the pool
        k = randi(length(player_pool));
        player = par.uniquePlayers(player_pool(k));

        % Select a machine for the player to start at
        n = randi(length(choices));

        % Insert initial data point
        data_j = table(choices(n), par.initEventCode, player, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), 0, 'VariableNames', data.Properties.VariableNames);
        data = [data; data_j];

        % Update available machines and players
        machineIndex = par.uniqueMachineNumbers == choices(n);
        occupied(machineIndex) = true;
        player_pool = setdiff(player_pool, player_pool(k));
        choices(choices == choices(n)) = [];
    end
end
