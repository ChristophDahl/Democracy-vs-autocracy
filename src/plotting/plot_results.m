function hFig = plot_results(X, aux, metrics, P)
%PLOT_RESULTS
% Plot the main diagnostics for the democracy-autocracy model.

    [nRuns, T, ~] = size(X);

    meanAll = squeeze(mean(X,1));   % T x 4
    score   = aux.regimeScore;      % nRuns x T

    isDem = metrics.A == 1;
    isAut = metrics.A == 2;

    hFig = figure('Color','w', 'Name','Democracy backsliding model', ...
                  'Position',[50 50 1500 850]);
              
    % ---------------------------------------------------------------------
    subplot(2,3,1);
    plot(1:T, meanAll(:,1), 'k-', 'LineWidth', .75); hold on;
    plot(1:T, meanAll(:,3), 'k--', 'LineWidth', .75);
    plot(1:T, meanAll(:,2), 'r-', 'LineWidth', .75);
    plot(1:T, meanAll(:,4), 'r--', 'LineWidth', .75);
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('Time', 'Interpreter', 'latex');
    ylabel('Mean state', 'Interpreter', 'latex');
    title('Ensemble mean dynamics', 'Interpreter', 'latex');
%     legend({'N norms','E elite pressure','D institutions','P polarization'}, ...
%            'Location','best', 'Box', 'off', 'Interpreter', 'latex');
    placeLegendAtAxes(ax, 0.55, 0.38, ...
    {'N norms','D institutions','E elite pressure','P polarization'}, ...
    'Box','off', 'Interpreter','latex');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
            'LineWidth',0.5);
    ylim([0 1]);
    xlim([0 220]);

    box off;
    axis square
    labelSubplots(ax, 'A', [0.18 0.05], true, 'FontSize', 12);

    
    % ---------------------------------------------------------------------
    subplot(2,3,2);
    nShow = min(120, nRuns);
    idx   = randperm(nRuns, nShow);

    ax = gca();
    hold(ax, 'on');
    set(ax, 'TickLabelInterpreter', 'latex');

    % Sample runs
    hRunsAll = plot(1:T, score(idx,:)', 'Color',[.8 .8 .8], 'LineWidth',0.6);
    hRuns = hRunsAll(1); % one representative handle for legend

    % Neutral boundary
    hBoundary = plot([0 T],[0 0], 'k:', 'LineWidth', 0.6);

    % Initialize legend handles
    legendHandles = [hRuns, hBoundary];
    legendEntries = {'Sample runs', 'Neutral boundary'};

    % Basin means with explicit colors
    if any(isDem)
        hDem = plot(1:T, mean(score(isDem,:),1), ...
            'Color',[0 0 0], 'LineWidth', .75);
        legendHandles(end+1) = hDem;
        legendEntries{end+1} = 'Democratic basin mean';
    end

    if any(isAut)
        hAut = plot(1:T, mean(score(isAut,:),1), ...
            'Color',[0 0 0], 'LineStyle', '--',  'LineWidth', .75);
        legendHandles(end+1) = hAut;
        legendEntries{end+1} = 'Autocratic basin mean';
    end

    xlabel('Time', 'Interpreter', 'latex');
    ylabel('Regime score', 'Interpreter', 'latex');
    title('Sample trajectories and basin means', 'Interpreter', 'latex');

    placeLegendAtAxes(ax, 0.2, 0.51, ...
    legendHandles, legendEntries, ...
    'Box','off', 'Interpreter','latex');

%     legend(legendHandles, legendEntries, ...
%         'Location','southwest', 'Box','off', 'Interpreter','latex');

    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
            'LineWidth',0.5);
    xlim([0 220]);
    axis square
    labelSubplots(ax, 'B', [0.18 0.05], true, 'FontSize', 12);
    
    % ---------------------------------------------------------------------
    subplot(2,3,3);

    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');

    % Left axis: H in black
    yyaxis left
    plot(1:T, metrics.H, 'k', 'LineWidth', .75);
    ylabel('$H(S_t)$', 'Interpreter', 'latex');
    ax.YAxis(1).Color = [0 0 0];

    % Right axis: I in blue
    yyaxis right
    if all(isnan(metrics.I))
        plot(1:T, zeros(1,T), 'LineStyle','none');
        ylabel('$I(S_t;A)$', 'Interpreter', 'latex');
        ax.YAxis(2).Color = [0 0 1];
        ylim([0 1]);
        text(0.55*T, 0.5, 'single final class', ...
            'HorizontalAlignment','center', 'Interpreter','latex', ...
            'Color', [0 0 1]);
    else
        plot(1:T, metrics.I, 'Color', [0 0 0], 'LineStyle', '--', 'LineWidth', .75);
        ylabel('$I(S_t;A)$', 'Interpreter', 'latex');
        ax.YAxis(2).Color = [0 0 0];
    end

    xlabel('Time', 'Interpreter', 'latex');
    title('Information funnel diagnostics', 'Interpreter', 'latex');

    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    xlim([0 220]);
    axis square
    labelSubplots(ax, 'C', [0.18 0.05], true, 'FontSize', 12);

    % ---------------------------------------------------------------------
    subplot(2,3,4);
    h = histogram(metrics.finalScore, 50);
    counts = h.Values;
    edges  = h.BinEdges;
    centers = edges(1:end-1) + diff(edges)/2;
    delete(h)

    plot(centers, counts, 'k-', 'LineWidth',.75);
    ax = gca();
        set(ax, 'TickLabelInterpreter', 'latex'); 
    xline(0, '--k', 'LineWidth',.6);
    xlabel('Final regime score', 'Interpreter', 'latex');
    ylabel('Count', 'Interpreter', 'latex');
    title('Distribution of final outcomes', 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    box off;
    axis square
    labelSubplots(ax, 'D', [0.18 0.05], true, 'FontSize', 12);


    % ---------------------------------------------------------------------
    subplot(2,3,5);
    plot_phase_slice(P, 0.60, 0.40, 0.40);
    

    % ---------------------------------------------------------------------
    subplot(2,3,6);

    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');

    % Left axis: stress in black
    yyaxis left
    plot(1:T, mean(aux.stress,1), 'k', 'LineWidth',.75);
    ylabel('Mean stress', 'Interpreter', 'latex');
    ax.YAxis(1).Color = [0 0 0];

    % Right axis: autocratic fraction in blue
    yyaxis right
    plot(1:T, metrics.autFractionTime, 'Color',[0 0 0], 'LineStyle','--','LineWidth',.75);
    ylabel('Autocratic fraction', 'Interpreter', 'latex');
    ax.YAxis(2).Color = [0 0 0];
    ylim([0 1]);

    xlim([0 220]);
    xlabel('Time', 'Interpreter', 'latex');
    title('External stress and autocratic share', 'Interpreter', 'latex');

    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    axis square
    labelSubplots(ax, 'F', [0.18 0.05], true, 'FontSize', 12);

end


function plot_phase_slice(P, Dfix, Pfix, uFix)

    gridVals = linspace(0.05,0.95,21);
    [Ngrid, Egrid] = meshgrid(gridVals, gridVals);

    dN = zeros(size(Ngrid));
    dE = zeros(size(Egrid));

    for i = 1:numel(Ngrid)
        x  = [Ngrid(i), Egrid(i), Dfix, Pfix];
        x1 = step_model_local(x, uFix, 0, P, false);

        dN(i) = x1(1) - x(1);
        dE(i) = x1(2) - x(2);
    end

    quiver(Ngrid, Egrid, dN, dE, 'k', 'AutoScale', 'on', 'LineWidth', 0.5);
    hold on;
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('N: norm compliance', 'Interpreter', 'latex');
    ylabel('E: elite pressure', 'Interpreter', 'latex');
    title(sprintf('Phase slice at D=%.2f, P=%.2f, u=%.2f', Dfix, Pfix, uFix), 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    xlim([0 1]); ylim([0 1]);
    axis square
    box off;
    labelSubplots(ax, 'E', [0.18 0.05], true, 'FontSize', 12);
end


function x1 = step_model_local(x, u, shock, P, addNoise)

    N   = x(1);
    E   = x(2);
    D   = x(3);
    Pol = x(4);

    S = D * (1 - E);

    demBloc = N * D;
    autBloc = E * Pol;

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

    target = sigmoid_local([zN zE zD zP]);

    x1 = (1 - P.lam) .* x + P.lam .* target;

    if addNoise
        x1 = x1 + P.noiseStd .* randn(1,4);
    end

    x1 = clip01_local(x1);
end


function y = sigmoid_local(x)
    y = 1 ./ (1 + exp(-x));
end


function x = clip01_local(x)
    x = min(max(x,0),1);
end