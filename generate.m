% Initialize
rng(0);
par = setup;
load(par.EVD.filename);
occupied = false(par.N, 1);
player_pool_all = par.uniquePlayers(1:par.J);
% trans_mat_cardIn_new = zeros(size(trans_mat_cardIn));
% trans_mat_cardOut_new = zeros(size(trans_mat_cardOut));

varNames = EVD.Properties.VariableNames(1:8);
par.varNames = varNames;
data = table([], [], [], [], [], [], [], [], 'VariableNames', par.varNames);

[data, occupied] = initializeProcess(par, data, occupied);

%Begin generating data
num_iters = par.num_iters;
times = zeros(num_iters, par.J);
playerLeft = false(par.J, 1);
for i=1:num_iters
    % Reset player pool
    player_pool = player_pool_all;
    
    for j=1:par.J
        tic;
        %playerLeft = false;
        
        % Select a player from the pool
        k = randi(length(player_pool));
        player = player_pool(k);
        player_pool = setdiff(player_pool, player_pool(k));
        
        % Get current state of player
%        if ~playerLeft(player == par.uniquePlayers)
        prev_index = find(data.patronID == player, 1, 'last');
        curr_machineNumber = data.machineNumber(prev_index);
        curr_eventCode = data.eventCode(prev_index);
        curr_eventID = par.eventID_lookupTable(par.uniqueEventCodes == curr_eventCode, par.uniqueMachineNumbers == curr_machineNumber);
%        else
%             % Choose unoccupied first machine from firstMachines
%             % distribution, effectively resetting the player. hopefully
%             % will prevent the drop off in events/day and players/day
%             machineChoices = par.firstMachines(ismember(par.firstMachines, par.uniqueMachineNumbers(~occupied)));
%             curr_eventCode = par.initEventCode;
%             
%             prev_index = find(data.patronID == player, 1, 'last');
%             prev_machineNumber = data.machineNumber(prev_index);
%             prev_eventCode = data.eventCode(prev_index);
%             prev_eventID = par.eventID_lookupTable(prev_eventCode == par.uniqueEventCodes, prev_machineNumber == par.uniqueMachineNumbers);
%             
%             % Only choose from machines that are possible to transition to
%             % from the previous event ID
%             choice_eventIDs = par.eventID_lookupTable(curr_eventCode == par.uniqueEventCodes, ismember(par.uniqueMachineNumbers, machineChoices));
%             possibleTransitionsIndex = par.trans_mat.cardOut(prev_eventID == par.eventIDs.cardOut, ismember(par.eventIDs.cardOut, choice_eventIDs)) > 0;
%             
%             if ~any(possibleTransitionsIndex)
%                 % Try again later
%                 continue;
%             end
%             
%             choice_eventIDs = choice_eventIDs(possibleTransitionsIndex);
%             [~, uniqueMachineChoicesIndex] = ind2sub(size(par.eventID_lookupTable), choice_eventIDs);
%             uniqueMachineChoices = par.uniqueMachineNumbers(uniqueMachineChoicesIndex);
%             machineChoices = machineChoices(ismember(machineChoices, uniqueMachineChoices));
%             curr_machineNumber = machineChoices(randi(length(machineChoices)));
%             curr_eventID = par.eventID_lookupTable(curr_eventCode == par.uniqueEventCodes, curr_machineNumber == par.uniqueMachineNumbers);
%             
%             playerLeft(player == par.uniquePlayers) = false;
%             occupied(par.uniqueMachineNumbers == curr_machineNumber) = true;
%             
%             dataRecord = makeDataRecord(prev_eventID, curr_eventID, e, n, player, par);
%             
%             % Add the event to the data
%             data = [data; dataRecord];

             
%        end
        
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
        
%         if isempty(possibleTransitions)
%             playerLeft(player == player_pool_all) = true;
%             occ = false;
%         end
        
        while ~isempty(possibleTransitions) && occ
            num = rand;
            cumDist = cumsum1(possibleTransitions);
            k = find(cumDist > num, 1);
%             for k=1:length(possibleTransitions)
%                 cumsum = cumsum + possibleTransitions(k);
%                 if cumsum > num
%                     break;
%                 end
%             end
            next_eventID = eventIDs(trans_index(k));
            [e, n] = ind2sub(size(par.eventID_lookupTable), next_eventID);

            % Check if already occupied
            if par.uniqueMachineNumbers(n) == curr_machineNumber || ~occupied(n)
                occ = false;
%                 if cardIn
%                     trans_mat_cardIn_new(curr_eventID, next_eventID) = trans_mat_cardIn_new(curr_eventID, next_eventID) + 1;
%                 else
%                     trans_mat_cardOut_new(curr_eventID, next_eventID) = trans_mat_cardOut_new(curr_eventID, next_eventID) + 1;
%                 end
            else
                possibleTransitions = possibleTransitions([1:k-1, k+1:end]);
                trans_index = trans_index([1:k-1, k+1:end]);
                possibleTransitions = possibleTransitions/sum(possibleTransitions);
            end
        end
        
        if isempty(possibleTransitions)
            % If there are no machines the player wants to play, they
            % leave
            playerLeft(player == player_pool_all) = true;
        end
        
        % Update occupied machines
        occupied(par.uniqueMachineNumbers == curr_machineNumber) = false;
        
        if playerLeft(player == player_pool_all)
            playerLeft(player == player_pool_all) = false;
            [data, player_pool_all, occupied] = makePlayerLeave(data, player_pool_all, occupied, player, par);
            continue;
        end
        
        occupied(n) = true;
        
        dataRecord = makeDataRecord(curr_eventID, next_eventID, e, n, player, par);
        data = [data; dataRecord];
        times(i,j) = toc;
    end
end

% Convert time differences to absolutes
for j=1:par.J
    player = par.uniquePlayers(j);
    data_j = data(data.patronID == player, :);
    for i=2:height(data_j)
        data_j.numericTime(i) = data_j.numericTime(i-1) + data_j.numericTime(i);
    end
    data(data.patronID == player, :) = data_j;
end
data.numericTime = data.numericTime/(24*60*60) + par.startTime;
data.time = datetime(data.numericTime, 'ConvertFrom','datenum');

% Make meters cumulative
data = sortrows(data, [1,8]);
machineNumbers = unique(data.machineNumber);
for i=1:length(machineNumbers)
    index = data.machineNumber == machineNumbers(i);
    data.CI_meter(index) = cumsum1(data.CI_meter(index));
    data.CO_meter(index) = cumsum1(data.CO_meter(index));
    data.games_meter(index) = cumsum1(data.games_meter(index));
end

function par = setup
    load('K:\My Drive\School\Thesis\Data Anonymization\Data\par.mat');
    par.N = length(par.uniqueMachineNumbers);
    par.E = length(par.uniqueEventCodes);
    par.J = length(par.uniquePlayers);
    par.initEventCode = 901;
    par.startTime = datenum(2020, 6, 22, 0, 0, 0);
    par.num_iters = 1e2;
    par.J = 700;
    par.EVD.filename = 'K:\My Drive\School\Thesis\Data Anonymization\Data\EVD_datGen.mat';
end
