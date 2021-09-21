function JS = JSD(figName, methodName)
realPlotsDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly';
plotsDir = ['C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\', methodName];

h = openfig(fullfile(realPlotsDir, figName));
ax = gca(h);
histo = get(ax, 'Children');

binCountsReal = histo.Values;

close all;

h = openfig(fullfile(plotsDir, figName));
ax = gca(h);
histo = get(ax, 'Children');
binCountsEst = histo.Values;

close all;

% Relative frequency
f_r = binCountsEst;
f_r = f_r/sum(f_r);

% Relative frequencies real
f_r_real = binCountsReal;
f_r_real = f_r_real/sum(f_r_real);

% Mid Distribution
M = 0.5*(f_r + f_r_real);

log_PM = log2((f_r./M));
index = isnan(log_PM) | isinf(log_PM);
log_PM(index) = [];
f_r(index) = [];

log_QM = log2((f_r_real./M));
index = isnan(log_QM) | isinf(log_QM);
log_QM(index) = [];
f_r_real(index) = [];


D_PM = sum(f_r.*log_PM);
D_QM = sum(f_r_real.*log_QM);

JS = 0.5*D_PM + 0.5*D_QM;