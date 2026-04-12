function hLeg = placeLegendAtAxes(ax, x, y, hObjs, labels, varargin)
% x,y = lower-left corner in axes-normalized coordinates

    hLeg = legend(ax, hObjs, labels, varargin{:});
    set(hLeg, 'Units', 'normalized', 'AutoUpdate', 'off');

    axPos  = get(ax, 'Position');   % figure-normalized
    legPos = get(hLeg, 'Position');

    legPos(1) = axPos(1) + x * axPos(3);
    legPos(2) = axPos(2) + y * axPos(4);

    set(hLeg, 'Position', legPos);
end