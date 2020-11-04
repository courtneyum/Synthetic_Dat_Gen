function testLauncher

par = setup;
testValues = par.(par.testField);
coordination.mean_error_prob = zeros(length(testValues), par.numTests);
coordination.mean_error_trad = coordination.mean_error_prob;
coordination.mean_error_est = coordination.mean_error_prob;
coordination.reservedMachineNumbers = struct;
coordination.(par.testField) = testValues;
coordination.par = par;

%assign tests, alternating from front to back to give each node a more even
%load
testsPerNode = ceil(length(testValues)/par.NCores);
%start = 1;
testValues_temp = testValues;
rev = false;
for i=1:par.NCores
    coordination.reserved.(['process', num2str(i)]) = [];
    for j=1:testsPerNode
        if isempty(testValues_temp)
            break;
        end
        
        if rev
            val = testValues_temp(end);
            testValues_temp(end) = [];
        else
            val = testValues_temp(1);
            testValues_temp(1) = [];
        end
        coordination.reserved.(['process', num2str(i)]) = [coordination.reserved.(['process', num2str(i)]); val];
        rev = ~rev;
    end
end
%coordination.reserved.(['process', num2str(par.NCores)]) = testValues(start:end);
save('coordination', 'coordination');

thisDir=fileparts(which(mfilename));
if par.NCores > 1
    for c=1:par.NCores
        cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.testName, '(', num2str(c), ')', ';" &'];
        unix(cmd);
    end
else
    test(1);
end
end

function par=setup
par.NMachines=10:5:200;
par.NPlayers=9;
par.NSteps=1e7;
par.PNoMove=0.9;
par.numTests = 10;
par.testName = 'test';

par.NCores = 6;
% par.matlabStartupCmd=strrep(which('addpath'),...
%     fullfile('toolbox', 'matlab', 'general', 'addpath.m'),...
%     fullfile('bin', 'matlab'));
par.matlabStartupCmd = 'matlab';
par.matlabOptions='-nojvm -nodesktop -nosplash -singleCompThread -minimize';
par.testField = 'NMachines';
end

% mostCommonPlayerOccs = zeros(size(EVD0.segments));
% players_all = mostCommonPlayerOccs;
% for i=1:length(EVD0.segments)
%     players = unique(EVD0.data(i).patronID);
%     players(isnan(players)) = [];
%     for j=1:length(players)
%         count = sum(EVD0.data(i).patronID == players(j));
%         if count > mostCommonPlayerOccs(i)
%             mostCommonPlayerOccs(i) = count;
%             players_all(i) = players(j);
%         end
%     end
% end

% load('coordination');
% mean_error_prob = coordination.mean_error_prob;
% mean_error_trad = coordination.mean_error_trad;
% mean_error_est = coordination.mean_error_est;
% for i=1:6
%     load(['coordination', num2str(i)]);
%     mean_error_prob = mean_error_prob + coordination.mean_error_prob;
%     mean_error_est = mean_error_est + coordination.mean_error_est;
%     mean_error_trad = mean_error_trad + coordination.mean_error_trad;
% end