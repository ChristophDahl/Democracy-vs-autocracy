function hFig = plot_representative_comparison(reruns)

    hFig = figure('Color','w','Name','Representative rerun comparison', ...
           'Position',[120 120 800 800]);

    names = {};
    finalScores = {};
    entropies = {};
    infos = {};
    autFracs = {};

    if isfield(reruns,'best')
        names{end+1} = 'best';
        finalScores{end+1} = reruns.best.metrics.finalScore;
        entropies{end+1}   = reruns.best.metrics.H;
        infos{end+1}       = reruns.best.metrics.I;
        autFracs{end+1}    = reruns.best.metrics.autFractionTime;
    end
    if isfield(reruns,'mixed')
        names{end+1} = 'mixed';
        finalScores{end+1} = reruns.mixed.metrics.finalScore;
        entropies{end+1}   = reruns.mixed.metrics.H;
        infos{end+1}       = reruns.mixed.metrics.I;
        autFracs{end+1}    = reruns.mixed.metrics.autFractionTime;
    end
    if isfield(reruns,'dem')
        names{end+1} = 'dem';
        finalScores{end+1} = reruns.dem.metrics.finalScore;
        entropies{end+1}   = reruns.dem.metrics.H;
        infos{end+1}       = reruns.dem.metrics.I;
        autFracs{end+1}    = reruns.dem.metrics.autFractionTime;
    end
    if isfield(reruns,'aut')
        names{end+1} = 'aut';
        finalScores{end+1} = reruns.aut.metrics.finalScore;
        entropies{end+1}   = reruns.aut.metrics.H;
        infos{end+1}       = reruns.aut.metrics.I;
        autFracs{end+1}    = reruns.aut.metrics.autFractionTime;
    end

    subplot(2,2,1); hold on;
    for i = 1:numel(finalScores)
        histogram(finalScores{i}, 25, 'DisplayStyle','stairs', 'LineWidth', .75);
    end
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex'); 
    xline(0,'--k');
    xlabel('Final regime score', 'Interpreter', 'latex');
    ylabel('Count', 'Interpreter', 'latex');
    title('Final score distributions', 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
%     legend(names, 'Location','best', 'Interpreter', 'latex');
    placeLegendAtAxes(ax, 0.33, 0.8, ...
    names, ...
    'Box','off', 'Interpreter','latex');
    box off;
    axis square
    labelSubplots(ax, 'A', [0.18 0.05], true, 'FontSize', 12);

    subplot(2,2,2); hold on;
    for i = 1:numel(entropies)
        plot(entropies{i}, 'LineWidth',.75);
    end
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex'); 
    xlabel('Time', 'Interpreter', 'latex');
    ylabel('$H(S_t)$', 'Interpreter', 'latex');
    title('Entropy trajectories', 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
%     legend(names, 'Location','best', 'Interpreter', 'latex');
    placeLegendAtAxes(ax, 0.37, 0.8, ...
    names, ...
    'Box','off', 'Interpreter','latex');
    box off;
    axis square
    labelSubplots(ax, 'B', [0.18 0.05], true, 'FontSize', 12);

    subplot(2,2,3); hold on;
    for i = 1:numel(infos)
        if ~all(isnan(infos{i}))
            plot(infos{i}, 'LineWidth',.75);
        end
    end
    ax = gca();
        set(ax, 'TickLabelInterpreter', 'latex'); 
    xlabel('Time', 'Interpreter', 'latex');
    ylabel('$I(S_t ; A)$', 'Interpreter', 'latex');
    title('Mutual information trajectories', 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
%     legend(names, 'Location','best', 'Interpreter', 'latex');
    placeLegendAtAxes(ax, 0.37, 0.8, ...
    names, ...
    'Box','off', 'Interpreter','latex');
    box off;
    axis square
    labelSubplots(ax, 'C', [0.18 0.05], true, 'FontSize', 12);

    subplot(2,2,4); hold on;
    for i = 1:numel(autFracs)
        plot(autFracs{i}, 'LineWidth',.75);
    end
    ax = gca();
        set(ax, 'TickLabelInterpreter', 'latex'); 
    xlabel('Time', 'Interpreter','latex');
    ylabel('Autocratic fraction', 'Interpreter','latex');
    title('Autocratic share over time', 'Interpreter','latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    placeLegendAtAxes(ax, 0.37, 0.8, ...
    names, ...
    'Box','off', 'Interpreter','latex');    box off;
    axis square
    labelSubplots(ax, 'D', [0.18 0.05], true, 'FontSize', 12);

end