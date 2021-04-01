function [data, par, occupied] = makePlayerLeave(data, occupied, player, par)
    % Determine dynamic rate of replacement
    prevPlayerIndex = find(data.patronID == player, 1, 'last');
%     repRate = getRepRate(min(data.numericTime), data.numericTime(prevPlayerIndex), par.playerReplacement);
%     repRateFloor = floor(repRate);
%     numPlayersToDraw = repRateFloor + (rand <= repRate - repRateFloor);
    
    par.playerLeft(par.players == player) = [];
    par.players(par.players == player) = [];
    par.inCycleSteps(par.players == player) = [];
    
    numPlayersToDraw = 1;
    % Choose new players
    for i=1:numPlayersToDraw
        playerChoicesIndex = ~ismember(par.uniquePlayers, par.players);
        playerChoices = par.uniquePlayers(playerChoicesIndex);
        playersDist = par.playersDist(playerChoicesIndex)/sum(par.playersDist(playerChoicesIndex));
        cumDist = cumsum1(playersDist);
        num = rand;
        k = find(cumDist > num, 1);
        newPlayer = playerChoices(k);
        %par.players(par.players == player) = newPlayer;
        par.players = [par.players; newPlayer];
        par.playerLeft = [par.playerLeft; false];
        par.inCycleSteps = [par.inCycleSteps; 0];
        par.playerIndex(par.players == newPlayer) = find(par.uniquePlayers == newPlayer);

        % Insert initial event for this player
        machineChoicesIndex = ~occupied;
        machineChoices = par.uniqueMachineNumbers(machineChoicesIndex);
        cumDist = cumsum1(par.firstMachinesDist(machineChoicesIndex)/sum(par.firstMachinesDist(machineChoicesIndex)));
        num = rand;
        k = find(cumDist > num, 1);
        machine = machineChoices(k);
        occupied(par.uniqueMachineNumbers == machine) = true;

        par.eventNum(par.uniquePlayers == newPlayer) = par.eventNum(par.uniquePlayers == newPlayer) + 1;
        t = data.numericTime(prevPlayerIndex) + 5; % Chose 5 just cause, need to come up with a better way to choose the offset
        dataRecord = table(par.eventNum(par.uniquePlayers == newPlayer), machine, par.initEventCode, newPlayer, 0, 0, 0, datetime(0, 1, 1, 0, 0, 0), t, 'VariableNames', par.varNames);
        par.dataHeight = par.dataHeight + 1;
        data(par.dataHeight, :) = dataRecord;
    end
    
end

function repRate = getRepRate(minTime, time, par)
    % assume that data begins at the start of a cycle
    day = time - minTime;
    dayInCycle = rem(day, par.daysPerCycle) + 1;
    interval = ceil(dayInCycle*par.intervalsPerDay);
    
    repRate = par.repRate(interval);
end