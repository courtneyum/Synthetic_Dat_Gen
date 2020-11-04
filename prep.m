% load('K:\My Drive\School\Thesis\Data\Processed\EVD0.mat');
% fields = fieldnames(EVD.data(1));
% fields = fields(1:end-1);
% T = table(EVD.data(1).machineNumber, EVD.data(1).eventCode, EVD.data(1).patronID, EVD.data(1).CI_meter, EVD.data(1).CO_meter, EVD.data(1).games_meter, EVD.data(1).time, EVD.data(1).numericTime,...
%     'VariableNames', fields);
% for i=2:length(EVD.segments)
%     T_i = table(EVD.data(i).machineNumber, EVD.data(i).eventCode, EVD.data(i).patronID, EVD.data(i).CI_meter, EVD.data(i).CO_meter, EVD.data(i).games_meter, EVD.data(i).time, EVD.data(i).numericTime,...
%     'VariableNames', fields);
%     T = [T; T_i];
% end

% patronIDs = unique(EVD.patronID);
% patronIDs(isnan(patronIDs)) = [];
% %Find player with most occurences
% max_occ = 0;
% max_pid = 0;
% for i=1:length(patronIDs)
%     occ = sum(EVD.patronID == patronIDs(i));
%     if occ > max_occ
%         max_pid = patronIDs(i);
%         max_occ = occ;
%     end
% end

%Assign event ids
% eventID = zeros(size(EVD.machineNumber));
% uniqueMachineNumbers = unique(EVD.machineNumber);
% uniqueEventCodes = unique(EVD.eventCode);
% N = length(uniqueMachineNumbers);
% E = length(uniqueEventCodes);
% 
% NIDs = E*N;
% eventID_lookupTable = 1:E*N;
% eventID_lookupTable = reshape(eventID_lookupTable, E, N);
% for i=1:E
%     for j=1:N
%         EVD_index = EVD.eventCode == uniqueEventCodes(i) & EVD.machineNumber == uniqueMachineNumbers(j);
%         eventID(EVD_index) = eventID_lookupTable(i,j);
%     end
% end
% EVD.eventID = eventID;

% convert time to integer amounts of seconds
% EVD.secondTime = EVD.numericTime*24*60*60;
% minSecondTime = min(EVD.secondTime);
% EVD.secondTime = EVD.secondTime - minSecondTime;
% EVD.secondTime = round(EVD.secondTime);

%Record deltas caused by events
% delta_t = zeros(size(EVD.machineNumber));
% delta_CI = zeros(size(EVD.machineNumber));
% delta_CO = zeros(size(EVD.machineNumber));
% delta_GP = zeros(size(EVD.machineNumber));
% for n=1:N
%     EVD_index = EVD.machineNumber == uniqueMachineNumbers(n);
%     EVD_n = EVD(EVD_index, :);
%     delta_t(EVD_index) = [NaN; EVD_n.secondTime(2:end) - EVD_n.secondTime(1:end-1)];
%     delta_CI(EVD_index) = [NaN; EVD_n.CI_meter(2:end) - EVD_n.CI_meter(1:end-1)];
%     delta_CO(EVD_index) = [NaN; EVD_n.CO_meter(2:end) - EVD_n.CO_meter(1:end-1)];
%     delta_GP(EVD_index) = [NaN; EVD_n.games_meter(2:end) - EVD_n.games_meter(1:end-1)];
% end
% EVD.delta_t = delta_t;
% EVD.delta_CI = delta_CI;
% EVD.delta_CO = delta_CO;
% EVD.delta_GP = delta_GP;

%Build state transition matrix and delta t distribution and others
EVD(isnan(EVD.delta_t), :) = [];
uniquePlayers = unique(EVD.patronID);
uniquePlayers(isnan(uniquePlayers)) = [];
J = length(uniquePlayers);
trans_mat = zeros(E*N);
delta_t = repmat({[]}, E*N);
delta_CI = repmat({[]}, E*N);
delta_CO = repmat({[]}, E*N);
delta_GP = repmat({[]}, E*N);
total_transitions = zeros(1, N*E);
for j=1:J
    EVD_index = EVD.patronID == uniquePlayers(j);
    EVD_j = EVD(EVD_index, :);
    EVD_j = sortrows(EVD_j, 'numericTime');
    if height(EVD_j) < 2
        disp(['Ignoring player ', num2str(uniquePlayers(j)), ' at j=', num2str(j)]);
        continue;
    end
    t_j = EVD_j.delta_t;
    CI_j = EVD_j.delta_CI;
    CO_j = EVD_j.delta_CO;
    GP_j = EVD_j.delta_GP;
    prevs = EVD_j.eventID(1:end-1);
    currs = EVD_j.eventID(2:end);
    trans_mat_indices = [];
    for e=1:length(currs)
        trans_mat(prevs(e), currs(e)) = trans_mat(prevs(e), currs(e)) + 1;
        %trans_mat_indices = [trans_mat_indices; sub2ind(size(trans_mat), prevs(e), currs(e))];
        %delta_t{prevs(e), currs(e)} = [delta_t{prevs(e), currs(e)}; t_j(e)];
        delta_t{prevs(e), currs(e)} = [delta_t{prevs(e), currs(e)}; EVD_j.secondTime(e) - EVD_j.secondTime(e-1)];
        delta_CI{prevs(e), currs(e)} = [delta_CI{prevs(e), currs(e)}; CI_j(e)];
        delta_CO{prevs(e), currs(e)} = [delta_CO{prevs(e), currs(e)}; CO_j(e)];
        delta_GP{prevs(e), currs(e)} = [delta_GP{prevs(e), currs(e)}; GP_j(e)];
    end
end
trans_mat = trans_mat./sum(trans_mat, 1);