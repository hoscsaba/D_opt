function hidr_solver_driver
    clear all, close all, clc

    global wds

    fname="/Users/hoscsaba/Oktatas/Projektek/2022_23_2/medencek2.inp";
    %fname='systems/epanet_tutorial2.inp';
    %fname='systems/Net1.inp';
    %fname='systems/Anytown.inp';
    %fname='systems/d-town.inp';
    %fname='systems/MICROPOLIS_v1.inp';
    %fname='systems/PacificCity.inp';
    %fname='systems/Hanoi.inp';
    %% Load systems
    DEBUG_LEVEL=4;
    wds=load_epanet(fname,DEBUG_LEVEL);

    %% Solve system
    USE_PIVOTING=0;
    SHOW_RESULTS=1;
    [Q,p,dp]=hidr_solver(USE_PIVOTING,SHOW_RESULTS);

end

