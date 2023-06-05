function fun_graphWindSpeed(igenscenario, igenonline, WGgroupsonline, i_t_delta_vw, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours)

% This function shows several signals (including the frequency) with
% wind drops of 0, 0.5 and 1 m/s magnitude

hf = figure('WindowState','maximized');
subplot(5,1,1);

for i_delta_vw = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(i_delta_vw));hold on;
end
legend('0 m/s', '0.5 m/s', '1 m/s');
ylabel('Freq \omega (Hz)')
hold off;

subplot(5, 1, 2);

for i_delta_vw = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(i_delta_vw));hold on;
end
ylabel('P_{shedded}^{UFLS} (MW)')
hold off;

subplot(5, 1, 3);

for i_delta_vw = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(i_delta_vw));hold on;
end
ylabel('WG pen. (%)')
hold off;

subplot(5, 1, 4);

for i_delta_vw = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(i_delta_vw));hold on;
end
ylabel('P_{gen}^{WG} (MW)')
hold off;

subplot(5, 1, 5);

for i_delta_vw = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(i_delta_vw));hold on;
end
xlabel('Time (s)')
ylabel('P_{gen}^{tot} (MW)')
hold off;

sgt = sgtitle(['Scenario ', num2str(igenscenario), ' with the number ', num2str(igenonline), ' Bus shut off'],'Color',"#0072BD", 'interpreter','latex');
sgt.FontSize = 18;

