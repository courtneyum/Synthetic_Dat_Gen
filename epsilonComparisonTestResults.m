function epsilonComparisonTestResults(pid)

disp(num2str(pid));
par = setup;
load(fullfile(par.scratchDir, 'coordination'));
par = coordination.par;
testValues_all = par.(par.testField);
times = zeros(par.numTests, 1);

testValues = coordination.reserved.(['process', num2str(pid)]);
num_iters = zeros(length(testValues), 1);
error = zeros(length(testValues), par.NSteps);
for j=1:length(testValues)
    par.(par.testField) = testValues(j);
    for i=1:par.numTests
        tic;
        casino = epsilonComparisonTest(par);

        num_iters(j) = casino.num_iters;
        error(j, :) = casino.error;
        times(i) = toc;
        disp(['Completed test ', num2str(i), '/', num2str(par.numTests)]);
    end
    coordination.num_iters(testValues_all == testValues(j),:) = num_iters(j);
    coordination.error(testValues_all == testValues(j), :) = error(j, :);
    disp(['Completed test ', num2str(j), ' for alpha = ', num2str(testValues(j)), ' in ', num2str(mean(times)), ' seconds.']);
end
save(fullfile(par.scratchDir, ['coordination', num2str(pid)]), 'coordination', '-v7.3');
end

function par = setup
    par.scratchDir = 'K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\scratch\tests';
end