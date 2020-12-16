% card in

load('Data\par.mat');

cycles_cardIn = DFS(par.trans_mat.cardIn);

machineNumbers = [];
eventCodes = [];
for i=1:length(cycles_cardIn)
    cycle = cycles_cardIn{i};
    prob = 1;
    for j=1:length(cycle)-1
        id = par.eventIDs.cardIn(cycle(j));
        [e,n] = ind2sub(size(par.eventID_lookupTable), id);
        machineNumbers = [machineNumbers; par.uniqueMachineNumbers(n)];
        eventCodes = [eventCodes; par.uniqueEventCodes(e)];
        
        if j > 1
            prob = prob*par.trans_mat.cardIn(cycle(j-1), cycle(j));
        end
    end
    
    machineNumbers = [machineNumbers; prob; NaN];
    eventCodes = [eventCodes; NaN; NaN];
end

cycles_CI = table(machineNumbers, eventCodes);