function [data, occupied] = initializeProcess(par, data, occupied)
    choices = par.firstMachines;
    player_pool = par.uniquePlayers(1:par.J);
    for j=1:par.J
        % Select a player from the pool
        k = randi(length(player_pool));
        player = player_pool(k);

        % Select a machine for the player to start at
        machine = choices(randi(length(choices)));

        % Insert initial data point
        %data_j = table(choices(n), par.initEventCode, player, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), 0, 'VariableNames', data.Properties.VariableNames);
        dataRecord = table(machine, par.initEventCode, player, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), 0, 'VariableNames', par.varNames);
        data = [data; dataRecord];

        % Update available machines and players
        machineIndex = par.uniqueMachineNumbers == machine;
        occupied(machineIndex) = true;
        player_pool = setdiff(player_pool, player_pool(k));
        choices(choices == machine) = [];
    end
end
