Global_Node();
Alarm = T1(n_excel,26);
Alarm = table2array(Alarm);
Alarm = str2num(Alarm{1,1});
for i = 4000:var_num
    T2_Alarm = table2array(T2(i,22));
    T2_Alarm = T2_Alarm{1,1};
    T2_Alarm = str2num(T2_Alarm);
    if T2_Alarm == Alarm
        Alarm_type = table2array(T1(n_excel,15));
        Alarm_type = Alarm_type{1,1};
        if Alarm_type == '-'
            Alarm_type = table2array(T1(n_excel,14));
            Alarm_type = Alarm_type{1,1};
        end
        if Alarm_type == '-'
            Alarm_type = table2array(T1(n_excel,13));
            Alarm_type = Alarm_type{1,1};
        end
        Alarm_sig = table2array(T2(i,21));
        Alarm_sig = Alarm_sig{1,1};
        test_var = table2array(T2(i,18));
        test_var = test_var{1,1};
        break
    end
end

test_var = "P_" + test_var;

for i = 5200:var_num
    if table2array(T2(i,18)) == test_var
        en_sig = table2array(T2(i,21));
        en_sig = en_sig{1,1};
        ref_sig = table2array(T2(i+1,21));
        ref_sig = ref_sig{1,1};
        time_sig = table2array(T2(i+2,21));
        time_sig = time_sig{1,1};
        break
    end
end

% Alarm variables
AA = "abMemAICode";
Alarm_type = abs(Alarm_type);
Alarm_type = mat2num(Alarm_type);
AL = abs('AL');
AL = mat2num(AL);
GT = abs('GT');
GT = mat2num(GT);
PT = abs('PT');
PT = mat2num(PT);
SD = abs('SD');
SD = mat2num(SD);
ESD = abs('ESD');
ESD = mat2num(ESD);

if Alarm_type == AL
    alarm_num = sscanf(Alarm_sig, strcat("abMemAlCode[","%d","]"));
    AA = abMemAICode;
elseif Alarm_type == GT
    alarm_num = sscanf(Alarm_sig, strcat("abMemGtCode[","%d","]"));
    AA = abMemGtCode;
elseif Alarm_type == PT
    alarm_num = sscanf(Alarm_sig, strcat("abMemPtCode[","%d","]"));
    AA = abMemPtCode;
    alarm_num = alarm_num;
elseif Alarm_type == SD
    alarm_num = sscanf(Alarm_sig, strcat("abMemSdCode[","%d","]"));
    AA = abMemSdCode;
elseif Alarm_type == ESD
    alarm_num = sscanf(Alarm_sig, strcat("abMemEsdCode[","%d","]"));
    AA = abMemEsdCode;
end
input_num = sscanf(en_sig, strcat("abSf_En[","%d","]"));

% Test type (failure , Low , High)
Test_type = 0; % 0 : failure / 1 : low / 2 : high
code = T1(n_excel,8:9);
for i = 1:2
    A = code{1,i};
    A = A{1,1};
    if A > 0
        Test_type = i;
        break;
    end
end

scale = T1(n_excel,35);
scale = table2array(scale);
scale = str2num(scale{1,1});


code = T1(n_excel,45); code = code{1,1}; code = code{1,1}; code = str2num(code); code1 = code(1); code2 = code(2);
Digit3 = fix(code1/100); Digit2 = rem(code1,100);
str = sprintf('::Modbus_input%d',Digit3);
Modbus_Physical1 = findNodeByName(uaClient.Namespace,str);
Physical_val1 = Modbus_Physical1.Children(Digit2+1);

Digit3 = fix(code2/100); Digit2 = rem(code2,100);
str = sprintf('::Modbus_input%d',Digit3);
Modbus_Physical2 = findNodeByName(uaClient.Namespace,str);
Physical_val2 = Modbus_Physical2.Children(Digit2+1);

code = T1(n_excel,37); code = code{1,1}; code = code{1,1}; code = str2num(code); code1 = code(1); code2 = code(2);
Digit3 = fix(code1/100); Digit2 = rem(code1,100);
str = sprintf('::Modbus_hold%d_2',Digit3);
Modbus_ForceEnable1 = findNodeByName(uaClient.Namespace,str);
Forcing_Val1 = Modbus_ForceEnable1.Children(Digit2+1);

Digit3 = fix(code2/100); Digit2 = rem(code2,100);
str = sprintf('::Modbus_hold%d_2',Digit3);
Modbus_ForceEnable2 = findNodeByName(uaClient.Namespace,str);
Forcing_Val2 = Modbus_ForceEnable2.Children(Digit2+1);

code = T1(n_excel,36); code = code{1,1}; code = code{1,1}; code = str2num(code); code1 = code(1); code2 = code(2);
Digit3 = fix(code1/100); Digit2 = rem(code1,100);
str = sprintf('::Modbus_hold%d_2',Digit3);
Modbus_ForceValue1 = findNodeByName(uaClient.Namespace,str);
Forcing_En1 = Modbus_ForceValue1.Children(Digit2+1);

Digit3 = fix(code2/100); Digit2 = rem(code2,100);
str = sprintf('::Modbus_hold%d_2',Digit3);
Modbus_ForceValue2 = findNodeByName(uaClient.Namespace,str);
Forcing_En2 = Modbus_ForceValue2.Children(Digit2+1);