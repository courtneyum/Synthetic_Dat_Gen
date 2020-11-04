% Testing the relationship between forward and backward transitions
% matrices, as well as the relationship between backward transition
% matrices when collisions are(not) allowed.
function test(pid)
disp(num2str(pid));
load('coordination');
par = coordination.par;
testValues_all = par.(par.testField);
times = zeros(par.numTests, 1);

mean_error_prob = zeros(par.numTests, 1);
mean_error_est = mean_error_prob;
mean_error_trad = mean_error_prob;
testValues = coordination.reserved.(['process', num2str(pid)]);
for j=1:length(testValues)
    par.(par.testField) = testValues(j);
    tic;
    for i=1:par.numTests
        
        casino = TM_test(par);

        mean_error = (casino.TM-casino.TM0)./casino.TM0;
        mean_error = mean(mean_error, 1);
        mean_error_prob(i) = mean(mean_error);
        %disp(['Mean error in traditional method: ', num2str(mean_error_trad(i))]);

        mean_error = (casino.TM_est-casino.TM0)./casino.TM0;
        mean_error = mean(mean_error, 1);
        mean_error_est(i) = mean(mean_error);
        %disp(['Mean error in estimation method: ', num2str(mean_error_est(i))]);

        mean_error = (casino.P_move-casino.TM0)./casino.TM0;
        mean_error = mean(mean_error, 1);
        mean_error_trad(i) = mean(mean_error);
        %disp(['Mean error in p_move method: ', num2str(mean_error_est(i))]);
        times(i) = toc;
        disp(['Completed test ', num2str(i), '/', num2str(par.numTests)]);
    end
    coordination.mean_error_prob(testValues_all == testValues(j),:) = mean_error_prob;
    coordination.mean_error_est(testValues_all == testValues(j), :) = mean_error_est;
    coordination.mean_error_trad(testValues_all == testValues(j), :) = mean_error_trad;
    disp(['Completed test ', num2str(j), ' for ', num2str(testValues(j)), ' machines in ', num2str(mean(times)), ' seconds.']);
end
save(['coordination', num2str(pid)], 'coordination');

% stationary distributions
% stat0 = casino.TM0;
% stat = casino.TM;
% err0 = ones(1, size(casino.TM, 1));
% err = ones(1, size(casino.TM, 1));
% n = 1;
% while ~all(abs(err) < 1e-8)
%     stat = stat*casino.TM;
%     err = mean(stat, 1) - min(stat, [], 1);
%     n = n+1;
% end
% 
% n = 1;
% while ~all(abs(err0) < 1e-8)
%     stat0 = stat0*casino.TM0;
%     err0 = mean(stat0, 1) - min(stat0, [], 1);
%     n = n + 1;
% end