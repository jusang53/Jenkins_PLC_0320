function [result] = Test_Runner_for_GUI(Test_name, Test_case, fuelmode, opmode, PLC_number)
    % Test_name : GUI에서 선택된 Test들의 이름들
    % Test_case : GUI에서 선택된 Test들의 번호들
    % fuelmode : GUI에서 선택된 fuel mode (diesel : 100, gas : 10, backup : 1)
    % opmode : GUI에서 선택된 run mode (stop : 100, start : 10, run : 1)
    
    clc; close all; format shortg;

    Fulltime = tic;
    Global_Node();  % function형식이기 때문에 Global Node로 전체 변수를 선언해서 사용 가능하도록 함.
    
    plc_no = PLC_number;
    
    test_len = length(Test_case);
    progress_bar_2 = 33;
    
    % Log파일 생성을 위함
    TestNumber = [];
    TestName = [];
    FuelMode = [];
    OperationMode = [];
    ForcingValue = [];
    Passed = [];
    Failed = [];
    TestType = [];
    Note = [];
    
    % Progress bar, h1은 전체 테스트의 진행상황을 표시, h2는 현재 테스트의 진행상황을 표시
    h1 = waitbar(0,'Wait for setting ... ');
    h2 = waitbar(0,'Wait for setting ... ');
    pos_w1 = [585.0000  435.0000  270.0000   56.2500];
    pos_w2 = [585.0000  355.7500  270.0000   56.2500];
    set(h1, 'position', pos_w1)
    set(h2, 'position', pos_w2)
    
    % fuelmode : GUI에서 선택된 fuel mode (diesel : 100, gas : 10, backup : 1)
    Diesel_test = fix(fuelmode/100);
    Gas_test = rem(fix(fuelmode/10),10);
    Backup_test = rem(fuelmode,10);

    % opmode : GUI에서 선택된 run mode (stop : 100, start : 10, run : 1)
    Run_test = fix(opmode/100);
    Stop_test = rem(fix(opmode/10),10);
    Start_test = rem(opmode,10);
    
    run_limit_time = 180;
    c = clock   % 실행 시간
    waitbar(1/(test_len+1),h1,sprintf('Progress : %d/%d, %s', 1, test_len+1, "Setting"))
    waitbar(0,h2,sprintf("New Test"))
    TEST_INIT();    % PLC의 OPC-UA서버에 Connect, OTS모드 실행하기
    latest_Test = "Setting";
    result={};
    for i = 1:length(Test_case)     % 선택된 테스트들 for loop로 실행
        % 재접속을 하여 오랜 시간 테스트를 진행할 때 에러가 나는 것을 방지
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
        
        % 테스트 실행
        result{i,2} = Test_script();
        Reset();
        
        % 임시 로그파일 생성 (테스트 하나 끝날 때마다 생성)
        filename = "";
        d = clock;
        for j = 1:5
            filename = filename + round(d(j)) + "-";
        end
        filename = filename + "SafetyListTest_Log_temp.xlsx";
        log = table(TestNumber, TestName, FuelMode, OperationMode, TestType, ForcingValue, Passed, Failed, Note);
        writetable(log,filename,'Sheet',1)
    end
    
    % 로그파일 생성 (테스트가 모두 끝나면 생성)
    filename = "";
    for i = 1:5
        filename = filename + round(c(i)) + "-";
    end
    filename = filename + "SafetyListTest_Log.xlsx";
    log = table(TestNumber, TestName, FuelMode, OperationMode, TestType, ForcingValue, Passed, Failed, Note)
    writetable(log,filename,'Sheet',1)
    waitbar(test_len/test_len,h1,sprintf('Test Finish'))
    waitbar(test_len/test_len,h2,sprintf('Test Finish'))
    
    pass_test = 0;
    fail_test = 0;
    for i = 1:length(Passed)
        if isequal(Passed(i), "o")
            pass_test = pass_test + 1;
        else
            fail_test = fail_test + 1;
        end            
    end
    contents = sprintf('Success Tests : %d, Fail Tests : %d', pass_test, fail_test);
    mail = 'maze0530@naver.com';            % 보내는 메일
    password = 'maze123123!!!!';            % 보내는 메일 비밀번호
    To_mail = 'maze0530@naver.com';         % 받는 메일
    mail_title = 'Safetylist Test Log';     % 제목
    mail_body = contents;                   % 본문 
    mail_file = convertStringsToChars(filename);                   % 첨부파일
    Send_Report();
    disconnect(uaClient);
end
