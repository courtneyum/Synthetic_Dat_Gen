function joinAndSaveTransMatProbUpdate
par = setup;
load(fullfile(par.scratchDir, par.converterCoordinationFile));
par0 = coordination.par;

fileTemplate = par0.scratch_transMat;
filenames = getTransMatFiles(fileTemplate);
load(filenames{1});
par.trans_mat = coordination.trans_mat;
par.numTransitions = coordination.numTransitions;

for i=2:length(filenames)
    load(filenames{i});
    par.trans_mat.cardIn = par.trans_mat.cardIn + coordination.trans_mat.cardIn;
    par.trans_mat.cardOut = par.trans_mat.cardOut + coordination.trans_mat.cardOut;
    par.numTransitions.cardIn = par.numTransitions.cardIn + coordination.numTransitions.cardIn;
    par.numTransitions.cardOut = par.numTransitions.cardOut + coordination.numTransitions.cardOut;
end

par0 = load(fullfile(par0.dataDir, par0.parFilename));
par0 = par0.par;
par0.trans_mat = par.trans_mat;
par = par0;

par.eventIDs.cardIn = (1:par.N*par.E)';
par.eventIDs.cardOut = (1:par.N*par.E)';

% Zero out elements for which there are no real data points
nonZeroIndexCardIn = find(par.trans_mat.cardIn > 0);

nonZeroDeltaIndexCardIn = find(par.delta.key > 0);
zeroIndex = setdiff(nonZeroIndexCardIn, nonZeroDeltaIndexCardIn);
par.trans_mat.cardIn(zeroIndex) = 0;

nonZeroIndexCardOut = find(par.trans_mat.cardOut > 0);

nonZeroDeltaIndexCardOut = find(par.delta.key > 0);
zeroIndex = setdiff(nonZeroIndexCardOut, nonZeroDeltaIndexCardOut);
par.trans_mat.cardOut(zeroIndex) = 0;

% Zero out elements not on the same machine for cardIn
for i=1:length(par.uniqueMachineNumbers)
    eventIDs = par.eventID_lookupTable(:, i);
    otherEventIDs = setdiff(1:par.N*par.E, eventIDs);
    par.trans_mat.cardIn(eventIDs, otherEventIDs) = 0;
end

% Renormalize. Have to do it this way because of large matrix size
[i_in, j_in, s_in] = find(par.trans_mat.cardIn);
[i_out, j_out, s_out] = find(par.trans_mat.cardOut);
unique_i_in = unique(i_in);
unique_i_out = unique(i_out);
for k = 1:length(unique_i_in)
    currSum = sum(s_in(i_in == unique_i_in(k)));
    if currSum == 0
        continue;
    end
    s_in(i_in == unique_i_in(k)) = s_in(i_in == unique_i_in(k))/currSum;
end
for k = 1:length(unique_i_out)
    currSum = sum(s_out(i_out == unique_i_out(k)));
    if currSum == 0
        continue;
    end
    s_out(i_out == unique_i_out(k)) = s_out(i_out == unique_i_out(k))/currSum;
end

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
par.trans_mat.cardIn = sparse(i_in, j_in, s_in);
par.trans_mat.cardOut = sparse(i_out, j_out, s_out);



 % Now we can remove any event IDs that can't be reached, shrinking the
% transition matrix to a more manageable size

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
'';
end


function files=getTransMatFiles(fileTemplate)
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
    files=cellfun(@fullfile, folder, name, 'UniformOutput', false);
end
function par = setup
    try
        %GDriveRoot=getpref('School', 'GDriveRoot');
        GDriveRoot = getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end
    par.scratchDir = fullfile(GDriveRoot, 'Data', 'scratch', 'transMatProbUpdate');
    par.converterCoordinationFile = 'coordination.mat';
end