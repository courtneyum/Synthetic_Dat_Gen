function casino =  epsilonComparisonTest(par)

rng(1);
casino.num_iters = 0;
casino.TM0=par.PNoMove*eye(par.NMachines)+(1-par.PNoMove)*rand(par.NMachines);
casino.TM0_sum=cumsum(casino.TM0,2);
TM_norm=casino.TM0_sum(:,end);
casino.TM0_sum=casino.TM0_sum./TM_norm;
casino.TM0=casino.TM0./TM_norm;
% figure(1); imagesc(casino.TM0_sum);

% This is the occupancy "timestream". True=occupied, false=not occupied.
casino.occ=false(par.NMachines,par.NSteps);
index_occ=randperm(par.NMachines); index_occ=index_occ(1:par.NPlayers);
occ=false(par.NMachines,1); occ(index_occ)=true;
casino.occ(occ,1)=1;

% Keep track of ACTUAL moves that have occurred.
casino.moves=zeros(par.NMachines);

%Track the error
error = zeros(par.NSteps, 1);

%TM_new=1e-6 + zeros(par.NMachines);
TM = (1/par.NMachines) * ones(par.NMachines);

for t=2:par.NSteps
    
    % Scramble the order.
    index_occ=find(occ);
    index_occ=index_occ(randperm(length(index_occ)));
    TM_prev = TM;
    
    % Move players: Loop over currently occupied machines.
    % disp(mat2str(occ_current));
    for i=1:length(index_occ)
        n=index_occ(i);
        P_occ=casino.TM0_sum(n,:);
        %
        % Keep searching until you find an unoccupied machine.
        while true
            n2=find(rand < P_occ,1,'first');
            if n2 == n || ~occ(n2)
                % A valid move occurred. Note that n --> n is considered valid.
                occ(n)=false;
                % disp([num2str(n) '-->', num2str(n2)]);
                break
            end
        end
        
        % Keep track of the move.
        casino.moves(n,n2)=casino.moves(n,n2)+1;
        N = sum(casino.moves(n, :));
        
        if par.alpha > 0
            alpha = par.alpha/N;
        else
            alpha = par.alpha;
        end
        %
        
        occ(n2) = true;
        sum_pj = sum(TM(n, ~occ));
        eps = sum_pj*(1 - alpha*(N-1))/N;
        q = (1 - alpha*(N-1))/N;
        
        TM(n,n2) = TM(n,n2) + eps;
        TM(n,~occ) = TM(n,~occ)*(1 - q);
    end
    %
    % Add the new state.
    casino.occ(:,t)=occ;
    
%     if all(all(abs(TM - casino.TM0) < par.precision))
%         % convergence reached
%         casino.num_iters = t;
%         break;
%     end
    error(t) = mean(mean(abs(TM - casino.TM0), 2));
end

casino.TM = TM;
casino.error = error;