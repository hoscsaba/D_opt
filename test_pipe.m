function test_pipe
    clear all, close all, clc

    global wds USE_PIVOTING DEBUG_LEVEL DO_PLOT SHOW_RESULTS

    fname="systems/pipe_test.inp";
    
    DEBUG_LEVEL=3; 
    SHOW_RESULTS=1; 
    DO_PLOT=1;
    USE_PIVOTING=0;
    
     %% Load system
    wds=load_epanet(fname);

    %% Solve system without pivoting
     x=hydr_solver_initiate();
    [Q1,p1,dp1]=hydr_solver(x);

end

