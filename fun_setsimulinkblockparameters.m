function fun_setsimulinkblockparameters(powersystemdl,ngen,m_gendata,ness, ...
    m_essdata,v_genscenario,v_igenonline,igenonline,v_iremgenonline,v_pshed0MW)

% fun_prepareuflsformat4simulinkformat
% Prepares and sets the parameters of the blocks of the Simulink model.
%
% Parameters are all in pu on system power and frequency basis

v_pinit = v_genscenario(v_iremgenonline);

% base power to convert everything in pu on system basis
v_Mbase = m_gendata(4,v_iremgenonline);
Sbase = sum(v_Mbase);

% ----
% calculate the total generated power
pgenCGtot = 0;
for i=1:ngen % iterate through every remaining generator
    pgenCGtot = pgenCGtot + v_genscenario(v_iremgenonline(i));  % sum the power of the remaining generator in question
end
pgenCGtot = pgenCGtot/Sbase;
% ----

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

% load shedding in pu on system basis
v_pshed0pu = v_pshed0MW/Sbase;

% get dynamic parameters of ess
v_kesspu = m_essdata(2,1).*m_essdata(3,1)/Sbase;

v_bess1 = m_essdata(9,1);
v_bess2 = m_essdata(10,1);
v_aess1 = m_essdata(11,1);
v_aess2 = m_essdata(12,1);

[m_Aess,m_Bess,m_Cess,m_Dess] = fun_getstatespace(ness,v_kesspu,v_bess1,v_bess2,v_aess1,v_aess2);
dpessmaxpu = m_essdata(4,1)/Sbase;
dpessminpu = m_essdata(5,1)/Sbase;
deessmaxpu = m_essdata(6,1)/Sbase;
deessminpu = m_essdata(7,1)/Sbase;

fracdeessmax = deessmaxpu*m_essdata(8,1)/100;

% set rotor parameters
set_param([powersystemdl,'/Rotor'],'Numerator', '[0 1]','Denominator', ['[2*', sprintf('%f',heq), ' 0]']);

% set generator state space parameters
set_param([powersystemdl,'/State-Space-Gen'],'A',mat2str(m_Ag),'B',mat2str(m_Bg),'C',mat2str(m_Cg),'D',mat2str(m_Dg));

% set generator power limits
set_param([powersystemdl '/Powerlimits'],'UpperLimit',['[' sprintf('%f ',v_dpgmaxpu) ']'],'LowerLimit',['[' sprintf('%f ',v_dpgminpu) ']']);

% set ess state space parameters
set_param([powersystemdl,'/State-Space-ESS'],'A',mat2str(m_Aess),'B',mat2str(m_Bess),'C',mat2str(m_Cess),'D',mat2str(m_Dess));

% set ess energy limits
set_param([powersystemdl '/Energylimits'],'dpmax',['[' sprintf('%f ',dpessmaxpu) ']'],'dpmin',['[' sprintf('%f ',dpessminpu) ']'],...
    'demax',['[' sprintf('%f ',deessmaxpu) ']'],'demin',['[' sprintf('%f ',deessminpu) ']'],'fracdemax',['[' sprintf('%f ',fracdeessmax) ']']);

% set UFLS parameters (step size only)
set_param([powersystemdl '/UFLS'],'v_pshed0pu',['[' sprintf('%f ',v_pshed0pu) ']']);

% set perturbation parameters (plost only)
set_param([powersystemdl '/Perturbation'],'After',['[' sprintf('%f',plostpu) ']'],'Before','0');

% WG-RELATED PARAMETERS
% set system base change parameters (System base only, where the system base is the sum of the Mbase's of the CG)
set_param([powersystemdl '/SystemBaseChange'],'Gain',['[1.5/' sprintf('%f',Sbase) ']']);

% set system base change parameters (System base only, where the system base is the sum of the Mbase's of the CG)
set_param([powersystemdl '/SystemBaseChange1'],'Gain',['[1.5/' sprintf('%f',Sbase) ']']);

% set total generated power by the CG (the actual one; not the change in
% power generation)
set_param([powersystemdl '/pgenCGtot'],'Value',['[' sprintf('%f ',pgenCGtot) ']']);

% % set WG parameters
% set_param([powersystemdl '/WindGenerator'],'Hw',sprintf('%f',Hw),'Tc1',sprintf('%f',Tc1),'Tc2',sprintf('%f',Tc2),'R',sprintf('%f',R), 'pinitwindgen', ...
%     sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0),'v_vw',['[' sprintf('%f ',v_vw) ']'],'v_wr',['[' sprintf('%f ',v_wr) ']'],'m_pw',mat2str(m_pw), ...
%     'v_wrdel',['[' sprintf('%f ',v_wrdel) ']'],'v_pwdel',['[' sprintf('%f ',v_pwdel) ']'],'v_wrmpp',['[' sprintf('%f ',v_wrmpp) ']'],'v_pwmpp',['[' sprintf('%f ',v_pwmpp) ']']);
