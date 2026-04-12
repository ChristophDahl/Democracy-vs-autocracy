function metrics = compute_funnel_metrics(X, aux, P)
%COMPUTE_FUNNEL_METRICS
% Compute entropy and mutual-information funnel metrics for the
% democracy-autocracy ensemble simulation.
%
% Input
%   X   : nRuns x T x 4 state array
%   aux : auxiliary struct from simulate_ensemble
%   P   : parameter struct
%
% Output
%   metrics struct with fields:
%       S               discrete macro-state IDs
%       A               final regime labels (1=dem, 2=aut)
%       H               entropy H(S_t)
%       I               mutual information I(S_t ; A), NaN if single class
%       finalScore      final regime score
%       autFractionTime fraction of runs with negative regime score over time

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
% Xfinal is n x 4: [N E D P]

    s = regime_score(Xfinal);
    A = ones(size(s));
    A(s < 0) = 2;   % autocratic basin
end


function s = regime_score(X)
% X is n x 4: [N E D P]

    s = 0.5 * (X(:,1) + X(:,3) - X(:,2) - X(:,4));
end


function H = entropy_from_counts(counts)

    total = sum(counts);
    if total <= 0
        H = 0;
        return
    end

    p = counts / total;
    p = p(p > 0);
    H = -sum(p .* log2(p));
end


function I = mutual_info_from_joint(jointCounts)

    total = sum(jointCounts(:));
    if total <= 0
        I = 0;
        return
    end

    joint = jointCounts / total;
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