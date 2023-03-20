function result = Test_script()
    Global_Node(); % 글로벌 변수 선언

    waitbar(1/progress_bar_2,h2,sprintf('Test Setting'))
    progress_bar_1 = progress_bar_1 + 1;    % 1
    Test_Setting(); % 테스트가 엑셀 몇 번째 줄에 위치하는지 찾기
    
    result = 0;
    Test_result = [];    
    
    % Run+Diesel 모드
    progress_bar_1 = 2;
    if Diesel_test == 1 && Run_test == 1
        x = 0;
        waitbar(2/progress_bar_2,h2,sprintf('Check Diesel Mode from Safetylist'))  % 2
        progress_bar_1 = progress_bar_1 + 1;
        y = Check_Excel_Sheet(100,100); % 엑셀 파일에 Run + Diesel모드가 존재하는지 확인
        if y == 1
            x = SafetyTest(test_structure,100,100); % 테스트 실행
        else
            x = 1;
            note = "The test will not be carried out in this condition";
        end
        Test_result = [Test_result; x];
    else
%         progress_bar_1 = 2;
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Diesel and Run mode are not selected'))
        progress_bar_1 = progress_bar_1 + 1;
        Test_result = [Test_result; 1];
    end
    progress_bar_1 = 8;
    if Gas_test == 1 && Run_test == 1
        x = 0;
%         progress_bar_1 = 8;
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Check Gas Mode from Safetylist'))  % 2
        progress_bar_1 = progress_bar_1 + 1;
        y = Check_Excel_Sheet(10,100);
        if y == 1
            x = SafetyTest(test_structure,10,100);
        else
            x = 1;
            note = "The test will not be carried out in this condition";
        end
        Test_result = [Test_result; x];
    else
        waitbar(2/progress_bar_2,h2,sprintf('Gas and Run mode are not selected'))
        progress_bar_1 = progress_bar_1 + 1;
        Test_result = [Test_result; 1];
    end
    progress_bar_1 = 14;
    if Backup_test == 1 && Run_test == 1
        x = 0;
%         progress_bar_1 = 14;
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Check Backup Mode from Safetylist'))  % 2
        progress_bar_1 = progress_bar_1 + 1;
        y = Check_Excel_Sheet(1,100);
        if y == 1
            x = SafetyTest(test_structure,1,100);
        else
            x = 1;
            note = "The test will not be carried out in this condition";
        end
        Test_result = [Test_result; x];
    else
        waitbar(2/progress_bar_2,h2,sprintf('Backup and Run mode are not selected'))
        progress_bar_1 = progress_bar_1 + 1;
        Test_result = [Test_result; 1];
    end
    progress_bar_1 = 20;
    if Stop_test == 1
        x = 0;
%         progress_bar_1 = 20;
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Check Stop Mode from Safetylist'))  % 2
        progress_bar_1 = progress_bar_1 + 1;
        y = Check_Excel_Sheet(0,10);
        if y == 1
            x = SafetyTest(test_structure,0,10);
        else
            x = 1;
            note = "The test will not be carried out in this condition";
        end
        Test_result = [Test_result; x];
    else
        waitbar(2/progress_bar_2,h2,sprintf('Stop mode is not selected'))
        progress_bar_1 = progress_bar_1 + 1;
        Test_result = [Test_result; 1];
    end
    progress_bar_1 = 26;
    if Start_test == 1
        x = 0;
%         progress_bar_1 = 26;
        waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Check Start Mode from Safetylist'))  % 2
        progress_bar_1 = progress_bar_1 + 1;
        y = Check_Excel_Sheet(0,1);
        if y == 1
            x = SafetyTest(test_structure,0,1);
        else
            x = 1;
            note = "The test will not be carried out in this condition";
        end
        Test_result = [Test_result; x];
    else
        waitbar(2/progress_bar_2,h2,sprintf('Start mode is not selected'))
        progress_bar_1 = progress_bar_1 + 1;
        Test_result = [Test_result; 1];
    end
    
    if isequal(Test_result, [1 1 1 1 1]')
        result = 1;
    end
end