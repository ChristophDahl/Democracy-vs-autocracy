%% run_robustness_checks.m
% Robustness analyses for the democracy/autocracy basin model.
%
% This script tests whether the main qualitative results depend on:
%   1. macro-state bin number for entropy / mutual information
%   2. initial-condition jitter
%   3. stochastic update noise
%   4. final regime-score definition
%
% Outputs:
%   results/robustness_summary.csv
%   results/robustness_summary.mat

clear; clc;

rng(11);

% -------------------------------------------------------------------------
% Paths
rootDir    = 'I:\democracy_autocracy';
resultsDir = fullfile(rootDir, 'results');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% If this script is not in the same folder as the model functions,
% uncomment and adapt:
% addpath(fullfile(rootDir, 'model_codes'));

% -------------------------------------------------------------------------
% Baseline model
P0 = default_params();
P0.doSweep = false;
P0.nRuns   = 1500;
P0.nBins   = 6;

fprintf('Running baseline ensemble...\n');
[X0, aux0] = simulate_ensemble(P0);
M0 = compute_metrics_custom_score(X0, P0, 'baseline');
baseLabels = M0.A;

rows = {};
rows = [rows; make_row('baseline', 'default', M0, NaN)];

% -------------------------------------------------------------------------
% 1) Coarse-graining robustness: recompute H and I on the same trajectories
binVals = [4 5 6 7 8 10];

fprintf('\nCoarse-graining robustness...\n');
for i = 1:numel(binVals)
    P = P0;
    P.nBins = binVals(i);

    M = compute_metrics_custom_score(X0, P, 'baseline');

    rows = [rows; make_row( ...
        'coarse_graining', ...
        sprintf('nBins_%d', binVals(i)), ...
        M, NaN)];
end

% -------------------------------------------------------------------------
% 2) Initial-condition robustness: rerun ensemble with different jitter widths
jitterFactors = [0.5 0.75 1.0 1.25 1.5];

fprintf('\nInitial-condition robustness...\n');
for i = 1:numel(jitterFactors)
    rng(1000 + i);

    P = P0;
    P.initJitter = P0.initJitter .* jitterFactors(i);

    [X, aux] = simulate_ensemble(P); %#ok<ASGLU>
    M = compute_metrics_custom_score(X, P, 'baseline');

    rows = [rows; make_row( ...
        'initial_jitter', ...
        sprintf('factor_%.2f', jitterFactors(i)), ...
        M, NaN)];
end

% -------------------------------------------------------------------------
% 3) Noise-level robustness: rerun ensemble with different state-noise levels
noiseFactors = [0 0.5 1.0 1.5 2.0];

fprintf('\nNoise-level robustness...\n');
for i = 1:numel(noiseFactors)
    rng(2000 + i);

    P = P0;
    P.noiseStd = P0.noiseStd .* noiseFactors(i);

    [X, aux] = simulate_ensemble(P); %#ok<ASGLU>
    M = compute_metrics_custom_score(X, P, 'baseline');

    rows = [rows; make_row( ...
        'state_noise', ...
        sprintf('factor_%.2f', noiseFactors(i)), ...
        M, NaN)];
end

% -------------------------------------------------------------------------
% 4) Regime-score robustness: reclassify the same terminal states
scoreDefs = {'baseline', 'bloc', 'strict', ...
             'norm_weighted', 'institution_weighted'};

fprintf('\nRegime-score robustness...\n');
for i = 1:numel(scoreDefs)
    M = compute_metrics_custom_score(X0, P0, scoreDefs{i});

    classAgreement = mean(M.A == baseLabels);

    rows = [rows; make_row( ...
        'score_definition', ...
        scoreDefs{i}, ...
        M, classAgreement)];
end

% -------------------------------------------------------------------------
% Export table
varNames = { ...
    'checkType', ...
    'setting', ...
    'pDem', ...
    'pAut', ...
    'meanFinalScore', ...
    'stdFinalScore', ...
    'Imax', ...
    'Hmin', ...
    'Hmax', ...
    'Hdrop', ...
    'classAgreementWithBaseline'};

Trob = cell2table(rows, 'VariableNames', varNames);

outCsv = fullfile(resultsDir, 'robustness_summary.csv');
outMat = fullfile(resultsDir, 'robustness_summary.mat');

writetable(Trob, outCsv);
save(outMat, 'Trob', 'P0');

fprintf('\nSaved robustness summary:\n  %s\n  %s\n', outCsv, outMat);

disp(Trob);

% =========================================================================
% Local helper functions
% =========================================================================

function r = make_row(checkType, setting, M, agreement)

    if all(isnan(M.I))
        Imax = NaN;
    else
        Imax = max(M.I(~isnan(M.I)));
    end

    Hmin  = min(M.H);
    Hmax  = max(M.H);
    Hdrop = Hmax - Hmin;

    r = { ...
        checkType, ...
        setting, ...
        M.pDem, ...
        M.pAut, ...
        mean(M.finalScore), ...
        std(M.finalScore), ...
        Imax, ...
        Hmin, ...
        Hmax, ...
        Hdrop, ...
        agreement};
end

function M = compute_metrics_custom_score(X, P, scoreName)

    [nRuns, T, ~] = size(X);

    S = state_ids_local(X, P.nBins);

    finalX = squeeze(X(:,end,:));
    scoreF = score_from_name(finalX, scoreName);

    A = ones(nRuns, 1);
    A(scoreF < 0) = 2;

    H = zeros(1, T);
    I = nan(1, T);

    for t = 1:T
        counts = accumarray(S(:,t), 1, [P.nBins^4, 1]);
        H(t) = entropy_from_counts_local(counts);
    end

    if numel(unique(A)) >= 2
        I = zeros(1, T);
        for t = 1:T
            joint = accumarray([S(:,t), A], 1, [P.nBins^4, 2]);
            I(t) = mutual_info_from_joint_local(joint);
        end
    end

    M.S = S;
    M.A = A;
    M.H = H;
    M.I = I;
    M.finalScore = scoreF;
    M.pDem = mean(scoreF > 0);
    M.pAut = mean(scoreF < 0);
end

function s = score_from_name(X, scoreName)

    N = X(:,1);
    E = X(:,2);
    D = X(:,3);
    P = X(:,4);

    switch scoreName

        case 'baseline'
            % Original manuscript score
            s = 0.5 .* (N + D - E - P);

        case 'bloc'
            % Uses the two multiplicative bloc terms already in the model
            s = (N .* D) - (E .* P);

        case 'strict'
            % Conservative score: weakest democratic component must exceed
            % strongest autocratic component
            s = min(N, D) - max(E, P);

        case 'norm_weighted'
            % Puts more weight on informal democratic restraint / elite pressure
            s = (0.65 .* N + 0.35 .* D) - ...
                (0.65 .* E + 0.35 .* P);

        case 'institution_weighted'
            % Puts more weight on institutional strength / polarization
            s = (0.35 .* N + 0.65 .* D) - ...
                (0.35 .* E + 0.65 .* P);

        otherwise
            error('Unknown score definition: %s', scoreName);
    end
end

function S = state_ids_local(X, B)

    idx = floor(X .* B) + 1;
    idx(idx < 1) = 1;
    idx(idx > B) = B;

    b1 = idx(:,:,1);
    b2 = idx(:,:,2);
    b3 = idx(:,:,3);
    b4 = idx(:,:,4);

    S = b1 ...
      + (b2 - 1) .* B ...
      + (b3 - 1) .* B^2 ...
      + (b4 - 1) .* B^3;
end

function H = entropy_from_counts_local(counts)

    total = sum(counts);

    if total <= 0
        H = 0;
        return
    end

    p = counts ./ total;
    p = p(p > 0);

    H = -sum(p .* log2(p));
end

function I = mutual_info_from_joint_local(jointCounts)

    total = sum(jointCounts(:));

    if total <= 0
        I = 0;
        return
    end

    joint = jointCounts ./ total;
    pS = sum(joint, 2);
    pA = sum(joint, 1);

    I = 0;

    for i = 1:size(joint,1)
        for j = 1:size(joint,2)
            if joint(i,j) > 0
                I = I + joint(i,j) .* log2(joint(i,j) ./ (pS(i) .* pA(j)));
            end
        end
    end
end