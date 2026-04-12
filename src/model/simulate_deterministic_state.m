function xf = simulate_deterministic_state(P, x0, Tdet)

    x = x0;
    for t = 1:Tdet
        u = stress_schedule_local(t, P);
        x = step_model_local(x, u, 0, P);
    end
    xf = x;
end