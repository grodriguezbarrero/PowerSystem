function fun_graphGeneratorLoss(igenscenario, WGgroupsonline, i_t_delta_vw, i_delta_vw, m_genscenarios, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours)

% This function shows several signals (including the frequency) with
% different Gens shutting off

ngenonline = length(find(m_genscenarios(igenscenario,:)>0)); % a unit is online if its generation > 0 MW

hf = figure('WindowState','maximized');
subplot(5,1,1);

% labels = cellstr(num2str((1:ngenonline)'));
labels = cellstr(num2str((1:ngenonline)', 'Gen. %d'));

for igenonline = 1:ngenonline
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenonline));hold on;
end
legend(labels);
ylabel('Freq \omega (Hz)')
hold off;

subplot(5, 1, 2);

for igenonline = 1:ngenonline
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenonline));hold on;
end
ylabel('P_{shedded}^{UFLS} (MW)')
hold off;

subplot(5, 1, 3);

for igenonline = 1:ngenonline
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenonline));hold on;
end
ylabel('WG pen. (%)')
hold off;

subplot(5, 1, 4);

for igenonline = 1:ngenonline
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenonline));hold on;
end
ylabel('P_{gen}^{WG} (MW)')
hold off;

subplot(5, 1, 5);

for igenonline = 1:ngenonline
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenonline));hold on;
end
xlabel('Time (s)')
ylabel('P_{gen}^{tot} (MW)')
hold off;

sgt = sgtitle(['Scenario ', num2str(igenscenario)],'Color',"#0072BD", 'interpreter','latex');
sgt.FontSize = 18;

