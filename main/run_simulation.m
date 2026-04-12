%% run_simulation.m

rng(1);

% -------------------------------------------------------------------------
% Control flags
cfg.plot4D_base   = true;
cfg.plot4D_best   = false;
cfg.plot4D_mixed  = false;
cfg.plot4D_dem    = false;
cfg.plot4D_aut    = false;

cfg.computeBaseline = false;
cfg.computeScan     = false;
cfg.computeReruns   = false;

cfg.plotBaseline    = true;
cfg.plotScanSummary = true;
cfg.plotReruns      = true;

cfg.saveResults     = false;
cfg.loadResults     = true;

cfg.resultsFile     = 'I:\democracy_autocracy\results\democracy_scan_results.mat';
cfg.figDir          = 'I:\democracy_autocracy\figures';
cfg.results4D_base = 'I:\democracy_autocracy\results\explore_4d_base.mat';

cfg.nSamples        = 500;
cfg.nRunsQuick      = 250;
cfg.nRunsFull       = 1500;

if ~exist(cfg.figDir, 'dir')
    mkdir(cfg.figDir);
end
if ~exist(fileparts(cfg.resultsFile), 'dir')
    mkdir(fileparts(cfg.resultsFile));
end

% -------------------------------------------------------------------------
% Load previous results if requested
if cfg.loadResults

    S = load(cfg.resultsFile);

    if isfield(S,'P0'),       P0 = S.P0; end
    if isfield(S,'spec'),     spec = S.spec; end
    if isfield(S,'scan'),     scan = S.scan; end
    if isfield(S,'X0'),       X0 = S.X0; end
    if isfield(S,'aux0'),     aux0 = S.aux0; end
    if isfield(S,'metrics0'), metrics0 = S.metrics0; end
    if isfield(S,'reruns'),   reruns = S.reruns; end

    fprintf('Loaded results from %s\n', cfg.resultsFile);

else

    % ---------------------------------------------------------------------
    % Baseline parameter set
    P0 = default_params();

    % ---------------------------------------------------------------------
    % Baseline simulation
    if cfg.computeBaseline
        [X0, aux0] = simulate_ensemble(P0);
        metrics0   = compute_funnel_metrics(X0, aux0, P0);

        fprintf('Baseline test:\n');
        fprintf('  pDem = %.3f\n', mean(metrics0.finalScore > 0));
        fprintf('  pAut = %.3f\n', mean(metrics0.finalScore < 0));
        fprintf('  mean final score = %.3f\n', mean(metrics0.finalScore));
    end

    % ---------------------------------------------------------------------
    % Parameter scan
    spec = default_scan_spec(P0);

    if cfg.computeScan
        scan = run_parameter_scan(P0, spec, cfg.nSamples, cfg.nRunsQuick, 1);
        fprintf('\nTop 20 scanned parameter sets:\n');
        disp(scan.summary(1:20,:))
    end

    % ---------------------------------------------------------------------
    % Representative reruns
    reruns = struct();

    if cfg.computeReruns
        P_best  = scan.bestP;
        P_mixed = scan.representative.mixedP;
        P_dem   = scan.representative.demP;
        P_aut   = scan.representative.autP;

        if ~isempty(P_best)
            P_best.nRuns = cfg.nRunsFull;
            [reruns.best.X, reruns.best.aux] = simulate_ensemble(P_best);
            reruns.best.metrics = compute_funnel_metrics(reruns.best.X, reruns.best.aux, P_best);
            reruns.best.P = P_best;
        end

        if ~isempty(P_mixed)
            P_mixed.nRuns = cfg.nRunsFull;
            [reruns.mixed.X, reruns.mixed.aux] = simulate_ensemble(P_mixed);
            reruns.mixed.metrics = compute_funnel_metrics(reruns.mixed.X, reruns.mixed.aux, P_mixed);
            reruns.mixed.P = P_mixed;
        end

        if ~isempty(P_dem)
            P_dem.nRuns = cfg.nRunsFull;
            [reruns.dem.X, reruns.dem.aux] = simulate_ensemble(P_dem);
            reruns.dem.metrics = compute_funnel_metrics(reruns.dem.X, reruns.dem.aux, P_dem);
            reruns.dem.P = P_dem;
        end

        if ~isempty(P_aut)
            P_aut.nRuns = cfg.nRunsFull;
            [reruns.aut.X, reruns.aut.aux] = simulate_ensemble(P_aut);
            reruns.aut.metrics = compute_funnel_metrics(reruns.aut.X, reruns.aut.aux, P_aut);
            reruns.aut.P = P_aut;
        end
    end

    % ---------------------------------------------------------------------
    % Save results once
    if cfg.saveResults
        save(cfg.resultsFile, 'P0', 'spec', 'scan', ...
            'X0', 'aux0', 'metrics0', 'reruns', '-v7.3');
        fprintf('\nSaved results to %s\n', cfg.resultsFile);
    end
end

% -------------------------------------------------------------------------
% Plotting and figure export
if cfg.plotBaseline && exist('X0','var')
    hBase = plot_results(X0, aux0, metrics0, P0);
    save_model_figure(hBase, fullfile(cfg.figDir, 'figure1_baseline'));
end

if cfg.plotScanSummary && exist('scan','var')
    hScan = plot_scan_summary(scan);
    save_model_figure(hScan, fullfile(cfg.figDir, 'figure2_scan'));
end

if cfg.plotReruns && exist('reruns','var')
    hComp = plot_representative_comparison(reruns);
    save_model_figure(hComp, fullfile(cfg.figDir, 'figure3_representatives'));
end

% -------------------------------------------------------------------------
% 4D state-space exploration
if cfg.plot4D_base && exist('P0','var')
    [hBasin, hFinal, out4D_base] = explore_4d_state_space(P0);
    save(cfg.results4D_base, 'out4D_base', 'P0', '-v7.3');
    save_model_figure(hBasin, fullfile(cfg.figDir, 'figure4_pairwisebasins'));
%     save_model_figure(hTraj,  fullfile(cfg.figDir, 'trajectory_projection_4d'));
    save_model_figure(hFinal, fullfile(cfg.figDir, 'figure5_terminalstructure'));
end

% if cfg.plot4D_best && exist('reruns','var') && isfield(reruns,'best')
%     explore_4d_state_space(reruns.best.P);
% end
% 
% if cfg.plot4D_mixed && exist('reruns','var') && isfield(reruns,'mixed')
%     explore_4d_state_space(reruns.mixed.P);
% end
% 
% if cfg.plot4D_dem && exist('reruns','var') && isfield(reruns,'dem')
%     explore_4d_state_space(reruns.dem.P);
% end
% 
% if cfg.plot4D_aut && exist('reruns','var') && isfield(reruns,'aut')
%     explore_4d_state_space(reruns.aut.P);
% end