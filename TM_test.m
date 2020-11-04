function casino = TM_test(par)
%par=setup;

% Initialize a random TM: expresses probabilities that a player DESIRES to
% move from machine A to B.
% randomMatrix = rand(par.NMachines); % represents player preferences
% casino.TM0 = eye(par.NMachines);
% casino.TM0(casino.TM0 == 1) = par.PNoMove*randomMatrix(casino.TM0 == 1);
% casino.TM0(casino.TM0 == 0) = (1-par.PNoMove)*randomMatrix(casino.TM0 == 0);


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
casino.attempts=zeros(par.NMachines);
casino.rejections=zeros(par.NMachines);

for t=2:par.NSteps
    
    % Scramble the order.
    index_occ=find(occ);
    index_occ=index_occ(randperm(length(index_occ)));
    
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
                occ(n)=false; occ(n2)=true;
                % disp([num2str(n) '-->', num2str(n2)]);
                break
            end
        end
        %
        % Keep track of the move.
        casino.moves(n,n2)=casino.moves(n,n2)+1;
    end
    %
    % Add the new state.
    casino.occ(:,t)=occ;
    %
end


% Calculate actual move probability.
casino.P_move=casino.moves./sum(casino.moves,2);

% Plot the occupancy.
% figure(2); imagesc(casino.occ);

% Probability that a machine is occupied.
P_occ=mean(casino.occ,2);
% figure(3); plot(P_occ);

% Try to get estimate the transition matrix from the occupancy data in casino.occ.
% This is one attempt of many, and the part we need to figure out!
TM=zeros(par.NMachines);
TM_est=TM;
for i=1:par.NMachines
    for j=1:par.NMachines
        N_i = sum(casino.moves(i,:));
        beta = sqrt(N_i)/par.NMachines;
        if i == j
            TM(i,j)=casino.P_move(i,j);
            TM_est(i,j) = (casino.moves(i,j)+beta)/(N_i + sqrt(N_i));
        else
            % Calculate probability that j is occupied under the condition
            % that i is occupied. Basic equation here is:
            % (prob of move i->j)=TM(i->j)*(prob that j is unoccupied when i is occupied.)
            index=casino.occ(i,:); P_occ=mean(casino.occ(:,index),2);
            P_j_is_unocc=1-P_occ(j);
            TM(i,j)=casino.P_move(i,j)/P_j_is_unocc;
            TM_est(i,j)=(casino.moves(i,j)+beta)/(N_i + sqrt(N_i));
            TM_est(i,j) = TM_est(i,j)/P_j_is_unocc;
        end
         
    end
end
% Normalize.
casino.TM=TM./sum(TM,2);
casino.TM_est = TM_est./sum(TM,2);

% figure(4);
% subplot(2,2,1); imagesc(casino.TM0); axis image; colorbar;
% % The original TM.
% subplot(2,2,2); imagesc(casino.P_move); axis image; colorbar;
% % The TM that can be measured from data -- does not account for collisions.
% subplot(2,2,3); imagesc(casino.P_move-casino.TM0); axis image; colorbar;
% % This plot shows how badly we do is we don't correct for collisions.
% subplot(2,2,4); imagesc(casino.TM-casino.TM0); axis image; colorbar;
% % The last plot should be nearly zeros once this is correct!

