function save_model_figure(hFig, basePath)
% basePath without extension, e.g.
% fullfile(cfg.figDir, 'baseline_overview')

    exportgraphics(hFig, [basePath '.png'], 'Resolution', 300);
    exportgraphics(hFig, [basePath '.pdf'], 'ContentType', 'vector');
    savefig(hFig, [basePath '.fig']);

    fprintf('Saved figure:\n  %s.png\n  %s.pdf\n  %s.fig\n', ...
        basePath, basePath, basePath);
end