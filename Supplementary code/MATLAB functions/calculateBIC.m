function bic = calculateBIC(n, k, likelihood)
    % n: number of observations
    % k: number of parameters in the model
    % negtive likelihood value

    bic = k * log(n) + 2 * likelihood;
end
