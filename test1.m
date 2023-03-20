function Alarm_asrt = test1(input)
    Global_Node(); % �۷ι� ���� ����
    Reset();
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Testing ... '))   % 5
    progress_bar_1 = progress_bar_1 + 1;
    Alarm_asrt = [];
    
    % ������ forcing ������ �� �б�
    forval_og = readValue(Physical_val);
    enable_og = readValue(abSf_En.Children(input_num+1));
    
    % �׽�Ʈ ���� �� �˶��� ���� �ִ��� Ȯ��
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(1) = 1;
    else
        Alarm_asrt(1) = 0;
    end
    
    % forcing �� �ֱ�
    writeValue(abSf_En.Children(input_num+1),1);
    writeValue(bSigForceMode, 1);
    forcing_value = scale * input;
    writeValue(Forcing_Val, forcing_value);
    pause(3);
    writeValue(Forcing_En, 1);
%     writeValue(abSf_En.Children(input_num+1), 1);
    delay = T1(n_excel,12); delay = delay{1,1}; delay = delay{1,1}; delay = sscanf(delay,'%f');
    stop_dt = 10;
    tic
    dt = toc;
    
    % forcing ���� �� �����ϴ��� Ȯ��
    if Alarm_type ~= PT
        Value_check = 0;
        while dt < stop_dt
            Value_check = readValue(Physical_val);
            minv = min(0.95 * forcing_value, 1.05 * forcing_value);
            maxv = max(0.95 * forcing_value, 1.05 * forcing_value);
            if minv < Value_check && maxv > Value_check
                break
            end
            dt = toc;
        end
    end
    pause(0.8 * delay);
    tic
    dt = toc;

    % forcing ���� �Է��� ����, �˶� Ȯ��
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
    
    % �˶��� delay�� �� �����ϴ��� Ȯ��
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(2) = 1;
    else
        Alarm_asrt(2) = 0;
    end

    if Alarm_check == 1
        Alarm_asrt(3) = 1;
    else
        Alarm_asrt(3) = 0;
    end
    
    % forcing ����
    writeValue(bSigForceMode, 0);
    writeValue(Forcing_Val, forval_og);
    writeValue(Forcing_En, 0);
    writeValue(abSf_En.Children(input_num+1), enable_og);
%     writeValue(abSf_En.Children(input_num+1), 0);
    
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
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Reset ... '))	% 6
    progress_bar_1 = progress_bar_1 + 1;
    
    % ���� ���� �˶��� �������� Ȯ��
    Reset();
    if readValue(AA.Children(alarm_num+1)) == 1
        Alarm_asrt(4) = 1;
    else
        Alarm_asrt(4) = 0;
    end
end