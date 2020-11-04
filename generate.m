% % Initialize
% rng(0);
% par = setup;
% load(par.EVD.filename);
% occupied = zeros(par.N, 1);
% % trans_mat_cardIn_new = zeros(size(trans_mat_cardIn));
% % trans_mat_cardOut_new = zeros(size(trans_mat_cardOut));
% 
% varNames = EVD.Properties.VariableNames(1:8);
% data = table([], [], [], [], [], [], [], [], 'VariableNames', varNames);
% 
% [data, occupied] = initializeProcess(par, data, occupied);
% 
% %Begin generating data
% num_iters = par.num_iters;
% times = zeros(num_iters, par.J);
% for i=1:num_iters
%     % Reset player pool
%     player_pool = 1:par.J; player_pool = player_pool(:);
%     
%     for j=1:par.J
%         tic;
%         playerLeft = false;
%         
%         % Select a player from the pool
%         k = randi(length(player_pool));
%         player = par.uniquePlayers(player_pool(k));
%         player_pool = setdiff(player_pool, player_pool(k));
%         
%         % Get current state of player
%         prev_index = find(data.patronID == player, 1, 'last');
%         curr_machineNumber = data.machineNumber(prev_index);
%         curr_eventCode = data.eventCode(prev_index);
%         curr_eventID = par.eventID_lookupTable(par.uniqueEventCodes == curr_eventCode, par.uniqueMachineNumbers == curr_machineNumber);
%         
%         % Did we last see a card in or card out event for this player
%         cardIn_index = find(data.patronID == player & data.eventCode == 901, 1, 'last');
%         cardOut_index = find(data.patronID == player & data.eventCode == 902, 1, 'last');
%         if isempty(cardOut_index) || cardIn_index > cardOut_index
%             cardIn = true;
%         else
%             cardIn = false;
%         end
%         
%         % Choose transition
%         occ = true;
%         if cardIn
%             eventIDs = par.eventIDs.cardIn;
%             trans_index = find(par.trans_mat.cardIn(curr_eventID == eventIDs, :) > 0);
%             possibleTransitions = par.trans_mat.cardIn(curr_eventID == eventIDs, trans_index);
%         else
%             eventIDs = par.eventIDs.cardOut;
%             trans_index = find(par.trans_mat.cardOut(curr_eventID == eventIDs, :) > 0);
%             possibleTransitions = par.trans_mat.cardOut(curr_eventID == eventIDs, trans_index);
%         end
%         
%         if isempty(possibleTransitions)
%             playerLeft = true;
%             occ = false;
%         end
%         
%         while occ
%             num = rand;
%             cumsum = 0;
%             for k=1:length(possibleTransitions)
%                 cumsum = cumsum + possibleTransitions(k);
%                 if cumsum > num
%                     break;
%                 end
%             end
%             next_eventID = eventIDs(trans_index(k));
%             [e, n] = ind2sub(size(par.eventID_lookupTable), next_eventID);
% 
%             % Check if already occupied
%             if par.uniqueMachineNumbers(n) == curr_machineNumber || ~occupied(n)
%                 occ = false;
% %                 if cardIn
% %                     trans_mat_cardIn_new(curr_eventID, next_eventID) = trans_mat_cardIn_new(curr_eventID, next_eventID) + 1;
% %                 else
% %                     trans_mat_cardOut_new(curr_eventID, next_eventID) = trans_mat_cardOut_new(curr_eventID, next_eventID) + 1;
% %                 end
%             else
%                 possibleTransitions = possibleTransitions([1:k-1, k+1:end]);
%                 possibleTransitions = possibleTransitions/sum(possibleTransitions);
%             end
%             
%             if isempty(possibleTransitions)
%                 % If there are no machines the player wants to play, they
%                 % leave
%                 playerLeft = true;
%                 break;
%             end
%         end
%         
%         % Update occupied machines
%         occupied(par.uniqueMachineNumbers == curr_machineNumber) = false;
%         if playerLeft
%             continue;
%         end
%         
%         occupied(n) = true;
%         
%         % Draw accompanying info
%         index = par.delta.key(:,1) == curr_eventID & par.delta.key(:,2) == next_eventID;
%         
%         choices = par.delta.CI{index};
%         k = randi(length(choices));
%         CI = choices(k);
%         
%         choices = par.delta.CO{index};
%         k = randi(length(choices));
%         CO = choices(k);
%         
%         choices = par.delta.GP{index};
%         k = randi(length(choices));
%         GP = choices(k);
%         
%         choices = par.delta.t{index};
%         k = randi(length(choices));
%         t = choices(k);
%         
%         % Add to data
%         data_ij = table(par.uniqueMachineNumbers(n), par.uniqueEventCodes(e), player, CI, CO, GP, datetime(0, 1, 1, 0, 0, 0), t, 'VariableNames', varNames);
%         data = [data; data_ij];
%         times(i,j) = toc;
%     end
% end
% 
% % Convert time differences to absolutes
% for j=1:par.J
%     player = par.uniquePlayers(j);
%     data_j = data(data.patronID == player, :);
%     for i=2:height(data_j)
%         data_j.numericTime(i) = data_j.numericTime(i-1) + data_j.numericTime(i);
%     end
%     data(data.patronID == player, :) = data_j;
% end
% data.numericTime = data.numericTime/(24*60*60) + par.startTime;
% data.time = datetime(data.numericTime, 'ConvertFrom','datenum');

% Make meters cumulative
data = sortrows(data, [1,8]);
machineNumbers = unique(data.machineNumber);
for i=1:length(machineNumbers)
    index = data.machineNumber == machineNumbers(i);
    data.CI_meter(index) = cumsum(data.CI_meter(index));
    data.CO_meter(index) = cumsum(data.CO_meter(index));
    data.games_meter(index) = cumsum(data.games_meter(index));
end

function par = setup
    load('K:\My Drive\School\Thesis\Data Anonymization\Data\par.mat');
    par.N = length(par.uniqueMachineNumbers);
    par.E = length(par.uniqueEventCodes);
    par.J = length(par.uniquePlayers);
    par.initEventCode = 901;
    par.startTime = datenum(2020, 6, 22, 0, 0, 0);
    par.num_iters = 10000;
    par.J = 700;
    par.EVD.filename = 'K:\My Drive\School\Thesis\Data Anonymization\Data\EVD_datGen.mat';
end
