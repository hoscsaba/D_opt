function [out,gradient] = cost(x)
global wds
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize
global OPT_PAR OPT_SOLVER USER_GRADIENT xini
global Aeq beq lb ub

switch OPT_PAR
    case 'L'
        for i=1:length(x)
            change_length(id_pipes_to_optimize{i},x(i));
        end
    case 'D'
        for i=1:length(x)
            change_diameter(id_pipes_to_optimize{i},x(i));
        end

    otherwise
        OPT_PAR
        error('The value of OPT_PAR must be: D|L !');
end

if strcmp(OPT_SOLVER,'ga') && USER_GRADIENT==1
    % Before evaluating, we run a local search
    options = optimoptions(@fmincon,'SpecifyObjectiveGradient',true,'MaxIterations',5);
    [x,costval,exitflag,out]=fmincon(@eval_cost,x,[],[],Aeq,beq,lb,ub,[],options);
    switch OPT_PAR
        case 'L'
            for i=1:length(x)
                change_length(id_pipes_to_optimize{i},x(i));
            end
        case 'D'
            for i=1:length(x)
                change_diameter(id_pipes_to_optimize{i},x(i));
            end
        otherwise
            OPT_PAR
            error('The value of OPT_PAR must be: D|L !');
    end
end
[out,gradient] = eval_cost(x);
end

function [out,gradient] = eval_cost(x)
global wds
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize
global OPT_PAR OPT_SOLVER USER_GRADIENT xini
global Aeq beq lb ub

[Q,p,dp]=hydr_solver(xini);

out1=0;
for i=1:length(x)
    switch OPT_PAR
        case 'L'
            out1=out1+pipe_price(x(i),wds.edges.diameter(idx_pipes_to_optimize(i))/1000);
        case 'D'
            out1=out1+pipe_price(wds.edges.length(idx_pipes_to_optimize(i)),x(i));
        otherwise
            OPT_PAR
            error('The value of OPT_PAR must be: D|L !');
    end
end
power_price=5000;
out2_vec=power_price*Q(idx_pipes).*dp(idx_pipes);
out2=sum(out2_vec);

PMIN=0;
penalty = 1e10*norm(min(0,(p-PMIN)));

out=out1+out2+0.*penalty;

%% USER_GRADIENT is provided based on the article
if nargout>1
    for i=1:length(x)
        idx=idx_pipes_to_optimize(i);
        switch OPT_PAR
            case 'L'
                gr_out1=diff_pipe_price(x(i),wds.edges.diameter(idx_pipes_to_optimize(i))/1000);
                gr_out2=power_price*1/x(i)*Q(idx)*dp(idx);
                gr_penalty=0;
            case 'D'
                gr_out1=diff_pipe_price(wds.edges.length(idx_pipes_to_optimize(i)),x(i));
                gr_out2=power_price*(-5)/x(i)*Q(idx)*dp(idx);
                gr_penalty=0;
            otherwise
                OPT_PAR
                error('The value of OPT_PAR must be: D|L !');
        end
        gradient(i,1)=gr_out1+gr_out2+0.*gr_penalty;
    end
end
end

function out=pipe_price(L,D)
out=500*L*D^2;
end

function out=diff_pipe_price(L,D)
global OPT_PAR
out=0;
switch OPT_PAR
    case 'L'
        out=500*D^2;
    case 'D'
        out=500*L*2*D;
    otherwise
        OPT_PAR
        error('Unknown OPT_PAR value! (valid values L|D)');
end
end
