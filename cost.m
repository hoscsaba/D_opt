function out = cost(x)
global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize
x
sum(x)
for i=1:length(x)
change_diameter(id_pipes_to_optimize{i},x(i));
end

[Q,p,dp]=hydr_solver(USE_PIVOTING,SHOW_RESULTS);

out1=0;
for i=1:length(x)
    out1=out1+pipe_price(x(i),wds.edges.diameter(idx_pipes_to_optimize(i))/1000);
end
out2=500*dot(abs(Q(idx_pipes)),abs(dp(idx_pipes)));

PMIN=0;
penalty = 1e10*norm(min(0,(p-PMIN)));

out=out1+out2+penalty;
end

function out=pipe_price(L,D)
out=1000*L*D^2;
end