function u = stress_schedule_local(t, P)
    if t < P.uStart
        u = 0;
    elseif t <= P.uRampEnd
        u = P.uMax * (t - P.uStart) / (P.uRampEnd - P.uStart);
    else
        u = P.uMax;
    end
end