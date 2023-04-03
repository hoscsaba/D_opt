function hidr_solver_driver
    clear all, close all, clc

    global wds USE_PIVOTING

    %fname="/Users/hoscsaba/Oktatas/Projektek/2022_23_2/medencek2.inp";
    fname='systems/epanet_tutorial2.inp';
    %fname='systems/pivot_sample.inp';
    %fname='systems/Net1.inp';
    %fname='systems/Anytown.inp';
    %fname='systems/d-town.inp';
    %fname='systems/MICROPOLIS_v1.inp';
    %fname='systems/PacificCity.inp';
    %fname='systems/Hanoi.inp';
    %% Load systems
    DEBUG_LEVEL=3;
    wds=load_epanet(fname,DEBUG_LEVEL);

    SHOW_RESULTS=1;
    DO_PLOT=1;

    %% Solve system without pivoting
    USE_PIVOTING=0;
    [Q1,p1,dp1]=hidr_solver(SHOW_RESULTS,DO_PLOT);

    %% Solve system with pivoting
    USE_PIVOTING=1;
    [Q2,p2,dp2]=hidr_solver(SHOW_RESULTS,DO_PLOT);

    norm(Q1-Q2)/norm(Q1)
    norm(p1-p2)/norm(p1)

end

