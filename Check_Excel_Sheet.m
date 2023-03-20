function y = Check_Excel_Sheet(fuel, op)
    Global_Node();
    global T1;
    y = 0;
    Eng_stop = T1(n_excel, 13);
    Eng_stop = Eng_stop{1,1};
    Eng_stop = Eng_stop{1,1};
    Eng_start = T1(n_excel, 14);
    Eng_start = Eng_start{1,1};
    Eng_start = Eng_start{1,1};
    Eng_run = T1(n_excel, 15);
    Eng_run = Eng_run{1,1};
    Eng_run = Eng_run{1,1};
    
    Eng_fuel = T1(n_excel, 16);
    Eng_fuel = Eng_fuel{1,1};
    Eng_fuel = Eng_fuel{1,1};
    Eng_fuel = abs(Eng_fuel);
    Eng_fuel = mat2num(Eng_fuel);

    % 현재까지 발견한 조건들, 추가 발견 시 추가 기입
    ALL = abs('All');
    DIESEL = abs('Diesel');
    GAS = abs('Gas');
    BACKUP = abs('Backup');
    FSM = abs('FSM');
    DIESEL_or_BACKUP = abs('Diesel/ Backup');
    DIESEL_or_GAS = abs('Diesel/ Gas');
    
    ALL = mat2num(ALL);
    DIESEL = mat2num(DIESEL);
    GAS = mat2num(GAS);
    BACKUP = mat2num(BACKUP);
    DIESEL_or_BACKUP = mat2num(DIESEL_or_BACKUP);
    DIESEL_or_GAS = mat2num(DIESEL_or_GAS);
    
    if fuel == 0
        if op == 1  % start
            if Eng_start == '-'
            else
                y = 1;
            end
        elseif op == 10 % stop
            if Eng_stop == '-'
            else
                y = 1;
            end
        end
    elseif fuel == 100  % Diesel
        if Eng_fuel == ALL || Eng_fuel == DIESEL || Eng_fuel == DIESEL_or_BACKUP || Eng_fuel == DIESEL_or_GAS
            y = 1;
        end
    elseif fuel == 10   % Gas
        if Eng_fuel == ALL || Eng_fuel == GAS || Eng_fuel == DIESEL_or_GAS
            y = 1;
        end
    elseif fuel == 1    % Backup
        if Eng_fuel == ALL || Eng_fuel == BACKUP || Eng_fuel == DIESEL_or_BACKUP
            y = 1;
        end
    end
end