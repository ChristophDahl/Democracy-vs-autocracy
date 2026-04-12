function [X, aux] = simulate_ensemble(P)
%SIMULATE_ENSEMBLE
% Simulate an ensemble of societies under the democracy-autocracy model.
%
% Input
%   P : parameter struct from default_params()
%
% Output
%   X   : nRuns x T x 4 array of states [N E D P]
%   aux : struct with stress, shock, sensitivity, regimeScore

    % X is nRuns x T x 4
    X = zeros(P.nRuns, P.T, 4);

    aux.stress      = zeros(P.nRuns, P.T);
    aux.shock       = zeros(P.nRuns, P.T);
    aux.sensitivity = zeros(P.nRuns, 1);

    for r = 1:P.nRuns

        x0 = P.initMean + P.initJitter .* randn(1,4);
        x0 = clip01(x0);

        X(r,1,:) = x0;

        sens = max(P.stressSensitivityMin, ...
                   P.stressSensitivityMean + P.stressSensitivityStd * randn);
        aux.sensitivity(r) = sens;

        for t = 1:(P.T-1)

            u = sens * stress_schedule(t, P);

            shock = 0;
            if rand < P.shockProb
                shock = max(0, P.shockMean + P.shockStd * randn);
            end

            x  = reshape(X(r,t,:), 1, 4);
            x1 = step_model(x, u, shock, P, true);

            X(r,t+1,:)      = x1;
            aux.stress(r,t) = u;
            aux.shock(r,t)  = shock;
        end

        aux.stress(r,P.T) = sens * stress_schedule(P.T, P);
        aux.shock(r,P.T)  = 0;
    end

    % Regime score for each run/time
    aux.regimeScore = 0.5 * (X(:,:,1) + X(:,:,3) - X(:,:,2) - X(:,:,4));
end


function x1 = step_model(x, u, shock, P, addNoise)

    N   = x(1);
    E   = x(2);
    D   = x(3);
    Pol = x(4);

    % Sanction credibility / enforcement quality
    S = D * (1 - E);

    % Explicit bloc-level reinforcement
    demBloc = N * D;
    autBloc = E * Pol;

    % Latent targets
    zN = P.thetaN ...
       + P.aND    * D ...
       - P.aNE    * E ...
       - P.aNP    * Pol ...
       + P.aNN    * (N - 0.5) ...
       + P.aNS    * S ...
       - P.aNU    * u ...
       + P.aNdem  * demBloc ...
       - P.aNaut  * autBloc;

    zE = P.thetaE ...
       + P.aEP    * Pol ...
       + P.aEN    * (1 - N) ...
       + P.aED    * (1 - D) ...
       + P.aEE    * (E - 0.5) ...
       - P.aEnegD * D ...
       + P.aEU    * u ...
       - P.aEdem  * demBloc ...
       + P.aEaut  * autBloc;

    zD = P.thetaD ...
       + P.aDN    * N ...
       - P.aDE    * E ...
       - P.aDP    * Pol ...
       + P.aDD    * (D - 0.5) ...
       - P.aDU    * u ...
       + P.aDdem  * demBloc ...
       - P.aDaut  * autBloc;

    zP = P.thetaP ...
       + P.aPE     * E ...
       + P.aPnegD  * (1 - D) ...
       - P.aPN     * N ...
       + P.aPP     * (Pol - 0.5) ...
       + P.aPU     * u ...
       + P.aPshock * shock ...
       - P.aPdem   * demBloc ...
       + P.aPaut   * autBloc;

    target = sigmoid([zN zE zD zP]);

    % Relaxation dynamics; D changes more slowly through small lambda
    x1 = (1 - P.lam) .* x + P.lam .* target;

    if addNoise
        x1 = x1 + P.noiseStd .* randn(1,4);
    end

    x1 = clip01(x1);
end


function u = stress_schedule(t, P)
    if t < P.uStart
        u = 0;
    elseif t <= P.uRampEnd
        u = P.uMax * (t - P.uStart) / (P.uRampEnd - P.uStart);
    else
        u = P.uMax;
    end
end


function y = sigmoid(x)
    y = 1 ./ (1 + exp(-x));
end


function x = clip01(x)
    x = min(max(x,0),1);
end