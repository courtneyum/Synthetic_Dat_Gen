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
% This must be calculated. 

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

% We can also assign player ids to uncarded events that 
% take place before a card is inserted or afterwards based on sessions.
load('K:\My Drive\School\Thesis\Data\Processed\sessionData-AcresNew.mat');
half_sec = 1/(24*60*60*2);
for i=1:height(sessions)
    t_start = sessions.t_start_numeric(i) - half_sec;
    t_end = sessions.t_end_numeric(i) + half_sec;
    patronID = sessions.patronID(i);
    EVD_index = EVD.machineNumber == sessions.machineNumber(i) & EVD.numericTime >= t_start & EVD.numericTime <= t_end;
    EVD.patronID(EVD_index) = patronID;
end

% When a session ends, how many more start up within an hour?
% This is the rate at which players are replaced
t_start = floor(min(sessions.t_start_numeric));
t_end = ceil(max(sessions.t_end_numeric));
intervalsPerDay = 6;
M = (t_end - t_start)*(intervalsPerDay); % number of intervals between t_start and t_end
repRate = zeros(M, 1);
for m=1:M
    interval_start = (m-1)/intervalsPerDay + t_start;
    interval_end = m/intervalsPerDay + t_start;
    departures = sum(sessions.t_end_numeric > interval_start & sessions.t_end_numeric < interval_end);
    arrivals = sum(sessions.t_start_numeric > interval_start & sessions.t_start_numeric < interval_end);
    repRate(m) = arrivals/departures;
end
repRate(isinf(repRate)) = NaN;

% Use a weekly cycle to model player replacement
daysPerCycle = 7;
intervalsPerCycle = daysPerCycle*intervalsPerDay;
numCycles = floor((t_end - t_start)/daysPerCycle);
cutoff = length(repRate) - rem(t_end - t_start, daysPerCycle);
repRate = repRate(1:cutoff);
repRate = reshape(repRate, numCycles, intervalsPerCycle);
repRate = mean(repRate, 1, 'omitnan');
%Data starts on Wednesday to need to shift by three days
repRate = circshift(repRate, 3*intervalsPerDay);
par.playerReplacement.repRate = repRate;
par.playerReplacement.intervalsPerDay = intervalsPerDay;
par.playerReplacement.daysPerCycle = daysPerCycle;
par.playerReplacement.numCycles = numCycles;

% Delete events for players that don't have any valid sessions. This is
% usually indicative of bad data
uniquePlayers_sessions = unique(sessions.patronID);
uniquePlayers_EVD = unique(EVD.patronID);
uniquePlayers_EVD(isnan(uniquePlayers_EVD)) = [];
uniquePlayers_del = find(~ismember(uniquePlayers_EVD, uniquePlayers_sessions));
for i=1:length(uniquePlayers_del)
    EVD(EVD.patronID == uniquePlayers_del(i), :) = [];
end
save('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\EVD_datGen.mat', 'EVD', '-v7.3');
clear("delta_CI");
clear("delta_CO");
clear("delta_GP");
clear("EVD_n");

% 
% Now we are ready to build the transition matrix and associated coin-in, coin-out, games played, 
% and time elapsed distributions. Time elapsed is handled differently because with time, 
% we are interested in the time between player events. But with coin-in, coin-out, and games played, 
% we are interested in the deltas caused by the event itself on the current machine. 
% Time elapsed is a player level quantity, while the meter deltas are machine level quantities.
% The transition matrix is made right-stochastic by dividing each row by its sum.
% In the following section, the number of transitions made from each event to each other event is calculated.
% 

% Save created par structure in 'par0.mat'
uniquePlayers = unique(EVD.patronID);
uniquePlayers(isnan(uniquePlayers)) = [];
J = length(uniquePlayers);
par.J = J;
par.uniquePlayers = uniquePlayers;
% par = setupForTransMatBuild(par);
save('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\par0.mat', 'par'); % par0 denotes a par structure ready for building probability matrices and distributions
% buildTransitionMatrices_Launcher(par);
% load(fullfile(par.dataDir, par.transMatFilename));
% 
% %Build transition matrix using probability update method, requires building
% %of transition matrix via uniform occupancy first
% par = buildTransMatProbUpdate(par);


% Below, we average the diagonal blocks of the transition matrix, normalized and unnormalized, 
% to get an idea about the "average" sequence of events that make up a session.

% E = par.E;
% N = par.N;
% avgBlock_cardIn_normalized = zeros(E);
% for n=1:N
%     currBlock = par.trans_mat.cardIn((n-1)*E + 1:n*E, (n-1)*E + 1:n*E);
%     currBlock(isnan(currBlock)) = 0;
%     avgBlock_cardIn_normalized = avgBlock_cardIn_normalized + currBlock;
% end
% avgBlock_cardIn_normalized = avgBlock_cardIn_normalized/N;
% 
% avgBlock_cardOut_normalized = zeros(E);
% for n=1:N
%     currBlock = par.trans_mat.cardOut((n-1)*E + 1:n*E, (n-1)*E + 1:n*E);
%     currBlock(isnan(currBlock)) = 0;
%     avgBlock_cardOut_normalized = avgBlock_cardOut_normalized + currBlock;
% end
% avgBlock_cardOut_normalized = avgBlock_cardOut_normalized/N;

function par = setupForTransMatBuild(par)
    try
        %GDriveRoot=getpref('School', 'GDriveRoot');
        GDriveRoot = getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end
    
    par.transMatFilename = 'parUnifOcc';
    par.dataDir = fullfile(GDriveRoot, 'Synthetic_Dat_Gen', 'Data');
    par.NCores = 8;
end
