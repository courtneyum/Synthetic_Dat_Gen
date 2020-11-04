function B = find_block_upper_triangular_form(A)
    N = size(A, 1);
    P = zeros(size(A));
    index = 1:N+1:N^2;
    P(index) = 1;
    for i=1:N
        for j=i+1:N
            P_1=P;
            P_1(:,i)=P(:,j);
            P_1(:,j)=P(:,i);

            B=P_1*A*transpose(P_1);
            if is_block_upper_triangular(B)
                return;
            end
        end
    end
    
    B = -1;
    return;
% 
% permutations = perms(1:5);
% for i=1:size(permutations,1)
%     perm = permutations(i,:);
%     for j=1:size(permutations,2)
%         for k=1:size(permutations,2)
%             A(j,k) = D(perm(j),perm(k));
%         end
%     end
%     A
%     '';
% end

% for i=1:4
% hold on
% x_i=x(i);
% y_i=y(i);
% r_i=r(i);
% th = 0:pi/50:2*pi;
% xunit = r_i * cos(th) + x_i;
% yunit = r_i * sin(th) + y_i;
% h = plot(xunit, yunit);
% 
% end
% scatter(x,y, 'b', 'filled');
% scatter(eigen_x, eigen_y, 'r', 'filled');
% xlabel('Real Axis');
% ylabel('Imaginary Axis');

