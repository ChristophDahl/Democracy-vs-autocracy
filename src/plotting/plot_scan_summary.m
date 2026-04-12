function hFig = plot_scan_summary(scan)

    T = scan.summary;
    T = T(T.successFlag == 1,:);

    hFig = figure('Color','w','Name','Parameter scan summary', ...
                  'Position',[100 100 900 800]);
    tiledlayout(2,2, 'TileSpacing','normal', 'Padding','normal');
    
    nexttile;
    scatter(T.uMax, T.pDem, 12, T.transitionScore, 'filled');
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('uMax', 'Interpreter', 'latex');
    ylabel('pDem', 'Interpreter', 'latex');
    title({'Democratic occupancy', 'across scan'}, 'Interpreter', 'latex');   
    cb = colorbar;
    cb.Label.String = '$\mathrm{Transition score}$';
    cb.Label.Interpreter = 'latex';
    set(cb, 'TickLabelInterpreter', 'latex');
    cb.Box = 'off';
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    axis square
    box off;
    labelSubplots(ax, 'A', [0.18 0.05], true, 'FontSize', 12);

    nexttile;
    scatter(T.balance, T.Imax, 12, T.Hdrop, 'filled');
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('Balance', 'Interpreter', 'latex');
    ylabel('Imax', 'Interpreter', 'latex');
    title('Transition-band structure', 'Interpreter', 'latex');
    cb = colorbar;
    cb.Label.String = 'Hdrop';
    cb.Label.Interpreter = 'latex';
    set(cb, 'TickLabelInterpreter', 'latex');
    cb.Box = 'off';
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    axis square
    box off;
    labelSubplots(ax, 'B', [0.18 0.05], true, 'FontSize', 12);

    nexttile;
    h = histogram(T.pDem, 50);
    counts = h.Values;
    edges  = h.BinEdges;
    centers = edges(1:end-1) + diff(edges)/2;
    delete(h)

    plot(centers, counts, 'k-', 'LineWidth', .75);
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('pDem', 'Interpreter', 'latex');
    ylabel('Count', 'Interpreter', 'latex');
    title('Distribution of democratic occupancy', 'Interpreter', 'latex');
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    axis square
    box off;
    labelSubplots(ax, 'C', [0.18 0.05], true, 'FontSize', 12);

    nexttile;
    scatter(T.pDem, T.meanFinalScore, 12, T.transitionScore, 'filled');
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('pDem', 'Interpreter', 'latex');
    ylabel('Mean final score', 'Interpreter', 'latex');
    title('Outcome magnitude vs occupancy', 'Interpreter', 'latex');
    cb = colorbar;
    cb.Label.String = 'Transition score';
    cb.Label.Interpreter = 'latex';
    set(cb, 'TickLabelInterpreter', 'latex');
    cb.Box = 'off';
    set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
        'LineWidth',0.5);
    axis square
    box off;
    labelSubplots(ax, 'D', [0.18 0.05], true, 'FontSize', 12);

end