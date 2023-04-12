function s=load_epanet(fname,DEBUG_LEVEL)
    if DEBUG_LEVEL>0
        fprintf("Loading EPAnet file %s ...",fname);
    end

    d=readlines(fname);

    node_count=0;
    edge_count=0;
    nj=0; nt=0; nr=0;
    nl=0; np=0; nv=0;

    cl=1;
    while cl<length(d)
        if contains(d{cl},"[JUNCTIONS]")
            if DEBUG_LEVEL>1
                fprintf("\n loading junctions...");
            end
            cl=cl+2;
            while length(d{cl})>0
                nj=nj+1;
                node_count=node_count+1;
                s.nodes.type(node_count)=0;
                s.nodes.type_idx(node_count)=nj;
                [s.nodes.ID{node_count},strrem]=strtok(d{cl});

                [tmp,strrem]=strtok(strrem);
                s.nodes.junction.elevation(nj)=str2num(tmp);

                [tmp,strrem]=strtok(strrem);
                s.nodes.demand(node_count)=str2num(tmp);

                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%3s, elev=%5.0f m, demand=%5.3f m3/h",...
                        nj,s.nodes.ID{node_count},...
                        s.nodes.junction.elevation(nj),s.nodes.demand(node_count));
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[PIPES]")
            if DEBUG_LEVEL>1
                fprintf("\n loading pipes...");
            end
            cl=cl+2;
            while length(d{cl})>0
                nl=nl+1;
                edge_count=edge_count+1;
                s.edges.type(edge_count)=0;
                s.edges.type_idx(edge_count)=nl;
                [s.edges.ID{edge_count},strrem]=strtok(d{cl});
                [s.edges.node_from_ID{edge_count},strrem]=strtok(strrem);
                [s.edges.node_to_ID{edge_count},strrem]  =strtok(strrem);

                [tmp,strrem]=strtok(strrem);
                s.edges.pipe.L(nl)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.edges.pipe.diameter(edge_count)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.edges.pipe.roughness(nl)=str2num(tmp);
                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%3s, nodes: %3s -> %3s, L=%5.0f m, D=%5.1f mm, r=%5.3f",...
                        nl,s.edges.ID{edge_count},...
                        s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                        s.edges.pipe.L(nl),s.edges.pipe.diameter(edge_count),s.edges.pipe.roughness(nl));
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[TANKS]")
            if DEBUG_LEVEL>1
                fprintf("\n loading tanks...");
            end
            cl=cl+2;
            while length(d{cl})>0
                nt=nt+1;
                node_count=node_count+1;
                s.nodes.type(node_count)=1;
                [s.nodes.ID{node_count},strrem]=strtok(d{cl});
                s.nodes.demand(node_count)=0;
                s.nodes.type_idx(node_count)=nt;

                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.elev(nt)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.Hini(nt)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.Hmin(nt)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.Hmax(nt)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.diameter(nt)=str2num(tmp);
                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%3s, elev=%5.3f m, Hini=%5.1f m, Hmin=%5.1f m, Hmax=%5.1f m, dia=%5.1f mm",...
                        nt,s.nodes.ID{node_count},s.nodes.tank.elev(nt),...
                        s.nodes.tank.Hini(nt),s.nodes.tank.Hmin(nt),s.nodes.tank.Hmax(nt),...
                        s.nodes.tank.diameter(nt));
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[RESERVOIRS]")
            if DEBUG_LEVEL>1
                fprintf("\n loading reservoirs...");
            end
            cl=cl+2;
            while length(d{cl})>0
                nr=nr+1;
                node_count=node_count+1;
                s.nodes.type(node_count)=2;
                [s.nodes.ID{node_count},strrem]=strtok(d{cl});
                s.nodes.demand(node_count)=0;
                s.nodes.type_idx(node_count)=nr;

                [tmp,strrem]=strtok(strrem);
                s.nodes.reservoir.H(nr)=str2num(tmp);
                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%3s, H=%5.1f m",...
                        nr,s.nodes.ID{node_count},s.nodes.reservoir.H(nr));
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[PUMPS]")
            if DEBUG_LEVEL>1
                fprintf("\n loading pumps...");
            end
            cl=cl+2;
            while length(d{cl})>0
                np=np+1;
                edge_count=edge_count+1;
                s.edges.type(edge_count)=1;
                s.edges.type_idx(edge_count)=np;
                [s.edges.ID{edge_count},strrem]=strtok(d{cl});
                [s.edges.node_from_ID{edge_count},strrem]=strtok(strrem);
                [s.edges.node_to_ID{edge_count},strrem]  =strtok(strrem);
                s.edges.diameter(edge_count)=1.e-6; % Artificial diameter, all edges must have

                [tmp,strrem]  =strtok(strrem,';');
                [tmp,strrem]  =strtok(tmp);
                s.edges.pump.headcurve_ID{np}=strtrim(strrem);
                if DEBUG_LEVEL>1
                    fprintf("\n\t #%2d: ID=%3s, nodes= %3s -> %3s, headcurve_ID: HEAD %d",...
                        np,s.edges.ID{edge_count},...
                        s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                        s.edges.pump.headcurve_ID{np});
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[VALVES]")
            if DEBUG_LEVEL>1
                fprintf("\n loading valves...");
            end
            cl=cl+2;
            while length(d{cl})>0
                [tmp_ID,strrem]=strtok(d{cl});
                [tmp_node_from_ID,strrem]=strtok(strrem);
                [tmp_node_to_ID,strrem]  =strtok(strrem);
                [tmp,strrem]  =strtok(strrem);
                tmp_diameter=str2num(tmp);
                [tmp_type,strrem]  =strtok(strrem);
                [tmp,strrem]  =strtok(strrem);
                tmp_setting=str2num(tmp);
                if strcmp(tmp_type,'TCV')
                    nv=nv+1;
                    edge_count=edge_count+1;
                    s.edges.type(edge_count)=2; % !!! TCV VALVE
                    s.edges.type_idx(edge_count)=nv;
                    s.edges.ID{edge_count}=tmp_ID;
                    s.edges.node_from_ID{edge_count}=tmp_node_from_ID;
                    s.edges.node_to_ID{edge_count}=tmp_node_to_ID;
                    s.edges.diameter(edge_count)=tmp_diameter;

                    s.edges.valve.type{nv}=tmp_type;
                    s.edges.valve.setting(nv)=tmp_setting;
                    if DEBUG_LEVEL>2
                        fprintf("\n\t #%2d: ID=%s, nodes= %2s -> %2s, diameter: %5.1f mm, type=%s, setting=%g",...
                            nv,s.edges.ID{edge_count},...
                            s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                            s.edges.diameter(edge_count),s.edges.valve.type{nv},...
                            s.edges.valve.setting(nv));
                    end
                elseif strcmp(tmp_type,'PRV')
                    nv=nv+1;
                    edge_count=edge_count+1;
                    s.edges.type(edge_count)=3; % !!! PRV VALVE
                    s.edges.type_idx(edge_count)=nv;
                    s.edges.ID{edge_count}=tmp_ID;
                    s.edges.node_from_ID{edge_count}=tmp_node_from_ID;
                    s.edges.node_to_ID{edge_count}=tmp_node_to_ID;
                    s.edges.diameter(edge_count)=tmp_diameter;

                    s.edges.valve.type{nv}=tmp_type;
                    s.edges.valve.setting(nv)=tmp_setting;
                    if DEBUG_LEVEL>2
                        fprintf("\n\t #%2d: ID=%s, nodes= %2s -> %2s, diameter: %5.1f mm, type=%s, setting=%g",...
                            nv,s.edges.ID{edge_count},...
                            s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                            s.edges.diameter(edge_count),s.edges.valve.type{nv},...
                            s.edges.valve.setting(nv));
                    end
                else
                    warning("VALVE #%d (ID: %s, type=%s) type skipped, only TCV & PRV valves are imported!",nv,tmp_ID,tmp_type);
                end
                cl=cl+1;
            end

        elseif contains(d{cl},"[OPTIONS]")
            if DEBUG_LEVEL>1
                fprintf("\n loading options...");
            end
            cl=cl+1;
            while length(d{cl})>0
                [tmp,rem]=strtok(d{cl});
                if strcmp(tmp,'Units')
                    s.options.Units=strtrim(rem);
                    cl=cl+1;
                elseif strcmp(tmp,'Headloss')
                    s.options.Headloss=strtrim(rem);
                    cl=cl+1;
                else
                    cl=cl+1;
                end
            end

        elseif contains(d{cl},"[CURVES]")
            if DEBUG_LEVEL>1
                fprintf("\n loading curves...");
            end
            cl=cl+1;
            icp=1; c.ID={};
            while length(d{cl})>0
                tmp=d{cl};
                if strcmp(tmp(1),';')==0
                    [tok,rem]=strtok(d{cl}); c.ID{icp}=strtrim(tok);
                    [tok,rem]=strtok(rem);   c.x(icp)=str2num(tok);
                    [tok,rem]=strtok(rem);   c.y(icp)=str2num(tok);
                    icp=icp+1;
                end
                cl=cl+1;
            end

            %% Build the curves
            if length(c.ID)>0
                s.curves.ID=unique(c.ID);
                for ic=1:length(s.curves.ID)
                    s.curves.x{ic}=[];
                    s.curves.y{ic}=[];
                end
                for ic=1:length(c.ID)
                    is_found=0;
                    for jc=1:length(s.curves.ID)
                        %     c.ID(ic)
                        %    s.curves.ID(jc)
                        %   strcmp(s.curves.ID{jc},c.ID{ic})
                        if strcmp(s.curves.ID{jc},c.ID{ic})==1
                            s.curves.x{jc}=[s.curves.x{jc},c.x(ic)];
                            s.curves.y{jc}=[s.curves.y{jc},c.y(ic)];
                            is_found=1;
                            break;
                        end
                    end
                    if is_found==0
                        error('???');
                    end
                end
                %    for i=1:length(s.curves.ID)
                %s.curves.ID{i}
                %s.curves.x{i}
                %s.curves.y{i}
                %    end

                %% Single-point curve: add 133% of shutoff head and double the flow for zero head
                for ic=1:length(s.curves.ID)
                    if length(s.curves.x{ic})==1
                        tmpQ=s.curves.x{ic};
                        tmpH=s.curves.y{ic};
                        Qnom=tmpQ(1);
                        Hnom=tmpH(1);
                        s.curves.x{ic}=[0,         Qnom, 2*Qnom];
                        s.curves.y{ic}=[1.33*Hnom, Hnom, 0];
                    end
                end
            end
            %% End of curve reading
        else
            cl=cl+1;
        end
    end


    if DEBUG_LEVEL>4
        for i=1:length(s.edges.ID)
            fprintf('\n\t edge #%2d: ID: %6s, type: %d, nodes: %5s -> %5s',...
                i,s.edges.ID{i},s.edges.type(i),s.edges.node_from_ID{i},s.edges.node_to_ID{i});
        end
    end

    %% Locate indices of head and tail nodes
    for i=1:length(s.edges.ID)
        head=find_node(s.edges.node_from_ID{i},s.nodes,DEBUG_LEVEL);
        tail=find_node(s.edges.node_to_ID{i},s.nodes,DEBUG_LEVEL);
        s.edges.node_idx{i}=[head tail];
    end

    for i=1:length(s.edges.ID)
        if s.edges.type(i)==0
            s.edges.is_pipe(i)=1;
        else
            s.edges.is_pipe(i)=0;
        end
    end

    %% Add pump curve indices to pump objects
    if np>0 
        for ip=1:length(s.edges.pump.headcurve_ID)
            tmp=find(s.edges.type==1,ip);
            idx_of_ID=tmp(end);
            idx=find(1==strcmp(s.edges.pump.headcurve_ID{ip},s.curves.ID));
            if isempty(idx)
                error('Cannor find pump head curve!!!');
            end
            %fprintf("\n Searching for head curve of pump %s, whose ID is %s -> curve_ID(%d) is %s",...
            %    s.edges.ID{idx_of_ID},s.edges.pump.headcurve_ID{ip},idx,s.curves.ID{idx});
            s.edges.pump.headcurve_idx(ip)=idx;
        end
    end

    %% Unit conversion, see Epanet doc "Units of Measurement" for more details
    % if Units = 'LPS' | 'LPM' | 'MLD'| 'CMH' | 'CMD' -> SI
    % if Units = 'CFS' | 'GPM' | 'MGD' | 'IMGD' | 'AFD'
    unit_system=-1; 
    if sum(strcmp(s.options.Units,{'LPS', 'LPM', 'MLD', 'CMH' , 'CMD'}))>0
        unit_system=0;
    end
    if sum(strcmp(s.options.Units,{'CFS', 'GPM', 'MGD', 'IMGD' , 'AFD'}))>0
        unit_system=1;
    end
    if unit_system<0
        unit_system
        error('Unknown Unit system!');
    end

    if unit_system==0
        %% Convert to m^3/h
        if strcmp(s.options.Units,'LPS'), mul=1/1000*3600; end
        if strcmp(s.options.Units,'LPM'), mul=1/1000*60; end
        if strcmp(s.options.Units,'MLD'), mul=1000*60; end
        if strcmp(s.options.Units,'CMH'), mul=1; end
        if strcmp(s.options.Units,'CMD'), mul=1/24; end

        % standard unit for demand: m3/h
        s.nodes.demand=convert_unit(s.nodes.demand,mul);

        % standard unit for diameter: m
        s.edges.pipe.diameter=convert_unit(s.edges.pipe.diameter,1/1000);

        % standard unit for pump flow rate: m3/h
        if length(c.ID)>0
            for ic=1:length(s.curves.ID)
                s.curves.x{ic}=convert_unit(s.curves.x{ic},mul);
            end
        end
    end

    if unit_system==1
        %% Convert to m^3/h
        ft_to_m=0.3048;
        in_to_m=0.0254;
        gallon_to_m3=0.00378541178;
        imperial_gallon_to_litre=4.54609188;
        ac_foot_to_m3=1233.4818375475;
        if strcmp(s.options.Units,'CFS'), mul=ft_to_m^3*3600; end
        if strcmp(s.options.Units,'GPM'), mul=gallon_to_m3*60; end
        if strcmp(s.options.Units,'MGD'), mul=1e6*galon_to_m3/24; end
        if strcmp(s.options.Units,'IMGD'), mul=imperial_gallon_to_litre/1000/24; end
        if strcmp(s.options.Units,'AFD'), mul=ac_foot_ti_m3/24; end

        % standard unit for demand: m3/h
        s.nodes.demand=convert_unit(s.nodes.demand,mul);

        % standard unit for pump flow rate: m3/h
        % standard unit for pump flow rate: m
        for ic=1:length(s.curves.ID)
            s.curves.x{ic}=convert_unit(s.curves.x{ic},mul);
            s.curves.y{ic}=convert_unit(s.curves.y{ic},ft_to_m);
        end

        % standard unit for pipe diameter: in -> m
        s.edges.pipe.diameter=convert_unit(s.edges.pipe.diameter,in_to_m);

        % standard unit for tank diameter: ft -> m
        if nt>0
            s.nodes.tank.diameter=convert_unit(s.nodes.tank.diameter,in_to_m);
        end

        % standard unit for elevation: ft -> m
        s.nodes.junction.elevation=convert_unit(s.nodes.junction.elevation,in_to_m);
        if nt>0
            s.nodes.tank.elev=convert_unit(s.nodes.tank.elev,in_to_m);
            s.nodes.tank.Hini=convert_unit(s.nodes.tank.Hini,in_to_m);
            s.nodes.tank.Hmin=convert_unit(s.nodes.tank.Hmin,in_to_m);
            s.nodes.tank.Hmax=convert_unit(s.nodes.tank.Hmax,in_to_m);
        end
        if nr>0
            s.nodes.reservoir.H=convert_unit(s.nodes.reservoir.H,in_to_m);
        end

        % standard unit for length: ft -> m
        s.edges.pipe.L=convert_unit(s.edges.pipe.L,ft_to_m);
    end

    s.N_j=nj; % # of junctions
    s.N_t=nt; % # of tanks
    s.N_r=nr; % # of reservoirs 
    s.N_l=nl; % # of links (pipes) 
    s.N_p=np; % # of pumps
    s.N_v=nv; % # of valves
    s.N_e=length(s.edges.ID); % # of edges (nl+np+nv)

    if DEBUG_LEVEL>0
        fprintf('\n\n Summary:');
        fprintf('\n\t EPAnet file     : %s',fname);
        fprintf('\n\t # of junctions  : %d',nj);
        fprintf('\n\t # of tanks      : %d',nt);
        fprintf('\n\t # of reservoirs : %d',nr);
        fprintf('\n\t # of pipes      : %d',nl); % links
        fprintf('\n\t # of pumps      : %d',np);
        fprintf('\n\t # of TCV valves : %d',nv);
        fprintf('\n\t Units           : %s',s.options.Units);
        fprintf('\n\n');
    end
end

function out = find_node(ID,nodes,DEBUG_LEVEL)
    is_found=0;
    if (DEBUG_LEVEL>5)
        fprintf("\n");
    end
    for i=1:length(nodes.ID)
        if (DEBUG_LEVEL>5)
            fprintf("\n\t %3s =? %3s",ID,nodes.ID{i});
        end
        if strcmp(ID,nodes.ID{i})==1
            out=i;
            is_found=1;
            if (DEBUG_LEVEL>5)
                fprintf(" ! ");
            end
            break
        end
    end
    if is_found==0
        error("Node not found! Set DEBUG_LEVEL>3 for detailed info!");
    end
end

function out = convert_unit(vals,mul)
    for i=1:length(vals)
        out(i)=vals(i)*mul;
    end
end
