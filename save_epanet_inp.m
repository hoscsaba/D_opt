function save_epanet_inp(outfile,wds)

fprintf("\n\nSaving EPAnet file %s ...",outfile);

fp=fopen(outfile,'w');
fclose(fp);


% [TITLE]
write_title(outfile)
% [JUNCTIONS]
write_junctions(outfile,wds)
% [RESERVOIRS]
write_reservoirs(outfile,wds)
% [TANKS]
write_tanks(outfile,wds);
% [PIPES]
write_pipes(outfile,wds);
% [PUMPS]
write_pumps(outfile,wds);
% [VALVES]
write_valves(outfile,wds);
% [TAGS]
write_tags(outfile,wds);
%[DEMANDS]
write_demands(outfile,wds);
%[STATUS]
write_status(outfile,wds);
% [PATTERNS]
data_per_line=6;
write_patterns(outfile,wds,data_per_line,1);
% [CURVES]
write_curves(outfile,wds);
% [CONTROLS]
write_controls(outfile,wds);
% [RULES]
write_rules(outfile,wds);
% [ENERGY]
%write_energy(outfile,wds);
% [EMITTERS]
write_emitters(outfile,wds);
% [QUALITY]
write_quality(outfile,wds);
% [SOURCES]
write_sources(outfile,wds);
% [REACTIONS]
write_reactions(outfile,wds);
% [MIXING]
write_mixing(outfile,wds);
% [TIMES]
write_times(outfile,wds);
% [REPORT]
write_report(outfile,wds);
% [OPTIONS]
write_options(outfile,wds);
% [COORDINATES]
write_coordinates(outfile,wds);
% [VERTICES]
write_vertices(outfile,wds);
% [LABELS]
write_labels(outfile,wds);
% [BACKDROP]
write_backdrop(outfile,wds);
% [END]
write_end(outfile)

fprintf(" done.\n");

end

function write_title(outfile)
fp=fopen(outfile,'a');
fprintf(fp,'[TITLE]\n');
fprintf(fp,'Scenario: sample\n');
fprintf(fp,'Date: %s\n',datetime("now"));
fclose(fp);
end

function write_junctions(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[JUNCTIONS]\n');
fprintf(fp,';ID              	Elev        	Demand      	Pattern         ');
nj=1;
for i=1:length(wds.nodes.type)
    if wds.nodes.type(i)==0
        fprintf(fp,'\n %15s\t %6.2f\t %5.3e\t%15s\t;',...
            wds.nodes.ID{i}, ...
            wds.nodes.junction.elevation(nj), ...
            wds.nodes.demand(i),...
            wds.nodes.junction.pattern{nj});

        %if length(wds.nodes.junction.pattern{nj})>1
        %    fprintf(fp,';');
        %end
        nj=nj+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_reservoirs(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[RESERVOIRS]\n');
fprintf(fp,';ID              	Head        	Pattern  ');
nr=1;
for i=1:length(wds.nodes.type)
    if wds.nodes.type(i)==2
        fprintf(fp,'\n %15s\t %6.2f\t %15s',...
            wds.nodes.ID{i}, ...
            wds.nodes.reservoir.H(nr),...
            wds.nodes.reservoir.pattern{nr});

        if length(wds.nodes.reservoir.pattern{nr})>1
            fprintf(fp,';');
        end
        nr=nr+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_tanks(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[TANKS]');
fprintf(fp,'\n;ID\t Elevation\t InitLevel\t MinLevel\t MaxLevel\t Diameter\t MinVol\t VolCurve\t Overflow');
nt=1;
for i=1:length(wds.nodes.type)
    if wds.nodes.type(i)==1
        %wds.nodes.tank
        %pause
        fprintf(fp,"\n %15s\t %5.3f\t %5.1f\t %5.1f\t %5.1f\t %5.1f\t %g\t %15s\t %5.1f;",...
            wds.nodes.ID{i}, ...
            wds.nodes.tank.elev(nt),...
            wds.nodes.tank.Hini(nt),...
            wds.nodes.tank.Hmin(nt),...
            wds.nodes.tank.Hmax(nt),...
            wds.nodes.tank.diameter(nt), ...
            wds.nodes.tank.MinVol(nt), ...
            wds.nodes.tank.VolCurve{nt},...
            wds.nodes.tank.Overflow(nt));
        nt=nt+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_pipes(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[PIPES]\n');

fprintf(fp,';ID              	Node1           	Node2           	Length      	Diameter    	Roughness   	MinorLoss   	Status');
nl=1;
for i=1:length(wds.edges.ID)
    if wds.edges.type(i)==0

        fprintf(fp,"\n%15s\t %15s\t %15s\t %5.1e\t %5.1e\t %5.3e\t %5.3e\t %s ;",...
            wds.edges.ID{i},...
            wds.edges.node_from_ID{i},...
            wds.edges.node_to_ID{i},...
            wds.edges.length(i),...
            wds.edges.diameter(i),...
            wds.edges.pipe.roughness(nl),...
            wds.edges.pipe.minorloss(nl),...
            wds.edges.pipe.status{nl});
        nl=nl+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_pumps(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[PUMPS]\n');

fprintf(fp,';ID              	Node1           	Node2           	Parameters');
np=1;
for i=1:length(wds.edges.ID)
    if wds.edges.type(i)==1
        fprintf(fp,"\n%15s\t %15s\t %15s\t HEAD %15s\t SPEED %g;",...
            wds.edges.ID{i},...
            wds.edges.node_from_ID{i},...
            wds.edges.node_to_ID{i},...
            wds.edges.pump.headcurve_ID{np}, ...
            wds.edges.pump.SPEED(np));
        np=np+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_valves(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[VALVES]\n');

fprintf(fp,';ID              	Node1           	Node2           	Diameter    	Type	Setting     	MinorLoss   ');
nv=1;
for i=1:length(wds.edges.ID)
    if wds.edges.type(i)==2 || wds.edges.type(i)==3
        fprintf(fp,"\n%15s\t %15s\t %15s\t %5.1f\t %s\t %g\t %g\t %g;",...
            wds.edges.ID{i},...
            wds.edges.node_from_ID{i},...
            wds.edges.node_to_ID{i},...
            wds.edges.diameter(i),...
            wds.edges.valve.type{nv},...
            wds.edges.valve.setting(nv),...
            wds.edges.valve.minorloss(nv));
        nv=nv+1;
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_status(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[STATUS]\n');

fprintf(fp,';ID        Status/Setting');
ns=1;
for i=1:length(wds.status.ID)
    fprintf(fp,"\n%15s\t %15s",wds.status.ID{ns},wds.status.status{ns});
    ns=ns+1;
end
fprintf(fp,'\n');
fclose(fp);
end

function write_patterns(outfile,wds,data_per_lines,write_only_used)

fp=fopen(outfile,'a');
fprintf(fp,'\n[PATTERNS]\n');

fprintf(fp,';ID              	Multipliers');
for i=1:length(wds.patterns.ID)
    if write_only_used==1
        if wds.patterns.is_used(i)==1
            write_this_demand(fp,wds.patterns.ID{i},wds.patterns.data{i},data_per_lines);
        end
    else
        write_this_demand(fp,wds.patterns.ID{i},wds.patterns.data{i},data_per_lines);
    end

end
fprintf(fp,'\n');
fclose(fp);
end

function write_this_demand(fp,ID,data,data_per_lines)
tmp=data;
j=1;
fprintf(fp,"\n;");
% cycle through full lines
for k=1:floor(length(tmp)/data_per_lines)
    fprintf(fp,"\n%15s\t",ID);
    for ll=1:data_per_lines
        fprintf(fp,"%5.3f\t",tmp(j));
        j=j+1;
    end
end

% reminder number of data
if rem(length(tmp),data_per_lines)>0
    fprintf(fp,"\n%15s",ID);

    for ll=1:rem(length(tmp),data_per_lines)
        fprintf(fp,"%5.3f",tmp(j));
        j=j+1;
    end
end
end

function write_tags(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[TAGS]');
fprintf(fp,'\n');

fclose(fp);
end

function write_controls(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[CONTROLS]');
for i=1:length(wds.controls.line)
    fprintf(fp,"\n%s\n",wds.controls.line{i});
end
fprintf(fp,'\n');
fclose(fp);
end

function write_rules(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[RULES]');
il=0;
for i=1:length(wds.rules.line)
    fprintf(fp,"\n%s \t %s",wds.rules.line{i});
    il=il+1;
    if il==3
        fprintf(fp,"\n");
        il=0;
    end

end
fprintf(fp,'\n');
fclose(fp);
end

function write_mixing(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[MIXING]');
fprintf(fp,'\n;Tank            	Model\n');
fprintf(fp,'\n');
fclose(fp);
end

function write_emitters(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[EMITTERS]');
fprintf(fp,'\n;Junction        	Coefficient');
fprintf(fp,'\n');
fclose(fp);
end

function write_quality(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[QUALITY]');
fprintf(fp,'\n;Node            	InitQual');
fprintf(fp,'\n');
fclose(fp);
end

function write_sources(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[SOURCES]');
fprintf(fp,'\n;Node            	Type        	Quality     	Pattern');
fprintf(fp,'\n');
fclose(fp);
end

function write_reactions(outfile,wds)
fp=fopen(outfile,'a');
fprintf(fp,'\n[REACTIONS]');
fprintf(fp,'\n;Type     	Pipe/Tank       	Coefficient\n\n');
fprintf(fp,'\n[REACTIONS]');
fprintf(fp,'\nOrder Bulk            	1');
fprintf(fp,'\nOrder Tank            	1');
fprintf(fp,'\nOrder Wall            	1');
fprintf(fp,'\nGlobal Bulk           	0');
fprintf(fp,'\nGlobal Wall           	0');
fprintf(fp,'\nLimiting Potential    	0');
fprintf(fp,'\nRoughness Correlation 	0\n');

fprintf(fp,'\n[MIXING]');
fprintf(fp,'\n;Tank            	Model');
fprintf(fp,'\n');
fclose(fp);
end

function write_demands(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[DEMANDS]\n');

fprintf(fp,';Junction        	Demand      	Pattern         	Category');
for i=1:length(wds.demands.ID)
    fprintf(fp,"\n%15s\t%g\t%15s   ;",...
        wds.demands.ID{i},...
        wds.demands.demand(i),...
        wds.demands.pattern{i});
end
fprintf(fp,'\n');
fclose(fp);
end

function write_curves(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[CURVES]');

fprintf(fp,'\n;ID              	X-Value     	Y-Value');
for i=1:length(wds.curves.ID)
    %    fprintf(fp,"\n;%s",wds.curves.curve_type{i});
    for j=1:length(wds.curves.x{i})
        fprintf(fp,"\n%15s\t%g\t%g",...
            wds.curves.ID{i},...
            wds.curves.x{i}(j),...
            wds.curves.y{i}(j));
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_times(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[TIMES]');

for i=1:length(wds.times.ID)
    fprintf(fp,"\n%s\t%s",wds.times.ID{i},wds.times.val{i});
end
fprintf(fp,'\n');
fclose(fp);
end

function write_report(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[REPORT]');
if isfield(wds,'report')
    for i=1:length(wds.report.ID)
        fprintf(fp,"\n%s \t %s",wds.report.ID{i},wds.report.val{i});
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_options(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[OPTIONS]');

for i=1:length(wds.options.ID)
    fprintf(fp,"\n%s \t %s",wds.options.ID{i},wds.options.val{i});
end
fprintf(fp,'\n');
fclose(fp);
end

function write_coordinates(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[COORDINATES]');
fprintf(fp,'\n;Node            	X-Coord           	Y-Coord');

for i=1:length(wds.coordinates.ID)
    fprintf(fp,"\n%15s\t%10.3f\t %10.3f",...
        wds.coordinates.ID{i},...
        wds.coordinates.X(i),...
        wds.coordinates.Y(i));
end
fprintf(fp,'\n');
fclose(fp);
end

function write_vertices(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[VERTICES]');
fprintf(fp,'\n;Link            	X-Coord           	Y-Coord');

for i=1:length(wds.vertices.ID)
    fprintf(fp,"\n%15s\t%10.3f\t %10.3f",...
        wds.vertices.ID{i},...
        wds.vertices.X(i),...
        wds.vertices.Y(i));
end
fprintf(fp,'\n');
fclose(fp);
end

function write_labels(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[LABELS]');
fprintf(fp,'\n;X-Coord             Y-Coord             Label & Anchor Node');

if isfield(wds,'labels')
    for i=1:length(wds.labels.line)
        fprintf(fp,"\n%s",wds.labels.line{i});
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_energy(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[ENERGY]');

for i=1:length(wds.energy.line)
    fprintf(fp,"\n%s",wds.energy.line{i});
end

fprintf(fp,'\n');
fclose(fp);
end


function write_backdrop(outfile,wds)

fp=fopen(outfile,'a');
fprintf(fp,'\n[BACKDROP]');
if isfield(wds,'backdrop')
    for i=1:length(wds.backdrop.line)
        fprintf(fp,"\n%s",wds.backdrop.line{i});
    end
end
fprintf(fp,'\n');
fclose(fp);
end

function write_end(outfile)

fp=fopen(outfile,'a');
fprintf(fp,'\n[END]\n');
fclose(fp);
end
