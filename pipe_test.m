function pipe_test
    clear all, close all, clc

    global wds USE_PIVOTING

    fname="/Users/hoscsaba/Oktatas/Projektek/2022_23_2/medencek2.inp";
    
    %% Load system
    DEBUG_LEVEL=3;
    wds=load_epanet(fname,DEBUG_LEVEL);

    SHOW_RESULTS=1;
    DO_PLOT=1;

    %% Solve system without pivoting
    USE_PIVOTING=0;
    [Q1,p1,dp1]=hidr_solver(SHOW_RESULTS,DO_PLOT);

end

