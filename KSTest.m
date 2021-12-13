% Arguments: 
% binEdges, the edges of histogram bins that are common to both distributions
% binCountsReal, the frequency in each bin for the distribution we are
% comparing to
% binCountsEst, the frequency in each bin for the distribution being tested
% Returns: a boolean indicating pass or failure


function [n, m, mean_divergence, max_divergence, p_mean, p_max, D_ref] = KSTest(figName, methodName, weighted)
%Kolmogorov-Smirnov test statistic for measuring the similarity between two
%distributions, alpha=0.05 is assumed

realPlotsDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly';
plotsDir = ['C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\', methodName];
saveDir = ['C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\KS Test Results\', methodName, '\CumDist'];
nbins = 150;
openfig(fullfile(realPlotsDir, figName));
ax = gca;
xtick = ax.XTick;
xticklabel = ax.XTickLabels;
xlabels = ax.XLabel.String;
histo = get(ax, 'Children');

binEdges = histo.BinEdges;
binCountsReal = histo.Values;

close all;

openfig(fullfile(plotsDir, figName));
ax = gca;
histo = get(ax, 'Children');
binCountsEst = histo.Values;

close all;

n = sum(binCountsEst);
m = sum(binCountsReal);

% Add on extra bins and beginning and end with zero count
% binEdges = [binEdges(1) - (binEdges(2) - binEdges(1)); binEdges];
% binEdges = [binEdges; binEdges(end) + (binEdges(2) - binEdges(1))];
% binCountsReal = [0; binCountsReal; 0];
% binCountsEst = [0; binCountsEst; 0];

% Bin midpoints
binEdges1 = binEdges(1:end-1);
binEdges2 = binEdges(2:end);
binMidpoints = (binEdges2 + binEdges1)/2;

% Relative frequency
f_r = binCountsEst;
f_r = f_r/sum(f_r);
F_r = cumsum(f_r);

% Relative frequencies real
f_r_real = binCountsReal;
f_r_real = f_r_real/sum(f_r_real);
F_r_real = cumsum(f_r_real);

% Divergences weighted by bin midpoint
D_bar = abs(F_r_real - F_r);
if weighted
    D_bar = D_bar./(10.^binMidpoints);
end


h = figure;
h.Position(3) = 800;
h.Position(4) = 660;
plot(binMidpoints, D_bar, '.');
xlabel(xlabels);
ylabel('Difference in Frequency');
xticks(xtick);
xticklabels(xticklabel);
title(['Difference Between Distributions (', methodName, ' ', figName, ')']);
saveas(h, fullfile(saveDir, ['frequencyDifference', figName, '.fig']));
saveas(h, fullfile(saveDir, ['frequencyDifference', figName, '.png']));

h = figure;
h.Position(3) = 800;
h.Position(4) = 660;
hold on;
plot(binMidpoints, F_r_real, 'r.');
plot(binMidpoints, F_r, 'b.');
title(['Relative Frequencies (', methodName, ' ', figName, ')']);
xlabel(xlabels);
ylabel('Relative Frequency');
xticks(xtick);
xticklabels(xticklabel);
legend('Real', 'Generated');
saveas(h, fullfile(saveDir, ['relativeFrequencies', figName, '.fig']));
saveas(h, fullfile(saveDir, ['relativeFrequencies', figName, '.png']))

max_divergence = max(D_bar);
mean_divergence = mean(D_bar);
D = mean_divergence;
Z_mean = sqrt((m*n)/(m+n))*D;
disp([methodName, ' Z = ', num2str(Z_mean)]);

if Z_mean >= 0 && Z_mean < 0.27
    p_mean = 1;
elseif Z_mean >= 0.27 && Z_mean < 1
    Q = exp(-1.233701*Z_mean^(-2));
    p_mean = 1 - (2.506628/Z_mean)*(Q + Q^9 + Q^25);
elseif Z_mean >= 1 && Z_mean < 3.1
    Q = exp(-2*Z_mean^2);
    p_mean = 2*(Q - Q^4 + Q^9 - Q^16);
else
    p_mean = 0;
end

D = max_divergence;
Z_max = sqrt((m*n)/(m+n))*D;
if Z_max >= 0 && Z_max < 0.27
    p_max = 1;
elseif Z_max >= 0.27 && Z_max < 1
    Q = exp(-1.233701*Z_max^(-2));
    p_max = 1 - (2.506628/Z_max)*(Q + Q^9 + Q^25);
elseif Z_max >= 1 && Z_max < 3.1
    Q = exp(-2*Z_max^2);
    p_max = 2*(Q - Q^4 + Q^9 - Q^16);
else
    p_max = 0;
end

alpha = 0.01;
c_alpha = sqrt(-0.5*log(0.5*alpha));
D_ref = c_alpha*sqrt((n+m)/(n*m));
close all;
end

