function s=load_epanet(fname)
global DEBUG_LEVEL
if DEBUG_LEVEL>0
    fprintf("Loading EPANET file %s ...",fname);
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
        cl=cl+1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                [node_ID,strrem]=strtok(d{cl});

                node_exists=0;
                if nj>0
                    if ismember(node_ID,s.nodes.ID)==1
                        fprintf('\nNode %s already exists, skipping!',node_ID);
                        node_exists=1;
                    end
                end
                if node_exists==0
                    nj=nj+1;
                    node_count=node_count+1;
                    s.nodes.type(node_count)=0;
                    s.nodes.type_idx(node_count)=nj;
                    s.nodes.X(node_count)=0;
                    s.nodes.Y(node_count)=0;

                    [s.nodes.ID{node_count},strrem]=strtok(d{cl});
                    s.nodes.junction.ID_safe_save{node_count}=s.nodes.ID{node_count};

                    [tmp,strrem]=strtok(strrem);
                    s.nodes.junction.elevation(nj)=str2num(tmp);

                    [tmp,strrem]=strtok(strrem);
                    s.nodes.demand(node_count)=str2num(tmp);

                    [tmp,strrem]=strtok(strrem);
                    if strcmp(tmp,';')==1
                        s.nodes.junction.pattern{node_count}='ones';
                    else
                        s.nodes.junction.pattern{node_count}=tmp;
                    end


                    if DEBUG_LEVEL>2
                        fprintf("\n\t #%2d: ID=%15s, elev=%5.0f m, demand=%5.3f m3/h, pattern: %s",...
                            nj, ...
                            s.nodes.ID{node_count},...
                            s.nodes.junction.elevation(nj), ...
                            s.nodes.demand(node_count), ...
                            s.nodes.junction.pattern{node_count});
                    end
                end

            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[PIPES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading pipes...");
        end
        cl=cl+1;
        while length(d{cl})>0
            if strcmp(d{cl}(1),';')==0
                nl=nl+1;
                edge_count=edge_count+1;
                s.edges.type(edge_count)=0;
                s.edges.type_idx(edge_count)=nl;
                [s.edges.ID{edge_count},strrem]=strtok(d{cl});

                [tmp1,strrem]=strtok(strrem);
                [tmp2,strrem]  =strtok(strrem);
                s.edges.node_from_ID{edge_count}=strtrim(tmp1);
                s.edges.node_to_ID{edge_count}=strtrim(tmp2);


                [tmp,strrem]=strtok(strrem);
                s.edges.length(edge_count)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.edges.diameter(edge_count)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.edges.pipe.roughness(nl)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                s.edges.pipe.minorloss(nl)=str2num(tmp);
                [tmp,strrem]=strtok(strrem);
                % if 1==strcmp(strtrim(tmp),"Closed")
                %     s.edges.pipe.is_closed(nl)=1;
                % else
                %     s.edges.pipe.is_closed(nl)=0;
                % end
                s.edges.pipe.status{nl}=strtrim(tmp);

                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%15s, nodes: %15s -> %15s, " + ...
                        "L=%5.0f m, D=%5.1f mm, r=%5.3f, minorloss=%5.3f, status=%s",...
                        nl,...
                        s.edges.ID{edge_count},...
                        s.edges.node_from_ID{edge_count},...
                        s.edges.node_to_ID{edge_count},...
                        s.edges.length(edge_count),...
                        s.edges.diameter(edge_count),...
                        s.edges.pipe.roughness(nl),...
                        s.edges.pipe.minorloss(nl),...
                        s.edges.pipe.status{nl});
                end
            end
            cl=cl+1;
        end


    elseif contains(d{cl},"[TANKS]")
        %';ID Elevation InitLevel MinLevel MaxLevel Diameter MinVol VolCurve Overflow'
        if DEBUG_LEVEL>1
            fprintf("\n loading tanks...");
        end
        cl=cl+1;
        while length(d{cl})>0

            if strcmp(d{cl}(1),';')==0
                nt=nt+1;
                node_count=node_count+1;
                s.nodes.type(node_count)=1;
                [s.nodes.ID{node_count},strrem]=strtok(d{cl});
                s.nodes.demand(node_count)=0;
                s.nodes.type_idx(node_count)=nt;
                s.nodes.X(node_count)=0;
                    s.nodes.Y(node_count)=0;

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
                [tmp,strrem]=strtok(strrem);
                s.nodes.tank.MinVol(nt)=str2num(tmp);

                [tmp,strrem]=strtok(strrem);
                [tmp1,strrem]=strtok(strrem);

                if isempty(strtrim(tmp)) || strcmp(strtrim(tmp),';')==1
                    s.nodes.tank.VolCurve{nt}='';
                    s.nodes.tank.Overflow{nt}='';
                else
                    s.nodes.tank.VolCurve{nt}=tmp;
                    s.nodes.tank.Overflow{nt}=tmp1(1:end-1);
                end

                % [tmp,strrem]=strtok(strrem);
                % if ~isempty(strtrim(tmp))
                %     s.nodes.tank.Overflow{nt}=tmp;
                % else
                %     s.nodes.tank.Overflow{nt}='';
                % end

                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%15s, elev=%5.3f m, Hini=%5.1f m, " + ...
                        "Hmin=%5.1f m, Hmax=%5.1f m, dia=%5.1f mm, " + ...
                        "MinVol=%5.0f m3, VolCurve: %s, Overflow=%5.3f m",...
                        nt,...
                        s.nodes.ID{node_count},...
                        s.nodes.tank.elev(nt),...
                        s.nodes.tank.Hini(nt),...
                        s.nodes.tank.Hmin(nt),...
                        s.nodes.tank.Hmax(nt),...
                        s.nodes.tank.diameter(nt),...
                        s.nodes.tank.MinVol(nt),...
                        s.nodes.tank.VolCurve{nt},...
                        s.nodes.tank.Overflow(nt));
                end
            end
            cl=cl+1;

        end

    elseif contains(d{cl},"[RESERVOIRS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading reservoirs...");
        end
        cl=cl+1;
        while length(d{cl})>0
            if strcmp(d{cl}(1),';')==0
                nr=nr+1;
                node_count=node_count+1;
                s.nodes.type(node_count)=2;
                [s.nodes.ID{node_count},strrem]=strtok(d{cl});
                s.nodes.demand(node_count)=0;
                s.nodes.type_idx(node_count)=nr;
                s.nodes.X(node_count)=0;
                    s.nodes.Y(node_count)=0;

                [tmp,strrem]=strtok(strrem);
                s.nodes.reservoir.H(nr)=str2num(tmp);

                [tmp,strrem]=strtok(strrem);
                s.nodes.reservoir.pattern{nr}=tmp;
                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%15s, H=%5.1f m, Pattern:%s",...
                        nr,s.nodes.ID{node_count},s.nodes.reservoir.H(nr),...
                        s.nodes.reservoir.pattern{nr});
                end

            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[PUMPS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading pumps...");
        end
        cl=cl+1;
        np=0;
        while length(d{cl})>0
            if strcmp(d{cl}(1),';')==0
                np=np+1;
                edge_count=edge_count+1;
                s.edges.type(edge_count)=1;
                s.edges.type_idx(edge_count)=np;
                [s.edges.ID{edge_count},strrem]=strtok(d{cl});
                [s.edges.node_from_ID{edge_count},strrem]=strtok(strrem);
                [s.edges.node_to_ID{edge_count},strrem]  =strtok(strrem);
                s.edges.diameter(edge_count)=1.e-6; % Artificial diameter, all edges must have
                s.edges.length(edge_count)=1;

                % remove 'HEAD'
                [tmp,strrem]  =strtok(strrem);
                % Get ID
                [tmp1,strrem]  =strtok(strrem);
                strrem=strtrim(strrem);
                % REMOVE SPEED
                [tmp,strrem]  =strtok(strrem);
                % Get ID
                [tmp2,strrem]  =strtok(strrem,';');


                %[tmp,strrem]  =strtok(strrem,';');
                %[tmp,strrem]  =strtok(tmp);
                s.edges.pump.headcurve_ID{np}=strtrim(tmp1);
                s.edges.pump.SPEED(np)=str2num(strtrim(tmp2));
                if DEBUG_LEVEL>2
                    fprintf("\n\t #%2d: ID=%15s, nodes= %15s -> %15s, headcurve_ID: %15s, rel speed: %g",...
                        np,s.edges.ID{edge_count},...
                        s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                        s.edges.pump.headcurve_ID{np}, ...
                        s.edges.pump.SPEED(np));
                end
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[VALVES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading valves...");
        end
        cl=cl+1;
        while length(d{cl})>0
            if strcmp(d{cl}(1),';')==0
                [tmp_ID,strrem]=strtok(d{cl});
                [tmp_node_from_ID,strrem]=strtok(strrem);
                [tmp_node_to_ID,strrem]  =strtok(strrem);
                [tmp,strrem]  =strtok(strrem);
                tmp_diameter=str2num(tmp);
                [tmp_type,strrem]  =strtok(strrem);
                [tmp,strrem]  =strtok(strrem);
                tmp_setting=str2num(tmp);
                [tmp,strrem]  =strtok(strrem);
                tmp_minorloss=str2num(tmp);
                % =======
                %                 [tmp,strrem]  =strtok(strrem,';');
                %                 [tmp,strrem]  =strtok(tmp);
                %                 s.edges.pump.headcurve_ID{np}=strtrim(strrem);
                %                 if DEBUG_LEVEL>2
                %                     fprintf("\n\t #%2d: ID=%15s, nodes= %15s -> %15s, headcurve_ID: HEAD %s",...
                %                         np,s.edges.ID{edge_count},...
                %                         s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                %                         s.edges.pump.headcurve_ID{np});
                %                 end
                %                 cl=cl+1;
                %             end
                % >>>>>>> Stashed changes

                if strcmp(tmp_type,'TCV')
                    nv=nv+1;
                    edge_count=edge_count+1;
                    s.edges.type(edge_count)=2; % !!! TCV VALVE
                    s.edges.type_idx(edge_count)=nv;
                    s.edges.ID{edge_count}=tmp_ID;
                    s.edges.node_from_ID{edge_count}=tmp_node_from_ID;
                    s.edges.node_to_ID{edge_count}=tmp_node_to_ID;
                    s.edges.diameter(edge_count)=tmp_diameter;
                    s.edges.length(edge_count)=1;

                    s.edges.valve.type{nv}=tmp_type;
                    s.edges.valve.setting(nv)=tmp_setting;
                    s.edges.valve.minorloss(nv)=tmp_minorloss;
                    if DEBUG_LEVEL>2
                        fprintf("\n\t #%2d: ID=%15s, nodes= %15s -> %15s, diameter: %5.1f mm, type=%s, setting=%g",...
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
                    s.edges.length(edge_count)=1;

                    s.edges.valve.type{nv}=tmp_type;
                    s.edges.valve.setting(nv)=tmp_setting;
                    s.edges.valve.minorloss(nv)=tmp_minorloss;
                    if DEBUG_LEVEL>2
                        fprintf("\n\t #%2d: ID=%15s, nodes= %15s -> %15s, diameter: %5.1f mm, type=%s, setting=%g",...
                            nv,s.edges.ID{edge_count},...
                            s.edges.node_from_ID{edge_count},s.edges.node_to_ID{edge_count},...
                            s.edges.diameter(edge_count),s.edges.valve.type{nv},...
                            s.edges.valve.setting(nv));
                    end
                else
                    warning("VALVE #%d (ID: %15s, type=%s) type skipped, only TCV & PRV valves are imported!",nv,tmp_ID,tmp_type);
                end
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[OPTIONS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading options...");
        end
        cl=cl+1;

        option_keys={'Units'
            'Headloss'
            'Trials'
            'Accuracy'
            'Emitter exponent'
            'Damplimit'
            'Maxcheck'
            'CHECKFREQ'
            'FLOWCHANGE'
            'HEADERROR'
            'SPECIFIC GRAVITY'
            'VISCOSITY'
            'UNBALANCED CONTINUE'
            'QUALITY'};
        option_found=zeros(1,length(option_keys));

        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0

                str=d{cl};
                line_found=0;
                for iop=1:length(option_keys)
                    pattern = option_keys{iop};
                    matches = regexp(str, pattern, 'ignorecase');

                    if ~isempty(matches)
                        startIdx = matches(1);
                        endIdx = startIdx + length(pattern) - 1;
                        option_val=strtrim(str(endIdx+1:end));
                        s.options.ID{iop}=option_keys{iop};
                        s.options.val{iop}=option_val;
                        option_found(iop)=1;
                        line_found=1;
                        if DEBUG_LEVEL>2
                            fprintf('\nOption %s found -> option_val=%s', ...
                                option_keys{iop},option_val);
                        end
                        if iop==1 % Units
                            s.options.Units=option_val;
                        elseif iop==2
                            s.options.Headloss=option_val;
                        end

                        break
                    end

                end
                if line_found==0
                    fprintf('\n\n %s',str);
                    warning('Unknown option, not stored!');
                end

                cl=cl+1;
            end
        end
        for i=1:length(option_found)
            if option_found(i)==0
                fprintf('\n Option %s not found in data file.', ...
                    option_keys{i});
            end
        end

    elseif contains(d{cl},"[COORDINATES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading coordinates...");
        end
        cl=cl+1;

        ic=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                [tok,rem]=strtok(tmp);
                [tok1,rem]=strtok(rem);
                % Store values
                s.coordinates.ID{ic} = strtrim(tok);
                s.coordinates.X(ic) = str2double(strtrim(tok1));
                s.coordinates.Y(ic) = str2double(strtrim(rem));

                % Add coordinates to nodes.
                
                [found, index] = ismember(s.coordinates.ID{ic} , s.nodes.ID);
                
                if found==1
                    s.nodes.X(index)=s.coordinates.X(ic);
                    s.nodes.Y(index)=s.coordinates.Y(ic);
                    s.nodes.coordinate_found(index)=1;
                    
                else
                    s.nodes.coordinate_found(index)=0;
                    fprintf('\n \t coordinate ID: %s -> NOT FOUND in s.nodes.ID!\n',s.coordinates.ID{ic});
                    pause
                end
                ic=ic+1;
            end
            cl=cl+1;
        end
        %% Is there a node for which no coordinate was found?
        zero_indices = find(s.nodes.coordinate_found == 0);
        if ~isempty(zero_indices)
            warning('No coordinates were found for the following indices:');
            disp(s.nodes.ID{zero_indices});
            pause
        end

    elseif contains(d{cl},"[VERTICES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading vertices...");
        end
        cl=cl+1;

        ic=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                [tok,rem]=strtok(tmp);
                [tok1,rem]=strtok(rem);
                % Store values
                s.vertices.ID{ic} = strtrim(tok);
                s.vertices.X(ic) = str2double(strtrim(tok1));
                s.vertices.Y(ic) = str2double(strtrim(rem));

                ic=ic+1;
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[LABELS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading labels...");
        end
        cl=cl+1;
        il=1;
        s.labels.line={};
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                s.labels.line{il} = d{cl};
                il=il+1;
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[CONTROLS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading controls...");
        end
        cl=cl+1;
        ic=1;
        s.controls.line={};
        while ~isempty(d{cl})
            if  contains(d{cl},'[')==1
                break;
            else
                if strcmp(d{cl}(1),';')==0
                    % 1 sor, utána üres sor
                    s.controls.line{ic} = d{cl};
                    ic=ic+1;
                    cl=cl+2;
                end
            end
        end

    elseif contains(d{cl},"[RULES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading rules...");
        end
        cl=cl+1;
        ir=1;
        s.rules.line={};
        while ~isempty(d{cl})
            if  contains(d{cl},'[')==1
                break;
            else
                if strcmp(d{cl}(1),';')==0
                    % 2 soronként, utána üres sor
                    for jj=1:3
                        s.rules.line{ir} = d{cl};
                        ir=ir+1;
                        cl=cl+1;
                    end
                end
                cl=cl+1;
            end
        end

    elseif contains(d{cl},"[ENERGY]")
        if DEBUG_LEVEL>1
            fprintf("\n loading energies...");
        end
        cl=cl+1;
        el=1;
        s.energy.line={};
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                s.energy.line{el} = d{cl};
                el=el+1;
            end
            cl=cl+1;

        end

    elseif contains(d{cl},"[BACKDROP]")
        if DEBUG_LEVEL>1
            fprintf("\n loading backdrop...");
        end
        cl=cl+1;
        il=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                s.backdrop.line{il} = d{cl};
                il=il+1;
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[PATTERNS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading patterns...");
        end
        cl=cl+1;
        np=1;
        s.patterns.ID{np}='ones';
        s.patterns.data{np}=ones(96,1);
        s.patterns.is_used(np)=0;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                % read all lines NOT starting with ;
                if strcmp(tmp(1),';')==0
                    [tmp,rem]=strtok(strtrim(tmp));
                    tmp_p.ID{np}=tmp;
                    tmp_p.data{np}=rem;
                    tmp_p.is_used(np)=0;
                end
                np=np+1;
            end
            cl=cl+1;

        end

        for i=1:length(tmp_p.ID)
            is_added=0;
            for j=1:length(s.patterns.ID)
                if strcmp(tmp_p.ID{i},s.patterns.ID{j})==1
                    is_added=1;
                end
            end

            if is_added==1
                % Add data set only
                %if DEBUG_LEVEL>2
                %fprintf('\nPattern %salready added, expanding data set...',tmp_p.ID{i});
                %end
                rem=tmp_p.data{i};
                while ~isempty(rem)
                    [tmp,rem]=strtok(strtrim(rem));
                    s.patterns.data{j}=[s.patterns.data{j} str2double(tmp)];
                end
            else
                % Add new pattern and data set
                if DEBUG_LEVEL>2
                    fprintf('\n\tPattern %s is missing, creating new entry...',tmp_p.ID{i});
                end
                new_idx=length(s.patterns.ID)+1;
                s.patterns.ID{new_idx}=tmp_p.ID{i};
                s.patterns.data{new_idx}=[];
                s.patterns.is_used(new_idx)=0;

                % Add data set
                rem=tmp_p.data{i};
                while ~isempty(rem)
                    [tmp,rem]=strtok(strtrim(rem));
                    s.patterns.data{new_idx}=[s.patterns.data{new_idx} str2double(tmp)];
                end
            end
        end
    elseif contains(d{cl},"[STATUS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading status...");
        end
        cl=cl+1;
        ns=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                [tmp,rem]=strtok(d{cl});
                s.status.ID{ns}=strtrim(tmp);
                s.status.status{ns}=strtrim(rem);
                ns=ns+1;
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[DEMANDS]")
        if DEBUG_LEVEL>1
            fprintf("\n loading demands...");
        end
        cl=cl+1;
        ns=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                [tmp,rem]  =strtok(d{cl});
                [tmp1,rem1]=strtok(rem);
                [tmp2,rem2]=strtok(rem1);
                s.demands.ID{ns}=strtrim(tmp);
                s.demands.demand(ns)=str2double(strtrim(tmp1));
                s.demands.pattern{ns}=strtrim(tmp2);
                if isempty(s.demands.pattern{ns})
                    fprintf('\n\t Pattern missing for demand: %s',s.demands.ID{ns});
                end
                ns=ns+1;
            end
            cl=cl+1;
        end



    elseif contains(d{cl},"[CURVES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading curves...");
        end
        cl=cl+1;
        icp=1; ict=1; c.ID={};
        while length(d{cl})>0
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                % if strcmp(tmp(1),';')==0
                [c.ID{icp},c.x(icp),c.y(icp)]=gel_curve_line(d{cl});
                if DEBUG_LEVEL>4
                    fprintf("\n\t #%2d: ID=%15s, x= %g y=%g",...
                        icp,c.ID{icp},c.x(icp),c.y(icp));
                end
                icp=icp+1;
                %else
                %    curve_types{ict}=tmp(2:end);
                %    ict=ict+1;
                %end

            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[TIMES]")
        if DEBUG_LEVEL>1
            fprintf("\n loading times...");
        end
        cl=cl+1;
        it=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                [tok,rem]=strtok(tmp);
                s.times.ID{it}=strtrim(tok);
                s.times.val{it}=strtrim(rem);
                it=it+1;
            end
            cl=cl+1;
        end

    elseif contains(d{cl},"[REPORT]")
        if DEBUG_LEVEL>1
            fprintf("\n loading report...");
        end
        cl=cl+1;
        it=1;
        while ~isempty(d{cl})
            if strcmp(d{cl}(1),';')==0
                tmp=d{cl};
                [tok,rem]=strtok(tmp);
                s.report.ID{it}=strtrim(tok);
                s.report.val{it}=strtrim(rem);
                it=it+1;
            end
            cl=cl+1;
        end

    else
        cl=cl+1;
    end
end


if DEBUG_LEVEL>1
    fprintf("\n building curves...");
end
%% Build the curves
if length(c.ID)>0
    s.curves.ID=unique(c.ID);
    %            s.curves.curve_type=curve_types;
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
    if DEBUG_LEVEL>2
        for i=1:length(s.curves.ID)
            fprintf('\n\t curve #%2d: %15s, number of data pairs: %d',...
                i,s.curves.ID{i}, length(s.curves.x{i}));
        end
    end



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

if DEBUG_LEVEL>4
    for i=1:length(s.edges.ID)
        fprintf('\n\t edge #%2d: ID: %6s, type: %d, nodes: %5s -> %5s',...
            i,s.edges.ID{i},s.edges.type(i),s.edges.node_from_ID{i},s.edges.node_to_ID{i});
    end
end


%% Add pump curve indices to pump objects
if DEBUG_LEVEL>1
    fprintf("\n adding curves to pumps...");
end
if np>0
    for ip=1:length(s.edges.pump.headcurve_ID)
        tmp=find(s.edges.type==1,ip);
        idx_of_ID=tmp(end);
        idx=find(1==strcmp(s.edges.pump.headcurve_ID{ip},s.curves.ID));
        if isempty(idx)
            fprintf('\n\nCannot find pump head curve: %s of pump %s\n\n', ...
                s.edges.pump.headcurve_ID{ip},s.edges.ID{idx_of_ID});
            error('Exiting');
        end
        if DEBUG_LEVEL>2
            fprintf("\n Head curve of pump %s: curve ID %s -> found curve_ID(%d): %s",...
                s.edges.ID{idx_of_ID},s.edges.pump.headcurve_ID{ip},idx,s.curves.ID{idx});
        end
        s.edges.pump.headcurve_idx(ip)=idx;
    end
end


%% Unit conversion, see Epanet doc "Units of Measurement" for more details
% if Units = 'LPS' | 'LPM' | 'MLD'| 'CMH' | 'CMD' -> SI
% if Units = 'CFS' | 'GPM' | 'MGD' | 'IMGD' | 'AFD'
DO_CONVERT_UNITS=0;

if DO_CONVERT_UNITS==1
    if DEBUG_LEVEL>1
        fprintf("\n converting units ...");
    end
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
        s.edges.diameter=convert_unit(s.edges.diameter,1/1000);

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
        s.edges.diameter=convert_unit(s.edges.diameter,in_to_m);
        % standard unit for length: ft -> m
        s.edges.length=convert_unit(s.edges.length,ft_to_m);

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
    end
end


%%!!!!!!!!!!!!!!!!!!!!!!!!
DO_COMPUTE_NODE_RANKS=1;

if DO_COMPUTE_NODE_RANKS==1

    if DEBUG_LEVEL>0
        fprintf('\n computing node ranks & deleting orphan nodes...');
    end

    % Compute node ranks & remove orphan junctions (nodes)
    node_count=1;
    num_of_nodes_orig=length(s.nodes.ID);
    i=1;

    while i<length(s.nodes.ID)+1 % length(s.nodes.ID) changes!!!                
        node_to_remove = s.nodes.ID{i};

        s.nodes.rank(i)=0;
        idx = find(strcmp(s.nodes.ID{i},s.edges.node_from_ID),1);
        if ~isempty(idx)

            s.nodes.rank(i)=s.nodes.rank(i)+1;
        end
        idx = find(strcmp(s.nodes.ID{i},s.edges.node_to_ID),1);
        if ~isempty(idx)
            s.nodes.rank(i)=s.nodes.rank(i)+1;
        end


        is_type_node=0;
        if s.nodes.rank(i)==0 && s.nodes.type(i)==0
            % DELETE THIS NODE

            is_type_node=1;

            fprintf('\n\t %3.0f%% - node %s (#%d) rank=%d, deleting... (total: %d/%d nodes)', ...
                round(i)/length(s.nodes.ID)*100, ...
                s.nodes.ID{i}, ...
                i,...
                s.nodes.rank(i), ...
                length(s.nodes.ID), ...
                num_of_nodes_orig);

            s.nodes.type=remove_element_d(s.nodes.type,i);
            s.nodes.type_idx=remove_element_d(s.nodes.type_idx,i);
            s.nodes.ID=remove_element_s(s.nodes.ID,i);
            s.nodes.demand=remove_element_d(s.nodes.demand,i);
            %s.nodes.junction.elevation(1:5)
            s.nodes.junction.elevation=remove_element_d(s.nodes.junction.elevation,node_count);
            %s.nodes.junction.elevation(1:5)
            %pause
            s.nodes.junction.pattern=remove_element_s(s.nodes.junction.pattern,node_count);
            % s.node.junction.pattern_index ?
            s.nodes.junction.ID_safe_save=remove_element_d(s.nodes.junction.ID_safe_save,node_count);

            % At this points, s.nodes.ID{i} is the next node ID!!! Use node_to_remove

            %% Remove demand
            idx = find(strcmp(node_to_remove,s.demands.ID));
            if ~isempty(idx)
                fprintf('\n\t deleting demand %s',node_to_remove);
                s.demands.ID=remove_element_s(s.demands.ID,idx);
                s.demands.demand=remove_element_d(s.demands.demand,idx);
                s.demands.pattern=remove_element_s(s.demands.pattern,idx);
            else
                fprintf('\n\t Unable to delete demand %s (not found.)',node_to_remove);
            end

            %% Remove coordinate
            idx = find(strcmp(node_to_remove,s.coordinates.ID));
            if ~isempty(idx)
                fprintf('\n\t deleting coordinate %s',node_to_remove);
                s.coordinates.ID=remove_element_s(s.coordinates.ID,idx);
                s.coordinates.X=remove_element_d(s.coordinates.X,idx);
                s.coordinates.Y=remove_element_d(s.coordinates.Y,idx);
            else
                fprintf('\n\t Unable to delete coordinate %s (not found.)',node_to_remove);
            end
            

        else
            % DO NOT DELETE THIS NODE: EITHER NOT A NODE OR RANK>0
            if DEBUG_LEVEL>2
                fprintf('\n %3.0f%% - node %s (#%d) rank=%d', ...
                    round(i)/length(s.nodes.ID)*100, ...
                    s.nodes.ID{i}, ...
                    i,...
                    s.nodes.rank(i));
            end
            i=i+1;
            if is_type_node==0
                node_count=node_count+1;
            end
        end
        %fprintf('\n i=%d, node_count=%d, length(s.nodes.ID)=%d',i,node_count,length(s.nodes.ID));
        %pause
    end
    fprintf('\n\t deleted %d of %d junctions (%g%%)\n', ...
        num_of_nodes_orig-length(s.nodes.ID),num_of_nodes_orig,(1-length(s.nodes.ID)/num_of_nodes_orig)*100);

    % Mark the edges connected to rank-1 nodes
    for i=1:length(s.edges.ID)
        node_from_idx=find_node(s.edges.node_from_ID{i},s.nodes,0);
        node_to_idx  =find_node(s.edges.node_to_ID{i},s.nodes,0);
        if (s.nodes.rank(node_from_idx)==1) || (s.nodes.rank(node_to_idx)==1)
            s.edges.is_endedge(i)=1;
            if DEBUG_LEVEL>2
                fprintf("\n\t edge %15s is connected to a node with rank 1 (no further edges).",s.edges.ID{i});
            end
        else
            s.edges.is_endedge(i)=0;
        end
    end

    if DEBUG_LEVEL>0
        fprintf(' done.');
    end
end


if DEBUG_LEVEL>1
    fprintf("\n building system, locating head and tail nodes for edges...");
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




%% CHECK MISSING & UNUSED PATTERNS AMONG NODES
n_n=1;
for i=1:length(s.nodes.ID)
    if s.nodes.type(i)==0
        if ~isempty(s.nodes.junction.pattern{n_n})
            tmp1=s.nodes.junction.pattern{n_n};
            is_found=0;
            %fprintf('\n\n\t node %3d: %15s pattern: %s searching....',...
            %        i,s.nodes.ID{i},s.nodes.junction.pattern{i});
            for j=1:length(s.patterns.ID)
                tmp2=s.patterns.ID{j};
                if strcmp(tmp1,tmp2)==1
                    is_found=1;
                    s.nodes.junction.pattern_idx(n_n)=j;
                    s.patterns.is_used(j)=1;
                    %       fprintf(" found, pattern_idx=%g.",j);
                end
            end
            if is_found==0
                fprintf('\n\n\t node #%3d: ID %15s, pattern: %s searching....',...
                    i,s.nodes.ID{i},s.nodes.junction.pattern{n_n});
                fprintf("\n\t ERROR: pattern >>%s<< not found!!!\n\n",tmp1);
            end
        else
            s.nodes.junction.pattern_idx(n_n)=1;
        end
        n_n=n_n+1;
    end
end

% CHECK MISSING & UNUSED PATTERNS AMONG DEMANDS
n_n=1;
for i=1:length(s.demands.ID)

    if ~isempty(s.demands.pattern{n_n})
        tmp1=s.demands.pattern{n_n};
        is_found=0;
        % fprintf('\n\n\t demand %3d: %15s pattern: %s searching....',...
        %         i,s.demands.ID{i},s.demands.pattern{i});
        for j=1:length(s.patterns.ID)
            tmp2=s.patterns.ID{j};
            if strcmp(tmp1,tmp2)==1
                is_found=1;
                s.patterns.is_used(j)=1;
                %s.nodes.junction.pattern_idx(n_n)=j;
                %     fprintf(" found, pattern_idx=%g.",j);
            end
        end
        if is_found==0
            fprintf('\n\n\t demand #%3d: ID %15s, pattern: %s searching....',...
                i,s.demands.ID{i},s.demands.pattern{n_n});
            fprintf("\n\t ERROR: pattern %s not found!!!\n\n",tmp1);
            %pause
        end
    else
        %  s.nodes.junction.pattern_idx(n_n)=1;
    end
    n_n=n_n+1;

end

%%---------------

s.N_j=length(s.nodes.ID); % # of junctions
s.N_t=length(s.nodes.tank.elev); % # of tanks
s.N_r=length(s.nodes.reservoir.H); % # of reservoirs
s.N_l=length(s.edges.pipe.roughness); % # of links (pipes)
s.N_p=length(s.edges.pump.headcurve_ID); % # of pumps
s.N_v=length(s.edges.valve.type); % # of valves
s.N_e=length(s.edges.ID); % # of edges (pipe+pump+valve)

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
        fprintf("\n\t %15s =? %15s",ID,nodes.ID{i});
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
    fprintf("\n\n node ID: %15s not found",ID);
    error("Error, exiting");
end
end

function out = convert_unit(vals,mul)
for i=1:length(vals)
    out(i)=vals(i)*mul;
end
end

function [out1,tmp_x,tmp_y]=gel_curve_line(d)
[tok,rem]=strtok(d); out1=strtrim(tok);
[tok,rem]=strtok(rem);   tmp_x=str2num(tok);
[tok,rem]=strtok(rem);   tmp_y=str2num(tok);
end

function x=remove_element_d(x,i)
x=[x(1:i-1),x(i+1:end)];
end

function x=remove_element_s(x,i)
x={x{1:i-1},x{i+1:end}};
end