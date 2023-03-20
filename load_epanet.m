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
                s.edges.diameter(edge_count)=1.e-3; % Artificial diameter, all edges must have

                [tmp,strrem]  =strtok(strrem,';');
                [tmp,strrem]  =strtok(tmp);
                s.edges.pump.headcurve_ID(np)=str2num(strrem);
                if DEBUG_LEVEL>1
                    fprintf("\n\t #%2d: ID=%3s, nodes= %3s -> %3s, headcurve_ID: HEAD %s",...
                    np,s.edges.ID{edge_count},...
                    s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                    s.edges.pump.headcurve_ID(np));
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
        head=find_node(s.edges.node_from_ID{i},s.nodes);
        tail=find_node(s.edges.node_to_ID{i},s.nodes);
        s.edges.node_idx{i}=[head tail];
    end

    for i=1:length(s.edges.ID)
        if s.edges.type(i)==0
            s.edges.is_pipe(i)=1;
        else
            s.edges.is_pipe(i)=0;
        end
    end

    if strcmp(s.options.Units,'LPS')
        for i=1:length(s.nodes)
            tmp=s.nodes.demand(i)/1000*3600;
            s.nodes.demand(i)=tmp;
        end
    end

    s.N_j=nj;
    s.N_t=nt;
    s.N_r=nr;
    s.N_l=nl;
    s.N_p=np;
    s.N_v=nv;
    s.N_e=length(s.edges.ID);

    if DEBUG_LEVEL>0
        fprintf('\n\n Summary:');
        fprintf('\n\t EPAnet file     : %s',fname);
        fprintf('\n\t # of junctions  : %d',nj);
        fprintf('\n\t # of tanks      : %d',nt);
        fprintf('\n\t # of reservoirs : %d',nr);
        fprintf('\n\t # of pipes      : %d',nl); % links
        fprintf('\n\t # of pumps      : %d',np);
        fprintf('\n\t # of TCV valves : %d',nv);
        fprintf('\n\n');
    end
end

function out = find_node(ID,nodes)
    is_found=0;
    %fprintf("\n");
    for i=1:length(nodes.ID)
        %fprintf("\n\t %3s =? %3s",ID,nodes.ID{i});
        if strcmp(ID,nodes.ID{i})==1
            out=i;
            is_found=1;
            %fprintf(" ! ");
            break
        end
    end
    if is_found==0
        ID
        error("Node not found!");
    end
end
