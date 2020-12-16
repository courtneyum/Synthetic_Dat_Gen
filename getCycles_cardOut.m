%getCycles_cardOut

load('Data\par.mat');

cycles_cardOut = DFS(par.trans_mat.cardOut);

machineNumbers = [];
eventCodes = [];
for i=1:length(cycles_cardOut)
    cycle = cycles_cardOut{i};
    prob = 1;
    for j=1:length(cycle)-1
        id = par.eventIDs.cardOut(cycle(j));
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

cycles_CO = table(machineNumbers, eventCodes);