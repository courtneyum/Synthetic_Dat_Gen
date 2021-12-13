function testLauncher

par = setup;

% Delete the scratchDir if it exists. Generate a new one.
if exist(par.scratchDir, 'dir')
    rmdir(par.scratchDir, 's');
end
pause(5);
mkdir(par.scratchDir);

testValues = par.(par.testField);
coordination.mean_error_prob = zeros(length(testValues), par.numTests);
coordination.mean_error_trad = coordination.mean_error_prob;
coordination.mean_error_est = coordination.mean_error_prob;
coordination.mean_error_new = coordination.mean_error_prob;
coordination.max_error_prob = zeros(length(testValues), par.numTests);
coordination.max_error_trad = coordination.mean_error_prob;
coordination.max_error_est = coordination.mean_error_prob;
coordination.max_error_new = coordination.mean_error_prob;
% coordination.num_iters = coordination.mean_error_prob;
% coordination.error = zeros(length(testValues), par.NSteps);
coordination.reservedMachineNumbers = struct;
coordination.(par.testField) = testValues;
coordination.par = par;

%assign tests, alternating from front to back to give each node a more even
%load, test values at the end are more time intensive than test values at
%the beginning
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
save(fullfile(par.scratchDir, 'coordination'), 'coordination', '-v7.3');

thisDir=fileparts(which(mfilename));
if par.NCores > 1
    for c=1:par.NCores
        cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.testName, '(', num2str(c), ')', ';" &'];
        unix(cmd);
    end
else
    %test(1);
    f = par.testFunctionHandle;
    f(1);
    joinAndViewTests;
end
end

function par=setup
par.NMachines=5;
par.NPlayers = 2;
par.NSteps=10.^8;
par.alpha = -1:0.1:1;
par.precision = 1e-3;
par.PNoMove=0.9;
par.numTests = 1;
par.testName = 'epsilonComparisonTestResults';
par.testFunctionHandle = @epsilonComparisonTestResults;

par.NCores = 1;
% par.matlabStartupCmd=strrep(which('addpath'),...
%     fullfile('toolbox', 'matlab', 'general', 'addpath.m'),...
%     fullfile('bin', 'matlab'));
par.matlabStartupCmd = 'matlab';
par.matlabOptions='-nojvm -nodesktop -nosplash -singleCompThread -minimize';
if length(par.NMachines) > 1
    par.testField = 'NMachines';
elseif length(par.NPlayers) > 1
    par.testField = 'NPlayers';
elseif length(par.NSteps) > 1
    par.testField = 'NSteps';
elseif length(par.alpha) > 1
    par.testField = 'alpha';
else
    par.testField = 'NMachines';
end

par.scratchDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\scratch\tests';
end