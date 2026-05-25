# Competing democratic and autocratic long-run regimes in a minimal norm–institution model

This repository contains MATLAB code for the study:

**Dahl, C. D., & Lane, T. J.**  
*Competing democratic and autocratic long-run regimes in a minimal norm–institution model.*

## Overview

This project implements a minimal dynamical model designed to examine whether democratic and autocratic regime outcomes can emerge as competing long-run basins under coupled interactions among:

- democratic norm compliance (`N`)
- elite autocratic pressure (`E`)
- institutional strength (`D`)
- polarization (`P`)

The repository includes code for:

- baseline ensemble simulations
- systematic parameter exploration around the baseline setting
- information-funneling diagnostics
- deterministic exploration of basin structure in the four-dimensional state space
- figure generation for the manuscript

The central aim is not to fit a specific empirical data set, but to test whether a minimal norm–institution system can generate:
1. two competing long-run regime families,
2. a democracy-leaning baseline with nontrivial autocratic risk,
3. an extended transition band in parameter space, and
4. interpretable information-theoretic diagnostics of how trajectories become predictive of their eventual regime outcome.

## Repository structure

```text
democracy_autocracy/
├── README.md
├── main/
│   ├── run_democracy_backsliding_model.m
│   ├── run_parameter_scan.m
│   └── run_simulation.m
├── src/
│   ├── config/
│   │   ├── default_params.m
│   │   └── default_scan_spec.m
│   ├── model/
│   │   ├── step_model_local.m
│   │   ├── stress_schedule_local.m
│   │   ├── regime_score_local.m
│   │   ├── simulate_deterministic_state.m
│   │   └── simulate_deterministic_trajectory.m
│   ├── simulate/
│   │   └── simulate_ensemble.m
│   ├── analysis/
│   │   ├── compute_funnel_metrics.m
│   │   ├── compute_pairwise_basin_map.m
│   │   ├── explore_4d_state_space.m
│   │   └── run_robustness_checks.m
│   └── plotting/
│       ├── plot_results.m
│       ├── plot_scan_summary.m
│       ├── labelSubplots.m
│       ├── placeLegendAt.m
│       ├── placeLegendAtAxes.m
│       ├── save_model_figure.m
│       └── create_model_architecture_figure.m

├── figures/
├── results/
└── manuscript/
