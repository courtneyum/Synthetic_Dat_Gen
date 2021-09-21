function [sigma, mu, error] = GaussNewton(x, y, sigma, mu, weighted)
    error = sigma^2 + mu^2;
    beta_prev = [mu; sigma];
    max_iters = 100;
    num_iters = 0;
    alpha = 1;
    if weighted
        P = diag(x);
        x_p = x;
        x_p(x_p < mu) = 1e-2;
        P = diag(x_p);
    else
        P = eye(length(x));
    end
    while error > 1e-10 && num_iters < max_iters
        num_iters = num_iters + 1;
        J = [mu_derivative(beta_prev, x), sigma_derivative(beta_prev, x)];
        r = y - normal(x, beta_prev);
        diff = (transpose(J)*P*J)^(-1)*transpose(J)*P*r;
        
        disp(['Total Residual: ', num2str(sum(abs(r))), ' Diffs: ', mat2str(diff)]);
        
        beta = beta_prev + alpha*diff;
        error = sum((beta_prev - beta).^2);
        beta_prev = beta;
    end
    sigma = beta_prev(2); mu = beta_prev(1);
    '';
end

function deriv = sigma_derivative(beta, x)
    mu = beta(1); sigma = beta(2);
    deriv = normal(x, beta);
    deriv = deriv.*(-1/sigma + (x-mu).^2/sigma^3);
end
function deriv = mu_derivative(beta, x)
    mu = beta(1); sigma = beta(2);
    deriv = normal(x, beta);
    deriv = deriv.*(x-mu)/sigma^2;
end
function f = normal(x, beta)
    mu = beta(1); sigma = beta(2);
    x = (x-mu)/sigma;
    f = 1/(sigma*sqrt(2*pi));
    f = f*exp(-0.5*(x.^2));
    f = f/sum(f);
end