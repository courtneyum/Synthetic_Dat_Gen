function [par, stuck] = stuckInCycle(data, par, cardIn)

    stuck = false;
    if cardIn
        C = par.commClasses.C.in;
        closed = par.commClasses.closed.in;
        eventIDs = par.eventIDs.cardIn;
    else
        C = par.commClasses.C.out;
        closed = par.commClasses.closed.out;
        eventIDs = par.eventIDs.cardOut;
    end
    
    lastEventID = par.eventID_lookupTable(par.uniqueEventCodes == data.eventCode(end), par.uniqueMachineNumbers == data.machineNumber(end));
    if closed(eventIDs == lastEventID)
        par.inCycleSteps(par.players == data.patronID(end)) = par.inCycleSteps(par.players == data.patronID(end)) + 1;
        if par.inCycleSteps(par.players == data.patronID(end)) > sum(C(eventIDs == lastEventID, :))
            stuck = true;
        end
    end
    
    
end