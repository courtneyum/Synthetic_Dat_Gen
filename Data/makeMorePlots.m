methodName = 'UnifOcc';
load(['sessionData-GenSingle', methodName]);
load(['EVDGen_Single', methodName, '.mat']);
% load('EVD_datGenCarded.mat');
% load('sessionData-AcresCarded.mat');

realPlotsDir = fullfile('figs', 'resultsReal', 'cardedOnly');
saveDir = fullfile('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement', methodName);
data = EVD;

days = min(floor(data.numericTime)):max(floor(data.numericTime));
days = days(:);
days = sort(days);
days = days(1:floor(0.95*length(days)));
days = [days; days(end) + 1];

% Events per day plot
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
rootFilename = 'eventsPerDay';
days_cont = min(days):max(days);
eventsPerDay = zeros(length(days_cont) - 1, 1);
for i=1:length(days_cont) - 1
    eventsPerDay(i) = sum(data.numericTime >= days_cont(i) & data.numericTime < days_cont(i+1));
end
plot(ax, eventsPerDay);
title(ax, ['Events Per Day (', methodName, ')']);
xlabel(ax, 'Day');
ylabel(ax, 'Number of Events');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% Events per day hist
rootFilename = 'eventsPerDayHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, eventsPerDay(1:end-1));
else
    histogram(ax, eventsPerDay(1:end-1), binedges);
end
title(ax, ['Events Per Day (', methodName, ')']);
xlabel(ax, 'Events Per Day');
ylabel(ax, 'Count');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% Players per day plot
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
rootFilename = 'playersPerDayEventData';
playersPerDay = zeros(length(days_cont) - 1, 1);
for i=1:length(days_cont) - 1
    players = data.patronID(data.numericTime >= days_cont(i) & data.numericTime < days_cont(i+1));
    playersPerDay(i) = length(unique(players));
end
plot(ax, playersPerDay);
title(ax, ['Players Per Day From Event Data (', methodName, ')']);
xlabel(ax, 'Day');
ylabel(ax, 'Number of Players');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'playersPerDayEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, playersPerDay);
else
    histogram(ax, playersPerDay, binedges);
end
title(ax, ['Players Per Day From Event Data (', methodName, ')']);
xlabel(ax, 'Players Per Day');
ylabel(ax, 'Count');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
rootFilename = 'playersPerDaySessionData';
playersPerDay = zeros(length(days_cont) - 1, 1);
for i=1:length(days_cont) - 1
    players = sessions.patronID(sessions.t_start_numeric >= days_cont(i) & sessions.t_start_numeric < days_cont(i+1));
    playersPerDay(i) = length(unique(players));
end
plot(ax, playersPerDay);
title(ax, ['Players Per Day From Session Data (', methodName, ')']);
xlabel(ax, 'Day');
ylabel(ax, 'Number of Players');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'playersPerDaySessionDataHist';
if ~ strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, playersPerDay);
else
    histogram(ax, playersPerDay, binedges);
end
title(ax, ['Players Per Day From Session Data (', methodName, ')']);
xlabel(ax, 'Players Per Day');
ylabel(ax, 'Count');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


% Active Machines Per Day
rootFilename = 'machinesPerDayEventData';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make y axis line up with real plot
    ax = gca(h);
    ylimitsReal = ax.YLim;
end
machinesPerDay = zeros(length(days_cont) - 1, 1);
for i=1:length(days_cont) - 1
    machines = data.machineNumber(data.numericTime >= days_cont(i) & data.numericTime < days_cont(i+1));
    machinesPerDay(i) = length(unique(machines));
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
plot(ax, machinesPerDay);

if ~strcmpi(methodName, 'real')
    ylimits = ax.YLim;
    if ylimits(2) < ylimitsReal(2)
        yimits = ylimitsReal;
    end
    ylim(ylimits);
end
title(ax, ['Active Machines Per Day From Event Data (', methodName, ')']);
xlabel(ax, 'Day');
ylabel(ax, 'Number of Machines');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'machinesPerDayEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, machinesPerDay);
else
    histogram(ax, machinesPerDay, binedges);
end
title(ax, ['Active Machines Per Day From Event Data (', methodName, ')']);
xlabel(ax, 'Active Machines Per Day');
ylabel(ax, 'Count (Days)');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'machinesPerDaySessionData';
machinesPerDay = zeros(length(days_cont) - 1, 1);
for i=1:length(days_cont) - 1
    machines = sessions.machineNumber(sessions.t_start_numeric >= days_cont(i) & sessions.t_start_numeric < days_cont(i+1));
    machinesPerDay(i) = length(unique(machines));
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
plot(ax, machinesPerDay);
title(ax, ['Active Machines Per Day From Session Data (', methodName, ')']);
xlabel(ax, 'Day');
ylabel(ax, 'Number of Machines');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'machinesPerDaySessionDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, machinesPerDay);
else
    histogram(ax, machinesPerDay, binedges);
end
title(ax, ['Active Machines Per Day From Session Data (', methodName, ')']);
xlabel(ax, 'Active Machines Per Day');
ylabel(ax, 'Count (Days)');

filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


rootFilename = 'CIEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end

scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
data = sortrows(data, [2,9]);
uniqueMachineNumbers = unique(data.machineNumber);
deltaCI = data.delta_CI;
deltaCI(deltaCI < 0) = [];
if isempty(binedges)
    histogram(ax, log10(deltaCI));
else
    histogram(ax, log10(deltaCI), binedges);
end
title(ax, ['CI From Event Data (', methodName, ')']);
xlabel(ax, 'log10(CI)');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

rootFilename = 'gamesPlayedEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end

deltaGP = data.delta_GP;
deltaGP(deltaGP < 0) = [];

scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, log10(deltaGP));
else
    histogram(ax, log10(deltaGP), binedges);
end
title(ax, ['Games Played From Event Data (', methodName, ')']);
xlabel(ax, 'log10(Games Played)');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

%Histogram of machines
rootFilename = 'machineIndexEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);

if isempty(binedges)
    histogram(ax, data.machineIndex(~isnan(data.patronID)));
else
    histogram(ax, data.machineIndex(~isnan(data.patronID)), binedges);
end
title(ax, ['Frequency of Machine Numbers From Event Data (', methodName, ')']);
xlabel(ax, 'Machine Number By Index');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

rootFilename = 'machineIndexSessionDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);

if isempty(binedges)
    histogram(ax, sessions.machineIndex);
else
    histogram(ax, sessions.machineIndex, binedges);
end
title(ax, ['Frequency of Machine Numbers From Session Data (', methodName, ')']);
xlabel(ax, 'Machine Number By Index');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

%Histogram of players
rootFilename = 'playerIndexEventDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
rootFilename = 'playerIndexEventDataHist';
if isempty(binedges)
    histogram(ax, data.playerIndex(data.playerIndex ~= 0));
else
    histogram(ax, data.playerIndex(data.playerIndex ~= 0), binedges);
end
title(ax, ['Frequency of Patron IDs From Event Data (', methodName, ')']);
xlabel(ax, 'Patron ID By Index');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

rootFilename = 'playerIndexSessionDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, sessions.playerIndex(sessions.playerIndex ~= 0));
else
    histogram(ax, sessions.playerIndex(sessions.playerIndex ~= 0), binedges);
end
title(ax, ['Frequency of Patron IDs From Session Data (', methodName, ')']);
xlabel(ax, 'Patron ID By Index');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);


% Time elapsed between events histogram
data.secondTime = data.numericTime*24*60*60;
minSecondTime = min(data.secondTime);
data.secondTime = data.secondTime - minSecondTime;
data.secondTime = round(data.secondTime);
uniqueMachines = unique(data.machineNumber);
timeElapsed = NaN(size(data.machineNumber));
data = sortrows(data, [2,9]);
for i=1:length(uniqueMachines)
    secondTime = data.secondTime(data.machineNumber == uniqueMachines(i));
    timeDiffs = [NaN; secondTime(2:end) - secondTime(1:end-1)];
    timeElapsed(data.machineNumber == uniqueMachines(i)) = timeDiffs;
end

rootFilename = 'timeBetweenEventsHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, log10(timeElapsed));
else
    histogram(ax, log10(timeElapsed), binedges);
end
title(ax, ['Time Between Player Initiated Events (', methodName, ')']);
xlabel(ax, 'log10(seconds)');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% Games played per session histogram
rootFilename = 'gamesPlayedPerSessionHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax = gca(h);
if isempty(binedges)
    histogram(ax, log10(sessions.gamesPlayed));
else
    histogram(ax, log10(sessions.gamesPlayed), binedges);
end
title(ax, ['Games Played Per Session (', methodName, ')']);
xlabel(ax, 'log10(games played)');
ylabel(ax, 'Frequency');
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% CI per session
rootFilename = 'CISessionDataHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h = figure('Position',scrsz); ax=gca(h);
if isempty(binedges)
    histogram(ax, log10(1+sessions.CI));
else
    histogram(ax, log10(1+sessions.CI), binedges);
end
xlabel(ax, 'log10(CI)');
ylabel(ax, 'Count');
title(ax, ['CI Histogram (', methodName, ')']);
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% Session duration
scrsz = get(0,'ScreenSize');
rootFilename = 'durationHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
h=figure('Position',scrsz); ax=gca(h);
if isempty(binedges)
    histogram(ax, log10(sessions.duration_numeric));
else
    histogram(ax, log10(sessions.duration_numeric), binedges);
end
xlabel(ax, 'Session Duration (log10(days))');
ylabel(ax, 'Count');
title(ax, ['Session Duration Histogram (', methodName, ')']);
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);

% Games per minute
rootFilename = 'gamesPerMinHist';
if ~strcmpi(methodName, 'real')
    h = openfig(fullfile(realPlotsDir, rootFilename)); % make bin edges line up with real plot
    ax = gca(h);
    currhist = get(ax, 'Children');
    binedges = currhist.BinEdges;
else
    binedges = [];
end
scrsz = get(0,'ScreenSize');
h=figure('Position',scrsz); ax=gca(h);
gamesPerMinute = sessions.gamesPlayed./(sessions.duration_numeric*24*60);
if isempty(binedges)
    histogram(ax, log10(gamesPerMinute));
else
    histogram(ax, log10(gamesPerMinute), binedges);
end
xlabel(ax, 'Games Per Minute');
ylabel(ax, 'Count');
title(ax, ['Games Per Minute Histogram (', methodName, ')']);
filename = fullfile(saveDir, [rootFilename, '.fig']);
saveas(gcf, filename);
filename = fullfile(saveDir, [rootFilename, '.png']);
saveas(gcf, filename);