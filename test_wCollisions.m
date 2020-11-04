% Testing if we can make up a transition matrix, generate data from it,
% then get the same transition matrix back when we create a transition
% matrix from the generated data
function par = test_wCollisions(par)
% Initialize
E = par.E;
N = par.N;
J = par.J;
eventID_lookupTable = 1:E*N;
eventID_lookupTable = reshape(eventID_lookupTable, E, N);

uniquePlayers = 1:J;
uniqueEventCodes = 1:E;

uniqueMachineNumbers = 1:N;
firstMachines = 1:J;

trans_mat = par.trans_mat;

% Generate some simple data (just events, no CI, CO, GP, or time)
player_pool = 1:J; player_pool = player_pool(:);

varNames = {'machineNumber', 'eventCode', 'patronID', 'eventID'};
data = table([],[],[],[],'VariableNames', varNames);
choices = firstMachines;
occupied = zeros(N, 1);
occupiedCount = zeros(N, 1);
for j=1:J
    % Select a player from the pool
    player = j;

    % Select a machine for the player to start at
    n = randi(length(choices));
    
    % Insert initial data point
    eventID = eventID_lookupTable(1, uniqueMachineNumbers == choices(n));
    data_j = table(choices(n), 1, player, eventID, 'VariableNames', varNames);
    data = [data; data_j];

    % Update available machines and players
    machineIndex = uniqueMachineNumbers == choices(n);
    occupied(machineIndex) = true;
    player_pool = setdiff(player_pool, player_pool(k));
    choices(choices == choices(n)) = [];
end

times = zeros(par.num_iters, J);
for i=1:par.num_iters
    % Reset player pool
    player_pool = 1:J; player_pool = player_pool(:);
    
    for j=1:J
        tic;
        playerLeft = false;
        
        % Select a player from the pool
        k = randi(length(player_pool));
        player = uniquePlayers(player_pool(k));
        player_pool = setdiff(player_pool, player_pool(k));
        
        % Find out where this player is currently
        prev_index = find(data.patronID == player, 1, 'last');
        curr_machineNumber = data.machineNumber(prev_index);
        curr_eventCode = data.eventCode(prev_index);
        curr_eventID = eventID_lookupTable(1, uniqueMachineNumbers == curr_machineNumber);
        
        % Choose transition
        occ = true;
        trans_index = find(trans_mat(curr_eventID, :) > 0);
        possibleTransitions = trans_mat(curr_eventID, trans_index);
        
        if isempty(possibleTransitions)
            playerLeft = true;
            occ = false;
        end
        
        while occ
            num = rand;
            cumsum = 0;
            for k=1:length(possibleTransitions)
                cumsum = cumsum + possibleTransitions(k);
                if cumsum > num
                    break;
                end
            end
            next_eventID = trans_index(k);
            [e, n] = ind2sub(size(eventID_lookupTable), next_eventID);

            % Check if already occupied
            if uniqueMachineNumbers(n) == curr_machineNumber || ~occupied(n)
                occ = false;
            else
                possibleTransitions = possibleTransitions([1:k-1, k+1:end]);
                possibleTransitions = possibleTransitions/sum(possibleTransitions);
            end
            
            if isempty(possibleTransitions)
                % If there are no machines the player wants to play, they
                % leave
                playerLeft = true;
                break;
            end
        end
        
        % Update occupied machines
        occupied(uniqueMachineNumbers == curr_machineNumber) = false;
        if playerLeft
            %If the player did not move anywhere, don't add to data
            continue;
        end
        occupied(n) = true;
        
        % Add to data
        data_ij = table(uniqueMachineNumbers(n), 1, player, next_eventID, 'VariableNames', varNames);
        data = [data; data_ij];
        times(i,j) = toc;
    end
    % Update the number of iterations that each machine is occupied for.
    occupiedCount = occupiedCount + occupied;
end

%Now calculate trans_mat from generated data
EVD = data;
trans_mat_new = zeros(E*N);
for j=1:J
    EVD_index = EVD.patronID == uniquePlayers(j);
    EVD_j = EVD(EVD_index, :);
    if height(EVD_j) < 2
        disp(['Ignoring player ', num2str(uniquePlayers(j)), ' at j=', num2str(j)]);
        continue;
    end
    prevs = EVD_j.eventID(1:end-1);
    currs = EVD_j.eventID(2:end);
    for e=1:length(currs)
        trans_mat_new(prevs(e), currs(e)) = trans_mat_new(prevs(e), currs(e)) + 1;
    end
end
%Normalize transition matrix and return it
totalTransitions = sum(trans_mat_new, 2, 'omitnan');
par.trans_mat_new = trans_mat_new./totalTransitions;
par.occupiedCount = occupiedCount;