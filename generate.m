% Initialize
rng(0);
par = setup;
load(par.EVD.filename);
occupied = false(par.N, 1);
par.playerIndex = 1:par.J;
par.players = par.uniquePlayers(par.playerIndex);
par.eventNum = zeros(length(par.uniquePlayers), 1);
par.eventNum(par.playerIndex) = 1;

varNames = EVD.Properties.VariableNames(1:8);
varNames = [{'eventNum'}, varNames];
par.varNames = varNames;
data = table([], [], [], [], [], [], [], [], [], 'VariableNames', par.varNames);

[data, occupied] = initializeProcess(par, data, occupied);
par.dataHeight = height(data);

%Begin generating data
num_iters = par.num_iters;
times = zeros(num_iters, par.J);
playerLeft = false(par.J, 1);
for i=1:num_iters
    % Reset player pool
    player_pool = par.players;
    
    for j=1:par.J
        tic;
        %playerLeft = false;
        
        % Select a player from the pool
        k = randi(length(player_pool));
        player = player_pool(k);
        player_pool = setdiff(player_pool, player_pool(k));
        
        % Get current state of player
%        if ~playerLeft(player == par.uniquePlayers)
        prev_index = find(data.patronID(1:par.dataHeight) == player, 1, 'last');
        curr_machineNumber = data.machineNumber(prev_index);
        curr_eventCode = data.eventCode(prev_index);
        curr_eventID = par.eventID_lookupTable(par.uniqueEventCodes == curr_eventCode, par.uniqueMachineNumbers == curr_machineNumber);
        
        % Did we last see a card in or card out event for this player
        cardIn_index = find(data.patronID == player & data.eventCode == 901, 1, 'last');
        cardOut_index = find(data.patronID == player & data.eventCode == 902, 1, 'last');
        if isempty(cardOut_index) || cardIn_index > cardOut_index
            cardIn = true;
        else
            cardIn = false;
        end
        
        % Choose transition
        occ = true;
        if cardIn
            eventIDs = par.eventIDs.cardIn;
            trans_index = find(par.trans_mat.cardIn(curr_eventID == eventIDs, :) > 0);
            possibleTransitions = par.trans_mat.cardIn(curr_eventID == eventIDs, trans_index);
        else
            eventIDs = par.eventIDs.cardOut;
            trans_index = find(par.trans_mat.cardOut(curr_eventID == eventIDs, :) > 0);
            possibleTransitions = par.trans_mat.cardOut(curr_eventID == eventIDs, trans_index);
        end
        
        while ~isempty(possibleTransitions) && occ
            num = rand;
            cumDist = cumsum1(possibleTransitions);
            k = find(cumDist > num, 1);
            next_eventID = eventIDs(trans_index(k));
            [e, n] = ind2sub(size(par.eventID_lookupTable), next_eventID);

            % Check if already occupied
            if par.uniqueMachineNumbers(n) == curr_machineNumber || ~occupied(n)
                occ = false;
            else
                possibleTransitions = possibleTransitions([1:k-1, k+1:end]);
                trans_index = trans_index([1:k-1, k+1:end]);
                possibleTransitions = possibleTransitions/sum(possibleTransitions);
            end
        end
        
        if isempty(possibleTransitions)
            % If there are no machines the player wants to play, they
            % leave
            playerLeft(player == par.players) = true;
        else
            dataRecord = makeDataRecord(curr_eventID, next_eventID, e, n, player, par);
        
            if dataRecord.numericTime > par.timeout
                playerLeft(player == par.players) = true;
            end
        end
        
        % Update occupied machines
        occupied(par.uniqueMachineNumbers == curr_machineNumber) = false;
        
        if playerLeft(player == par.players)
            playerLeft(player == par.players) = false;
            [data, par, occupied] = makePlayerLeave(data, occupied, player, par);
            continue;
        end
        
        occupied(n) = true;
        
        % Add session.
        par.eventNum(par.uniquePlayers == dataRecord.patronID) = par.eventNum(par.uniquePlayers == dataRecord.patronID) + 1;
        if par.dataHeight >= height(data)
            data=[data; repmat(dataRecord, 1000*par.J, 1)];
        else
            data(par.dataHeight + 1, :)=dataRecord;
        end
        par.dataHeight = par.dataHeight + 1;
        %data = [data; dataRecord];
        times(i,j) = toc;
    end
end

data(par.dataHeight + 1:end, :) = [];

% Convert time differences to absolutes
for j=1:par.J
    player = par.uniquePlayers(j);
    data_j = data(data.patronID == player, :);
    data_j = sortrows(data_j, 1);
    for i=2:height(data_j)
        data_j.numericTime(i) = data_j.numericTime(i-1) + data_j.numericTime(i);
    end
    data(data.patronID == player, :) = data_j;
end

% Make meters cumulative
data = sortrows(data, [2,9]);
machineNumbers = unique(data.machineNumber);
for i=1:length(machineNumbers)
    index = data.machineNumber == machineNumbers(i);
    data.CI_meter(index) = cumsum1(data.CI_meter(index));
    data.CO_meter(index) = cumsum1(data.CO_meter(index));
    data.games_meter(index) = cumsum1(data.games_meter(index));
end
data.numericTime = data.numericTime/(24*60*60) + par.startTime;
data.time = datetime(data.numericTime, 'ConvertFrom','datenum');

data = sortrows(data, [4,1]);
save('Data\EVD_genNew', 'data');
writetable(data, 'Data\EVD_genNew.csv');

function par = setup
    load('Data\par.mat');
    par.N = length(par.uniqueMachineNumbers);
    par.E = length(par.uniqueEventCodes);
    par.J = length(par.uniquePlayers);
    par.initEventCode = 901;
    par.startTime = datenum(2020, 6, 22, 0, 0, 0);
    par.num_iters = 1e6;
    par.J = 1;
    par.timeout = 2*3600; % 2 hr timeout in seconds
    par.EVD.filename = 'K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\EVD_datGen.mat';
end
