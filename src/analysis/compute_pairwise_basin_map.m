function [Xg, Yg, scoreGrid, labelGrid] = compute_pairwise_basin_map(P, ij, fixedState, gridN, Tdet)

    vals = linspace(0,1,gridN);
    [Xg, Yg] = meshgrid(vals, vals);

    scoreGrid = zeros(gridN, gridN);
    labelGrid = zeros(gridN, gridN);

    for a = 1:gridN
        for b = 1:gridN
            x0 = fixedState;
            x0(ij(1)) = Xg(a,b);
            x0(ij(2)) = Yg(a,b);

            xf = simulate_deterministic_state(P, x0, Tdet);
            s  = regime_score_local(xf);

            scoreGrid(a,b) = s;
            labelGrid(a,b) = 1 + (s < 0);  % 1 dem, 2 aut
        end
    end
end