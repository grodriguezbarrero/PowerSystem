    % function main_rundynamicsimulation_v2

    % This version aims to provide fewer graphs but more quickly.
    
    % -------------------------------------------------------------------------
    % Predefined values
    % -------------------------------------------------------------------------
    close all;
    
    powersystemdl = 'Powersystem.slx';
    
    load_system('Powersystem');
    
    str_uftype = 'uf';
    str_rocoftype = 'rocof';
    
    fbase = 50;
    tsimulation = 60;
    t0 = 5;
    
    v_essemptydefault = [1000, 80]; % if no ess, use these values for a1, a2, dfracemax
    
    % initialise WG model
    vw_ini        = 10;
    t_wind_change = 60;
    vw_after      = 8;
    [pinitwindgen,wr0, ~, ~, ~, ~, ~, ~, ~, ~, ~,~,~] = fun_WGmodel_startup_v3(vw_ini);
    
    numWG         = 9;
    
    % -------------------------------------------------------------------------
    % Read input data
    % -------------------------------------------------------------------------
    
    disp('Reading data...');
    
    xlsfilename = 'LaPalmaInputData_noESS.xls';
    
    [status, c_sheets] = xlsfinfo(xlsfilename);
    
    % read generator dynamic model data
    m_gendata = xlsread(xlsfilename,c_sheets{1}); 
    
     % read generation scenarios
    m_genscenarios = xlsread(xlsfilename,c_sheets{3});
    m_genscenarios = m_genscenarios(2:end,2:end); % delete first row and column
    
    % correct max and min generation output
    ngen = size(m_gendata,2);
    for igen = 1:ngen
        v_idxcommitted = find(m_genscenarios(:,igen)>0);
        m_gendata(6,igen) = min([m_genscenarios(v_idxcommitted,igen);m_gendata(6,igen)]); % pmax
        m_gendata(5,igen) = max([m_genscenarios(v_idxcommitted,igen);m_gendata(5,igen)]); % pmin
    end
    
    % read ufls parameters
    [m_uflsparam,c_uflsID] = xlsread(xlsfilename,c_sheets{4}); 
    [m_ufparam , m_rocofparam, v_pshed0] = ...
        fun_prepareuflsformat4simulinkformat(m_uflsparam, c_uflsID, str_uftype, str_rocoftype);
    
    v_dfufpu = (m_ufparam(:,1)-fbase)/fbase;
    v_tintuf = m_ufparam(:,3);
    v_topnuf = m_ufparam(:,4);
    
    v_dfrocofpu = (m_rocofparam(:,1)-fbase)/fbase;
    v_dfdtrocofpu = m_rocofparam(:,2)/fbase;
    v_tintrocof = m_rocofparam(:,3);
    v_topnrocof = m_rocofparam(:,4);
    
    % read UC data
    m_essdata = xlsread(xlsfilename,c_sheets{2});
    if isempty(m_essdata)
        m_essdata = zeros(12,1);
        m_essdata([6, 11],1) = v_essemptydefault(1);
        m_essdata(8,1) = v_essemptydefault(2);
    end
    ness = length(m_essdata(1,:));
    
    % -------------------------------------------------------------------------
    % Simulate all possible single generating unit outages
    % -------------------------------------------------------------------------
    
    disp('Simulation start...');
    
    nscenarios = 1;
    m_genscenarios = m_genscenarios(1:nscenarios,:); % REMOVE THIS TO GET ALL SCENARIOS
    
    % preallocate output cells
    nsimulations = length(nonzeros(m_genscenarios));
%     c_t                 = cell(nsimulations,1);
%     c_w                 = cell(nsimulations,1);
%     c_pgentot           = cell(nsimulations,1);
%     c_pufls             = cell(nsimulations,1);
%     c_pgenWGtot         = cell(nsimulations,1);
    isim = nsimulations;
    
    % preallocate output cells, but for the simulations where different WGs are
    % connected
    nsimulations_wg = 4 * nsimulations; % four WG combinations for every generator shut off
    c_t_wg              = cell(nsimulations_wg,1);
    c_w_wg              = cell(nsimulations_wg,1);
    c_pgentot_wg        = cell(nsimulations_wg,1);
    c_pufls_wg          = cell(nsimulations_wg,1);
    c_pgenWGtot_wg      = cell(nsimulations_wg,1);
    c_WGpenetration_wg  = cell(nsimulations_wg,1);
    isim_wg = nsimulations_wg;
    
    ngenscenarios = size(m_genscenarios,1);
    
    % set fix simulation block paramters
    set_param([powersystemdl(1:end-4) '/UFLS'],'v_dfufpu',['[' sprintf('%f ',v_dfufpu) ']'],...
        'v_tintuf',['[' sprintf('%f ',v_tintuf) ']'],'v_topnuf',['[' sprintf('%f ',v_topnuf) ']'],... 
        'v_dfrocofpu',['[' sprintf('%f ',v_dfrocofpu) ']'],'v_dfdtrocofpu',['[' sprintf('%f ',v_dfdtrocofpu) ']'],...
        'v_tintrocof',['[' sprintf('%f ',v_tintrocof) ']'],'v_topnrocof',['[' sprintf('%f ',v_topnrocof) ']']); % set UFLS parameters 
    
    set_param([powersystemdl(1:end-4) '/Perturbation'],'time',['[' sprintf('%f',t0) ']'],'Sampletime','0'); % set perturbation parameters 
    
    set_param(powersystemdl(1:end-4),'StopTime',sprintf('%f',tsimulation));
    
    set_param([powersystemdl(1:end-4) '/Wind'],'time',['[' sprintf('%f',t_wind_change) ']'], 'After',['[' sprintf('%f',vw_after) ']'], ...
        'Before',['[' sprintf('%f',vw_ini) ']']);
    
    for i = 0:numWG-1
        set_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'pinitwindgen',sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0));
    end

    % simulate each scenario
    for igenscenario = ngenscenarios:-1:1
        
        fprintf('Scenario: %i', igenscenario);
        
        % get generation scenario
        v_genscenario = m_genscenarios(igenscenario,:); % generation of each unit in MW
        pdem_CG = sum(v_genscenario); % demand = sum of generation (in MW)
%         v_pshed0MW = v_pshed0/100*pdem;
        
        % get online units
        v_igenonline = find(v_genscenario>0); % a unit is online if its generation > 0 MW
        ngenonline = length(v_igenonline);
        
    
        % simulate every single generator outage
        for igenonline = 1:ngenonline
            
            % remaining units
            v_iremgenonline = v_igenonline;
            v_iremgenonline(igenonline) = []; % take out the lost generator
            ngen = length(v_iremgenonline);
    
            % set model parameters
            fun_setsimulinkblockparameters(powersystemdl(1:end-4),ngen,m_gendata,ness,m_essdata, ...
                v_genscenario,v_igenonline,igenonline,v_iremgenonline); %v_pshed0MW
            
            %if igenonline == 1 % for the FIRST GENERATOR DOWN in each scenario
                for nWGgroupsonline = 0:3
                    
                    % base power to convert everything in pu on system basis
                    v_Mbase = m_gendata(4,v_iremgenonline);
                    Sbase = sum(v_Mbase);

                    pdem = pdem_CG + nWGgroupsonline*3*pinitwindgen*1.5;  % total demand in MW (Pn = 1.5 MW)
                    v_pshed0MW = v_pshed0/100*pdem;                    

                    v_pshed0pu = v_pshed0MW/Sbase;
                    % set UFLS parameters (step size only)
                    set_param([powersystemdl(1:end-4) '/UFLS'],'v_pshed0pu',['[' sprintf('%f ',v_pshed0pu) ']']);


                    % set the right number of WGs
                    set_param([powersystemdl(1:end-4) '/numWG'],'Value',['[' sprintf('%f',4-nWGgroupsonline) ':4]']);
                    % simulate it and store results
                    [c_t_wg{isim_wg},~,c_w_wg{isim_wg},c_pgentot_wg{isim_wg},c_pufls_wg{isim_wg}, c_pgenWGtot_wg{isim_wg},c_WGpenetration_wg{isim_wg}] = sim(powersystemdl);
                    isim_wg = isim_wg - 1;
                end
            %end
            
%             set_param([powersystemdl(1:end-4) '/numWG'],'Value','4');
    
%             [c_t{isim},~,c_w{isim},c_pgentot{isim},c_pufls{isim}, c_pgenWGtot{isim},~] = sim(powersystemdl); % ~ means that the output is not used
%             isim = isim-1;
    
        end
        
    end
    
    disp('Simulation stops.');
    
    % close_system(powersystemdl,0);
    
    %% -------------------------------------------------------------------------
    % Display frequency variations for different scenarios
    % -------------------------------------------------------------------------
    
    close all;

    v_legend    = strings(1,nsimulations);
    v_colours   = ["#EDB120" "#7E2F8E" "#77AC30" "#4DBEEE" "#A2142F" "#AE43F0" "#0076A8" "#0072BD" "#D95319"];
    
    % m_genscenarios
    num_scenarios           = length(m_genscenarios(:,1));
    num_gen_in_total        = length(m_genscenarios(1,:));
    isim = nsimulations;
    
    isim_wg = nsimulations_wg;
    
%     for i_scenario = 1:num_scenarios            % iterate through each scenario
%         
%         hf1 = figure;axes
%         ha1 = hf1.CurrentAxes;
%     
%         sim_in_scenario = 0;
%     
%         for j_simulation = 1:num_gen_in_total   % iterate through every generator
%             
%             if m_genscenarios(i_scenario, j_simulation) ~= 0
%                 sim_in_scenario = sim_in_scenario + 1;
%                 plot(ha1,c_t{isim},c_w{isim}*fbase,'Color',v_colours(j_simulation));hold on;
%                 isim = isim - 1;
%                 % add new label to the legend. +10 is added because the
%                 % generator number labels start at 11.
%                 v_legend(sim_in_scenario) = strcat("Bus ", num2str(j_simulation+10)); % shows the disconnected generator
%                 
%             end
%         end
%         title(['Scenario ', num2str(i_scenario)]);
%         legend(v_legend);
%         xlabel(ha1,'Time (s)')
%         ylabel(ha1,'Frequency deviation \Delta\omega (Hz)')
%         hold off;
%     end


    for i_scenario = 1:num_scenarios            % iterate through each scenario
        for j_simulation = 1:num_gen_in_total   % iterate through every generator
                        
            if m_genscenarios(i_scenario, j_simulation) ~= 0
                % add new label to the legend. +10 is added because the
                % generator number labels start at 11.
                
                hf = figure('WindowState','maximized');
                subplot(3,1,1);

                for sim_in_scenario_wg = 1:4   % four sub-scenarios: 0, 1, 2, and 3 WGs
                    plot(c_t_wg{isim_wg},fbase+c_w_wg{isim_wg}*fbase,'Color',v_colours(sim_in_scenario_wg));hold on;
                    isim_wg = isim_wg - 1;
                end
                title('Frequency');
                legend('Zero WG', '3 WGs', '6 WGs', '9 WGs');
                xlabel('Time (s)')
                ylabel('Frequency \omega (Hz)') % ylabel('Frequency deviation \Delta\omega (Hz)')
                hold off;
                
                subplot(3, 1, 2);
                isim_wg = isim_wg + 4;

                for sim_in_scenario_wg = 1:4   % four sub-scenarios: 0, 3, 6, and 9 WGs
                    plot(c_t_wg{isim_wg},c_pufls_wg{isim_wg},'Color',v_colours(sim_in_scenario_wg));hold on;
                    isim_wg = isim_wg - 1;
                end
                title('Power shedded by UFLS');
                legend('Zero WG', '3 WG', '6 WGs', '9 WGs');
                xlabel('Time (s)')
                ylabel('Total power shedded by UFLS (pu)')
                hold off;
                
                subplot(3, 1, 3);
                isim_wg = isim_wg + 4;

                for sim_in_scenario_wg = 1:4   % four sub-scenarios: 0, 3, 6, and 9 WGs
                    plot(c_t_wg{isim_wg},c_WGpenetration_wg{isim_wg},'Color',v_colours(sim_in_scenario_wg));hold on;
                    isim_wg = isim_wg - 1;
                end
                title('WG penetration');
                legend('Zero WG', '3 WGs', '6 WGs', '9 WGs');
                xlabel('Time (s)')
                ylabel('WG penetration (%)')
                hold off;
                
                sgt = sgtitle(['Scenario ', num2str(i_scenario), ' with Bus ', num2str(j_simulation+10), ' shut off'],'Color',"#0072BD");
                sgt.FontSize = 18;
            end
        end
    end
