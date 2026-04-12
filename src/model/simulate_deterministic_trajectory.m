function X = simulate_deterministic_trajectory(P, x0, Tdet)

    X = zeros(Tdet,4);
    x = x0;
    X(1,:) = x;

    for t = 2:Tdet
        u = stress_schedule_local(t, P);
        x = step_model_local(x, u, 0, P);
        X(t,:) = x;
    end
end