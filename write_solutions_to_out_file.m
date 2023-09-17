function write_solutions_to_out_file(fname,xopt,costval,out,t1)
global wds id_pipes_to_optimize
global USE_PIVOTING OPT_PAR USER_GRADIENT OPT_SOLVER
global probname xini

fp=fopen(fname,'w');
fprintf(fp,'\n Network                      : %s',[probname,'.inp']);
fprintf(fp,'\n Parameter to optimize        : %s',OPT_PAR);
fprintf(fp,'\n USE_PIVOTING                 : %g',USE_PIVOTING );
fprintf(fp,'\n USER_GRADIENT                : %g',USER_GRADIENT);
fprintf(fp,'\n OPT_SOLVER                   : %s',OPT_SOLVER);
fprintf(fp,'\n objective value              : %g',costval);
fprintf(fp,'\n CPU time                     : %g',t1);
switch OPT_SOLVER
    case 'fmincon'
        fprintf(fp,'\n funCount                     : %g',out.funcCount);
    case 'ga'
        fprintf(fp,'\n funCount                     : %g',out.funccount);
    otherwise
        OPT_SOLVER
        error('Unknown OPT_SOLVER')
end
fprintf(fp,'\n Optimal values found:');
fprintf(fp,'\n name, value');
for i=1:length(xopt)
    fprintf(fp,'\n %10s, %5.3e',id_pipes_to_optimize{i},xopt(i));
end

switch OPT_PAR
    case 'L'
        for i=1:length(xopt)
            change_length(id_pipes_to_optimize{i},xopt(i));
        end
    case 'D'
        for i=1:length(xopt)
            change_diameter(id_pipes_to_optimize{i},xopt(i));
        end

    otherwise
        OPT_PAR
        error('The value of OPT_PAR must be: D|L !');
end
[Q,p,dp]=hydr_solver(xini);

fprintf(fp,'\n\n edge flow rates:');
for i=1:length(Q)
    fprintf(fp,'\n\t %10s: %6.2f',wds.edges.ID{i},Q(i));
end

fprintf(fp,'\n\n edge pressure drops:');
for i=1:length(Q)
    fprintf(fp,'\n\t %10s: %6.2f  %6.2f  %6.2f',wds.edges.ID{i},dp(i));
end

fprintf(fp,'\n\n node pressures:');
for i=1:length(p)
    fprintf(fp,'\n\t %10s: %6.2f  %6.2f  %6.2f',wds.nodes.ID{i},p(i));
end
fclose(fp);
end