function y = SafetyTest(structure_num,fuel,op)
    Global_Node(); % 글로벌 변수 선언
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Fuel and Run mode Checked !'))  % 3
    progress_bar_1 = progress_bar_1 + 1;
    y = 0;
    
    % 엑셀 파일 내의 Test Structure 별로 테스트 실행
    if structure_num == 1
        y = structure_1(fuel,op);
        Reset();
    end
    if structure_num == 2
        y = structure_2(fuel,op);   % 인풋 개수만 다르고 structure_1과 같은 구조
        Reset();
    end
end