function Alarm_asrt = test2(input1,input2)
    Global_Node();
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Testing ... '))
    progress_bar_1 = progress_bar_1 + 1;
%     input1 = input(1);
%     input2 = input(2);
    Alarm_asrt = [];
%     fprintf("og forcing val")
    forval_og1 = readValue(Physical_val1);
    forval_og2 = readValue(Physical_val2);
    enable_og = readValue(abSf_En.Children(input_num+1));
    
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(1) = 1;
    else
        Alarm_asrt(1) = 0;
    end
    writeValue(abSf_En.Children(input_num+1),1);
    writeValue(bSigForceMode, 1);
%     fprintf("input forcing val")
    forcing_value1 = scale * input1;
    forcing_value2 = scale * input2;
    writeValue(Forcing_Val1, forcing_value1);
    writeValue(Forcing_Val2, forcing_value2);
    pause(3);
    writeValue(Forcing_En1, 1);
    writeValue(Forcing_En2, 1);
    delay = T1(n_excel,12); delay = delay{1,1}; delay = delay{1,1}; delay = sscanf(delay,'%f');
    stop_dt = 10;
    tic
    dt = toc;
    if Alarm_type ~= PT
        Value_check1 = 0;
        Value_check2 = 0;
        while dt < stop_dt
            Value_check1 = readValue(Physical_val1);
            Value_check2 = readValue(Physical_val2);
            minv1 = min(0.95 * forcing_value1, 1.05 * forcing_value1);
            maxv1 = max(0.95 * forcing_value1, 1.05 * forcing_value1);
            minv2 = min(0.95 * forcing_value2, 1.05 * forcing_value2);
            maxv2 = max(0.95 * forcing_value2, 1.05 * forcing_value2);
            if minv1 < Value_check1 && maxv1 > Value_check1 && minv2 < Value_check2 && maxv2 > Value_check2
                break
            end
            dt = toc;
        end
    end
    pause(0.8 * delay);
    tic
    dt = toc;

    Alarm_check = 0;
    while dt < 0.2 * delay + 0.2
        Alarm_check = readValue(AA.Children(alarm_num+1));
        if Alarm_check == 1
            break
        end
        dt = toc;
    end
    stop_dt = max(delay, 0.5)+delay-0.2;
    tic
    dt = toc;
    if Alarm_check == 0
        while dt < stop_dt
            Alarm_check = readValue(AA.Children(alarm_num+1));
            if Alarm_check == 1
                break
            end
            dt = toc;
        end
    end
    pause(1);
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(2) = 1;
    else
        Alarm_asrt(2) = 0;
    end

%     if Alarm_check == 1 && (dt > delay && dt < max(delay, 0.5)+delay)
    if Alarm_check == 1
        Alarm_asrt(3) = 1;
    else
        Alarm_asrt(3) = 0;
    end

    writeValue(bSigForceMode, 0);
    writeValue(Forcing_Val1, forval_og1);
    writeValue(Forcing_Val2, forval_og2);
    writeValue(Forcing_En1, 0);
    writeValue(Forcing_En2, 0);
    writeValue(abSf_En.Children(input_num+1), enable_og);
    
    if Alarm_type == SD || Alarm_type == ESD
        writeValue(Diesel_mode,0);
        writeValue(Gas_mode,0);
        writeValue(Backup_mode,0);
        tic;
        dt = toc;
        while dt < 120
            speed = readValue(Engine_speed);
            if speed < 1
                break;
            end
            dt = toc;
            pause(1);
        end

        for i = 1:3
            writeValue(bSimReset, 1);
            pause(2)
            writeValue(bSimReset, 0);
            pause(2)
        end
        pause(3)
        for i = 1:3
            writeValue(bSimReset, 1);
            pause(2)
            writeValue(bSimReset, 0);
            pause(2)
        end
    end
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Reset ... '))
    progress_bar_1 = progress_bar_1 + 1;
    Reset();
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(4) = 1;
    else
        Alarm_asrt(4) = 0;
    end
end