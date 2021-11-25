function joinAndSaveTransMat
    par0 = setup;
    load(par0.converterCoordinationFile);
    par0 = coordination.par;
    fileTemplate=par0.scratch_transMat;
    %[par0.transMatRootFileName, '.*']);
    transMatFiles = getTransMatFiles(fileTemplate);
    load(transMatFiles{1});
    
    par0.playersCount = zeros(size(par0.uniquePlayers));
    par0.firstMachinesCount = zeros(size(par0.uniqueMachineNumbers));
    
    par = prepForIntegration(par, par0);
    
    trans_mat.cardIn = sparse(par.i.in, par.j.in, par.s.in);
    trans_mat.cardOut = sparse(par.i.out, par.j.out, par.s.out);
    par0.firstMachinesCount = par.firstMachinesCount;
    par0.playersCount = par.playersCount;
    delta = par.delta;
    
    for i=2:length(transMatFiles)
        load(transMatFiles{i});
        
        par = prepForIntegration(par, par0);
    
        trans_mat.cardIn = trans_mat.cardIn + sparse(par.i.in, par.j.in, par.s.in);
        trans_mat.cardOut = trans_mat.cardOut + sparse(par.i.out, par.j.out, par.s.out);
        par0.firstMachinesCount = par0.firstMachinesCount + par.firstMachinesCount;
        par0.playersCount = par0.playersCount + par.playersCount;
        
        deltaIndex = find(par.delta.key > 0);
        [m, n] = ind2sub(size(par.delta.key), deltaIndex);
        for j=1:length(deltaIndex)
            if delta.key(m(j), n(j)) == 0
                delta.length = delta.length + 1;
                delta.key(m(j), n(j)) = delta.length;
                index = delta.length;
                delta.CI(index) = {[]};
                delta.CO(index) = {[]};
                delta.GP(index) = {[]};
                delta.t(index) = {[]};
            end
            
            index = delta.key(m(j), n(j));
            
            delta.CI{index} = [delta.CI{index}; par.delta.CI{par.delta.key(m(j),n(j))}];
            delta.CO{index} = [delta.CO{index}; par.delta.CO{par.delta.key(m(j),n(j))}];
            delta.GP{index} = [delta.GP{index}; par.delta.GP{par.delta.key(m(j),n(j))}];
            delta.t{index} = [delta.t{index}; par.delta.t{par.delta.key(m(j),n(j))}];
        end
    end
    
    par0.trans_mat = trans_mat;
    par0.totalTransitions.cardIn = sum(par0.trans_mat.cardIn, 2);
    par0.totalTransitions.cardOut = sum(par0.trans_mat.cardOut, 2);
    par0.playersDist = par0.playersCount/sum(par0.playersCount);
    par0.firstMachinesDist = par0.firstMachinesCount/sum(par0.firstMachinesCount);
    par0.delta = delta;
    par = par0;
    
    % get occupancy probability matrix if not already computed
    load('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\sessionData-AcresNew.mat');
    load('K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\EVD_datGen.mat');
    timeAlive = zeros(size(par.uniqueMachineNumbers));
    for i=1:length(par.uniqueMachineNumbers)
        EVD_index = EVD.machineNumber == par.uniqueMachineNumbers(i);
        timeAlive(i) = max(EVD.numericTime(EVD_index)) - min(EVD.numericTime(EVD_index));
    end
    
    time_i_occ_j_occ = zeros(par.N);
    time_i_occ = zeros(par.N, 1);
    for i=1:height(sessions)
        session_i = sessions(i, :);
        time_i_occ(par.uniqueMachineNumbers == session_i.machineNumber) = time_i_occ(par.uniqueMachineNumbers == session_i.machineNumber) + session_i.duration_numeric;
        
        sessionIndex = sessions.t_start_numeric >= session_i.t_start_numeric & sessions.t_start_numeric < session_i.t_end_numeric;
        sessionIndex = sessionIndex | (sessions.t_end_numeric > session_i.t_start_numeric & sessions.t_end_numeric <= session_i.t_end_numeric);
        sessions_j = sessions(sessionIndex, :);
        for j=1:height(sessions_j)
            session_j = sessions_j(j, :);
            index_i = par.uniqueMachineNumbers == session_i.machineNumber;
            index_j = par.uniqueMachineNumbers == session_j.machineNumber;
            
            if session_j.t_start_numeric  >= session_i.t_start_numeric && session_j.t_end_numeric <= session_i.t_end_numeric
                %session j is fully enclosed within session i
                time_i_occ_j_occ(index_i, index_j) = time_i_occ_j_occ(index_i, index_j) + session_j.duration_numeric;
            elseif session_j.t_start_numeric < session_i.t_start_numeric && session_j.t_end_numeric < session_i.t_end_numeric
                %tail end of session j overlaps with session i
                time_i_occ_j_occ(index_i, index_j) = time_i_occ_j_occ(index_i, index_j) + session_j.t_end_numeric - session_i.t_start_numeric;
            elseif session_j.t_start_numeric > session_i.t_start_numeric && session_j.t_end_numeric > session_i.t_end_numeric
                %beginning of session j overlaps with session i
                time_i_occ_j_occ(index_i, index_j) = time_i_occ_j_occ(index_i, index_j) + session_i.t_end_numeric - session_j.t_start_numeric;
            end
        end
    end
    prob_i_occ = time_i_occ./timeAlive;
    prob_i_occ_j_unocc = repmat(prob_i_occ, 1, par.N) - time_i_occ_j_occ./timeAlive; % 1 = P(i occ) + P(i unocc) = P(i occ & j occ) + P(i occ & j unocc) + P(i unocc)
    
    par.Q = prob_i_occ_j_unocc./prob_i_occ; %The probability that j is unoccupied given that i is occupied
    
    
    [i_in, j_in, s_in] = find(par.trans_mat.cardIn);
    [i_out, j_out, s_out] = find(par.trans_mat.cardOut);


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
    par.totalTransitions.cardIn = sum(trans_mat_cardIn, 2);
    trans_mat_cardOut = sparse(i_out, j_out, s_out);
    par.totalTransitions.cardOut = sum(trans_mat_cardOut, 2);
    par.i.in = i_in;
    par.i.out = i_out;
    par.j.in = j_in;
    par.j.out = j_out;
    par.s.in = s_in;
    par.s.out = s_out;
    % 
    unique_i_in = unique(i_in);
    unique_i_out = unique(i_out);

    cardInSum = zeros(size(unique_i_in));
    for k=1:length(s_in)
        i = i_in(k);
        j = j_in(k);
        [~,n_i] = ind2sub(size(par.eventID_lookupTable), i);
        [~,n_j] = ind2sub(size(par.eventID_lookupTable), j);

        if par.totalTransitions.cardIn(i) ~= 0
            % This condition will not be met if there are no transitions
            % between the last event ID and itself. It gets added onto i,j,s
            % after the fact to make sure both transition matrices are the same
            % size
            s_in(k) = s_in(k)/par.totalTransitions.cardIn(i);
        end
        if n_i ~= n_j
            s_in(k) = s_in(k)/par.Q(n_i, n_j);
        end
        cardInSum(unique_i_in == i) = cardInSum(unique_i_in == i) + s_in(k);
    end
    cardOutSum = zeros(size(unique_i_out));
    for k=1:length(s_out)
        i = i_out(k);
        j = j_out(k);
        [~,n_i] = ind2sub(size(par.eventID_lookupTable), i);
        [~,n_j] = ind2sub(size(par.eventID_lookupTable), j);

        if par.totalTransitions.cardOut(i) ~= 0
            s_out(k) = s_out(k)/par.totalTransitions.cardOut(i);
        end
        if n_i ~= n_j
            s_out(k) = s_out(k)/par.Q(n_i,n_j);
        end
        cardOutSum(unique_i_out == i) = cardOutSum(unique_i_out == i) + s_out(k);
    end

    % Renormalize. Have to do it this way because of large matrix size
    for k = 1:length(unique_i_in)
        s_in(i_in == unique_i_in(k)) = s_in(i_in == unique_i_in(k))/cardInSum(k);
    end
    for k = 1:length(unique_i_out)
        s_out(i_out == unique_i_out(k)) = s_out(i_out == unique_i_out(k))/cardOutSum(k);
    end
    par.trans_mat.cardIn = sparse(i_in, j_in, s_in);
    par.trans_mat.cardOut = sparse(i_out, j_out, s_out);
    % 


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

    % Get Communicating Classes
    [par.commClasses.C.in, par.commClasses.closed.in] = getCommunicatingClasses(par.trans_mat.cardIn);
    [par.commClasses.C.out, par.commClasses.closed.out] = getCommunicatingClasses(par.trans_mat.cardOut);
    
    save(fullfile(par.dataDir, par.transMatFilename), 'par');
end

function sessionsFiles=getTransMatFiles(fileTemplate)
    % Get filenames matching the sessionTemplate. files are assumed to be
    % numbers, and are returned in numerically sorted order.
    d=dir(fileTemplate);
    fileNumbers=regexp({d.name}, '(\d+)\.mat$', 'tokens');
    delIndex = cellfun(@isempty, fileNumbers);
    d(delIndex) = [];
    fileNumbers=[fileNumbers{:}]; fileNumbers=[fileNumbers{:}];
    fileNumbers=str2double(fileNumbers);
    [~,index]=sort(fileNumbers);
    d=d(index);
    folder={d.folder}; name={d.name};
    sessionsFiles=cellfun(@fullfile, folder, name, 'UniformOutput', false);
end

function par = prepForIntegration(par, par0)
    if max(par.i.in) < par.N*par.E || max(par.j.in) < par.N*par.E
        par.i.in = [par.i.in; par.N*par.E];
        par.j.in = [par.j.in; par.N*par.E];
        par.s.in = [par.s.in; 0];
    end
    if max(par.i.out) < par.N*par.E || max(par.j.out) < par.N*par.E
        par.i.out = [par.i.out; par.N*par.E];
        par.j.out = [par.j.out; par.N*par.E];
        par.s.out = [par.s.out; 0];
    end
    
    playersIndex = ismember(par0.uniquePlayers, par.uniquePlayers);
    playersCount = par.playersCount;
    par.playersCount = zeros(size(par0.uniquePlayers));
    par.playersCount(playersIndex) = par0.playersCount(playersIndex) + playersCount;
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