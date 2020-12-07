% By loading 'EVD_semiraw.mat', we can take advantage of some of the 
% processing done by the event to session converter. 
% This processing includes only 'applyDictionary', 'table2struct', 'segmentByField', 
 %and 'correctForMachineMoves', as well as the addition of a numeric time. 
 % For data generation purposes, we need a table format.
 
load('K:\My Drive\School\Thesis\Data\Processed\EVD_semiraw.mat');
EVD = EVD0;
segments = EVD.segments;
fields = fieldnames(EVD.data(1));
fields = fields(1:end-1);
T = table(EVD.data(1).machineNumber, EVD.data(1).eventCode, EVD.data(1).patronID, EVD.data(1).CI_meter, EVD.data(1).CO_meter, EVD.data(1).games_meter, EVD.data(1).time, EVD.data(1).numericTime,...
    'VariableNames', fields);
for i=2:length(segments)
    T_i = table(EVD.data(i).machineNumber, EVD.data(i).eventCode, EVD.data(i).patronID, EVD.data(i).CI_meter, EVD.data(i).CO_meter, EVD.data(i).games_meter, EVD.data(i).time, EVD.data(i).numericTime,...
    'VariableNames', fields);
    T = [T; T_i];
end
EVD = T;
clear("T");
clear('T_i');
clear("EVD0");

% Remove events that do not indicate player activity but may have a player
% ID attached to them
EVD(EVD.eventCode == 1001, :) = [];



% Next, event IDs are assigned to each event according to the event ID lookup table. 
% For example, eventID_lookupTable(e, n) gives the event ID for an event of type e occuring on machine n. 

eventID = zeros(size(EVD.machineNumber));
uniqueMachineNumbers = unique(EVD.machineNumber(~isnan(EVD.patronID)));
uniqueEventCodes = unique(EVD.eventCode(~isnan(EVD.patronID)));
N = length(uniqueMachineNumbers);
E = length(uniqueEventCodes);
eventCodeFreq = zeros(E, 1);

NIDs = E*N;
eventID_lookupTable = cast(1:E*N, 'uint32');
eventID_lookupTable = reshape(eventID_lookupTable, E, N);
for i=1:E
    eventCodeFreq(i) = sum(EVD.eventCode(~isnan(EVD.patronID)) == uniqueEventCodes(i));
    for j=1:N
        EVD_index = EVD.eventCode == uniqueEventCodes(i) & EVD.machineNumber == uniqueMachineNumbers(j);
        eventID(EVD_index) = eventID_lookupTable(i,j);
    end
end
EVD.eventID = eventID;
par.eventID_lookupTable = eventID_lookupTable;
clear('eventID');

par.N = N;
par.E = E;
par.uniqueMachineNumbers = uniqueMachineNumbers;
par.uniqueEventCodes = uniqueEventCodes;
par.eventID_lookupTable = eventID_lookupTable;



% Times in most datasets are only precise down to the second. 
% So we can record the change in time in seconds. But to do this, 
% we must first convert the numeric times to units of seconds. 
% The minimum time present in the dataset is subtracted to prevent numbers from getting too big. 
% We can do this since we are only interested in relative time when generating new data.

EVD.secondTime = EVD.numericTime*24*60*60;
minSecondTime = min(EVD.secondTime);
EVD.secondTime = EVD.secondTime - minSecondTime;
EVD.secondTime = round(EVD.secondTime);



% We are only interested in the amount of coin-in, coin-out, and games played 
% caused by each event relative to the event that occurred previously on the same machine. 
% This must be calculated. We can also assign player ids to uncarded events that 
% take place before a card is inserted or afterwards based on sessions.

delta_CI = zeros(size(EVD.machineNumber));
delta_CO = zeros(size(EVD.machineNumber));
delta_GP = zeros(size(EVD.machineNumber));
delta_t = zeros(size(EVD.machineNumber));
for n=1:par.N
    EVD_index = EVD.machineNumber == par.uniqueMachineNumbers(n);
    EVD_n = EVD(EVD_index, :);
    EVD_n = sortrows(EVD_n, 'numericTime');
    delta_CI(EVD_index) = [NaN; EVD_n.CI_meter(2:end) - EVD_n.CI_meter(1:end-1)];
    delta_CO(EVD_index) = [NaN; EVD_n.CO_meter(2:end) - EVD_n.CO_meter(1:end-1)];
    delta_GP(EVD_index) = [NaN; EVD_n.games_meter(2:end) - EVD_n.games_meter(1:end-1)];
    delta_t(EVD_index) = [NaN; EVD_n.secondTime(2:end) - EVD_n.secondTime(1:end-1)];
end
EVD.delta_CI = delta_CI;
EVD.delta_CO = delta_CO;
EVD.delta_GP = delta_GP;
EVD.delta_t = delta_t;

load('K:\My Drive\School\Thesis\Data\Processed\sessionData-AcresNew.mat');
half_sec = 1/(24*60*60*2);
for i=1:height(sessions)
    t_start = sessions.t_start_numeric(i) - half_sec;
    t_end = sessions.t_end_numeric(i) + half_sec;
    patronID = sessions.patronID(i);
    EVD_index = EVD.machineNumber == sessions.machineNumber(i) & EVD.numericTime >= t_start & EVD.numericTime <= t_end;
    EVD.patronID(EVD_index) = patronID;
end
save('K:\My Drive\School\Thesis\Data Anonymization\Data\EVD_datGen.mat', 'EVD', '-v7.3');
clear("delta_CI");
clear("delta_CO");
clear("delta_GP");
clear("EVD_n");



% Now we are ready to build the transition matrix and associated coin-in, coin-out, games played, 
% and time elapsed distributions. Time elapsed is handled differently because with time, 
% we are interested in the time between player events. But with coin-in, coin-out, and games played, 
% we are interested in the deltas caused by the event itself on the current machine. 
% Time elapsed is a player level quantity, while the meter deltas are machine level quantities.
% The transition matrix is made right-stochastic by dividing each row by its sum.
% In the following section, the number of transitions made from each event to each other event is calculated.

uniquePlayers = unique(EVD.patronID);
uniquePlayers(isnan(uniquePlayers)) = [];
J = length(uniquePlayers);
i_in = []; i_out = [];
j_in = []; j_out = [];
s_in = []; s_out = [];
delta.key = [];
delta.CI = {};
delta.CO = {};
delta.GP = {};
delta.t = {};
firstMachines = zeros(par.N, 1);
players = zeros(J, 1);
for j=1:J
    EVD_index = EVD.patronID == uniquePlayers(j);
    EVD_j = EVD(EVD_index, :);
    EVD_j = sortrows(EVD_j, 'numericTime');
    if height(EVD_j) < 2
        disp(['Ignoring player ', num2str(uniquePlayers(j)), ' at j=', num2str(j)]);
        continue;
    end
    %firstMachines = [firstMachines; EVD_j.machineNumber(1)];
    firstMachines(par.uniqueMachineNumbers == EVD_j.machineNumber(1)) = firstMachines(par.uniqueMachineNumbers == EVD_j.machineNumber(1)) + 1;
    players(j) = sum(EVD_j.patronID == uniquePlayers(j));
    CI_j = EVD_j.delta_CI;
    CO_j = EVD_j.delta_CO;
    GP_j = EVD_j.delta_GP;
    prevs = EVD_j.eventID(1:end-1);
    currs = EVD_j.eventID(2:end);
    cardIn = false;
    for e=1:length(currs)
        if EVD_j.eventCode(e) == 901
            cardIn = true;
        elseif EVD_j.eventCode(e) == 902
            cardIn = false;
        end
        
        if cardIn
            % Check if prev and curr are on the same machine
            if EVD_j.machineNumber(e) == EVD_j.machineNumber(e+1)
                [i_in, j_in, s_in] = insert_trans(prevs(e), currs(e), i_in, j_in, s_in);
            end
        else
            [i_out, j_out, s_out] = insert_trans(prevs(e), currs(e), i_out, j_out, s_out);
        end
        delta = insert_delta(delta, prevs(e), currs(e), EVD_j, e);
    end
end

par.J = J;
par.uniquePlayers = uniquePlayers;
par.players = players/sum(players);
par.firstMachines = firstMachines/sum(firstMachines);



% This next section consists of the next step in building the transition matrices. 
% Here, the occupancy of each machine is taken into account.

load('K:\My Drive\School\Thesis\Data Anonymization\Data\sessionData-AcresNew.mat');
timeAlive = zeros(size(par.uniqueMachineNumbers));
timeOccupied = zeros(size(par.uniqueMachineNumbers));
for i=1:length(par.uniqueMachineNumbers)
    session_index = sessions.machineNumber == par.uniqueMachineNumbers(i);
    EVD_index = EVD.machineNumber == par.uniqueMachineNumbers(i);
    if ~any(session_index)
        timeOccupied(i) = 0;
    else
        timeOccupied(i) = sum(sessions.duration_numeric(session_index));
    end
    timeAlive(i) = max(EVD.numericTime(EVD_index)) - min(EVD.numericTime(EVD_index));
end

p_occ = timeOccupied./timeAlive;

for k=1:length(s_in)
    i = i_in(k);
    j = j_in(k);
    [~,n_i] = ind2sub(size(eventID_lookupTable), i);
    [~,n_j] = ind2sub(size(eventID_lookupTable), j);
    
    s_in(k) = s_in(k)/(1-p_occ(n_j));
end
for k=1:length(s_out)
    i = i_out(k);
    j = j_out(k);
    [~,n_i] = ind2sub(size(eventID_lookupTable), i);
    [~,n_j] = ind2sub(size(eventID_lookupTable), j);
    
    s_out(k) = s_out(k)/(1-p_occ(n_j));
end



% Build par structure and save it
par.i.in = i_in;
par.i.out = i_out;
par.j.in = j_in;
par.j.out = j_out;
par.s.in = s_in;
par.s.out = s_out;

trans_mat_cardIn = sparse(i_in, j_in, s_in, N*E, N*E);
trans_mat_cardOut = sparse(i_out, j_out, s_out, N*E, N*E);
par.totalTransitions.cardIn = sum(trans_mat_cardIn, 2, 'omitnan');
par.totalTransitions.cardOut = sum(trans_mat_cardOut, 2, 'omitnan');
par.trans_mat.cardIn = sparse(i_in, j_in, s_in./par.totalTransitions.cardIn(i_in), N*E, N*E);
par.trans_mat.cardOut = sparse(i_out, j_out, s_out./par.totalTransitions.cardOut(i_out), N*E, N*E);
par.delta = delta;
save('K:\My Drive\School\Thesis\Data Anonymization\Data\par.mat', 'par');



% Now we can remove any event IDs that can't be reached, shrinking the
% transition matrix to a more manageable size

par.eventIDs.cardIn = (1:N*E)';
par.eventIDs.cardOut = (1:N*E)';
deleteIndex_cardIn = [];
deleteIndex_cardOut = [];
for i=1:size(par.trans_mat.cardIn, 1)
    if all(par.trans_mat.cardIn(:,i) == 0) && all(par.trans_mat.cardIn(i,:) == 0)
        deleteIndex_cardIn = [deleteIndex_cardIn; i];
        
    end
    
    if all(par.trans_mat.cardOut(:,i) == 0) && all(par.trans_mat.cardOut(i,:) == 0)
        deleteIndex_cardOut = [deleteIndex_cardOut; i];
    end
end

par.trans_mat.cardIn(deleteIndex_cardIn,:) = [];
par.trans_mat.cardIn(:,deleteIndex_cardIn) = [];
par.eventIDs.cardIn(deleteIndex_cardIn) = [];

par.trans_mat.cardOut(deleteIndex_cardOut,:) = [];
par.trans_mat.cardOut(:,deleteIndex_cardOut) = [];
par.eventIDs.cardOut(deleteIndex_cardOut) = [];

save('K:\My Drive\School\Thesis\Data Anonymization\Data\par.mat', 'par');



% Below, we average the diagonal blocks of the transition matrix, normalized and unnormalized, 
% to get an idea about the "average" sequence of events that make up a session.

E = par.E;
N = par.N;
avgBlock_cardIn_normalized = zeros(E);
for n=1:N
    currBlock = par.trans_mat.cardIn((n-1)*E + 1:n*E, (n-1)*E + 1:n*E);
    currBlock(isnan(currBlock)) = 0;
    avgBlock_cardIn_normalized = avgBlock_cardIn_normalized + currBlock;
end
avgBlock_cardIn_normalized = avgBlock_cardIn_normalized/N;

avgBlock_cardOut_normalized = zeros(E);
for n=1:N
    currBlock = par.trans_mat.cardOut((n-1)*E + 1:n*E, (n-1)*E + 1:n*E);
    currBlock(isnan(currBlock)) = 0;
    avgBlock_cardOut_normalized = avgBlock_cardOut_normalized + currBlock;
end
avgBlock_cardOut_normalized = avgBlock_cardOut_normalized/N;