function P = default_params()

    % ---------------- simulation ----------------
    P.T          = 220;     % time steps
    P.nRuns      = 1500;    % ensemble size
    P.nBins      = 6;       % discretization per dimension for funnel metrics

    % Initial mean state [N E D P]
    P.initMean   = [0.53 0.47 0.53 0.47];
    P.initJitter = [0.13 0.13 0.11 0.13];

    % Additive Gaussian noise per update [N E D P]
    P.noiseStd   = [0.024 0.021 0.011 0.024];

    % Rare grievance / crisis shocks
    P.shockProb  = 0.025;
    P.shockMean  = 0.15;
    P.shockStd   = 0.08;

    % Update rates (D slower than the others)
    P.lam        = [0.28 0.28 0.06 0.26];

    % Exogenous stress schedule
    P.uStart     = 65;
    P.uRampEnd   = 145;
    P.uMax       = 0.56;

    % Heterogeneity in sensitivity to stress across runs
    P.stressSensitivityMean = 1.00;
    P.stressSensitivityStd  = 0.24;
    P.stressSensitivityMin  = 0.60;

    % ---------------- latent target equations ----------------
    % N target
    P.thetaN =  0.06;
    P.aND    =  1.95;
    P.aNE    =  1.10;
    P.aNP    =  0.92;
    P.aNN    =  0.92;
    P.aNS    =  1.05;
    P.aNU    =  0.82;

    % E target
    P.thetaE = -1.02;
    P.aEP    =  1.08;
    P.aEN    =  1.00;
    P.aED    =  0.84;
    P.aEE    =  0.84;
    P.aEnegD =  0.90;
    P.aEU    =  0.82;

    % D target
    P.thetaD =  0.03;
    P.aDN    =  1.95;
    P.aDE    =  1.08;
    P.aDP    =  0.66;
    P.aDD    =  0.72;
    P.aDU    =  0.76;

    % P target
    P.thetaP = -0.82;
    P.aPE    =  1.02;
    P.aPnegD =  0.68;
    P.aPN    =  0.98;
    P.aPP    =  0.84;
    P.aPU    =  0.82;
    P.aPshock=  1.05;

    % ---------------- explicit bloc reinforcement ----------------
    P.aNdem  = 0.60;
    P.aNaut  = 0.82;

    P.aEdem  = 0.40;
    P.aEaut  = 0.98;

    P.aDdem  = 0.60;
    P.aDaut  = 0.82;

    P.aPdem  = 0.40;
    P.aPaut  = 1.00;

    % ---------------- optional sweep ----------------
    P.doSweep         = true;
    P.sweep.nRuns     = 350;
    P.sweep.uVals     = linspace(0,1,15);
end