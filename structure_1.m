function y = structure_1(fuel,op)
    Global_Node(); % �۷ι� ���� ����
    clock
    normal_test = [0 0 0 0];    % ������� �׽�Ʈ�� �˶� x
    fault_test = [0 1 1 0];     % ������� �׽�Ʈ�� �˶� o
    % ������� �׽�Ʈ ��ǲ ����
    normal = T1(n_excel,47);
    normal = normal{1,1};
    normal = normal{1,1};
    normal_input = T1(n_excel,48);
    normal_input = normal_input{1,1};
    normal_input = str2double(normal_input{1,1});
    % ������� �׽�Ʈ ��ǲ ����
    fault = T1(n_excel,49);
    fault = fault{1,1};
    fault = fault{1,1};
    fault_input = T1(n_excel,50);
    fault_input = fault_input{1,1};
    fault_input = str2double(fault_input{1,1});
    y = 0;
    % Test Structure1�� �׽�Ʈ ���� ���� (forcing ����, ����͸� ���� ��)
    variable_setting1();
    % �׽�Ʈ Condition ���� (���� �� ������ ����)
    Set_Condition(fuel,op);
    % �׽�Ʈ Condition�� �� ���� �ƴ��� Ȯ��
    c = Check_Condition(fuel,op);
    [fmode, rmode] = mode_check(fuel, op);
    Alarm_asrt1 = normal_test;
    Alarm_asrt2 = fault_test;
    note = " ";
    
    % �׽�Ʈ Condition�� �� ���� �Ǿ����� �׽�Ʈ ����, �ƴϸ� �׽�Ʈ ���� ����
    if c == 1
        if isequal(normal,'o')
            waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Normal Test'))
            progress_bar_1 = progress_bar_1 + 1;
            Alarm_asrt1 = test1(normal_input);
            note1 = " ";
        elseif isequal(normal,'o') ~= 1
            waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Normal Test is not selected'))
            progress_bar_1 = progress_bar_1 + 3;
            Alarm_asrt1 = normal_test;
            note1 = "Normal mode is not selected !";
        end
        if isequal(fault,'o')
            waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Fault Test'))
            progress_bar_1 = progress_bar_1 + 1;
            Alarm_asrt2 = test1(fault_input);
            note2 = " ";
        elseif isequal(normal,'o') ~= 1
            waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Fault Test is not selected'))
            progress_bar_1 = progress_bar_1 + 3;
            Alarm_asrt2 = fault_test;
            note2 = "Fault mode is not selected !";
        end
    else
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Set up failed'))
        progress_bar_1 = progress_bar_1 + 4;
        note = "Set fuel/op mode failed !";
    end
    
    % Log ������Ʈ
    if isequal(note," ") ~= 1
        note1 = note;
        note2 = note;
    end
    
    if (isequal(normal,'o') && isequal(Alarm_asrt1,normal_test) && c == 1) || isequal(normal,'o') ~= 1
        Log_update(current_Testname, fmode, rmode, "normal", normal_input, "o", " ", note1);
    else
        Log_update(current_Testname, fmode, rmode, "normal", normal_input, " ", "o", note1);
    end
    
    if (isequal(fault,'o') && isequal(Alarm_asrt2,fault_test) && c == 1) || isequal(fault,'o') ~= 1
        Log_update(current_Testname, fmode, rmode, "fault", fault_input, "o", " ", note2);
    else
        Log_update(current_Testname, fmode, rmode, "fault", fault_input, " ", "o", note2);
    end
    
    % �׽�Ʈ ����� �� ���Դ��� Ȯ��
    if isequal(Alarm_asrt1,normal_test) && isequal(Alarm_asrt2,fault_test) && c == 1
        y = 1;
    end
end