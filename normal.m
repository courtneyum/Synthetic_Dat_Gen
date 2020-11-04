function y = normal(x, mu, sigma)
    c = (sigma*sqrt(2*pi)).^(-1);
    expo = -0.5*((x - mu)/sigma).^2;
    y = c.*exp(expo);
end

