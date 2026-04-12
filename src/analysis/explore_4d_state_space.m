function [hBasin, hFinal, out4D] = explore_4d_state_space(P)

    if nargin < 1 || isempty(P)
        P = default_params();
    end

    rng(1);

    % deterministic exploration settings
    Tdet          = 220;
    gridN         = 41;
    nCloud        = 2000;
    nTraj         = 150;
    showTrajEvery = 5;

    labels = {'N','E','D','P'};
    pairIdx = nchoosek(1:4,2);

    % ---------------------------------------------------------------------
    % 1) Pairwise basin maps
    hBasin = figure('Color','w','Name','Pairwise basin maps','Position',[50 50 950 580]);
    tl = tiledlayout(2,3, 'TileSpacing','normal', 'Padding','normal');

    for p = 1:size(pairIdx,1)

        ij = pairIdx(p,:);
        other = setdiff(1:4, ij);

        fixedState = 0.50 * ones(1,4);

        [~, ~, scoreGrid, labelGrid] = compute_pairwise_basin_map(P, ij, fixedState, gridN, Tdet);

        ax = nexttile;
        imagesc(linspace(0,1,gridN), linspace(0,1,gridN), scoreGrid);
        set(ax, 'YDir','normal', 'TickLabelInterpreter','latex');
        hold(ax, 'on');

        contour(linspace(0,1,gridN), linspace(0,1,gridN), labelGrid, [1.5 1.5], ...
            'k', 'LineWidth', 1.2);

        xlabel(labels{ij(1)}, 'Interpreter','latex');
        ylabel(labels{ij(2)}, 'Interpreter','latex');

        title(sprintf('%s-%s basin map (%s=%0.2f, %s=%0.2f)', ...
            labels{ij(1)}, labels{ij(2)}, ...
            labels{other(1)}, fixedState(other(1)), ...
            labels{other(2)}, fixedState(other(2))), ...
            'Interpreter','latex');

        set(ax, 'Box','off', 'TickDir','out', 'TickLength',[.01 .01], ...
            'LineWidth',0.5, 'XTick', [0:.2:1], 'YTick', [0:.2:1]);

        caxis(ax, [-1 1]);
        axis(ax, 'square');
        labelSubplots(ax, char('A' + (p-1)), [0.18 0.05], true, 'FontSize', 12);    
    end

    % Create one invisible axes only for the shared colorbar
    cbAx = axes('Position',[0.92 0.11 0.01 0.77], 'Visible','off');
    colormap(cbAx, parula);
    caxis(cbAx, [-1 1]);

    cb = colorbar(cbAx, 'Position',[0.93 0.14 0.018 0.72]);
    cb.Label.String = '$\mathrm{Final\ regime\ score}$';
    cb.Label.Interpreter = 'latex';
    cb.TickLabelInterpreter = 'latex';
    cb.Label.FontSize = 11;
    cb.Box = 'off';
    
    % ---------------------------------------------------------------------
    % 2) Final-state cloud from random 4D initial conditions
    X0 = rand(nCloud,4);
    Xf = zeros(nCloud,4);
    finalScore = zeros(nCloud,1);
    finalLabel = zeros(nCloud,1);

    for i = 1:nCloud
        xf = simulate_deterministic_state(P, X0(i,:), Tdet);
        Xf(i,:) = xf;
        finalScore(i) = regime_score_local(xf);
        finalLabel(i) = 1 + (finalScore(i) < 0);  % 1 dem, 2 aut
    end

    [~, scoreF] = pca(Xf);
    
    hFinal = figure('Color','w','Name','Final-state PCA','Position',[120 120 1200 400]);

%     subplot(1,2,1);
%     scatter(scoreF(finalLabel==1,1), scoreF(finalLabel==1,2), 12, 'filled'); hold on;
%     scatter(scoreF(finalLabel==2,1), scoreF(finalLabel==2,2), 12, 'filled');
%     xlabel('PC1');
%     ylabel('PC2');
%     title('Final states projected by PCA');
%     legend({'Democratic final states','Autocratic final states'}, 'Location','best');
%     box off;

    subplot(1,3,1);
    scatter3(scoreF(finalLabel==1,1), scoreF(finalLabel==1,2), scoreF(finalLabel==1,3), 12, 'filled'); hold on;
    scatter3(scoreF(finalLabel==2,1), scoreF(finalLabel==2,2), scoreF(finalLabel==2,3), 12, 'filled');
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('PC1', 'Interpreter', 'latex');
    ylabel('PC2', 'Interpreter', 'latex');
    zlabel('PC3', 'Interpreter', 'latex');
    title('Final states projected into 3D PCA space', 'Interpreter', 'latex');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
        'LineWidth',0.5, 'XTick', [-1:.5:1]);
    placeLegendAtAxes(ax, 0.15, 0.8, ...
    {'Democratic final states','Autocratic final states'}, ...
    'Box','off', 'Interpreter','latex');
    grid on;
    axis square
    box off;
    labelSubplots(ax, 'A', [0.18 0.05], true, 'FontSize', 12);   
    
    % ---------------------------------------------------------------------
    % 3) Trajectory projection + final-score histogram
    Xtraj = zeros(nTraj, Tdet, 4);
    Xtraj0 = rand(nTraj,4);

    for i = 1:nTraj
        Xtraj(i,:,:) = simulate_deterministic_trajectory(P, Xtraj0(i,:), Tdet);
    end

    allStates = reshape(Xtraj, nTraj*Tdet, 4);
    [~, scoreT] = pca(allStates);
    scoreT = reshape(scoreT(:,1:2), nTraj, Tdet, 2);

%     hTraj = figure('Color','w','Name','Trajectory PCA projection','Position',[150 150 1000 800]);

    subplot(1,3,2); hold on;
    for i = 1:showTrajEvery:nTraj
        plot(squeeze(scoreT(i,:,1)), squeeze(scoreT(i,:,2)), 'LineWidth', .75, 'Color', 'k');
    end
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xlabel('PC1', 'Interpreter', 'latex');
    ylabel('PC2', 'Interpreter', 'latex');
    title('Projected trajectories in PCA space', 'Interpreter', 'latex');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
        'LineWidth',0.5);
    box off;
    axis square
    labelSubplots(ax, 'B', [0.18 0.05], true, 'FontSize', 12);   

    subplot(1,3,3);
%     histogram(finalScore, 40);
    h = histogram(finalScore, 40);
    counts = h.Values;
    edges  = h.BinEdges;
    centers = edges(1:end-1) + diff(edges)/2;
    delete(h)

    bar(centers, counts, 1.0, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0.7 0.7 0.7]);
    ax = gca();
    set(ax, 'TickLabelInterpreter', 'latex');
    xline(0,'--k');
    xlabel('Final regime score', 'Interpreter', 'latex');
    ylabel('Count', 'Interpreter', 'latex');
    title({'Final score distribution from', 'random 4D initial conditions'}, 'Interpreter', 'latex');   
%     title('Final score distribution from random 4D initial conditions', 'Interpreter', 'latex');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
        'LineWidth',0.5);
    box off;    
    axis square
    labelSubplots(ax, 'C', [0.18 0.05], true, 'FontSize', 12);  
    
    out4D.finalScore = finalScore;
    out4D.finalLabel = finalLabel;
    out4D.Xf         = Xf;
    out4D.scoreF     = scoreF;
    out4D.Xtraj      = Xtraj;
    out4D.scoreT     = scoreT;
end