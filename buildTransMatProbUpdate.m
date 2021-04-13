function par =  buildTransMatProbUpdate(par)
% Transition Matrix Using the Probability update method
load('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\sessionData-AcresNew.mat');
load('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\parUnifOcc.mat');
load('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\EVD_datGen.mat');
trans_mat.cardIn = ones(size(par.trans_mat.cardIn))/size(par.trans_mat.cardIn, 1);
trans_mat.cardOut = ones(size(par.trans_mat.cardOut))/size(par.trans_mat.cardOut, 1);
eventIDs.cardIn = par.eventIDs.cardIn;
eventIDs.cardOut = par.eventIDs.cardOut;
EVD = EVD(~isnan(EVD.patronID), :);
EVD = sortrows(EVD, [3,8]);
cardIn = false;
occ = false(par.N*par.E, 1);
uniquePlayers = unique(EVD.patronID);
numTransitions.cardIn = zeros(size(trans_mat.cardIn, 1), 1);
numTransitions.cardOut = zeros(size(trans_mat.cardOut, 1), 1);
for i=1:length(uniquePlayers)
    EVD_i = EVD(EVD.patronID == uniquePlayers(i), :);
    for j=1:height(EVD_i)-1
        prevEventID = EVD_i.eventID(j);
        currEventID = EVD_i.eventID(j+1);
        transitionTime = EVD_i.numericTime(j+1);
        
        if any(currEventID == par.eventID_lookupTable(par.uniqueEventCodes == 901, :))
            cardIn = true;
        end
        
        if any(currEventID == par.eventID_lookupTable(par.uniqueEventCodes == 902, :))
            cardIn = false;
        end
        
        occupiedSessionIndex = transitionTime > sessions.t_start_numeric & transitionTime < sessions.t_end_numeric;
        if any(occupiedSessionIndex)
            occupiedMachineNumbers = sessions.machineNumber(occupiedSessionIndex);
            [~,~,occupiedMachineNumbersIndex] = intersect(occupiedMachineNumbers, par.uniqueMachineNumbers);
            occupiedEventIDs = par.eventID_lookupTable(:, occupiedMachineNumbersIndex);
            occ(occupiedEventIDs) = true;
        end
        occ(currEventID) = true;
        
        if cardIn
            prevEventIDIndex = prevEventID == eventIDs.cardIn;
            currEventIDIndex = currEventID == eventIDs.cardIn;
            numTransitions.cardIn(prevEventIDIndex) = numTransitions.cardIn(prevEventIDIndex) + 1;
            [~, ~, occIndex] = intersect(eventIDs.cardIn, 1:par.N*par.E);
            occ_i = occ(occIndex);
            sum_p_j = sum(trans_mat.cardIn(prevEventIDIndex, ~occ_i));
            if any(prevEventIDIndex) && any(currEventIDIndex)
                trans_mat.cardIn(prevEventIDIndex, currEventIDIndex) = trans_mat.cardIn(prevEventIDIndex, currEventIDIndex) + sum_p_j/numTransitions.cardIn(prevEventIDIndex);
                trans_mat.cardIn(prevEventIDIndex, ~occ_i) = trans_mat.cardIn(prevEventIDIndex, ~occ_i)*(1 - 1/numTransitions.cardIn(prevEventIDIndex));
            end
                
        else
            prevEventIDIndex = prevEventID == eventIDs.cardOut;
            currEventIDIndex = currEventID == eventIDs.cardOut;
            numTransitions.cardOut(prevEventIDIndex) = numTransitions.cardOut(prevEventIDIndex) + 1;
            [~, ~, occIndex] = intersect(eventIDs.cardOut, 1:par.N*par.E);
            occ_i = occ(occIndex);
            sum_p_j = sum(trans_mat.cardOut(prevEventIDIndex, ~occ_i));
            if any(prevEventIDIndex) && any(currEventIDIndex == eventIDs.cardOut)
                trans_mat.cardOut(prevEventIDIndex, currEventIDIndex) = trans_mat.cardOut(prevEventIDIndex, currEventIDIndex) + sum_p_j/numTransitions.cardOut(prevEventIDIndex);
                trans_mat.cardOut(prevEventIDIndex, ~occ_i) = trans_mat.cardOut(prevEventIDIndex, ~occ_i)*(1 - 1/numTransitions.cardOut(prevEventIDIndex));
            end
        end
        
    end
end

par.trans_mat.cardIn = trans_mat.cardIn;
par.trans_mat.cardOut = trans_mat.cardOut;
par.eventIDs.cardIn = eventIDs.cardIn;
par.eventIDs.cardOut = eventIDs.cardOut;
[par.commClasses.C.in, par.commClasses.closed.in] = getCommunicatingClasses(par.trans_mat.cardIn);
[par.commClasses.C.out, par.commClasses.closed.out] = getCommunicatingClasses(par.trans_mat.cardOut);

save('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\parProbUpdate.mat', 'par');
end