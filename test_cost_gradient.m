function test_cost_gradient() 
	clear all, clc

	global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS OPT_PAR USER_GRADIENT
	global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize
    global xini

	%probname='mot_example_no_pump';
    probname='mot_example_L_no_pump';
    %probname='mot_example_L';
	fname=fullfile('systems',[probname,'.inp']);

	%% Load system to solver
	DEBUG_LEVEL=0;
	wds=load_epanet(fname);
    xini=hydr_solver_initiate();
    %plot_wds();

	%% set up problem
	USE_PIVOTING  = 0; 
	SHOW_RESULTS  = 0;
	USER_GRADIENT = 1; % 1: yes, 0: no
	id_pipes_to_optimize={"p1"};
	for i=1:length(id_pipes_to_optimize)
		idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
	end
	idx_pipes=1:1:length(wds.edges.ID);
	
	%OPT_PAR       = 'L'; %D or L 
	%par_vec=linspace(10,1000,10);
	
	OPT_PAR       = 'D'; %D or L 
	par_vec=linspace(0.1,0.5,10);

	for i=1:length(par_vec)
		par=par_vec(i);
		[c(i),g(i)]=cost(par);

		dx=par*0.001;
		c1=cost(par+dx);
		g1(i)=(c1-c(i))/dx;

		fprintf('\n\n %s=%5.3f, gradient: %+5.3e (analytical), %5.3e (numerical), ratio:%5.3f\n\n',...
			OPT_PAR,par,g(i),g1(i),g1(i)/g(i));
	end

	figure(1)
	subplot(2,1,1)
	plot(par_vec,c), ylabel('cost')

	subplot(2,1,2)
	plot(par_vec,g,'r',par_vec,g1,'bo')
	xlabel(OPT_PAR), ylabel('gradient'), legend('analytical','numerical')
end
