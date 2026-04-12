%% run_democracy_backsliding_model.m
% Democracy-autocracy backsliding as a nonlinear norm-institution system
%
% State variables:
%   N = democratic norm compliance / self-restraint
%   E = elite autocratic pressure
%   D = institutional strength
%   P = polarization
%
% The model is formulated as a bounded nonlinear dynamical system with:
%   - fast updates for N, E, P
%   - slower updates for D
%   - exogenous stress ramp
%   - stochastic grievance shocks
%   - ensemble simulation across many runs
%   - funnel metrics:
%         H(S_t)       = entropy of occupied macro-states at time t
%         I(S_t ; A)   = mutual information between state at time t
%                        and final attractor / regime outcome A
%
% This version rebalances the system away from a single inevitable
% autocratic attractor and adds explicit bloc reinforcement:
%   democratic bloc  ~ N * D
%   autocratic bloc  ~ E * P

clear; close all; clc;
rng(1);

P = default_params();

[X, aux] = simulate_ensemble(P);
metrics  = compute_funnel_metrics(X, aux, P);

plot_results(X, aux, metrics, P);

% Optional stress sweep across maximum stress levels
if P.doSweep
    sweep = run_stress_sweep(P);

    figure('Color','w','Name','Stress sweep','Position',[100 100 760 520]);

    yyaxis left
    plot(sweep.uVals, sweep.autFrac, 'o-', 'LineWidth', 1.6, 'MarkerSize', 6);
    ylabel('Autocratic fraction');
    ylim([0 1]);

    yyaxis right
    plot(sweep.uVals, sweep.meanFinalScore, 's--', 'LineWidth', 1.4, 'MarkerSize', 6);
    ylabel('Mean final regime score');
    ylim([-1 1]);

    xlabel('Maximum exogenous stress, u_{max}');
    title('Parameter sweep: final regime outcome vs. exogenous stress');
    legend({'Autocratic fraction','Mean final regime score'}, 'Location','best');
    box off;
end


%% ========================= MAIN FUNCTIONS ==============================

function P = default_params()

    % ---------------- simulation ----------------
    P.T          = 220;     % time steps
    P.nRuns      = 1500;    % ensemble size
    P.nBins      = 6;       % discretization per dimension for funnel metrics

    % Initial mean state [N E D P]
    % Keep the system close to the contested middle, but slightly less
    % spread than the previous strongly autocracy-biased version.
    P.initMean   = [0.53 0.47 0.53 0.47];
    P.initJitter = [0.13 0.13 0.11 0.13];

    % Additive Gaussian noise per update [N E D P]
    P.noiseStd   = [0.024 0.021 0.011 0.024];

    % Rare grievance / crisis shocks
    P.shockProb  = 0.025;   % per-step probability
    P.shockMean  = 0.15;    % mean amplitude
    P.shockStd   = 0.08;    % amplitude variability

    % Update rates (D slower than the others)
    % [N E D P]
    P.lam        = [0.28 0.28 0.06 0.26];

    % Exogenous stress schedule
    % Keep the ramp, but shift the default run nearer the transition region.
    P.uStart     = 65;
    P.uRampEnd   = 145;
    P.uMax       = 0.56;

    % Heterogeneity in sensitivity to stress across runs
    P.stressSensitivityMean = 1.00;
    P.stressSensitivityStd  = 0.24;
    P.stressSensitivityMin  = 0.60;

    % ---------------- latent target equations ----------------
    % N target
    P.thetaN =  0.06;
    P.aND    =  1.95;
    P.aNE    =  1.10;
    P.aNP    =  0.92;
    P.aNN    =  0.92;
    P.aNS    =  1.05;   % sanction credibility / institutional enforcement
    P.aNU    =  0.82;   % stress weakens norms

    % E target
    P.thetaE = -1.02;
    P.aEP    =  1.08;
    P.aEN    =  1.00;
    P.aED    =  0.84;
    P.aEE    =  0.84;
    P.aEnegD =  0.90;
    P.aEU    =  0.82;   % stress empowers elite predation

    % D target
    P.thetaD =  0.03;
    P.aDN    =  1.95;
    P.aDE    =  1.08;
    P.aDP    =  0.66;
    P.aDD    =  0.72;
    P.aDU    =  0.76;   % stress erodes institutions

    % P target
    P.thetaP = -0.82;
    P.aPE    =  1.02;
    P.aPnegD =  0.68;
    P.aPN    =  0.98;
    P.aPP    =  0.84;
    P.aPU    =  0.82;   % stress increases polarization
    P.aPshock=  1.05;   % grievance shock enters via polarization

    % ---------------- explicit bloc reinforcement ----------------
    % democratic bloc = N*D, autocratic bloc = E*P
    % Compared with the previous version, the autocratic bloc is softened
    % and democratic self-reinforcement is slightly restored.
    P.aNdem  = 0.60;
    P.aNaut  = 0.82;

    P.aEdem  = 0.40;
    P.aEaut  = 0.98;

    P.aDdem  = 0.60;
    P.aDaut  = 0.82;

    P.aPdem  = 0.40;
    P.aPaut  = 1.00;

    % ---------------- optional sweep ----------------
    P.doSweep         = true;
    P.sweep.nRuns     = 350;
    P.sweep.uVals     = linspace(0,1,15);
end

function [X, aux] = simulate_ensemble(P)

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

        % Fill final time point explicitly so the plotted stress does not
        % drop to zero at the last sample due to bookkeeping only.
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

    % Sanction credibility / enforcement quality:
    % strong institutions matter most when elite abuse is low
    S = D * (1 - E);

    % Explicit bloc-level reinforcement
    demBloc  = N * D;
    autBloc  = E * Pol;

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
       + P.aPE    * E ...
       + P.aPnegD * (1 - D) ...
       - P.aPN    * N ...
       + P.aPP    * (Pol - 0.5) ...
       + P.aPU    * u ...
       + P.aPshock* shock ...
       - P.aPdem  * demBloc ...
       + P.aPaut  * autBloc;

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


function metrics = compute_funnel_metrics(X, aux, P)

    [~, T, ~] = size(X);

    S = state_ids(X, P.nBins);

    finalX = squeeze(X(:,end,:));
    A      = regime_label(finalX);    % 1 = democratic basin, 2 = autocratic basin
    scoreF = regime_score(finalX);

    H = zeros(1,T);
    I = nan(1,T);

    for t = 1:T
        counts = accumarray(S(:,t), 1, [P.nBins^4, 1]);
        H(t)   = entropy_from_counts(counts);
    end

    % Mutual information is only meaningful if both final classes are present
    if numel(unique(A)) >= 2
        I = zeros(1,T);
        for t = 1:T
            joint = accumarray([S(:,t), A], 1, [P.nBins^4, 2]);
            I(t)  = mutual_info_from_joint(joint);
        end
    end

    metrics.S               = S;
    metrics.A               = A;
    metrics.H               = H;
    metrics.I               = I;
    metrics.finalScore      = scoreF;
    metrics.autFractionTime = mean(aux.regimeScore < 0, 1);
end


function sweep = run_stress_sweep(P)

    uVals          = P.sweep.uVals;
    autFrac        = zeros(size(uVals));
    meanFinalScore = zeros(size(uVals));

    P2 = P;
    P2.doSweep = false;
    P2.nRuns   = P.sweep.nRuns;

    for i = 1:numel(uVals)
        P2.uMax = uVals(i);

        [X, ~] = simulate_ensemble(P2);
        finalX = squeeze(X(:,end,:));
        score  = regime_score(finalX);

        autFrac(i)        = mean(score < 0);
        meanFinalScore(i) = mean(score);
    end

    sweep.uVals          = uVals;
    sweep.autFrac        = autFrac;
    sweep.meanFinalScore = meanFinalScore;
end


%% =========================== PLOTTING =================================

function plot_results(X, aux, metrics, P)

    [nRuns, T, ~] = size(X);

    meanAll = squeeze(mean(X,1));   % T x 4
    score   = aux.regimeScore;      % nRuns x T

    isDem = metrics.A == 1;
    isAut = metrics.A == 2;

    figure('Color','w', 'Name','Democracy backsliding model', ...
           'Position',[50 50 1500 850]);

    % ---------------------------------------------------------------------
    subplot(2,3,1);
    plot(1:T, meanAll(:,1), 'LineWidth',1.8); hold on;
    plot(1:T, meanAll(:,2), 'LineWidth',1.8);
    plot(1:T, meanAll(:,3), 'LineWidth',1.8);
    plot(1:T, meanAll(:,4), 'LineWidth',1.8);
    xlabel('Time');
    ylabel('Mean state');
    title('Ensemble mean dynamics');
    legend({'N norms','E elite pressure','D institutions','P polarization'}, ...
           'Location','best');
    ylim([0 1]);
    box off;

    % ---------------------------------------------------------------------
    subplot(2,3,2);
    nShow = min(120, nRuns);
    idx   = randperm(nRuns, nShow);

    plot(1:T, score(idx,:)', 'Color',[0.85 0.85 0.85], 'LineWidth',0.6); hold on;
    yline(0, '--k', 'LineWidth',1.0);

    if any(isDem)
        plot(1:T, mean(score(isDem,:),1), 'LineWidth',2.2);
    end
    if any(isAut)
        plot(1:T, mean(score(isAut,:),1), 'LineWidth',2.2);
    end

    xlabel('Time');
    ylabel('Regime score');
    title('Sample trajectories and basin means');
    legendEntries = {'Sample runs','Neutral boundary'};
    if any(isDem), legendEntries{end+1} = 'Democratic basin mean'; end
    if any(isAut), legendEntries{end+1} = 'Autocratic basin mean'; end
    legend(legendEntries, 'Location','best');
    box off;

    % ---------------------------------------------------------------------
    subplot(2,3,3);
    yyaxis left
    plot(1:T, metrics.H, 'LineWidth',2.0);
    ylabel('H(S_t)');

    yyaxis right
    if all(isnan(metrics.I))
        plot(1:T, zeros(1,T), 'LineStyle','none');
        ylabel('I(S_t ; A)');
        ylim([0 1]);
        text(0.55*T, 0.5, 'single final class', ...
            'HorizontalAlignment','center');
    else
        plot(1:T, metrics.I, 'LineWidth',2.0);
        ylabel('I(S_t ; A)');
    end

    xlabel('Time');
    title('Information funnel diagnostics');
    box off;

    % ---------------------------------------------------------------------
    subplot(2,3,4);
    histogram(metrics.finalScore, 30);
    xline(0, '--k', 'LineWidth',1.0);
    xlabel('Final regime score');
    ylabel('Count');
    title('Distribution of final outcomes');
    box off;

    % ---------------------------------------------------------------------
    subplot(2,3,5);
    plot_phase_slice(P, 0.60, 0.40, 0.40);
    box off;

    % ---------------------------------------------------------------------
    subplot(2,3,6);
    yyaxis left
    plot(1:T, mean(aux.stress,1), 'LineWidth',2.0);
    ylabel('Mean stress');

    yyaxis right
    plot(1:T, metrics.autFractionTime, 'LineWidth',2.0);
    ylabel('Fraction with regime score < 0');
    ylim([0 1]);

    xlabel('Time');
    title('External stress and autocratic share');
    box off;
end


function plot_phase_slice(P, Dfix, Pfix, uFix)

    gridVals = linspace(0.05,0.95,21);
    [Ngrid, Egrid] = meshgrid(gridVals, gridVals);

    dN = zeros(size(Ngrid));
    dE = zeros(size(Egrid));

    for i = 1:numel(Ngrid)
        x  = [Ngrid(i), Egrid(i), Dfix, Pfix];
        x1 = step_model(x, uFix, 0, P, false);

        dN(i) = x1(1) - x(1);
        dE(i) = x1(2) - x(2);
    end

    quiver(Ngrid, Egrid, dN, dE, 'AutoScale','on'); hold on;
    xlabel('N: norm compliance');
    ylabel('E: elite pressure');
    title(sprintf('Phase slice at D=%.2f, P=%.2f, u=%.2f', Dfix, Pfix, uFix));
    xlim([0 1]); ylim([0 1]);
end


%% ======================== METRIC HELPERS ==============================

function S = state_ids(X, B)
    % Convert continuous state in [0,1] to discrete macro-state IDs.

    idx = floor(X * B) + 1;
    idx(idx < 1) = 1;
    idx(idx > B) = B;

    b1 = idx(:,:,1);
    b2 = idx(:,:,2);
    b3 = idx(:,:,3);
    b4 = idx(:,:,4);

    S = b1 ...
      + (b2 - 1) * B ...
      + (b3 - 1) * B^2 ...
      + (b4 - 1) * B^3;
end


function A = regime_label(Xfinal)
    s = regime_score(Xfinal);
    A = ones(size(s));
    A(s < 0) = 2;   % autocratic basin
end


function s = regime_score(X)
    % X is n x 4: [N E D P]
    s = 0.5 * (X(:,1) + X(:,3) - X(:,2) - X(:,4));
end


function H = entropy_from_counts(counts)
    p = counts / sum(counts);
    p = p(p > 0);
    H = -sum(p .* log2(p));
end


function I = mutual_info_from_joint(jointCounts)
    joint = jointCounts / sum(jointCounts(:));
    pS    = sum(joint, 2);
    pA    = sum(joint, 1);

    I = 0;
    for i = 1:size(joint,1)
        for j = 1:size(joint,2)
            if joint(i,j) > 0
                I = I + joint(i,j) * log2(joint(i,j) / (pS(i) * pA(j)));
            end
        end
    end
end


%% ========================== UTILITIES =================================

function y = sigmoid(x)
    y = 1 ./ (1 + exp(-x));
end


function x = clip01(x)
    x = min(max(x,0),1);
end