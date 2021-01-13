function buildTransitionMatrices_Launcher(par)
    par = setup(par);
    if ispc
        [~,par.matlabStartupCmd]=fileparts(par.matlabStartupCmd);
    else
        par.matlabStartupCmd=par.matlabStartupCmd;
    end
    
    % Delete the scratchDir if it exists. Generate a new one.
    if exist(par.scratch_EVD, 'dir')
        rmdir(par.scratch_EVD, 's');
    end
    if exist(par.scratch_transMat, 'dir')
        rmdir(par.scratch_transMat, 's');
    end
    pause(5);
    mkdir(par.scratch_EVD);
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
    coordination=[];
    
    load(fullfile(par.dataDir, par.EVDFilename));
    
    uniquePlayers = unique(EVD.patronID);
    uniquePlayers(isnan(uniquePlayers)) = [];
%     uniquePlayers = uniquePlayers(find(uniquePlayers == 47068):find(uniquePlayers == 99929));
    coordination.uniquePlayers = uniquePlayers;
 
    for n=1:length(uniquePlayers)
        %
        % Specify EVD file.
        coordination.files(n).EVD=fullfile(par.scratch_EVD,...
            ['EVD4player_', num2str(uniquePlayers(n))]);
        %
        % Save EVD for each machine.
        EVD_n.player=uniquePlayers(n);
        EVD_n.data=EVD(EVD.patronID == EVD_n.player, :);
        save(coordination.files(n).EVD, 'EVD_n');
    end

% *** BEGIN GENERATING SESSIONS. ***

    % Generate coordination file.
    coordination.transMatRootFileName=par.transMatRootFileName;
    coordination.par=par;
    generateCoordinationFile(coordination, par);

    thisDir=fileparts(which(mfilename));

    disp('Spinning up Processes');
    if par.NCores > 1
        for c=1:par.NCores
            %cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.converterName, ';" &'];
            cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.converterName, '(', num2str(c), ')', ';" &'];
            unix(cmd);
        end
    else
        %For testing
        buildTransMat(1);
        joinAndSaveTransMat;
    end
end

function generateCoordinationFile(coordination, par)
% Generate coordination file.

% Specify session file targets.
for n=1:length(coordination.uniquePlayers)
    coordination.files(n).transMat=fullfile(par.scratch_transMat,...
        [coordination.transMatRootFileName, num2str(coordination.uniquePlayers(n))]);
end

coordination.reservedPlayers = struct;
playersPerNode = ceil(length(coordination.uniquePlayers)/par.NCores);
start = 1;
for i=1:par.NCores-1
    coordination.reservedPlayers.(['process', num2str(i)]) = coordination.uniquePlayers(start:i*playersPerNode);
    start = i*playersPerNode + 1;
end
coordination.reservedPlayers.(['process', num2str(par.NCores)]) = coordination.uniquePlayers(start:end);
%
% Save coordination file.
save(fullfile(par.scratchDir, par.converterCoordinationFile), 'coordination');
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
    par.scratchDir=fullfile(GDriveRoot, 'Synthetic_Dat_Gen', 'Data', 'scratch');
    par.scratch_EVD=fullfile(par.scratchDir, 'EVD_transMat');
    par.scratch_transMat=fullfile(par.scratchDir, 'transMat');
    par.transMatRootFileName='transMat4Process';
    %par.NCores=8;
    par.matlabStartupCmd=strrep(which('addpath'),...
        fullfile('toolbox', 'matlab', 'general', 'addpath.m'),...
        fullfile('bin', 'matlab'));
    % par.parallel.matlabOptions='-nodisplay -nodesktop -nosplash';
    par.matlabOptions='-nojvm -nodesktop -nosplash -singleCompThread -minimize';
    par.converterName = 'buildTransMat';
    par.converterCoordinationFile = 'coordination';
    %par.dataDir = fullfile(GDriveRoot, 'Synthetic_Dat_Gen', 'Data');
    par.EVDFilename = 'EVD_datGen.mat';
    %par.transMatFilename = 'parTest';
end