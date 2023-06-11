function fun_setsimulinkblockparameters(powersystemdl,ngen,m_gendata, ...
    v_genscenario,v_igenonline,igenonline,v_iremgenonline, Pn) % v_pshed0MW

% Prepares and sets the parameters of the blocks of the Simulink model.

v_pinit = v_genscenario(v_iremgenonline); % the initial power for the 

% base power to convert everything in pu on system basis
v_Mbase = m_gendata(4,v_iremgenonline);
Sbase = sum(v_Mbase);

% calculate the total generated power by CG
pgenCGtot = 0;
for i=1:ngen+1 % iterate through ALL generators
    pgenCGtot = pgenCGtot + v_genscenario(v_igenonline(i));  % sum the power (in MW) of the all the CGs in the scenario
end
pgenCGtot = pgenCGtot/Sbase; % to make it in pu

% lost amount of power
plostpu = v_genscenario(v_igenonline(igenonline))/Sbase;

% get dynamic parameters of remaining units
v_h = m_gendata(3,v_iremgenonline); % pu on generator rating basis
heq = v_h*v_Mbase(:)/Sbase;
close all

v_kpugenrating = m_gendata(2,v_iremgenonline); % pu on generator rating basis
v_kgpu = v_kpugenrating.*v_Mbase/Sbase;

v_bg1 = m_gendata(7,v_iremgenonline);
v_bg2 = m_gendata(8,v_iremgenonline);
v_ag1 = m_gendata(9,v_iremgenonline);
v_ag2 = m_gendata(10,v_iremgenonline);

[m_Ag,m_Bg,m_Cg,m_Dg] = fun_getstatespace(ngen,v_kgpu,v_bg1,v_bg2,v_ag1,v_ag2);
v_dpgmaxpu = (m_gendata(5,v_iremgenonline)-v_pinit)/Sbase;
v_dpgminpu = (m_gendata(6,v_iremgenonline)-v_pinit)/Sbase;

% set rotor parameters
set_param([powersystemdl,'/Rotor'],'Numerator', '[0 1]','Denominator', ['[2*', sprintf('%f',heq), ' 0]']);

% set generator state space parameters
set_param([powersystemdl,'/State-Space-Gen'],'A',mat2str(m_Ag),'B',mat2str(m_Bg),'C',mat2str(m_Cg),'D',mat2str(m_Dg));

% set generator power limits
set_param([powersystemdl '/Powerlimits'],'UpperLimit',['[' sprintf('%f ',v_dpgmaxpu) ']'],'LowerLimit',['[' sprintf('%f ',v_dpgminpu) ']']);

% set perturbation parameters (plost only)
set_param([powersystemdl '/Perturbation'],'After',['[' sprintf('%f',plostpu) ']'],'Before','0');

% WG-RELATED PARAMETERS
% set system base change parameters (System base only, where the system base is the sum of the Mbase's of the CG)
set_param([powersystemdl '/SystemBaseChange'],'Gain',['[' sprintf('%f',Pn) '/' sprintf('%f',Sbase) ']']);

% set system base change parameters (System base only, where the system base is the sum of the Mbase's of the CG)
set_param([powersystemdl '/SystemBaseChange1'],'Gain',['[' sprintf('%f',Pn) '/' sprintf('%f',Sbase) ']']);

% set total generated power by the CG (the actual one; not the change in
% power generation)
set_param([powersystemdl '/pgenCGtot'],'Value',['[' sprintf('%f ',pgenCGtot) ']']);
