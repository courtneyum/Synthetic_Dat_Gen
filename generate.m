function generate(PID, par)

% Initialize
rng(PID);
load(fullfile(par.scratchEVD, par.converterCoordinationFile));
par = coordination.par;
saveFile = fullfile(par.scratchEVD, [par.EVDRootFilename, num2str(PID)]);
saveFileCheckpoint = fullfile(par.scratchEVD, 'checkpoints', [par.EVDRootFilename, 'check', num2str(PID)]);
NCores = par.NCores;
loadCheckpoint = par.loadCheckpoint;

par = par.params;
par.N = length(par.uniqueMachineNumbers);
par.E = length(par.uniqueEventCodes);
num_iters = par.num_iters/NCores;

par.numTransitionsAttempted = zeros(par.N, 1);
par.numTransitionsRejected = zeros(par.N, 1);
par.rejectionVarNames = {'Prev Event ID', 'Next Event ID', 'Patron ID', 'Event Num'}; % patron ID and event num identify the event that blocked the transition
par.rejections = table([], [], [], [], 'VariableNames', par.rejectionVarNames);

load(par.EVD.filename);
occupied = false(par.N, 1);
par.playerIndex = 1:par.J;
par.players = par.uniquePlayers(par.playerIndex);
par.eventNum = zeros(length(par.uniquePlayers), 1);
par.eventNum(par.playerIndex) = 1;

varNames = EVD.Properties.VariableNames(1:8);
varNames = [{'eventNum'}, varNames];
par.varNames = varNames;

par.inCycleSteps = zeros(size(par.players));

if ~loadCheckpoint
    data = table([], [], [], [], [], [], [], [], [], 'VariableNames', par.varNames);

    [data, occupied] = initializeProcess(par, data, occupied);
else
    load(saveFileCheckpoint)
    data = saveData.data;
    occupied = saveData.occupied;
    par = saveData.par;
end
par.dataHeight = height(data);

%Begin generating data
times = zeros(num_iters, 1);
par.playerLeft = false(par.J, 1);
for i=par.dataHeight:num_iters
    % Reset player pool
    tic;
    player_pool = par.players;
    if mod(i, 1000) == 1 && i > 1
        disp(['On iteration ', num2str(i), 'Time elapsed: ', num2str(times(i-1))]);
        saveData.data = data(1:par.dataHeight, :);
        saveData.occupied = occupied;
        saveData.par = par;
        save(saveFileCheckpoint, 'saveData');
    end
    
    J = length(par.players);
    for j=1:J
        
        % Select a player from the pool
        k = randi(length(player_pool));
        player = player_pool(k);
        player_pool = setdiff(player_pool, player_pool(k));
        
        % Get current state of player
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
            par.numTransitionsAttempted(n) = par.numTransitionsAttempted(n) + 1;

            % Check if already occupied
            if par.uniqueMachineNumbers(n) == curr_machineNumber || ~occupied(n)
                occ = false;
            else
                possibleTransitions = possibleTransitions([1:k-1, k+1:end]);
                trans_index = trans_index([1:k-1, k+1:end]);
                possibleTransitions = possibleTransitions/sum(possibleTransitions);
                
                % Track the rejection for statistics
                par.numTransitionsRejected(n) = par.numTransitionsRejected(n) + 1;
                lastEventOnMachine = data(find(data.machineNumber == par.uniqueMachineNumbers(n), 1, 'last'), :);
                rejection = table(curr_eventID, next_eventID, lastEventOnMachine.patronID, lastEventOnMachine.eventNum, 'VariableNames', par.rejectionVarNames);
                par.rejections = [par.rejections; rejection];
            end
        end
        
        if isempty(possibleTransitions)
            % If there are no machines the player wants to play, they
            % leave
            par.playerLeft(player == par.players) = true;
        else
            data_temp = data(1:par.dataHeight, :);
            [par, stuck] = stuckInCycle(data(find(data_temp.patronID == player, 10, 'last'), :), par, cardIn);
                
            dataRecord = makeDataRecord(curr_eventID, next_eventID, e, n, player, par);
        
            if dataRecord.numericTime > par.timeout || stuck
                par.playerLeft(player == par.players) = true;
            end
        end
        
        % Update occupied machines
        occupied(par.uniqueMachineNumbers == curr_machineNumber) = false;
        
        if par.playerLeft(player == par.players)
            par.playerLeft(player == par.players) = false;
            [data, par, occupied] = makePlayerLeave(data, occupied, player, par);
            continue;
        end
        
        dataRecord.numericTime = dataRecord.numericTime + data.numericTime(prev_index);
        occupied(n) = true;
        
        % Add event.
        par.eventNum(par.uniquePlayers == dataRecord.patronID) = par.eventNum(par.uniquePlayers == dataRecord.patronID) + 1;
        if par.dataHeight >= height(data)
            data=[data; repmat(dataRecord, 1000*par.J, 1)];
        else
            data(par.dataHeight + 1, :)=dataRecord;
        end
        par.dataHeight = par.dataHeight + 1;
    end
    times(i) = toc;
end

data(par.dataHeight + 1:end, :) = [];

% Convert time differences to absolutes
% for j=1:par.J
%     player = par.uniquePlayers(j);
%     data_j = data(data.patronID == player, :);
%     data_j = sortrows(data_j, 1);
%     for i=2:height(data_j)
%         data_j.numericTime(i) = data_j.numericTime(i-1) + data_j.numericTime(i);
%     end
%     data(data.patronID == player, :) = data_j;
% end

% Make meters cumulative
data = sortrows(data, [2,9]);
data.delta_CI = zeros(size(data.CI_meter));
data.delta_CO = data.delta_CI;
data.delta_GP = data.delta_CI;
machineNumbers = unique(data.machineNumber);
for i=1:length(machineNumbers)
    index = data.machineNumber == machineNumbers(i);
    data.CI_meter(index) = cumsum1(data.CI_meter(index));
    data.CO_meter(index) = cumsum1(data.CO_meter(index));
    data.games_meter(index) = cumsum1(data.games_meter(index));
    
    CI_meter = data.CI_meter(index);
    data.delta_CI(index) = [NaN; CI_meter(2:end) - CI_meter(1:end-1)];
    CO_meter = data.CO_meter(index);
    data.delta_CO(index) = [NaN; CO_meter(2:end) - CO_meter(1:end-1)];
    games_meter = data.games_meter(index);
    data.delta_GP(index) = [NaN; games_meter(2:end) - games_meter(1:end-1)];
end
data.numericTime = data.numericTime/(24*60*60) + par.startTime;
data.time = datetime(data.numericTime, 'ConvertFrom','datenum');

data = sortrows(data, [4,1]);
% save('Data\EVD_genNew', 'data');
% writetable(data, 'Data\EVD_genNew.csv');
save(saveFile, 'data');
end

function par = setup
    try
        GDriveRoot=getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end
    par.scratchDir=fullfile(GDriveRoot, 'Data', 'scratch');
    par.scratchEVD = fullfile(par.scratchDir, 'EVD_gen_AddX');
    par.coordinationFilename = 'coordination';
end
