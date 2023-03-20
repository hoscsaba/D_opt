function D_opt_driver
    clear all, close all, clc
    global D is_pipe K dh cons_base

    dh=30;
    D=ones(1,8)*0.05; 
    cons_base=1.5;
    is_pipe=[0 1 1 1 1 1 1 1];

    which_pipe=3;
    Dvec=linspace(0.001,0.2,1000); dx=max(diff(Dvec));
    for i=1:length(Dvec)
        D(which_pipe)=Dvec(i);
        [Q,p,dp]=hidr_solver();

        data(i,1)=D(which_pipe);
        data(i,2)=sum(is_pipe.*Q/3600.*dp*9.81*1000);
        if i==1
            data(i,3)=0;
            data(i,4)=0;
        else
            data(i,3)=(data(i,2)-data(i-1,2))/dx;
            %data(i,4)=-5*K(which_pipe)/Dvec(i)^6*Q(which_pipe)/3600;
            %dQdD=(Q(which_pipe)-Qprev(which_pipe))/dx/3600;
            dQ2dD=(Q(2)-Qprev(2))/dx/3600;
            data(i,4)=-5*dp(which_pipe)*1000*9.81*Q(which_pipe)/3600/Dvec(i)...
                +dQ2dD*(-dh)*1000*9.81*3 ...
                -dQ2dD*dp(1)*1000*9.81*3;
        end
        Qprev=Q;
    end
    sumP=sum(dp.*Q);
    fprintf('\n\n Results: sumP=%5.3e\n',sumP);
    for i=1:length(Dvec)
        fprintf('\n\t D%d=%5.2f m, Ploss=%5.3f W ; der: %5.3f <-> %5.3f, %5.3f',which_pipe,data(i,1),data(i,2),data(i,3),data(i,4),data(i,4)/data(i,3));
    end
    figure(1)
    subplot(2,1,1)
    plot(data(:,1),data(:,2))
    xlabel(['D_',num2str(which_pipe),', m'])
    ylabel('P_{loss}, W')

    subplot(2,1,2)
    plot(data(2:end,1),data(2:end,3),'r',data(2:end,1),data(2:end,4),'k--')
    xlabel(['D_',num2str(which_pipe),', m'])
    ylabel('d Ploss/d D');
    xlim([min(Dvec),max(Dvec)]);
    %ylim([-2000 0]);
end
