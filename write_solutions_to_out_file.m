function out = write_solutions_to_out_file(fname,Dopt1,Dopt2,Dopt3)
global wds OPT_PAR id_pipes_to_optimize
global probname 
global costval1 t1 out1
global costval2 t2 out2
global costval3 t3 out3

fp=fopen(fname,'w');
	fprintf(fp,'\n Network                      : %s',[probname,'.inp']);
	fprintf(fp,'\n Parameter                    : %s',OPT_PAR);
	fprintf(fp,'\n (1) fmincon (no grad. info)  : fmin=%5.2e, time: %5.1f s, fun_evals: %g',costval1,t1,out1.funcCount);
	fprintf(fp,'\n (2) fmincon (with grad. info): fmin=%5.2e, time: %5.1f s, fun_evals: %g',costval2,t2,out2.funcCount);
	fprintf(fp,'\n (3) ga                       : fmin=%5.2e, time: %5.1f s, fun_evals: %g\n',costval3,t3,out3.funccount);
	fprintf(fp,'\n Optimal values found:');
	fprintf(fp,'\n name:  fmincon (no grad info), fmincon (grad. info),  ga');
	for i=1:length(Dopt1)
		fprintf(fp,'\n %s: %5.3e, %5.3e, %5.3e',id_pipes_to_optimize{i},Dopt1(i)*1000,Dopt2(i)*1000,Dopt3(i)*1000);
	end

	switch OPT_PAR
		case 'L'
			for i=1:length(Dopt1)
				change_length(id_pipes_to_optimize{i},Dopt1(i));
			end
		case 'D'
			for i=1:length(Dopt1)
				change_diameter(id_pipes_to_optimize{i},Dopt1(i));
			end

		otherwise 
			OPT_PAR
			error('The value of OPT_PAR must be: D|L !');
	end
	[Q1,p1,dp1]=hydr_solver();

		switch OPT_PAR
		case 'L'
			for i=1:length(Dopt2)
				change_length(id_pipes_to_optimize{i},Dopt2(i));
			end
		case 'D'
			for i=1:length(Dopt2)
				change_diameter(id_pipes_to_optimize{i},Dopt2(i));
			end

		otherwise 
			OPT_PAR
			error('The value of OPT_PAR must be: D|L !');
	end
	[Q2,p2,dp2]=hydr_solver();

		switch OPT_PAR
		case 'L'
			for i=1:length(Dopt3)
				change_length(id_pipes_to_optimize{i},Dopt3(i));
			end
		case 'D'
			for i=1:length(Dopt3)
				change_diameter(id_pipes_to_optimize{i},Dopt3(i));
			end

		otherwise 
			OPT_PAR
			error('The value of OPT_PAR must be: D|L !');
	end
	[Q3,p3,dp3]=hydr_solver();


nj=length(wds.nodes.ID);
fprintf(fp,'\n\n edge flow rates:');
	for i=1:length(Q1)
		fprintf(fp,'\n\t %10s: %6.2f  %6.2f  %6.2f',wds.edges.ID{i},Q1(i),Q2(i),Q3(i));
	end

fprintf(fp,'\n\n edge pressure drops:');
	for i=1:length(Q1)
		fprintf(fp,'\n\t %10s: %6.2f  %6.2f  %6.2f',wds.edges.ID{i},dp1(i),dp2(i),dp3(i));
	end

	fprintf(fp,'\n\n node pressures:');
	for i=1:length(p1)
		fprintf(fp,'\n\t %10s: %6.2f  %6.2f  %6.2f',wds.nodes.ID{i},p1(i),p2(i),p3(i));
	end
fclose(fp);
	end