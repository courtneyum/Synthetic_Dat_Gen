function buildTransMat(PID)

    par = setup;
    load(par.converterCoordinationFile);
    par = coordination.par;
    
    uniquePlayers = coordination.reservedPlayers.(['process', num2str(PID)]);
    fileIndex = find(ismember(coordination.uniquePlayers, uniquePlayers));
    
    J = length(uniquePlayers);
    i_in = []; i_out = [];
    j_in = []; j_out = [];
    s_in = []; s_out = [];
    delta.length = 0;
    delta.key = sparse(par.N*par.E, par.N*par.E);
    delta.CI = {};
    delta.CO = {};
    delta.GP = {};
    delta.t = {};
    firstMachinesCount = zeros(par.N, 1);
    playersCount = zeros(J, 1);
    for j=1:J
        n = fileIndex(j);
        load(coordination.files(n).EVD);
        EVD_j = EVD_n.data;
        EVD_j = sortrows(EVD_j, 'numericTime');
        if height(EVD_j) < 2
            disp(['Ignoring player ', num2str(uniquePlayers(j)), ' at j=', num2str(j)]);
            continue;
        end
        firstMachinesCount(par.uniqueMachineNumbers == EVD_j.machineNumber(1)) = firstMachinesCount(par.uniqueMachineNumbers == EVD_j.machineNumber(1)) + 1;
        playersCount(j) = sum(EVD_j.patronID == uniquePlayers(j));
        CI_j = EVD_j.delta_CI;
        CO_j = EVD_j.delta_CO;
        GP_j = EVD_j.delta_GP;
        prevs = EVD_j.eventID(1:end-1);
        currs = EVD_j.eventID(2:end);
        
        [prevEventCodeIndex, ~] = ind2sub(size(par.eventID_lookupTable), prevs(1));
        if par.uniqueEventCodes(prevEventCodeIndex) == 901
            cardIn = true;
        else
            cardIn = false;
        end

        for e=1:length(currs)
            [currEventCodeIndex, currMachineNumberIndex] = ind2sub(size(par.eventID_lookupTable), currs(e));
            [~, prevMachineNumberIndex] = ind2sub(size(par.eventID_lookupTable), prevs(e));
            currMachineNumber = par.uniqueMachineNumbers(currMachineNumberIndex);
            currEventCode = par.uniqueEventCodes(currEventCodeIndex);
            prevMachineNumber = par.uniqueMachineNumbers(prevMachineNumberIndex);
            if cardIn
                %Check if prev and curr are on the same machine, out of
                %order data make it possible that they aren't
                if prevMachineNumber == currMachineNumber
                    [i_in, j_in, s_in] = insert_trans(prevs(e), currs(e), i_in, j_in, s_in);
                    delta = insert_delta(delta, prevs(e), currs(e), EVD_j, e);
                end
            else
                [i_out, j_out, s_out] = insert_trans(prevs(e), currs(e), i_out, j_out, s_out);
                delta = insert_delta(delta, prevs(e), currs(e), EVD_j, e);
            end
            
            if currEventCode == 901
                cardIn = true;
            elseif currEventCode == 902
                cardIn = false;
            end
            
        end
    end
    
    par.uniquePlayers = uniquePlayers;
    par.delta = delta;
    par.i.in = i_in;
    par.i.out = i_out;
    par.j.in = j_in;
    par.j.out = j_out;
    par.s.in = s_in;
    par.s.out = s_out;
    par.playersCount = playersCount;
    par.firstMachinesCount = firstMachinesCount;
    
    save([fullfile(par.scratch_transMat, par.transMatRootFileName), num2str(PID)], 'par');
end

function par = setup
    % Get the name of the Google Drive root. This location can be set by
% running: setpref('nQube', 'GDriveRoot', 'E:\Shared drives'); or other
% location.

    try
        GDriveRoot=getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end

    par.converterCoordinationFile = fullfile(GDriveRoot, 'Data', 'scratch', 'transMatUnifOcc', 'coordination.mat');
end