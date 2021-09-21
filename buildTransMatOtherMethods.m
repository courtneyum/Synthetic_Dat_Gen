function buildTransMatOtherMethods
    % These methods are most similar to the UnifOcc method, so most
    % quantities will be equal except for the probability matrices
    load('Data\parUnifOcc.mat');
    load('Data\EVD_datGen.mat');
    
    % MLE
    i_in = []; i_out = [];
    j_in = []; j_out = [];
    s_in = []; s_out = [];
    
    uniquePlayers = unique(EVD.patronID(~isnan(EVD.patronID)));
    for i=1:length(uniquePlayers)
        EVD_i = EVD(EVD.patronID == uniquePlayers(i), :);
        EVD_i = sortrows(EVD_i, 'numericTime');
        
        if height(EVD_i) < 2
            disp(['Ignoring player ', num2str(uniquePlayers(i)), ' at j=', num2str(i)]);
            continue;
        end
        
        prevs = EVD_i.eventID(1:end-1);
        currs = EVD_i.eventID(2:end);
        
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
                    %delta = insert_delta(delta, prevs(e), currs(e), EVD_j, e);
                end
            else
                [i_out, j_out, s_out] = insert_trans(prevs(e), currs(e), i_out, j_out, s_out);
                %delta = insert_delta(delta, prevs(e), currs(e), EVD_j, e);
            end
            
            if currEventCode == 901
                cardIn = true;
            elseif currEventCode == 902
                cardIn = false;
            end
            
        end
    end
    
    %Force matrices to be full-sized and square
    if ~any(i_in == par.N*par.E) || ~any(j_in == par.N*par.E)
        i_in = [i_in; par.N*par.E];
        j_in = [j_in; par.N*par.E];
        s_in = [s_in; 0];
    end

    if ~any(i_out == par.N*par.E) || ~any(j_out == par.N*par.E)
        i_out = [i_out; par.N*par.E];
        j_out = [j_out; par.N*par.E];
        s_out = [s_out; 0];
    end
    % 
    trans_mat_cardIn = sparse(i_in, j_in, s_in);
    par.N_cardIn = trans_mat_cardIn; % For computing add-x
    par.totalTransitions.cardIn = sum(trans_mat_cardIn, 2);
    trans_mat_cardOut = sparse(i_out, j_out, s_out);
    par.N_cardOut = trans_mat_cardOut;
    par.totalTransitions.cardOut = sum(trans_mat_cardOut, 2);
    par.i.in = i_in;
    par.i.out = i_out;
    par.j.in = j_in;
    par.j.out = j_out;
    par.s.in = s_in;
    par.s.out = s_out;
    % 

    % Large matrix size forces the use of for loops to normalize
    for k=1:length(s_in)
        i = i_in(k);

        if par.totalTransitions.cardIn(i) ~= 0
            % This condition will not be met if there are no transitions
            % between the last event ID and itself. It gets added onto i,j,s
            % after the fact to make sure both transition matrices are the same
            % size
            s_in(k) = s_in(k)/par.totalTransitions.cardIn(i);
        end
    end
   
    for k=1:length(s_out)
        i = i_out(k);

        if par.totalTransitions.cardOut(i) ~= 0
            s_out(k) = s_out(k)/par.totalTransitions.cardOut(i);
        end
    end
    
    par.trans_mat.cardIn = sparse(i_in, j_in, s_in);
    par.trans_mat.cardOut = sparse(i_out, j_out, s_out);
    
    % Now we can remove any event IDs that can't be reached, shrinking the
    % transition matrix to a more manageable size

    par.eventIDs.cardIn = (1:par.N*par.E)';
    par.eventIDs.cardOut = (1:par.N*par.E)';
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
    
    save('Data\parMLE.mat', 'par');
    load('Data\parMLE.mat');
    
    % Add-x, have to use for loops again because otherwise the matrices get
    % too big (150 GB)
    N_cardIn = par.N_cardIn;
    N_cardOut = par.N_cardOut;
    [i_in, j_in, s_in] = find(N_cardIn);
    unique_i_in = unique(i_in);
    cardInSum = zeros(par.N*par.E, 1);
    for i=1:length(unique_i_in)
        N_ij = s_in(i_in == unique_i_in(i));
        N_i = par.totalTransitions.cardIn(unique_i_in(i));
        k = par.N*par.E;
        s_in(i_in == unique_i_in(i)) = (N_ij + sqrt(N_i)/k)/(N_i + sqrt(N_i));
        cardInSum(unique_i_in(i)) = cardInSum(unique_i_in(i)) + sum(s_in(i_in == unique_i_in(i)));
%         s_in(i_in == unique_i_in(i)) = (s_in(i_in == unique_i_in(i)) + sqrt(par.totalTransitions.cardIn(unique_i_in(i)))/(par.N*par.E))./(par.totalTransitions.cardIn(unique_i_in(i)) + sqrt(par.totalTransitions.cardIn(unique_i_in(i))));
%         cardInSum(unique_i_in(i)) = cardInSum(unique_i_in(i)) + sum(s_in(i_in == unique_i_in(i)));
    end
    
    [i_out, j_out, s_out] = find(N_cardOut);
    unique_i_out = unique(i_out);
    cardOutSum = zeros(par.N*par.E, 1);
    for i=1:length(unique_i_out)
        N_ij = s_out(i_out == unique_i_out(i));
        N_i = par.totalTransitions.cardOut(unique_i_out(i));
        k = par.N*par.E;
        s_out(i_out == unique_i_out(i)) = (N_ij + sqrt(N_i)/k)/(N_i + sqrt(N_i));
        cardOutSum(unique_i_out(i)) = cardOutSum(unique_i_out(i)) + sum(s_out(i_out == unique_i_out(i)));
%         s_out(i_out == unique_i_out(i)) = (s_out(i_out == unique_i_out(i)) + sqrt(par.totalTransitions.cardOut(unique_i_out(i)))/(par.N*par.E))./(par.totalTransitions.cardOut(unique_i_out(i)) + sqrt(par.totalTransitions.cardOut(unique_i_out(i))));
%         cardOutSum(unique_i_out(i)) = cardOutSum(unique_i_out(i)) + sum(s_out(i_out == unique_i_out(i)));
    end
    
    %Force matrices to be full-sized and square
    if ~any(i_in == par.N*par.E) || ~any(j_in == par.N*par.E)
        i_in = [i_in; par.N*par.E];
        j_in = [j_in; par.N*par.E];
        s_in = [s_in; 0];
    end
    

    if ~any(i_out == par.N*par.E) || ~any(j_out == par.N*par.E)
        i_out = [i_out; par.N*par.E];
        j_out = [j_out; par.N*par.E];
        s_out = [s_out; 0];
    end
    
    
    % Large matrix size forces the use of for loops to normalize
    for k=1:length(s_in)
        i = i_in(k);
        if par.totalTransitions.cardIn(i) ~= 0
            % This condition will not be met if there are no transitions
            % between the last event ID and itself. It gets added onto i,j,s
            % after the fact to make sure both transition matrices are the same
            % size
            s_in(k) = s_in(k)/cardInSum(i);
        end
    end
    for k=1:length(s_out)
        i = i_out(k);
        if par.totalTransitions.cardOut(i) ~= 0
            s_out(k) = s_out(k)/cardOutSum(i);
        end
    end
    
    par.trans_mat.cardIn = sparse(i_in, j_in, s_in);
    par.trans_mat.cardOut = sparse(i_out, j_out, s_out);
    
    % Now we can remove any event IDs that can't be reached, shrinking the
    % transition matrix to a more manageable size

    par.eventIDs.cardIn = (1:par.N*par.E)';
    par.eventIDs.cardOut = (1:par.N*par.E)';
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
    
    save('Data\parAddX.mat', 'par');
    