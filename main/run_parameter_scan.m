function scan = run_parameter_scan(baseP, spec, nSamples, nRunsQuick, rngSeed)
%RUN_PARAMETER_SCAN
% Systematic exploratory wrapper around the democracy/autocracy model.
%
% This version is rewritten to be robust and transparent:
%   - tests the baseline first
%   - records per-sample failures explicitly
%   - can stop on first error
%   - never silently turns the whole scan into NaNs without explanation
%
% Usage:
%   P0   = default_params();
%   spec = default_scan_spec(P0);
%   scan = run_parameter_scan(P0, spec, 200, 150, 1);
%
% Requirements:
%   default_params
%   default_scan_spec
%   simulate_ensemble
%   compute_funnel_metrics

    if nargin < 1 || isempty(baseP)
        baseP = default_params();
    end
    if nargin < 2 || isempty(spec)
        spec = default_scan_spec(baseP);
    end
    if nargin < 3 || isempty(nSamples)
        nSamples = 400;
    end
    if nargin < 4 || isempty(nRunsQuick)
        nRunsQuick = 200;
    end
    if nargin < 5 || isempty(rngSeed)
        rngSeed = 1;
    end

    rng(rngSeed);

    % ---------------- behavior controls ----------------
    stopOnError    = true;   % set false if you want to continue after failures
    printEvery     = 25;
    storeMessages  = true;

    % ---------------- baseline sanity check ----------------
    Ptest = baseP;
    Ptest.doSweep = false;
    Ptest.nRuns   = min(100, nRunsQuick);

    fprintf('Testing baseline parameter set before scan...\n');
    [Xtest, auxtest] = simulate_ensemble(Ptest);
    metricstest = compute_funnel_metrics(Xtest, auxtest, Ptest);

    fprintf('Baseline OK | pDem = %.3f | pAut = %.3f | meanFinal = %.3f\n', ...
        mean(metricstest.finalScore > 0), ...
        mean(metricstest.finalScore < 0), ...
        mean(metricstest.finalScore));

    % ---------------- allocate scan containers ----------------
    d = numel(spec.names);
    U = lhs_simple(nSamples, d);

    paramVals   = nan(nSamples, d);
    pDem        = nan(nSamples,1);
    pAut        = nan(nSamples,1);
    meanFinal   = nan(nSamples,1);
    stdFinal    = nan(nSamples,1);
    Imax        = nan(nSamples,1);
    Hmin        = nan(nSamples,1);
    Hmax        = nan(nSamples,1);
    Hdrop       = nan(nSamples,1);
    balance     = nan(nSamples,1);
    bimodalFlag = nan(nSamples,1);
    transScore  = nan(nSamples,1);
    successFlag = false(nSamples,1);

    if storeMessages
        failMessage = strings(nSamples,1);
    else
        failMessage = [];
    end

    % ---------------- main scan loop ----------------
    for s = 1:nSamples

        P = baseP;
        P.doSweep = false;
        P.nRuns   = nRunsQuick;

        vals = sample_to_param_values(baseP, spec, U(s,:));
        P    = apply_param_vector(P, spec, vals);
        paramVals(s,:) = vals;

        try
            [X, aux] = simulate_ensemble(P);
            metrics  = compute_funnel_metrics(X, aux, P);

            validate_metrics(metrics);

            fs = metrics.finalScore(:);

            pDem(s)      = mean(fs > 0);
            pAut(s)      = mean(fs < 0);
            meanFinal(s) = mean(fs);
            stdFinal(s)  = std(fs);

            if isfield(metrics, 'I') && ~isempty(metrics.I) && any(~isnan(metrics.I))
                tmp = metrics.I(~isnan(metrics.I));
                Imax(s) = max(tmp);
            else
                Imax(s) = 0;
            end

            Hmin(s) = min(metrics.H);
            Hmax(s) = max(metrics.H);
            Hdrop(s)= Hmax(s) - Hmin(s);

            % 1 if perfectly balanced, 0 if all in one basin
            balance(s) = 1 - abs(2*pDem(s) - 1);

            % crude coexistence indicator
            bimodalFlag(s) = double(pDem(s) >= 0.05 && pAut(s) >= 0.05);

            % exploratory transition-band score
            infoTerm   = Imax(s)  / (1 + Imax(s));
            funnelTerm = Hdrop(s) / (1 + Hdrop(s));
            transScore(s) = (balance(s) + infoTerm + funnelTerm) / 3;

            successFlag(s) = true;

        catch ME

            if storeMessages
                failMessage(s) = string(ME.message);
            end

            fprintf(2, '\nSample %d FAILED.\n', s);
            fprintf(2, 'Parameters:\n');
            for k = 1:d
                fprintf(2, '  %s = %.6g\n', spec.names{k}, vals(k));
            end
            fprintf(2, '%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));

            if stopOnError
                rethrow(ME);
            end
        end

        if mod(s, printEvery) == 0 || s == 1 || s == nSamples
            fprintf('scan %4d / %4d | success = %d | pDem = %.3f | pAut = %.3f | score = %.3f\n', ...
                s, nSamples, successFlag(s), pDem(s), pAut(s), transScore(s));
        end
    end

    % ---------------- summary table ----------------
    metricNames = { ...
        'pDem','pAut','meanFinalScore','stdFinalScore', ...
        'Imax','Hmin','Hmax','Hdrop','balance', ...
        'bimodalFlag','transitionScore','successFlag'};

    rawMat = [paramVals, ...
              pDem, pAut, meanFinal, stdFinal, ...
              Imax, Hmin, Hmax, Hdrop, balance, ...
              bimodalFlag, transScore, double(successFlag)];

    varNames = matlab.lang.makeValidName([spec.names, metricNames]);
    T = array2table(rawMat, 'VariableNames', varNames);

    if storeMessages
        T.failMessage = failMessage;
    end

    % sort successful rows first
    ok = T.successFlag == 1;

    if any(ok)
        Tok  = T(ok,:);
        Tbad = T(~ok,:);

        Tok  = sortrows(Tok, {'transitionScore','balance'}, {'descend','descend'});
        T    = [Tok; Tbad];
    end

    % ---------------- representative parameter sets ----------------
    rep = struct();
    rep.mixedIdx = [];
    rep.demIdx   = [];
    rep.autIdx   = [];

    rep.mixedP = [];
    rep.demP   = [];
    rep.autP   = [];

    okRows = find(T.successFlag == 1);

    if ~isempty(okRows)
        rep.mixedIdx = find(T.successFlag == 1 & T.pDem >= 0.35 & T.pDem <= 0.65, 1, 'first');
        rep.demIdx   = find(T.successFlag == 1 & T.pDem >= 0.85, 1, 'first');
        rep.autIdx   = find(T.successFlag == 1 & T.pAut >= 0.85, 1, 'first');

        if ~isempty(rep.mixedIdx)
            rep.mixedP = table_row_to_param_struct(baseP, spec, T(rep.mixedIdx,:));
        end
        if ~isempty(rep.demIdx)
            rep.demP = table_row_to_param_struct(baseP, spec, T(rep.demIdx,:));
        end
        if ~isempty(rep.autIdx)
            rep.autP = table_row_to_param_struct(baseP, spec, T(rep.autIdx,:));
        end

        bestIdx = okRows(1);
        bestP   = table_row_to_param_struct(baseP, spec, T(bestIdx,:));
    else
        bestP = [];
        warning('No successful parameter evaluations were completed.');
    end

    % ---------------- output struct ----------------
    scan = struct();
    scan.baseP          = baseP;
    scan.spec           = spec;
    scan.summary        = T;
    scan.bestP          = bestP;
    scan.representative = rep;

    scan.rawMetrics.U          = U;
    scan.rawMetrics.paramVals  = paramVals;
    scan.rawMetrics.pDem       = pDem;
    scan.rawMetrics.pAut       = pAut;
    scan.rawMetrics.meanFinal  = meanFinal;
    scan.rawMetrics.stdFinal   = stdFinal;
    scan.rawMetrics.Imax       = Imax;
    scan.rawMetrics.Hmin       = Hmin;
    scan.rawMetrics.Hmax       = Hmax;
    scan.rawMetrics.Hdrop      = Hdrop;
    scan.rawMetrics.balance    = balance;
    scan.rawMetrics.bimodal    = bimodalFlag;
    scan.rawMetrics.score      = transScore;
    scan.rawMetrics.success    = successFlag;
    if storeMessages
        scan.rawMetrics.failMessage = failMessage;
    end
end


function validate_metrics(metrics)
% Basic sanity checks so failures are caught early and explicitly.

    requiredFields = {'finalScore','H'};
    for i = 1:numel(requiredFields)
        if ~isfield(metrics, requiredFields{i})
            error('compute_funnel_metrics returned no field "%s".', requiredFields{i});
        end
    end

    if isempty(metrics.finalScore) || any(~isfinite(metrics.finalScore))
        error('metrics.finalScore is empty or contains non-finite values.');
    end

    if isempty(metrics.H) || any(~isfinite(metrics.H))
        error('metrics.H is empty or contains non-finite values.');
    end
end


function vals = sample_to_param_values(baseP, spec, uRow)

    d = numel(spec.names);
    vals = nan(1,d);

    for k = 1:d
        modek = lower(spec.mode{k});
        switch modek
            case 'mult'
                factor = spec.low(k) + (spec.high(k) - spec.low(k)) * uRow(k);
                vals(k) = baseP.(spec.names{k}) * factor;
            case 'abs'
                vals(k) = spec.low(k) + (spec.high(k) - spec.low(k)) * uRow(k);
            otherwise
                error('Unknown spec.mode{%d} = %s', k, spec.mode{k});
        end
    end
end


function P = apply_param_vector(P, spec, vals)
    for k = 1:numel(spec.names)
        P.(spec.names{k}) = vals(k);
    end
end


function Pout = table_row_to_param_struct(baseP, spec, rowT)
    Pout = baseP;
    for k = 1:numel(spec.names)
        Pout.(spec.names{k}) = rowT.(spec.names{k});
    end
    Pout.doSweep = false;
end


function U = lhs_simple(n, d)
% Simple Latin-hypercube sampler without toolbox dependency.

    U = zeros(n,d);

    for j = 1:d
        edges = linspace(0,1,n+1);
        pts   = edges(1:n) + rand(1,n) .* diff(edges);
        U(:,j)= pts(randperm(n))';
    end
end