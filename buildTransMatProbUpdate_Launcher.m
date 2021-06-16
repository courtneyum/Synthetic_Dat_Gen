function buildTransMatProbUpdate_Launcher()

    par = setup;
    if ispc
        [~,par.matlabStartupCmd]=fileparts(par.matlabStartupCmd);
    else
        par.matlabStartupCmd=par.matlabStartupCmd;
    end
    
    % Delete the scratchDir if it exists. Generate a new one.
    if exist(par.scratch_transMat, 'dir')
        rmdir(par.scratch_transMat, 's');
    end
    pause(5);
    mkdir(par.scratch_transMat);
    
    disp('Generating Coordination Files');
    folder = par.scratchDir;
    baseName = regexprep(par.converterCoordinationFile, '(.*\\)+', '');
    baseName = regexprep(baseName, '.mat', '');
    filenames = dir(folder);
    filenames = struct2table(filenames);
    filenames = filenames.name;
    index = regexp(filenames, [baseName, '\d*.mat']);
    index = ~cellfun(@isempty, index);
    filenames = filenames(index);
    for i=1:length(filenames)
        delete(fullfile(folder, filenames{i}));
    end
    coordination.par = par;
    NCores = par.NCores;
    load(fullfile(par.dataDir, par.parFilename));
    load(fullfile(par.dataDir, par.EVDFilename));
    
    % sort event ids by prevalence
    topEdge = par.N*par.E + 1;
    eventIDs = 1:par.E*par.N;
    eventIDCounts = histcounts(EVD.eventID(~isnan(EVD.patronID)), 1:topEdge);
    eventIDs(eventIDCounts == 0) = [];
    eventIDCounts(eventIDCounts == 0) = [];
    [~, sortedIndex] = sort(eventIDCounts);
    eventIDs = eventIDs(sortedIndex);
    for i=1:length(eventIDs)
        process = mod(i, NCores) + 1;
        if process == 0
            process = NCores;
        end
        if ~isfield(coordination, 'reservedEventIDs') || ~isfield(coordination.reservedEventIDs, ['process', num2str(process)])
            coordination.reservedEventIDs.(['process', num2str(process)]) = [];
        end
        coordination.reservedEventIDs.(['process', num2str(process)]) = [coordination.reservedEventIDs.(['process', num2str(process)]); eventIDs(i)];
    end
    
    coordination.trans_mat.cardIn = sparse(par.N*par.E, par.N*par.E);
    coordination.trans_mat.cardOut = sparse(par.N*par.E, par.N*par.E);
    coordination.numTransitions.cardIn = zeros(size(coordination.trans_mat.cardIn, 1), 1);
    coordination.numTransitions.cardOut = zeros(size(coordination.trans_mat.cardOut, 1), 1);
    save(fullfile(coordination.par.scratch_transMat, coordination.par.converterCoordinationFile), 'coordination');
    
    thisDir=fileparts(which(mfilename));
    par = coordination.par;
    disp('Spinning up Processes');
    if par.NCores > 1
        for c=1:par.NCores
            cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.converterName, '(', num2str(c), ')', ';" &'];
            unix(cmd);
        end
    else
        %For testing
        buildTransMatProbUpdate(1);
        joinAndSaveTransMatProbUpdate;
    end
end
    
function par = setup(par)
    try
        %GDriveRoot=getpref('School', 'GDriveRoot');
        GDriveRoot = getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end

    % Scratch directory.
    par.dataDir = fullfile(GDriveRoot, 'Data');
    par.scratchDir=fullfile(par.dataDir, 'scratch');
    par.scratch_transMat=fullfile(par.scratchDir, 'transMatProbUpdate');
    par.transMatRootFileName='transMatProbUpdate4Process';
    par.NCores=8;
    par.matlabStartupCmd=strrep(which('addpath'),...
        fullfile('toolbox', 'matlab', 'general', 'addpath.m'),...
        fullfile('bin', 'matlab'));
    % par.parallel.matlabOptions='-nodisplay -nodesktop -nosplash';
    par.matlabOptions='-nojvm -nodesktop -nosplash -singleCompThread -minimize';
    par.converterName = 'buildTransMatProbUpdate';
    par.converterCoordinationFile = 'coordination';
    %par.dataDir = fullfile(GDriveRoot, 'Synthetic_Dat_Gen', 'Data');
    par.EVDFilename = 'EVD_datGen.mat';
    par.sessionDataFilename = 'sessionData-AcresNew.mat';
    par.parFilename = 'parUnifOcc.mat';
    %par.transMatFilename = 'parTest';
end