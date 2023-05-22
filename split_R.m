function [Rp,Rs]=split_R(piv_idx)
    global R D wds 
    Rp=[]; Rs=[];
    %R
    %piv_idx
    %wds.edges.ID{piv_idx}
    %pause
    for i=1:length(R(1,:))
        if sum(piv_idx==i)>0 
            Rp=[Rp,R(:,i)];
        else
            Rs=[Rs,R(:,i)];
        end
    end
%    Rs
%    inv(Rs)
%    pause
%    Rsinv_D=inv(Rs)*D;
%    Rsinv_Rp=inv(Rs)*Rp;
end
