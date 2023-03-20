function [result] = Test_Runner_for_GUI(Test_name, Test_case, fuelmode, opmode, PLC_number)
    % Test_name : GUI���� ���õ� Test���� �̸���
    % Test_case : GUI���� ���õ� Test���� ��ȣ��
    % fuelmode : GUI���� ���õ� fuel mode (diesel : 100, gas : 10, backup : 1)
    % opmode : GUI���� ���õ� run mode (stop : 100, start : 10, run : 1)
    
    clc; close all; format shortg;

    Fulltime = tic;
    Global_Node();  % function�����̱� ������ Global Node�� ��ü ������ �����ؼ� ��� �����ϵ��� ��.
    
    plc_no = PLC_number;
    
    test_len = length(Test_case);
    progress_bar_2 = 33;
    
    % Log���� ������ ����
    TestNumber = [];
    TestName = [];
    FuelMode = [];
    OperationMode = [];
    ForcingValue = [];
    Passed = [];
    Failed = [];
    TestType = [];
    Note = [];
    
    % Progress bar, h1�� ��ü �׽�Ʈ�� �����Ȳ�� ǥ��, h2�� ���� �׽�Ʈ�� �����Ȳ�� ǥ��
    h1 = waitbar(0,'Wait for setting ... ');
    h2 = waitbar(0,'Wait for setting ... ');
    pos_w1 = [585.0000  435.0000  270.0000   56.2500];
    pos_w2 = [585.0000  355.7500  270.0000   56.2500];
    set(h1, 'position', pos_w1)
    set(h2, 'position', pos_w2)
    
    % fuelmode : GUI���� ���õ� fuel mode (diesel : 100, gas : 10, backup : 1)
    Diesel_test = fix(fuelmode/100);
    Gas_test = rem(fix(fuelmode/10),10);
    Backup_test = rem(fuelmode,10);

    % opmode : GUI���� ���õ� run mode (stop : 100, start : 10, run : 1)
    Run_test = fix(opmode/100);
    Stop_test = rem(fix(opmode/10),10);
    Start_test = rem(opmode,10);
    
    run_limit_time = 180;
%     c = clock   % ���� �ð�
    waitbar(1/(test_len+1),h1,sprintf('Progress : %d/%d, %s', 1, test_len+1, "Setting"))
    waitbar(0,h2,sprintf("New Test"))
    TEST_INIT();    % PLC�� OPC-UA������ Connect, OTS��� �����ϱ�
    latest_Test = "Setting";
    result={};
    for i = 1:length(Test_case)     % ���õ� �׽�Ʈ�� for loop�� ����
        % �������� �Ͽ� ���� �ð� �׽�Ʈ�� ������ �� ������ ���� ���� ����
        disconnect(uaClient);       
        connect(uaClient);
       
        current_Testname = Test_name{i};
        progress_bar_1 = 0;
        waitbar((i+1)/(test_len+1),h1,sprintf('Progress : %d/%d, %s', i+1, test_len+1, current_Testname))
        Reset();
        toc(Fulltime)
%         clock
        Test_number = Test_case(i);
        result{i,1} = Test_number;
        
        % �׽�Ʈ ����
        result{i,2} = Test_script();
        Reset();
        
        % �ӽ� �α����� ���� (�׽�Ʈ �ϳ� ���� ������ ����)
        filename = "";
        d = clock;
        for j = 1:5
            filename = filename + round(d(j)) + "-";
        end
        filename = filename + "SafetyListTest_Log_temp.xlsx";
        log = table(TestNumber, TestName, FuelMode, OperationMode, TestType, ForcingValue, Passed, Failed, Note);
        writetable(log,filename,'Sheet',1)
    end
    
    % �α����� ���� (�׽�Ʈ�� ��� ������ ����)
    filename = "";
    for i = 1:5
        filename = filename + round(c(i)) + "-";
    end
    filename = filename + "SafetyListTest_Log.xlsx";
    log = table(TestNumber, TestName, FuelMode, OperationMode, TestType, ForcingValue, Passed, Failed, Note)
    writetable(log,filename,'Sheet',1)
    waitbar(test_len/test_len,h1,sprintf('Test Finish'))
    waitbar(test_len/test_len,h2,sprintf('Test Finish'))
    disconnect(uaClient);
end
