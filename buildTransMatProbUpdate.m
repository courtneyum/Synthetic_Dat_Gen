function par =  buildTransMatProbUpdate(pid)
% Transition Matrix Using the Probability update method
par = setup;
load(fullfile(par.scratchDir, par.converterCoordinationFile));
par = coordination.par;
load(fullfile(par.dataDir, par.EVDFilename));
load(fullfile(par.dataDir, par.sessionDataFilename));
load(fullfile(par.dataDir, par.parFilename));

eventIDs = coordination.reservedEventIDs.(['process', num2str(pid)]);
EVD = EVD(~isnan(EVD.patronID), :);
EVD = sortrows(EVD, [3,8]);

trans_mat = coordination.trans_mat;
numTransitions = coordination.numTransitions;

cardInIndex = find(EVD.eventCode == 901);
cardOutIndex = find(EVD.eventCode == 902);

prevIndex = [];
currIndex = [];
for i=1:length(eventIDs)
    prevIndex_i = find(EVD.eventID == eventIDs(i));
    prevIndex = [prevIndex; prevIndex_i];
    currIndex = [currIndex; prevIndex_i + 1];
end
prevIndex(currIndex > height(EVD)) = [];
currIndex(currIndex > height(EVD)) = [];

cardInFlag = false(length(prevIndex), 1);
for i=1:length(prevIndex)
    inIndex = find(cardInIndex <= prevIndex(i) & EVD.patronID(cardInIndex) == EVD.patronID(prevIndex(i)), 1, 'last');
    outIndex = find(cardOutIndex <= prevIndex(i) & EVD.patronID(cardOutIndex) == EVD.patronID(prevIndex(i)), 1, 'last');
    
    if ~isempty(inIndex) && isempty(outIndex)
        cardInFlag(i) = true;
    elseif ~isempty(inIndex) && ~isempty(outIndex) && cardInIndex(inIndex) > cardOutIndex(outIndex)
        cardInFlag(i) = true;
    end
end

disp(['Processing ', num2str(length(prevIndex)), ' events']);


occ = false(par.N*par.E, 1);
for j=1:length(prevIndex)
    if mod(j, 1000) == 0
        disp(['Processed ', num2str(j), '/' num2str(length(prevIndex)), ' events']);
    end
    if EVD.patronID(prevIndex(j)) ~= EVD.patronID(currIndex(j))
        continue;
    end
    prevEventID = EVD.eventID(prevIndex(j));
    currEventID = EVD.eventID(currIndex(j));
    [~,prevN] = ind2sub(size(par.eventID_lookupTable), prevEventID);
    [~,currN] = ind2sub(size(par.eventID_lookupTable), currEventID);
    transitionTime = EVD.numericTime(currIndex(j));

    occupiedSessionIndex = transitionTime > sessions.t_start_numeric & transitionTime < sessions.t_end_numeric;
    if any(occupiedSessionIndex)
        occupiedMachineNumbers = sessions.machineNumber(occupiedSessionIndex);
        [~,~,occupiedMachineNumbersIndex] = intersect(occupiedMachineNumbers, par.uniqueMachineNumbers);
        occupiedEventIDs = par.eventID_lookupTable(:, occupiedMachineNumbersIndex);
        occ(occupiedEventIDs) = true;
    end
    occ(currEventID) = true;

    if cardInFlag(j) && prevN == currN %Need to second condition to make sure out of order data isn't used to inform on probabilities
        numTransitions.cardIn(prevEventID) = numTransitions.cardIn(prevEventID) + 1;
        occ_i = occ;

        numZeros = sum(trans_mat.cardIn(prevEventID, ~occ_i) == 0);

        sum_p_j = sum(trans_mat.cardIn(prevEventID, ~occ_i)) + numZeros/(par.N*par.E);
        if trans_mat.cardIn(prevEventID, currEventID) == 0
            eps = 1/(par.N*par.E);
        else
            eps = 0;
        end
        trans_mat.cardIn(prevEventID, currEventID) = trans_mat.cardIn(prevEventID, currEventID) + sum_p_j/numTransitions.cardIn(prevEventID) + eps;
        temp = trans_mat.cardIn(prevEventID, ~occ_i);
        temp(temp == 0) = 1/(par.N*par.E);
        trans_mat.cardIn(prevEventID, ~occ_i) = temp;
        trans_mat.cardIn(prevEventID, ~occ_i) = trans_mat.cardIn(prevEventID, ~occ_i)*(1 - 1/numTransitions.cardIn(prevEventID));


    elseif ~cardInFlag(j)
        numTransitions.cardOut(prevEventID) = numTransitions.cardOut(prevEventID) + 1;
        occ_i = occ;

        numZeros = sum(trans_mat.cardOut(prevEventID, ~occ_i) == 0);

        sum_p_j = sum(trans_mat.cardOut(prevEventID, ~occ_i)) + numZeros/(par.E*par.N);
        if trans_mat.cardOut(prevEventID, currEventID) == 0
            eps = 1/(par.N*par.E);
        else
            eps = 0;
        end
        trans_mat.cardOut(prevEventID, currEventID) = trans_mat.cardOut(prevEventID, currEventID) + sum_p_j/numTransitions.cardOut(prevEventID) + eps;
        temp = trans_mat.cardOut(prevEventID, ~occ_i);
        temp(temp == 0) = 1/(par.N*par.E);
        trans_mat.cardOut(prevEventID, ~occ_i) = temp;
        trans_mat.cardOut(prevEventID, ~occ_i) = trans_mat.cardOut(prevEventID, ~occ_i)*(1 - 1/numTransitions.cardOut(prevEventID));

    end
        
end
coordination.numTransitions = numTransitions;
coordination.trans_mat = trans_mat;

save(fullfile(coordination.par.scratch_transMat, [coordination.par.transMatRootFileName, num2str(pid)]), 'coordination', '-v7.3');

'';
end

function par = setup
    try
        GDriveRoot = getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end

    % Scratch directory.
    par.scratchDir=fullfile(GDriveRoot, 'Data', 'scratch', 'transMatProbUpdate');
    par.converterCoordinationFile = 'coordination';
end