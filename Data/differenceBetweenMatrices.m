% close all
% baseName = 'gamesPlayedPerSessionHist';
% baseDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement';
% dirs = {'AddX', 'MLE', 'ProbUpdate', 'UnifOcc'};
% 
% for i=1:length(dirs)
%     openfig(fullfile(baseDir, dirs{i}, ['sessionsPerDayHist', '.fig']));
%     %openfig(fullfile(baseDir, dirs{i}, ['eventsPerDay', '.fig']));
% end

methods = {'AddX', 'MLE', 'ProbUpdate', 'UnifOcc'};
combos = nchoosek(1:4, 2);
diffs_cardIn = zeros(4);
diffs_cardOut = zeros(4);
for i=1:length(combos)
    combo = combos(i, :);
    par1 = load(['par', methods{combo(1)}, '.mat']);
    par1 = par1.par;
    par2 = load(['par', methods{combo(2)}, '.mat']);
    par2 = par2.par;
    
    %Convert back to full size
    [i,j,s] = find(par1.trans_mat.cardIn);
    i = par1.eventIDs.cardIn(i);
    j = par1.eventIDs.cardIn(j);
    if max(i) < par1.N*par1.E || max(j) < par1.N*par1.E
        i = [i; par1.N*par1.E];
        j = [j; par1.N*par1.E];
        s = [s; 0];
    end
    tm1 = sparse(i,j,s);
    [i,j,s] = find(par2.trans_mat.cardIn);
    i = par2.eventIDs.cardIn(i);
    j = par2.eventIDs.cardIn(j);
    if max(i) < par2.N*par2.E || max(j) < par2.N*par2.E
        i = [i; par2.N*par2.E];
        j = [j; par2.N*par2.E];
        s = [s; 0];
    end
    tm2 = sparse(i,j,s);
    
    
    diffs = abs(tm1 - tm2);
    diffs = mean(mean(diffs, 'omitnan'), 'omitnan');
    diffs_cardIn(combo(1), combo(2)) = diffs;
    
    %Convert back to full size
    [i,j,s] = find(par1.trans_mat.cardOut);
    i = par1.eventIDs.cardOut(i);
    j = par1.eventIDs.cardOut(j);
    if max(i) < par1.N*par1.E || max(j) < par1.N*par1.E
        i = [i; par1.N*par1.E];
        j = [j; par1.N*par1.E];
        s = [s; 0];
    end
    tm1 = sparse(i,j,s);
    [i,j,s] = find(par2.trans_mat.cardOut);
    i = par2.eventIDs.cardOut(i);
    j = par2.eventIDs.cardOut(j);
    if max(i) < par2.N*par2.E || max(j) < par2.N*par2.E
        i = [i; par2.N*par2.E];
        j = [j; par2.N*par2.E];
        s = [s; 0];
    end
    tm2 = sparse(i,j,s);
    
    diffs = abs(tm1 - tm2);
    diffs = mean(mean(diffs, 'omitnan'), 'omitnan');
    diffs_cardOut(combo(1), combo(2)) = diffs;
end
    