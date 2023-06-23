function [Rp,Rs]=split_R(piv_idx)
    global R D wds 
    Rp=[]; Rs=[];
    for i=1:length(R(1,:))
        if sum(piv_idx==i)>0 
            Rp=[Rp,R(:,i)];
        else
            Rs=[Rs,R(:,i)];
        end
    end
    n=size(Rs);
    if n(1)~=n(2)
        error('????');
    end
end
